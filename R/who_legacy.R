# Legacy GHO adapter is the compatibility default.
# Backend selection is explicit; requests never fall back between providers.
.legacy_gho_indicators <- function(search = NULL) {
    url <- .gho_indicators_build_url(search)
    res <- .gho_get(url)
    if (is.null(res) || nrow(res) == 0L) {
        return(tibble::tibble(IndicatorCode = character(), IndicatorName = character(), Language = character()))
    }
    res[, c("IndicatorCode", "IndicatorName", "Language")]
}

.legacy_gho_data <- function(indicator, spatial_type = NULL, area = NULL, year_from = NULL, year_to = NULL,
    dim1 = NULL, dim2 = NULL, dim3 = NULL, dimensions = NULL) {
    if (!is.null(dimensions)) cli::cli_abort("Named dimensions require the xMart backend.")
    url <- .gho_build_url(indicator, spatial_type = spatial_type, area = area, year_from = year_from,
        year_to = year_to, dim1 = dim1, dim2 = dim2, dim3 = dim3)
    res <- .gho_get(url, indicator = indicator)
    if (is.null(res)) return(tibble::tibble())
    if (!nrow(res)) .gho_inform_empty('legacy')
    res
}

.legacy_gho_has_data <- function(indicator, spatial_type = NULL, area = NULL, year_from = NULL, year_to = NULL,
    dim1 = NULL, dim2 = NULL, dim3 = NULL, dimensions = NULL) {
    if (!is.null(dimensions)) cli::cli_abort("Named dimensions require the xMart backend.")
    url <- .gho_build_url(indicator, spatial_type = spatial_type, area = area, year_from = year_from,
        year_to = year_to, dim1 = dim1, dim2 = dim2, dim3 = dim3, top = 1, select = "Id")
    res <- .gho_get(url, indicator = indicator)
    if (is.null(res))
        return(NA)
    if (!nrow(res)) .gho_inform_empty('legacy')
    nrow(res) > 0L
}

.legacy_gho_count <- function(indicator, spatial_type = NULL, area = NULL, year_from = NULL, year_to = NULL,
    dim1 = NULL, dim2 = NULL, dim3 = NULL, dimensions = NULL) {
    if (!is.null(dimensions)) cli::cli_abort("Named dimensions require the xMart backend.")
    url <- .gho_build_url(indicator, spatial_type = spatial_type, area = area, year_from = year_from,
        year_to = year_to, dim1 = dim1, dim2 = dim2, dim3 = dim3, top = 0, count = TRUE)
    resp <- .legacy_gho_request(url, indicator)
    if (is.null(resp))
        return(NA_integer_)
    body <- tryCatch(httr2::resp_body_json(resp, simplifyVector = TRUE), error = function(e) {
        msg <- conditionMessage(e)
        cli::cli_warn(c("GHO response could not be parsed as JSON.", i = "URL: {.url {url}}", x = "{msg}"))
        NULL
    })
    if (is.null(body))
        return(NA_integer_)
    cnt <- if (is.list(body)) body[["@odata.count"]] else NULL
    if (is.null(cnt) || !is.numeric(cnt) || length(cnt) != 1L ||
        !is.finite(cnt) || cnt < 0 || cnt != floor(cnt) || cnt > .Machine$integer.max) {
        cli::cli_warn('GHO response lacks a valid integer row count; availability is unknown.')
        return(NA_integer_)
    }
    if (cnt == 0) .gho_inform_empty('legacy')
    as.integer(cnt)
}

.legacy_gho_coverage <- function(indicator, spatial_type = "country", area = NULL, year_from = NULL,
    year_to = NULL, dim1 = NULL, dim2 = NULL, dim3 = NULL, dimensions = NULL) {
    if (!is.null(dimensions)) cli::cli_abort("Named dimensions require the xMart backend.")
    empty <- tibble::tibble(location = character(), year_min = integer(), year_max = integer(), n_obs = integer())
    url <- .gho_build_url(indicator, spatial_type = spatial_type, area = area, year_from = year_from,
        year_to = year_to, dim1 = dim1, dim2 = dim2, dim3 = dim3, select = c("SpatialDim", "TimeDim"))
    res <- .gho_get(url, indicator = indicator)
    if (!is.null(res) && !nrow(res)) .gho_inform_empty('legacy')
    if (is.null(res) || nrow(res) == 0L)
        return(empty)
    if (!all(c("SpatialDim", "TimeDim") %in% names(res))) {
        cli::cli_warn('Malformed GHO coverage response; no data returned.')
        return(empty)
    }
    loc <- as.character(res$SpatialDim)
    yr <- suppressWarnings(as.integer(res$TimeDim))
    by_loc <- split(yr, loc)
    by_loc <- by_loc[order(names(by_loc))]
    yr_range <- function(x, fn) {
        x <- x[!is.na(x)]
        if (length(x) == 0L)
            NA_integer_
        else as.integer(fn(x))
    }
    tibble::tibble(location = names(by_loc), year_min = vapply(by_loc, yr_range, integer(1), fn = min),
        year_max = vapply(by_loc, yr_range, integer(1), fn = max), n_obs = vapply(by_loc, length, integer(1)))
}

.legacy_gho_dimensions <- function(indicator, dimension = "SpatialDimType") {
    stopifnot(is.character(indicator), length(indicator) == 1L, nzchar(indicator))
    stopifnot(is.character(dimension), length(dimension) == 1L, nzchar(dimension))
    url <- .gho_build_url(indicator, select = dimension)
    res <- .gho_get(url, indicator = indicator)
    if (is.null(res) || !dimension %in% names(res))
        return(character())
    vals <- unique(res[[dimension]])
    sort(vals[!is.na(vals)])
}


#' @noRd
.gho_indicators_build_url <- function(search = NULL) {
  base_url <- "https://ghoapi.azureedge.net/api/Indicator"
  if (is.null(search)) return(base_url)

  stopifnot(
    is.character(search),
    length(search) >= 1L,
    !anyNA(search),
    all(nzchar(search))
  )

  terms <- if (length(search) == 1L) {
    strsplit(search, "\\s+")[[1]]
  } else {
    search
  }
  terms <- terms[nzchar(terms)]
  stopifnot(length(terms) >= 1L)

  terms_escaped <- gsub("'", "''", tolower(terms), fixed = TRUE)
  clauses <- paste0("contains(tolower(IndicatorName),'", terms_escaped, "')")
  filter <- paste(clauses, collapse = " and ")
  paste0(base_url, "?$filter=", utils::URLencode(filter, reserved = TRUE))
}

#' @noRd
.gho_build_url <- function(indicator, spatial_type = NULL, area = NULL,
                           year_from = NULL, year_to = NULL,
                           dim1 = NULL, dim2 = NULL, dim3 = NULL,
                           top = NULL, select = NULL, count = FALSE) {
  stopifnot(is.character(indicator), length(indicator) == 1L, nzchar(indicator))
  base_url <- paste0("https://ghoapi.azureedge.net/api/", indicator)

  filters <- character(0)

  if (!is.null(area) && is.null(spatial_type)) {
    cli::cli_inform(c(
      "Assuming {.arg spatial_type} = {.val country} since {.arg area} was given.",
      "i" = "Pass {.arg spatial_type} explicitly to silence this message."
    ))
    spatial_type <- "country"
  }

  if (!is.null(spatial_type)) {
    spatial_type <- tolower(spatial_type)
    st <- switch(spatial_type,
                 country = "COUNTRY",
                 region  = "REGION",
                 global  = "GLOBAL",
                 cli::cli_abort("Unknown {.arg spatial_type}: {.val {spatial_type}}. Use \"country\", \"region\", or \"global\".")
    )
    filters <- c(filters, paste0("SpatialDimType eq '", st, "'"))
  }

  if (!is.null(area)) {
    stopifnot(
      is.character(area),
      length(area) >= 1L,
      !anyNA(area),
      all(nzchar(area))
    )
    area_filter <- paste0(
      "SpatialDim in ('",
      paste(area, collapse = "','"),
      "')"
    )
    filters <- c(filters, area_filter)
  }

  if (!is.null(year_from)) {
    filters <- c(filters, paste0("TimeDim ge ", year_from))
  }
  if (!is.null(year_to)) {
    filters <- c(filters, paste0("TimeDim le ", year_to))
  }

  dim_args <- list(Dim1 = dim1, Dim2 = dim2, Dim3 = dim3)
  for (col in names(dim_args)) {
    values <- dim_args[[col]]
    if (is.null(values)) next
    stopifnot(
      is.character(values),
      length(values) >= 1L,
      !anyNA(values),
      all(nzchar(values))
    )
    # Escape single quotes for the OData string literal, as
    # .gho_indicators_build_url() does for search terms.
    escaped <- gsub("'", "''", values, fixed = TRUE)
    filters <- c(filters, paste0(
      col, " in ('", paste(escaped, collapse = "','"), "')"
    ))
  }

  query_parts <- character(0)
  if (length(filters) > 0) {
    filter_str <- paste(filters, collapse = " and ")
    query_parts <- c(query_parts,
                     paste0("$filter=", utils::URLencode(filter_str, reserved = TRUE)))
  }
  if (!is.null(top)) {
    query_parts <- c(query_parts, paste0("$top=", top))
  }
  if (!is.null(select)) {
    query_parts <- c(query_parts, paste0("$select=", paste(select, collapse = ",")))
  }
  if (isTRUE(count)) {
    query_parts <- c(query_parts, "$count=true")
  }

  if (length(query_parts) == 0L) return(base_url)
  paste0(base_url, "?", paste(query_parts, collapse = "&"))
}

#' @noRd
.legacy_gho_request <- function(url, indicator = NULL) {
  cli::cli_inform("Fetching: {.url {url}}")
  tryCatch(
    httr2::req_perform(.dsi_request(url)),
    error = function(e) {
      # Only a 404 triggers a small directory probe. A service failure must
      # not be reported as an absent indicator, and does not trigger fallback.
      if (!is.null(indicator) && !is.null(e$resp) &&
          httr2::resp_status(e$resp) == 404L) {
        filter <- paste0("IndicatorCode eq '", gsub("'", "''", indicator, fixed = TRUE), "'")
        catalog_url <- paste0('https://ghoapi.azureedge.net/api/Indicator?$filter=',
          utils::URLencode(filter, reserved = TRUE), '&$top=1&$select=IndicatorCode')
        catalog <- .gho_get(catalog_url)
        if (!is.null(catalog) && !nrow(catalog)) {
          cli::cli_warn(c('GHO indicator code is absent from the legacy directory: {.val {indicator}}.',
            'i' = 'This is not a valid empty observation selection. Use {.fn gho_indicators} with {.code backend = "legacy"} to inspect current codes.'))
          return(NULL)
        }
      }
      msg <- conditionMessage(e)
      cli::cli_warn(c('GHO request failed.', 'i' = 'URL: {.url {url}}', 'x' = '{msg}'))
      NULL
    }
  )
}


#' @noRd
.gho_get <- function(url, indicator = NULL) {
  all_data <- list()
  next_url <- url
  visited <- character()

  repeat {
    if (next_url %in% visited || length(visited) >= 10000L) {
      cli::cli_warn('Repeated legacy WHO next link; incomplete download discarded.')
      return(NULL)
    }
    visited <- c(visited, next_url)
    resp <- .legacy_gho_request(next_url, indicator)
    if (is.null(resp)) return(NULL)

    # Body parse must also fail soft: a truncated response body (premature
    # EOF) would otherwise propagate a jsonlite parse error and break
    # R CMD check examples (CRAN-blocking).
    body <- tryCatch(
      httr2::resp_body_json(resp, simplifyVector = TRUE),
      error = function(e) {
        # Reference the message via a variable: a jsonlite parse error
        # carries literal `{`/`}` from the offending JSON, which cli would
        # otherwise try to interpret as glue expressions and re-error.
        msg <- conditionMessage(e)
        cli::cli_warn(c(
          "GHO response could not be parsed as JSON.",
          "i" = "URL: {.url {next_url}}",
          "x" = "{msg}"
        ))
        NULL
      }
    )
    if (is.null(body)) return(NULL)
    if (!is.list(body) || is.null(body$value) ||
        !(is.data.frame(body$value) || identical(body$value, list()))) {
      cli::cli_warn('Malformed GHO response envelope; no observations returned.')
      return(NULL)
    }
    # Skip empty `value` chunks. GHO returns `value = []` (an empty list,
    # not an empty data frame) when a filter matches no rows; rbind-ing
    # it would produce a spurious 1x1 result.
    val <- body$value
    if (is.data.frame(val) && nrow(val) > 0L) {
      all_data <- c(all_data, list(val))
    }

    next_url <- body[["@odata.nextLink"]]
    if (is.null(next_url)) break
    if (!is.character(next_url) || length(next_url) != 1L || is.na(next_url) || !nzchar(next_url)) {
      cli::cli_warn('Malformed legacy WHO next link; incomplete download discarded.')
      return(NULL)
    }
  }

  if (length(all_data) == 0L) {
    out <- tibble::tibble()
  } else {
    out <- do.call(rbind, c(all_data, list(make.row.names = FALSE)))
    rownames(out) <- NULL
    out <- tibble::as_tibble(out)
  }
  attr(out, 'who_provenance') <- list(backend = 'legacy',
    base_url = sub('^(https://[^/]+).*', '\\1', url), query_url = url,
    retrieved = format(Sys.time(), tz = 'UTC'), complete = TRUE, rows = nrow(out))
  out
}
