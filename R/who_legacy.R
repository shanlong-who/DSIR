# Legacy GHO adapter retained for explicit comparison only.
# Never selected automatically after an xMart failure.
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
    res <- .gho_get(url)
    if (is.null(res))
        tibble::tibble()
    else res
}

.legacy_gho_has_data <- function(indicator, spatial_type = NULL, area = NULL, year_from = NULL, year_to = NULL,
    dim1 = NULL, dim2 = NULL, dim3 = NULL, dimensions = NULL) {
    if (!is.null(dimensions)) cli::cli_abort("Named dimensions require the xMart backend.")
    url <- .gho_build_url(indicator, spatial_type = spatial_type, area = area, year_from = year_from,
        year_to = year_to, dim1 = dim1, dim2 = dim2, dim3 = dim3, top = 1, select = "Id")
    res <- .gho_get(url)
    if (is.null(res))
        return(NA)
    nrow(res) > 0L
}

.legacy_gho_count <- function(indicator, spatial_type = NULL, area = NULL, year_from = NULL, year_to = NULL,
    dim1 = NULL, dim2 = NULL, dim3 = NULL, dimensions = NULL) {
    if (!is.null(dimensions)) cli::cli_abort("Named dimensions require the xMart backend.")
    url <- .gho_build_url(indicator, spatial_type = spatial_type, area = area, year_from = year_from,
        year_to = year_to, dim1 = dim1, dim2 = dim2, dim3 = dim3, top = 0, count = TRUE)
    cli::cli_inform("Fetching: {.url {url}}")
    resp <- tryCatch(httr2::req_perform(.dsi_request(url)), error = function(e) {
        msg <- conditionMessage(e)
        cli::cli_warn(c("GHO request failed.", i = "URL: {.url {url}}", x = "{msg}"))
        NULL
    })
    if (is.null(resp))
        return(NA_integer_)
    body <- tryCatch(httr2::resp_body_json(resp, simplifyVector = TRUE), error = function(e) {
        msg <- conditionMessage(e)
        cli::cli_warn(c("GHO response could not be parsed as JSON.", i = "URL: {.url {url}}", x = "{msg}"))
        NULL
    })
    if (is.null(body))
        return(NA_integer_)
    cnt <- body[["@odata.count"]]
    if (is.null(cnt))
        return(NA_integer_)
    as.integer(cnt)
}

.legacy_gho_coverage <- function(indicator, spatial_type = "country", area = NULL, year_from = NULL,
    year_to = NULL, dim1 = NULL, dim2 = NULL, dim3 = NULL, dimensions = NULL) {
    if (!is.null(dimensions)) cli::cli_abort("Named dimensions require the xMart backend.")
    empty <- tibble::tibble(location = character(), year_min = integer(), year_max = integer(), n_obs = integer())
    url <- .gho_build_url(indicator, spatial_type = spatial_type, area = area, year_from = year_from,
        year_to = year_to, dim1 = dim1, dim2 = dim2, dim3 = dim3, select = c("SpatialDim", "TimeDim"))
    res <- .gho_get(url)
    if (is.null(res) || nrow(res) == 0L)
        return(empty)
    if (!all(c("SpatialDim", "TimeDim") %in% names(res)))
        return(empty)
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
    res <- .gho_get(url)
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
.gho_get <- function(url) {
  all_data <- list()
  next_url <- url
  visited <- character()

  repeat {
    if (next_url %in% visited || length(visited) >= 10000L) {
      cli::cli_warn('Repeated legacy WHO next link; incomplete download discarded.')
      return(NULL)
    }
    visited <- c(visited, next_url)
    cli::cli_inform("Fetching: {.url {next_url}}")

    resp <- tryCatch(
      .dsi_request(next_url) |>
        httr2::req_perform(),
      error = function(e) {
        # Reference the message via a variable so cli does not glue-interpret
        # any literal braces the error message may carry (see body parse below).
        msg <- conditionMessage(e)
        cli::cli_warn(c(
          "GHO request failed.",
          "i" = "URL: {.url {next_url}}",
          "x" = "{msg}"
        ))
        NULL
      }
    )
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
    # Skip empty `value` chunks. GHO returns `value = []` (an empty list,
    # not an empty data frame) when a filter matches no rows; rbind-ing
    # it would produce a spurious 1x1 result.
    val <- body$value
    if (is.data.frame(val) && nrow(val) > 0L) {
      all_data <- c(all_data, list(val))
    }

    next_url <- body[["@odata.nextLink"]]
    if (is.null(next_url)) break
  }

  if (length(all_data) == 0L) return(tibble::tibble())
  out <- do.call(rbind, c(all_data, list(make.row.names = FALSE)))
  rownames(out) <- NULL
  tibble::as_tibble(out)
}
