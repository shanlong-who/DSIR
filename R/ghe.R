# GHE provider fields and measure definitions are confined to this module.
.ghe_path <- 'DEX_CMS/GHE_FULL'
.ghe_measures <- function() {
  tibble::tibble(
    code = c('deaths', 'death_rate', 'yll', 'yll_rate', 'yld', 'yld_rate',
             'daly', 'daly_rate', 'deaths_percent', 'yld_percent', 'daly_percent'),
    field = c('VAL_DTHS_COUNT_NUMERIC', 'VAL_DTHS_RATE100K_NUMERIC',
              'VAL_YLL_COUNT_NUMERIC', 'VAL_YLL_RATE100K_NUMERIC',
              'VAL_YLD_COUNT_NUMERIC', 'VAL_YLD_RATE100K_NUMERIC',
              'VAL_DALY_COUNT_NUMERIC', 'VAL_DALY_RATE100K_NUMERIC',
              'VAL_PROP_DTHS_PERCENT', 'VAL_PROP_YLD_PERCENT', 'VAL_PROP_DALY_PERCENT'),
    label = c('Deaths', 'Death rate', 'Years of life lost', 'YLL rate',
              'Years lived with disability', 'YLD rate', 'Disability-adjusted life years',
              'DALY rate', 'Share of deaths', 'Share of YLD', 'Share of DALY'),
    unit = c('deaths', 'per 100,000 population', 'years', 'per 100,000 population',
             'years', 'per 100,000 population', 'years', 'per 100,000 population',
             'percent', 'percent', 'percent')
  )
}
.ghe_empty <- function() {
  tibble::tibble(iso3 = character(), location_name = character(), year = integer(),
                 sex = character(), age = character(), cause_code = character(),
                 cause_name = character(), measure = character(), value = double(),
                 low = double(), high = double(), population = double(), unit = character(),
                 level = integer(), cause_group = character(), rankable = logical())
}
.ghe_years <- function() {
  .who_cached('ghe_years', function() {
    ref <- .who_reference('DEX_CMS/REF_YEAR_COD', top = 100L)
    if (is.null(ref)) return(NULL)
    tibble::tibble(DIM_YEAR_CODE = sort(as.integer(ref$CODE)))
  })
}
.ghe_latest <- function() {
  years <- .ghe_years()
  if (is.null(years) || !nrow(years)) return(NULL)
  max(as.integer(years$DIM_YEAR_CODE))
}
.ghe_areas <- function() {
  year <- .ghe_latest()
  if (is.null(year)) return(NULL)
  .who_cached('ghe_areas', function() {
    .who_odata(.ghe_path,
      paste0('DIM_YEAR_CODE eq ', year, " and DIM_GHECAUSE_CODE eq 0 and DIM_AGEGROUP_CODE eq 'TOTAL' and DIM_SEX_CODE eq 'TOTAL'"),
      select = c('Sys_PK', 'DIM_COUNTRY_CODE'))
  })
}
.ghe_reference_area <- function() {
  areas <- .ghe_areas()
  if (is.null(areas) || !nrow(areas)) return(NULL)
  sort(intersect(areas$DIM_COUNTRY_CODE, who_countries$iso3))[1]
}

#' Explore Global Health Estimates Dimensions
#'
#' Retrieves official references and small, filtered code-list slices from
#' WHO's public xMart GHE table. Results are cached in memory for ten minutes.
#' @param dimension One of `"area"`, `"year"`, `"sex"`, `"age"`, `"cause"`,
#'   or `"measure"`. Default `"measure"`.
#' @return A tibble of `code` and `label`. Cause results include hierarchy
#'   fields. Measures include their provider field and unit. Missing official
#'   labels remain `NA`. Countries, ages and causes describe the latest GHE
#'   year; use [ghe_coverage()] to verify a specific selection.
#' @seealso [ghe_data()], [ghe_causes()], [ghe_coverage()]
#' @export
#' @examples
#' \donttest{
#' ghe_dimensions('sex')
#' ghe_dimensions('age')
#' ghe_dimensions('measure')
#' }
ghe_dimensions <- function(dimension = 'measure') {
  dimension <- match.arg(dimension, c('area', 'year', 'sex', 'age', 'cause', 'measure'))
  empty <- tibble::tibble(code = character(), label = character())
  if (dimension == 'cause') return(ghe_causes())
  if (dimension == 'measure') {
    fields <- .xmart_fields(.ghe_path)
    out <- .ghe_measures()
    if (!length(fields)) return(out[0, ])
    return(out[out$field %in% fields, ])
  }
  if (dimension == 'sex') {
    df <- .who_cached('ghe_sex', function() .who_reference('DEX_CMS/REF_SEX_COD', top = 20L))
    if (is.null(df) || !nrow(df)) return(empty)
    return(tibble::tibble(code = as.character(df$CODE), label = df$TITLE))
  }
  if (dimension == 'year') {
    df <- .ghe_years()
    if (is.null(df) || !nrow(df)) return(empty)
    return(tibble::tibble(code = as.character(df$DIM_YEAR_CODE), label = as.character(df$DIM_YEAR_CODE)))
  }
  year <- .ghe_latest()
  if (is.null(year)) return(empty)
  field <- if (dimension == 'area') 'DIM_COUNTRY_CODE' else 'DIM_AGEGROUP_CODE'
  if (dimension == 'area') df <- .ghe_areas() else {
    area <- .ghe_reference_area()
    if (is.null(area)) return(empty)
    filter <- paste0('DIM_YEAR_CODE eq ', year, " and DIM_GHECAUSE_CODE eq 0 and DIM_SEX_CODE eq 'TOTAL' and DIM_COUNTRY_CODE eq '", area, "'")
    df <- .who_cached('ghe_ages', function() .who_odata(.ghe_path, filter, select = c('Sys_PK', field)))
  }
  if (is.null(df) || !nrow(df)) return(empty)
  code <- as.character(df[[field]])
  if (dimension == 'area') {
    label <- who_countries$name_short[match(code, who_countries$iso3)]
  } else {
    ref <- .who_cached('ghe_age_labels', function() .who_reference('DEX_CMS/REF_AGE_COD', top = 100L))
    label <- if (is.null(ref)) rep(NA_character_, length(code)) else ref$TITLE[match(code, ref$CODE)]
  }
  out <- tibble::tibble(code = code, label = label)
  out[!duplicated(out$code), ][order(unique(code)), ]
}

#' Explore Global Health Estimates Causes
#'
#' Lists causes from an all-age, both-sex reference slice in the latest GHE
#' year. The reference country is the first available WHO Member State in
#' ISO3 order. This avoids grouping the full database. Codes are exact
#' download identifiers; selection coverage still needs [ghe_coverage()].
#' @param search Optional words matched against cause names, ignoring case.
#'   All terms must match; a single string is split on whitespace.
#' @return A tibble with `cause_code`, `cause_name`, `level`, `cause_group`,
#'   `rankable`, and `single_cause`. The provider has no parent-code field;
#'   `cause_group` is retained as published and is not a parent identifier.
#' @seealso [ghe_data()], [ghe_dimensions()]
#' @export
#' @examples
#' \donttest{
#' ghe_causes('diabetes')
#' ghe_causes('stroke')
#' }
ghe_causes <- function(search = NULL) {
  .who_codes(search, 'search')
  empty <- tibble::tibble(cause_code = character(), cause_name = character(),
                          level = integer(), cause_group = character(),
                          rankable = logical(), single_cause = logical())
  year <- .ghe_latest()
  if (is.null(year)) return(empty)
  area <- .ghe_reference_area()
  if (is.null(area)) return(empty)
  fields <- c('DIM_GHECAUSE_CODE', 'DIM_GHECAUSE_TITLE', 'FLAG_LEVEL',
              'DIM_CAUSE_GROUP', 'FLAG_RANKABLE', 'FLAG_SINGLE_CAUSE')
  df <- .who_cached('ghe_causes', function() {
    .who_odata(.ghe_path,
      paste0('DIM_YEAR_CODE eq ', year, " and DIM_AGEGROUP_CODE eq 'TOTAL' and DIM_SEX_CODE eq 'TOTAL' and DIM_COUNTRY_CODE eq '", area, "'"),
      select = c('Sys_PK', fields))
  })
  if (is.null(df) || !nrow(df)) return(empty)
  if (!all(fields %in% names(df))) {
    cli::cli_warn('Unsupported WHO GHE cause schema.')
    return(empty)
  }
  out <- tibble::tibble(cause_code = as.character(df$DIM_GHECAUSE_CODE),
                        cause_name = df$DIM_GHECAUSE_TITLE, level = as.integer(df$FLAG_LEVEL),
                        cause_group = as.character(df$DIM_CAUSE_GROUP),
                        rankable = as.logical(df$FLAG_RANKABLE), single_cause = as.logical(df$FLAG_SINGLE_CAUSE))
  .who_search(out, 'cause_name', search)
}

.ghe_filter <- function(area, year, year_from, year_to, sex, age, cause) {
  area <- .who_codes(area, 'area')
  year <- .who_year(year, 'year')
  year_from <- .who_year(year_from, 'year_from')
  year_to <- .who_year(year_to, 'year_to')
  sex <- .who_codes(sex, 'sex')
  age <- .who_codes(age, 'age')
  cause <- .who_codes(cause, 'cause', numeric = TRUE)
  if (length(year_from) > 1 || length(year_to) > 1 ||
      (!is.null(year_from) && !is.null(year_to) && year_from > year_to) ||
      (!is.null(year) && (!is.null(year_from) || !is.null(year_to)))) {
    cli::cli_abort('Supply either {.arg year} or an ordered scalar year range.')
  }
  # Validate exact selections against public GHE code lists. A failed lookup
  # is a failed request, never permission to remove a filter.
  selections <- list(area = area, year = as.character(year), sex = sex, age = age)
  for (dimension in names(selections)) {
    value <- selections[[dimension]]
    if (!length(value)) next
    codes <- ghe_dimensions(dimension)$code
    if (!length(codes)) return(NULL)
    unknown <- setdiff(value, codes)
    if (length(unknown)) {
      cli::cli_warn('Unknown GHE {.val {dimension}} code: {.val {unknown}}. No observations returned.')
      return(NULL)
    }
  }
  if (!is.null(cause)) {
    known <- ghe_causes()$cause_code
    if (!length(known)) return(NULL)
    unknown <- setdiff(cause, known)
    if (length(unknown)) {
      cli::cli_warn('Unknown GHE cause code: {.val {unknown}}. Use {.fn ghe_causes}.')
      return(NULL)
    }
  }
  .who_and(.who_in('DIM_COUNTRY_CODE', area), .who_in('DIM_YEAR_CODE', year, TRUE),
           if (!is.null(year_from)) paste('DIM_YEAR_CODE ge', year_from),
           if (!is.null(year_to)) paste('DIM_YEAR_CODE le', year_to),
           .who_in('DIM_SEX_CODE', sex), .who_in('DIM_AGEGROUP_CODE', age),
           .who_in('DIM_GHECAUSE_CODE', cause, TRUE))
}

#' Fetch WHO Global Health Estimates
#'
#' Retrieves current GHE estimates from `DEX_CMS/GHE_FULL` on the public
#' production xMart host, without credentials. Returns one row per selected
#' measure and country/year/sex/age/cause combination. Filters run server-side.
#' @param area ISO3 country/area codes. See [ghe_dimensions()].
#' @param year Integer years; mutually exclusive with a year range.
#' @param year_from,year_to Inclusive scalar year bounds.
#' @param sex Exact codes, e.g. `"TOTAL"`, `"FEMALE"`, `"MALE"`.
#' @param age Exact age codes, e.g. `"TOTAL"`, `"Y40T44"`, `"Y_GE85"`.
#'   Totals and overlapping age groups must not be summed together.
#' @param cause Exact cause codes from [ghe_causes()], numeric or character.
#'   Code `0` is all causes. Hierarchy totals overlap with their components.
#' @param measure Codes from [ghe_dimensions()] with `dimension = "measure"`: `deaths`,
#'   `death_rate`, `yll`, `yll_rate`, `yld`, `yld_rate`, `daly`, `daly_rate`,
#'   `deaths_percent`, `yld_percent`, `daly_percent`. `NULL` returns all
#'   supported measures, including missing values.
#' @details
#' Supply at least one filter. Queries over 1,000,000 source rows warn and
#' return no rows; narrow the selection or explicitly set
#' `options(DSIR.who_max_rows = ...)`. This limit applies before pivoting
#' measures. Completeness is checked across pages; failed or incomplete
#' downloads return an empty tibble with a warning. No legacy fallback occurs.
#'
#' Counts have published lower/upper bounds where available. The API does
#' not expose bounds for rates or percentages; those remain `NA` and are not
#' derived from population. Counts are persons or years, not thousands.
#' Rates are age-specific or all-age crude rates as selected, not newly
#' age-standardized rates. Published GHE vintages can revise earlier years.
#' @return A tibble with `iso3`, `location_name`, `year`, `sex`, `age`,
#'   `cause_code`, `cause_name`, `measure`, `value`, `low`, `high`,
#'   `population`, `unit`, `level`, `cause_group`, and `rankable`.
#'   A `who_provenance` attribute records the backend, table and retrieval.
#' @seealso [ghe_causes()], [ghe_dimensions()], [ghe_coverage()], [ghe_clean()], [snapshot()]
#' @export
#' @examples
#' \donttest{
#' ghe_data(area = 'PHL', year = 2023, age = 'TOTAL', sex = 'TOTAL',
#'          cause = 0, measure = 'deaths')
#' ghe_data(area = 'PHL', year = 2023, age = 'Y40T44',
#'          sex = c('FEMALE', 'MALE'), cause = 0, measure = 'death_rate')
#' }
ghe_data <- function(area = NULL, year = NULL, year_from = NULL, year_to = NULL,
                     sex = NULL, age = NULL, cause = NULL, measure = NULL) {
  if (all(vapply(list(area, year, year_from, year_to, sex, age, cause), is.null, logical(1)))) {
    cli::cli_abort('Supply at least one GHE selection, for example {.code area = "PHL", year = 2023}.')
  }
  measure <- .who_codes(measure, 'measure')
  definitions <- .ghe_measures()
  if (!is.null(measure) && any(!measure %in% definitions$code)) cli::cli_abort('Unknown GHE measure. Use {.code ghe_dimensions("measure")}.')
  filter <- .ghe_filter(area, year, year_from, year_to, sex, age, cause)
  if (is.null(filter)) return(.ghe_empty())
  available <- ghe_dimensions('measure')
  if (!nrow(available)) return(.ghe_empty())
  if (!is.null(measure) && any(!measure %in% available$code)) {
    cli::cli_warn('Requested GHE measure is absent from the current provider schema.')
    return(.ghe_empty())
  }
  if (!is.null(measure)) available <- available[match(measure, available$code), ]
  keys <- c('Sys_PK', 'DIM_COUNTRY_CODE', 'DIM_YEAR_CODE', 'DIM_SEX_CODE',
            'DIM_AGEGROUP_CODE', 'DIM_GHECAUSE_CODE', 'DIM_GHECAUSE_TITLE',
            'ATTR_POPULATION_NUMERIC', 'FLAG_LEVEL', 'DIM_CAUSE_GROUP', 'FLAG_RANKABLE')
  bounds <- unlist(lapply(available$field[grepl('_COUNT_NUMERIC$', available$field)],
                          function(x) paste0(sub('_NUMERIC$', '', x), c('_LOW', '_HIGH'))))
  fields <- .xmart_fields(.ghe_path)
  selected <- unique(c(keys, available$field, intersect(bounds, fields)))
  if (!all(keys %in% fields)) {
    cli::cli_warn('Unsupported WHO GHE observation schema.')
    return(.ghe_empty())
  }
  df <- .who_odata(.ghe_path, filter, select = selected)
  if (is.null(df) || !nrow(df)) return(.ghe_empty())
  if (!all(selected %in% names(df))) {
    cli::cli_warn('Malformed WHO GHE observations; no data returned.')
    return(.ghe_empty())
  }
  out <- lapply(seq_len(nrow(available)), function(i) {
    field <- available$field[i]
    lower <- sub('_NUMERIC$', '_LOW', field)
    upper <- sub('_NUMERIC$', '_HIGH', field)
    tibble::tibble(iso3 = as.character(df$DIM_COUNTRY_CODE),
      location_name = who_countries$name_short[match(df$DIM_COUNTRY_CODE, who_countries$iso3)],
      year = as.integer(df$DIM_YEAR_CODE), sex = df$DIM_SEX_CODE, age = df$DIM_AGEGROUP_CODE,
      cause_code = as.character(df$DIM_GHECAUSE_CODE), cause_name = df$DIM_GHECAUSE_TITLE,
      measure = rep(available$code[i], nrow(df)), value = as.numeric(df[[field]]),
      low = if (grepl('_COUNT_', field) && lower %in% names(df)) as.numeric(df[[lower]]) else rep(NA_real_, nrow(df)),
      high = if (grepl('_COUNT_', field) && upper %in% names(df)) as.numeric(df[[upper]]) else rep(NA_real_, nrow(df)),
      population = as.numeric(df$ATTR_POPULATION_NUMERIC), unit = rep(available$unit[i], nrow(df)),
      level = as.integer(df$FLAG_LEVEL), cause_group = as.character(df$DIM_CAUSE_GROUP),
      rankable = as.logical(df$FLAG_RANKABLE))
  })
  out <- tibble::as_tibble(vctrs::vec_rbind(!!!out))
  out <- out[order(out$iso3, out$year, out$sex, out$age, out$cause_code, out$measure), ]
  attr(out, 'who_provenance') <- attr(df, 'who_provenance')
  out
}

#' Summarise Global Health Estimates Coverage
#'
#' Fetches only identifiers, geography and year, respecting sex, age and
#' cause filters. Counts refer to source observations before measure pivoting.
#' @inheritParams ghe_data
#' @return A tibble with `location`, `year_min`, `year_max`, `n_years`,
#'   and `n_obs`. Empty selections or failures return the same typed schema.
#' @export
#' @examples
#' \donttest{
#' ghe_coverage(area = 'PHL', age = 'TOTAL', sex = 'TOTAL', cause = 0)
#' }
ghe_coverage <- function(area = NULL, year = NULL, year_from = NULL, year_to = NULL,
                         sex = NULL, age = NULL, cause = NULL) {
  empty <- tibble::tibble(location = character(), year_min = integer(), year_max = integer(), n_years = integer(), n_obs = integer())
  if (all(vapply(list(area, year, year_from, year_to, sex, age, cause), is.null, logical(1)))) {
    cli::cli_abort('Supply at least one GHE selection for coverage.')
  }
  filter <- .ghe_filter(area, year, year_from, year_to, sex, age, cause)
  if (is.null(filter)) return(empty)
  df <- .who_odata(.ghe_path, filter, select = c('Sys_PK', 'DIM_COUNTRY_CODE', 'DIM_YEAR_CODE'))
  if (is.null(df) || !nrow(df)) return(empty)
  if (!all(c('DIM_COUNTRY_CODE', 'DIM_YEAR_CODE') %in% names(df))) {
    cli::cli_warn('Malformed WHO GHE coverage response; no data returned.')
    return(empty)
  }
  groups <- split(as.integer(df$DIM_YEAR_CODE), df$DIM_COUNTRY_CODE)
  groups <- groups[order(names(groups))]
  tibble::tibble(location = names(groups), year_min = unname(vapply(groups, min, integer(1))),
                 year_max = unname(vapply(groups, max, integer(1))),
                 n_years = unname(vapply(groups, function(x) length(unique(x)), integer(1))),
                 n_obs = unname(vapply(groups, length, integer(1))))
}

#' Put GHE Estimates in the Unified DSIR Schema
#'
#' Converts [ghe_data()] output for [bind_indicators()]. A GHE cause is `id`,
#' the selected measure is `series`, sex is `dim1`, and age is `dim2`.
#' Use `keep_dimensions = TRUE` to retain named sex/age, cause hierarchy and
#' unit, preventing information loss when combining multiple measures.
#' @param df A data frame from [ghe_data()].
#' @param keep_dimensions Append `dim_sex`, `dim_age`, `cause_name`,
#'   `cause_group`, `cause_level`, `rankable`, `unit`, and `population`?
#'   Default `FALSE` keeps the 15-column core.
#' @return A tibble in the unified schema, with `source = "ghe"`.
#' @export
#' @examples
#' \donttest{
#' ghe_data('PHL', year = 2023, age = 'TOTAL', sex = 'TOTAL', cause = 0,
#'          measure = 'deaths') |> ghe_clean(keep_dimensions = TRUE)
#' }
ghe_clean <- function(df, keep_dimensions = FALSE) {
  if (!is.data.frame(df)) cli::cli_abort('{.arg df} must be a data frame.')
  .dsi_check_flag(keep_dimensions, 'keep_dimensions')
  required <- names(.ghe_empty())
  if (nrow(df) && !all(required %in% names(df))) cli::cli_abort('{.arg df} must be output from {.fn ghe_data}.')
  if (!nrow(df)) df <- .ghe_empty()
  out <- tibble::tibble(source = rep('ghe', nrow(df)), id = df$cause_code,
    indicator = if (nrow(df)) paste(df$cause_name, df$measure, sep = ': ') else character(),
    location = df$iso3, iso3 = as.character(ifelse(df$iso3 %in% who_countries$iso3, df$iso3, NA_character_)),
    location_name = df$location_name, year = df$year, value = as.character(df$value),
    value_num = df$value, low = df$low, high = df$high, series = df$measure,
    dim1 = df$sex, dim2 = df$age, dim3 = rep(NA_character_, nrow(df)))
  if (keep_dimensions) {
    out$dim_sex <- df$sex; out$dim_age <- df$age; out$cause_name <- df$cause_name
    out$cause_group <- df$cause_group; out$cause_level <- df$level; out$rankable <- df$rankable
    out$unit <- df$unit; out$population <- df$population
  }
  attr(out, 'who_provenance') <- attr(df, 'who_provenance')
  out
}
