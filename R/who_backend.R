# WHO provider configuration and read-only OData transport. No disk cache.
.who_config <- function(backend = NULL) {
  from_option <- is.null(backend)
  if (from_option) backend <- getOption('DSIR.who_backend', 'legacy')
  if (!is.character(backend) || length(backend) != 1L || is.na(backend) ||
      !backend %in% c('xmart', 'legacy')) {
    if (from_option) cli::cli_abort('Option {.code DSIR.who_backend} must be "xmart" or "legacy".')
    cli::cli_abort('{.arg backend} must be "xmart" or "legacy".')
  }
  base <- getOption('DSIR.who_base_url', 'https://xmart-api-public.who.int')
  if (!is.character(base) || length(base) != 1L || is.na(base) ||
      !grepl('^https://[^/?#]+$', sub('/$', '', base))) {
    cli::cli_abort('Option {.code DSIR.who_base_url} must be an HTTPS origin.')
  }
  list(backend = backend, base = sub('/$', '', base))
}

.who_cache <- new.env(parent = emptyenv())
.who_cached <- function(key, fetch) {
  # These reference caches serve xMart, including GHE, independently of
  # the selected GHO backend. Per-call selection never changes options.
  config <- .who_config('xmart')
  key <- paste(config$backend, config$base, key, sep = '|')
  saved <- .who_cache[[key]]
  if (!is.null(saved) && as.numeric(difftime(Sys.time(), saved$time, units = 'secs')) < 600) {
    return(saved$value)
  }
  value <- fetch()
  if (is.data.frame(value) && nrow(value) > 0L) {
    .who_cache[[key]] <- list(time = Sys.time(), value = value)
  }
  value
}

.who_codes <- function(x, name, numeric = FALSE) {
  if (is.null(x)) return(NULL)
  if ((!is.character(x) && !(numeric && is.numeric(x))) || !length(x) ||
      anyNA(x) || any(!nzchar(as.character(x)))) {
    cli::cli_abort('{.arg {name}} must contain non-missing codes.')
  }
  unique(as.character(x))
}
.who_year <- function(x, name) {
  if (is.null(x)) return(NULL)
  if (!is.numeric(x) || !length(x) || anyNA(x) || any(!is.finite(x)) ||
      any(abs(x) > .Machine$integer.max) ||
      any(x != as.integer(x))) cli::cli_abort('{.arg {name}} must contain integer years.')
  as.integer(x)
}
.who_in <- function(field, values, numeric = FALSE) {
  if (is.null(values)) return(character())
  values <- if (numeric) as.character(values) else paste0("'", gsub("'", "''", values, fixed = TRUE), "'")
  # Verified on production: compact `in` lists avoid xMart's 100-node
  # expression limit, which a regional vector expressed as OR can exceed.
  if (length(values) > 1L) return(paste0('(', field, ' in (', paste(values, collapse = ','), '))'))
  paste0('(', field, ' eq ', values, ')')
}
.who_and <- function(...) paste(unlist(list(...)), collapse = ' and ')
.who_search <- function(df, column, search) {
  if (is.null(search) || !nrow(df)) return(df)
  search <- .who_codes(search, 'search')
  terms <- if (length(search) == 1L) strsplit(search, '\\s+')[[1]] else search
  keep <- rep(TRUE, nrow(df))
  for (term in terms) keep <- keep & grepl(tolower(term), tolower(df[[column]]), fixed = TRUE)
  df[keep & !is.na(keep), , drop = FALSE]
}

.who_query <- function(path, params) {
  config <- .who_config('xmart')
  stopifnot(grepl('^[A-Za-z0-9_]+/[A-Za-z0-9_]+$', path))
  params <- params[!vapply(params, is.null, logical(1))]
  query <- paste(paste0(names(params), '=', vapply(params, as.character, character(1))), collapse = '&')
  encoded <- paste(paste0(names(params), '=', vapply(params, function(x) {
    utils::URLencode(as.character(x), reserved = TRUE)
  }, character(1))), collapse = '&')
  url <- paste0(config$base, '/', path)
  # The public xMart $query endpoint accepts a query string in a text body.
  req <- if (nchar(encoded, type = 'bytes') > 1800L) {
    .dsi_request(paste0(url, '/$query'), retry_on_html = TRUE) |>
      httr2::req_method('POST') |>
      httr2::req_body_raw(query, type = 'text/plain')
  } else .dsi_request(paste0(url, '?', encoded), retry_on_html = TRUE)
  cli::cli_inform('Fetching WHO: {.val {path}}')
  resp <- tryCatch(httr2::req_perform(req), error = function(e) {
    msg <- conditionMessage(e)
    cli::cli_warn(c('WHO request failed; no observations returned.', 'x' = '{msg}'))
    NULL
  })
  if (is.null(resp)) return(NULL)
  if (httr2::resp_content_type(resp) %in% c('text/html', 'application/xhtml+xml')) {
    cli::cli_warn(c('WHO API returned an HTML page instead of JSON; no observations returned.',
      'i' = 'The service may be temporarily unavailable. Retry later; this is not a valid empty data result.'))
    return(NULL)
  }
  tryCatch(httr2::resp_body_json(resp, simplifyVector = TRUE), error = function(e) {
    msg <- conditionMessage(e)
    cli::cli_warn(c('WHO response could not be parsed as JSON.', 'x' = '{msg}'))
    NULL
  })
}

.who_odata <- function(path, filter = NULL, select = NULL, group = NULL,
                       mode = c('data', 'count', 'exists'), order = 'Sys_PK') {
  mode <- match.arg(mode)
  size <- getOption('DSIR.who_page_size', 5000L)
  limit <- getOption('DSIR.who_max_rows', 1000000L)
  stopifnot(length(size) == 1L, is.finite(size), size >= 1, size <= 120000,
            length(limit) == 1L, is.finite(limit), limit >= 1)
  size <- as.integer(size)
  if (!is.null(group)) {
    apply <- paste0('groupby((', paste(group, collapse = ','), '))')
    if (!is.null(filter) && nzchar(filter)) apply <- paste0('filter(', filter, ')/', apply)
    filter <- NULL
    order <- paste(group, collapse = ',')
  } else apply <- NULL
  params <- list('$filter' = if (!is.null(filter) && nzchar(filter)) filter else NULL,
                 '$select' = if (!is.null(select)) paste(select, collapse = ',') else NULL,
                 '$apply' = apply, '$orderby' = order,
                 '$count' = if (is.null(group)) 'true' else NULL)
  chunks <- list()
  offset <- 0L
  total <- NULL
  previous <- NULL
  repeat {
    params[['$top']] <- if (mode == 'data') size else 1L
    params[['$skip']] <- if (offset == 0L && !is.null(group)) NULL else offset
    body <- .who_query(path, params)
    if (is.null(body)) return(NULL)
    if (!is.list(body) || is.null(body$value) ||
        !(is.data.frame(body$value) || identical(body$value, list()))) {
      cli::cli_warn('Malformed WHO OData envelope; no observations returned.')
      return(NULL)
    }
    count <- if (is.null(group)) body[['@odata.count']] else 0
    if (is.null(count) || length(count) != 1L || !is.numeric(count) ||
        !is.finite(count) || count < 0 || count != floor(count)) {
      cli::cli_warn('WHO response lacks a valid row count; completeness cannot be verified.')
      return(NULL)
    }
    if (mode == 'count') return(if (count > .Machine$integer.max) as.numeric(count) else as.integer(count))
    if (mode == 'exists') return(count > 0)
    if (is.null(total)) total <- count
    if (count != total) {
      cli::cli_warn('WHO row count changed during pagination; incomplete download discarded.')
      return(NULL)
    }
    if (is.null(group) && total > limit) {
      cli::cli_warn('WHO query exceeds {.val {limit}} rows. Narrow the filters or explicitly raise {.code DSIR.who_max_rows}.')
      return(NULL)
    }
    chunk <- body$value
    n <- if (is.data.frame(chunk)) nrow(chunk) else 0L
    # xMart's grouped @odata.count can describe underlying facts, not groups.
    # A short group page is complete because our requested top is below the
    # documented public cap (120000). Full pages require another request.
    if (!is.null(group) && n == 0L) break
    if (total == 0 && n == 0L) return(tibble::tibble())
    if (n == 0L || n > size || (is.null(group) && offset + n > total) || identical(chunk, previous)) {
      cli::cli_warn('Unexpected or repeated WHO page; incomplete download discarded.')
      return(NULL)
    }
    if (length(chunks) && !identical(names(chunk), names(previous))) {
      cli::cli_warn('WHO page schema changed; incomplete download discarded.')
      return(NULL)
    }
    chunks[[length(chunks) + 1L]] <- chunk
    offset <- offset + n
    if (offset > limit) {
      cli::cli_warn('WHO grouped query exceeds the download limit; narrow the filters.')
      return(NULL)
    }
    if (is.null(group) && offset == total) break
    if (!is.null(group) && n < size) break
    previous <- chunk
  }
  if (!length(chunks)) return(tibble::tibble())
  out <- tryCatch(vctrs::vec_rbind(!!!chunks), error = function(e) NULL)
  if (is.null(out)) {
    cli::cli_warn('Incompatible WHO page types; incomplete download discarded.')
    return(NULL)
  }
  if (!is.null(order) && order %in% names(out) && anyDuplicated(out[[order]])) {
    cli::cli_warn('Duplicate WHO observation identifiers; incomplete download discarded.')
    return(NULL)
  }
  out <- tibble::as_tibble(out)
  attr(out, 'who_provenance') <- list(backend = 'xmart', base_url = .who_config('xmart')$base,
                                    table = path, filter = filter, retrieved = format(Sys.time(), tz = 'UTC'),
                                    complete = TRUE, rows = nrow(out))
  out
}

.who_distinct <- function(path, fields, filter = NULL) {
  .who_odata(path, filter = filter, group = fields)
}

.who_reference <- function(path, top = 1000L) {
  # Small reference views can have expensive count/order expressions. Request
  # below the public cap and require a short page; never accept a full page
  # as a complete reference catalog.
  body <- .who_query(path, list('$top' = as.integer(top)))
  if (is.null(body)) return(NULL)
  if (!is.list(body)) {
    cli::cli_warn('WHO reference response is incomplete or malformed; no codes returned.')
    return(NULL)
  }
  if (identical(body$value, list())) return(tibble::tibble())
  if (!is.data.frame(body$value) || nrow(body$value) >= top ||
      !is.null(body[['@odata.nextLink']])) {
    cli::cli_warn('WHO reference response is incomplete or malformed; no codes returned.')
    return(NULL)
  }
  if (!all(c('CODE', 'TITLE') %in% names(body$value))) {
    cli::cli_warn('Malformed WHO reference schema; no codes returned.')
    return(NULL)
  }
  tibble::as_tibble(body$value)
}
