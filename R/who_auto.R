# Select one provider before applying user filters. Never infer absence from
# a failed request or from an empty selection of countries/years/dimensions.
.who_auto_select <- function(operation, args) {
  selection <- list(backend = 'xmart', ready = TRUE, fallback_reason = NULL)
  # Keyword searches cannot establish that a particular indicator is absent.
  if (operation == 'indicators') return(selection)
  .who_auto_validate(operation, args)
  selection$ready <- FALSE
  reason <- NULL
  warned <- FALSE
  .dsi_update_note(stage = 'directory', reason = 'lookup_failed',
                   http_status = NA_integer_)
  route <- withCallingHandlers(.xmart_gho_route(args$indicator),
    dsir_update_diagnostic = function(event) {
      if (!is.null(event$reason)) reason <<- event$reason
    }, warning = function(w) warned <<- TRUE)
  if (is.null(route)) {
    if (!identical(reason, 'directory_not_listed')) {
      if (!warned) {
        cli::cli_warn('WHO indicator availability could not be verified; no automatic fallback attempted.')
      }
      return(selection)
    }
    fallback <- 'directory_not_listed'
  } else {
    .dsi_update_note(stage = 'availability', reason = 'lookup_failed',
                     http_status = NA_integer_, provider_route = route$path,
                     provider_indicator = as.character(route$id))
    available <- .who_auto_available(route)
    if (is.na(available)) return(selection)
    if (available) {
      selection$ready <- TRUE
      return(selection)
    }
    fallback <- 'indicator_empty'
  }
  incompatible <- .who_auto_incompatible(operation, args)
  if (!is.null(incompatible)) {
    .dsi_update_note(reason = 'fallback_incompatible')
    cli::cli_warn(c('Automatic legacy fallback was not attempted for {.val {args$indicator}}.',
      'i' = '{incompatible}',
      'i' = 'Choose a backend explicitly and verify its filters; no filters have been dropped.'))
    return(selection)
  }
  cli::cli_warn(c('Automatic GHO selection is trying legacy for {.val {args$indicator}}.',
    'i' = 'xMart selection reason: {.val {fallback}}.',
    'i' = 'Legacy coverage and estimates may differ. The result records the actual provider.'))
  # The next adapter owns timestamp diagnostics. Do not leak xMart IDs or
  # successful probe statuses into a failed legacy request.
  .dsi_update_note(stage = NA_character_, reason = 'lookup_failed',
                   http_status = NA_integer_, provider_route = NA_character_,
                   provider_indicator = NA_character_)
  list(backend = 'legacy', ready = TRUE, fallback_reason = fallback)
}

.who_auto_available <- function(route) {
  if (length(route$id) != 1L || !is.atomic(route$id) || is.na(route$id) ||
      !nzchar(trimws(as.character(route$id)))) {
    .dsi_update_note(reason = 'invalid_response')
    cli::cli_warn('Malformed WHO indicator identifier; no automatic fallback attempted.')
    return(NA)
  }
  warned <- FALSE
  body <- withCallingHandlers(
    .who_query(route$path, list('$filter' = .who_in('IND_ID', route$id),
      '$select' = 'IND_ID', '$top' = 1L, '$count' = 'true')),
    warning = function(w) warned <<- TRUE)
  if (is.null(body)) {
    # JSON null is not a valid zero-row response. Transport/parsing failures
    # have already warned; retain those diagnostics without duplicating them.
    if (!warned) {
      .dsi_update_note(reason = 'invalid_response')
      cli::cli_warn('Malformed WHO indicator availability response; no automatic fallback attempted.')
    }
    return(NA)
  }
  count <- if (is.list(body)) body[['@odata.count']] else NULL
  value <- if (is.list(body)) body$value else NULL
  valid <- !is.null(count) && is.numeric(count) && length(count) == 1L &&
    is.finite(count) && count >= 0 && count == floor(count) &&
    (is.data.frame(value) || identical(value, list()))
  n <- if (is.data.frame(value)) nrow(value) else 0L
  if (valid && count == 0 && n == 0L) return(FALSE)
  if (valid && count > 0 && n == 1L && 'IND_ID' %in% names(value) &&
      is.atomic(value$IND_ID) && length(value$IND_ID) == 1L &&
      !is.na(value$IND_ID) && as.character(value$IND_ID) == as.character(route$id)) {
    return(TRUE)
  }
  .dsi_update_note(reason = 'invalid_response')
  cli::cli_warn('Malformed or inconsistent WHO indicator availability response; no automatic fallback attempted.')
  NA
}

.who_auto_validate <- function(operation, args) {
  indicator <- .who_codes(args$indicator, 'indicator')
  if (length(indicator) != 1L) cli::cli_abort('{.arg indicator} must be a single code.')
  .who_codes(args$area, 'area')
  from <- .who_year(args$year_from, 'year_from')
  to <- .who_year(args$year_to, 'year_to')
  if (length(from) > 1L || length(to) > 1L ||
      (!is.null(from) && !is.null(to) && from > to)) {
    cli::cli_abort('Supply an ordered, scalar year range.')
  }
  if (!is.null(args$spatial_type)) {
    match.arg(tolower(args$spatial_type), c('country', 'region', 'global'))
  }
  for (name in c('dim1', 'dim2', 'dim3')) .who_codes(args[[name]], name)
  dimensions <- args$dimensions
  if (!is.null(dimensions)) {
    if (!is.list(dimensions) || !length(dimensions) || is.null(names(dimensions)) ||
        anyNA(names(dimensions)) || any(!nzchar(names(dimensions))) || anyDuplicated(names(dimensions))) {
      cli::cli_abort('{.arg dimensions} must be a uniquely named list of exact xMart dimension codes.')
    }
    for (field in names(dimensions)) {
      if (is.null(.who_codes(dimensions[[field]], 'dimensions'))) {
        cli::cli_abort('Each named dimension must contain non-missing codes.')
      }
    }
  }
  if (operation == 'dimensions' && (!is.character(args$dimension) ||
      length(args$dimension) != 1L || is.na(args$dimension) || !nzchar(args$dimension))) {
    cli::cli_abort('{.arg dimension} must be a single non-empty column name.')
  }
  invisible(NULL)
}

.who_auto_incompatible <- function(operation, args) {
  if (any(!vapply(args[c('dimensions', 'dim1', 'dim2', 'dim3')], is.null, logical(1)))) {
    return('Named and positional dimension filters cannot be translated safely between providers.')
  }
  if (operation == 'dimensions' && !args$dimension %in%
      c('SpatialDim', 'SpatialDimType', 'TimeDim', 'TimeDimType')) {
    return('This dimension column has no verified equivalent in the legacy adapter.')
  }
  known <- c(who_countries$iso3, 'AFR', 'AMR', 'SEAR', 'EUR', 'EMR', 'WPR', 'GLOBAL')
  if (!is.null(args$area) && any(!args$area %in% known)) {
    return('Automatic legacy fallback requires known WHO ISO3 or region codes; M49/native codes are not converted.')
  }
  NULL
}

.who_gho_unavailable <- function(operation, indicator) {
  switch(operation,
    data = tibble::tibble(),
    count = NA_integer_,
    has_data = NA,
    coverage = tibble::tibble(location = character(), year_min = integer(),
                              year_max = integer(), n_obs = integer()),
    dimensions = character(),
    last_updated = .dsi_update_result('gho', 'xmart', 'indicator', indicator, 'Sys_CommitDateUtc')
  )
}
