# GHO adapters. Provider fields are confined to this file and the legacy adapter.
.who_gho <- function(operation, ..., backend = NULL) {
  args <- list(...)
  config <- .who_config(backend)
  out <- do.call(get(paste0('.', config$backend, '_gho_', operation), mode = 'function'), args)
  if (operation == 'data') {
    # Keep row-level origin when raw observations from both providers are bound.
    out$Provider <- rep(config$backend, nrow(out))
    provenance <- attr(out, 'who_provenance')
    if (is.null(provenance)) provenance <- list()
    provenance$backend <- config$backend
    attr(out, 'who_provenance') <- provenance
  }
  out
}

.gho_inform_empty <- function(backend) {
  cli::cli_inform('No GHO observations match the requested filters on {.val {backend}}.')
}

.xmart_catalog <- function() {
  .who_cached('gho_directory', function() {
    df <- .who_odata('DATA_/IND_DIRECTORY_WIDE', filter = "TERM_LANG eq 'en'",
               select = c('IND_ID', 'IND_PER_CODE', 'IND_CODE_GHO', 'IND_NAME_FULL',
                          'IND_NAME', 'TERM_LANG', 'IND_UNIT', 'IND_PUBLISH_TABLE', 'DWNL_QUERY'),
               order = 'IND_ID,IND_PER_CODE')
    required <- c('IND_ID', 'IND_PER_CODE', 'IND_CODE_GHO', 'IND_NAME_FULL',
                  'IND_NAME', 'TERM_LANG', 'IND_UNIT', 'IND_PUBLISH_TABLE', 'DWNL_QUERY')
    if (!is.null(df) && nrow(df) && !all(required %in% names(df))) {
      cli::cli_warn('Malformed WHO indicator directory; no codes returned.')
      return(NULL)
    }
    df
  })
}
.xmart_gho_indicators <- function(search = NULL) {
  .who_codes(search, 'search')
  df <- .xmart_catalog()
  empty <- tibble::tibble(IndicatorCode = character(), IndicatorName = character(), Language = character())
  if (is.null(df) || !nrow(df)) return(empty)
  if (!all(c('IND_CODE_GHO', 'IND_NAME', 'TERM_LANG') %in% names(df))) {
    cli::cli_warn('WHO indicator directory schema is unsupported.')
    return(empty)
  }
  df <- df[!is.na(df$IND_CODE_GHO) & nzchar(df$IND_CODE_GHO), , drop = FALSE]
  out <- tibble::tibble(IndicatorCode = df$IND_CODE_GHO,
                        IndicatorName = df$IND_NAME_FULL,
                        Language = toupper(df$TERM_LANG))
  missing <- is.na(out$IndicatorName) | !nzchar(out$IndicatorName)
  out$IndicatorName[missing] <- df$IND_NAME[missing]
  out <- out[!duplicated(out$IndicatorCode), , drop = FALSE]
  .who_search(out, 'IndicatorName', search)
}

.xmart_gho_route <- function(indicator) {
  df <- .xmart_catalog()
  if (is.null(df)) return(NULL)
  if (!nrow(df)) {
    cli::cli_warn('The WHO xMart indicator directory is empty; indicator availability could not be verified.')
    return(NULL)
  }
  rows <- df[!is.na(df$IND_CODE_GHO) & df$IND_CODE_GHO == indicator, , drop = FALSE]
  if (!nrow(rows)) {
    cli::cli_warn(c('Unknown GHO code in the public xMart directory: {.val {indicator}}.',
      'i' = 'The code is absent from this directory, not a valid empty observation selection. Use {.fn gho_indicators} with {.code backend = "xmart"} to inspect current codes.'))
    return(NULL)
  }
  downloadable <- !is.na(rows$DWNL_QUERY) & nzchar(rows$DWNL_QUERY)
  rows <- rows[order(!downloadable, rows$IND_PER_CODE != indicator), , drop = FALSE]
  for (i in seq_len(nrow(rows))) {
    # Extract only a mart/object identifier. Never follow directory hostnames
    # (some contain UAT/private URLs or spelling errors).
    candidates <- c(rows$DWNL_QUERY[i], rows$IND_PUBLISH_TABLE[i])
    for (url in candidates) {
      if (is.na(url)) next
      match <- regmatches(url, regexpr('DATA_/(data/)?[A-Za-z0-9_]+', url))
      if (!length(match) || !nzchar(match)) next
      path <- sub('/data/', '/', match, fixed = TRUE)
      if (!grepl('^DATA_/RELAY[A-Za-z0-9_]*$', path)) next
      download <- rows$DWNL_QUERY[i]
      dimension_fields <- NULL
      if (!is.na(download) && grepl('$select=', download, fixed = TRUE)) {
        selection <- sub('.*\\$select=([^&]*).*', '\\1', utils::URLdecode(download))
        dimension_fields <- trimws(strsplit(selection, ',', fixed = TRUE)[[1]])
        dimension_fields <- grep('^DIM_', dimension_fields, value = TRUE)
      }
      return(list(path = path, id = rows$IND_ID[i], code = indicator,
                  name = rows$IND_NAME_FULL[i], unit = rows$IND_UNIT[i],
                  download_dimensions = dimension_fields))
    }
  }
  cli::cli_warn('The public WHO directory has no supported download route for {.val {indicator}}.')
  NULL
}

.xmart_fields <- function(path) {
  df <- .who_cached(paste0('fields:', path), function() {
    body <- .who_query(path, list('$top' = 1L))
    if (is.null(body)) return(NULL)
    if (!is.list(body) || !is.data.frame(body$value)) {
      cli::cli_warn('Malformed WHO table schema response; no fields returned.')
      return(NULL)
    }
    tibble::tibble(field = names(body$value))
  })
  if (is.null(df)) character() else df$field
}
.xmart_geo <- function() {
  .who_cached('geo', function() {
    fields <- c('GEO_CODE_M49', 'GEO_CODE_ISO_3', 'GEO_TYPE', 'GEO_NAME_SHORT')
    df <- .who_odata('DATA_/REF_GEO', select = fields)
    if (!is.null(df) && nrow(df) && !all(fields %in% names(df))) {
      cli::cli_warn('Malformed WHO geography reference; no area codes returned.')
      return(NULL)
    }
    df
  })
}
.xmart_disaggregations <- function() {
  .who_cached('disaggregations', function() {
    .who_odata('DATA_/REF_DISAGGREGATIONS', select = c('TERM_SET', 'TERM_KEY', 'TERM_NAME_MAIN'), order = 'TERM_SET,TERM_KEY')
  })
}
.xmart_geo_code <- function(code, inverse = FALSE) {
  geo <- .xmart_geo()
  if (is.null(geo) || !nrow(geo)) return(rep(NA_character_, length(code)))
  # Regional M49 values are taken from the WHO reference, not inferred by length.
  # These WHO group identifiers were verified against REF_GEO. UN Africa
  # (002) and WHO Africa (953) share a name, so a name-only match is unsafe.
  regional <- c(AFR = '953', AMR = '954', SEAR = '955', EUR = '956',
                EMR = '957', WPR = '958', GLOBAL = '001')
  if (inverse) {
    result <- geo$GEO_CODE_ISO_3[match(code, geo$GEO_CODE_M49)]
    result[is.na(result) | !nzchar(result)] <- code[is.na(result) | !nzchar(result)]
    group <- code %in% regional
    result[group] <- names(regional)[match(code[group], regional)]
    return(as.character(result))
  }
  result <- geo$GEO_CODE_M49[match(code, geo$GEO_CODE_ISO_3)]
  known <- code %in% geo$GEO_CODE_M49
  result[known] <- code[known]
  for (r in intersect(code, names(regional))) {
    if (regional[[r]] %in% geo$GEO_CODE_M49) result[code == r] <- regional[[r]]
  }
  as.character(result)
}
.xmart_spatial_type <- function(x) {
  x[x %in% c('WHOREGION', 'WHO_REGION')] <- 'REGION'
  x[x %in% c('NATIONAL LIBERATION MOVEMENT', 'ORGANIZED, UNINCORPORATED TERRITORY', 'TERRITORY')] <- 'COUNTRY'
  x
}

.xmart_dimension_fields <- function(fields) {
  excluded <- c('DIM_TIME', 'DIM_TIME_TYPE', 'DIM_GEO_CODE_M49',
                'DIM_GEO_CODE_TYPE', 'DIM_PUBLISH_STATE_CODE', 'DIM_VALUE_TYPE')
  fields <- setdiff(grep('^DIM_', fields, value = TRUE), excluded)
  fields <- fields[!grepl('^DIM_([0-9]+|MEMBER_?[0-9]+)_CODE$', fields)]
  # Stable presentation order, not an assertion about old provider positions.
  c(intersect(c('DIM_SEX', 'DIM_AGE'), fields), sort(setdiff(fields, c('DIM_SEX', 'DIM_AGE'))))
}
.xmart_legacy_sex <- function(x, inverse = FALSE) {
  map <- c(SEX_BTSX = 'TOTAL', SEX_MLE = 'MALE', SEX_FMLE = 'FEMALE')
  if (inverse) map <- c(stats::setNames(names(map), map), BTSX = 'SEX_BTSX', MLE = 'SEX_MLE', FMLE = 'SEX_FMLE')
  found <- x %in% names(map)
  x[found] <- unname(map[x[found]])
  x
}
.xmart_dimension_type <- function(x) {
  x[x %in% c('DIM_SEX', 'DIM_POP_SEX')] <- 'SEX'
  x[x %in% c('DIM_AGE', 'DIM_POP_AGE_GRP')] <- 'AGEGROUP'
  x
}
.xmart_long_types <- function(context) {
  .who_cached(paste0('gho_types:', context$path, ':', context$id), function() {
    positions <- grep('^DIM_[0-9]+_CODE$', context$fields, value = TRUE)
    # The production API accepts at most six orderby clauses. Independent
    # type-code lists do not need a joint cross-product across all positions.
    batches <- split(positions, ceiling(seq_along(positions) / 6L))
    parts <- lapply(batches, function(fields) {
      .who_distinct(context$path, fields, .who_in('IND_ID', context$id))
    })
    if (any(vapply(parts, is.null, logical(1)))) return(NULL)
    tibble::as_tibble(vctrs::vec_rbind(!!!parts))
  })
}
.xmart_member_field <- function(type_field, fields) {
  member <- sub('^DIM_', 'DIM_MEMBER_', type_field)
  if (!member %in% fields) member <- sub('DIM_MEMBER_', 'DIM_MEMBER', member, fixed = TRUE)
  member
}
.xmart_age_code <- function(x, inverse = FALSE) {
  if (!inverse) return(sub('^AGEGROUP_', '', x))
  keep <- !is.na(x) & !startsWith(x, 'AGEGROUP_')
  x[keep] <- paste0('AGEGROUP_', x[keep])
  x
}

.xmart_gho_context <- function(indicator, spatial_type = NULL, area = NULL,
                               year_from = NULL, year_to = NULL,
                               dim1 = NULL, dim2 = NULL, dim3 = NULL,
                               dimensions = NULL) {
  indicator <- .who_codes(indicator, 'indicator')
  if (length(indicator) != 1L) cli::cli_abort('{.arg indicator} must be a single code.')
  area <- .who_codes(area, 'area')
  year_from <- .who_year(year_from, 'year_from')
  year_to <- .who_year(year_to, 'year_to')
  if (length(year_from) > 1 || length(year_to) > 1 ||
      (!is.null(year_from) && !is.null(year_to) && year_from > year_to)) {
    cli::cli_abort('Supply an ordered, scalar year range.')
  }
  dims <- lapply(list(dim1 = dim1, dim2 = dim2, dim3 = dim3), .who_codes, name = 'dim1/dim2/dim3')
  if (!is.null(area) && is.null(spatial_type)) {
    cli::cli_inform('Assuming {.arg spatial_type} = {.val country} since {.arg area} was given.')
    spatial_type <- 'country'
  }
  if (!is.null(spatial_type)) spatial_type <- match.arg(tolower(spatial_type), c('country', 'region', 'global'))
  route <- .xmart_gho_route(indicator)
  if (is.null(route)) return(NULL)
  fields <- .xmart_fields(route$path)
  if (!all(c('IND_ID', 'DIM_TIME', 'DIM_GEO_CODE_M49') %in% fields)) {
    cli::cli_warn('Unsupported WHO observation schema for {.val {route$path}}.')
    return(NULL)
  }
  filters <- .who_in('IND_ID', route$id)
  if (!is.null(spatial_type)) {
    types <- switch(spatial_type, country = c('COUNTRY', 'NATIONAL LIBERATION MOVEMENT',
                                             'ORGANIZED, UNINCORPORATED TERRITORY', 'TERRITORY'),
                    region = c('REGION', 'WHO_REGION', 'WHOREGION'), global = c('GLOBAL', 'WORLD'))
    filters <- c(filters, .who_in('DIM_GEO_CODE_TYPE', types))
  }
  if (!is.null(area)) {
    m49 <- .xmart_geo_code(area)
    if (anyNA(m49)) {
      unknown <- area[is.na(m49)]
      cli::cli_warn('Unknown WHO area code: {.val {unknown}}. No unrestricted query will be sent.')
      return(NULL)
    }
    filters <- c(filters, .who_in('DIM_GEO_CODE_M49', m49))
  }
  if (!is.null(year_from)) filters <- c(filters, paste0("DIM_TIME ge '", year_from, "'"))
  if (!is.null(year_to)) filters <- c(filters, paste0("DIM_TIME le '", year_to, "'"))
  named_fields <- .xmart_dimension_fields(fields)
  # Positional long tables carry explicit DIM_n_CODE / DIM_MEMBER_n_CODE.
  long <- 'DIM_1_CODE' %in% fields
  for (i in seq_len(3L)) {
    values <- dims[[i]]
    if (is.null(values)) next
    if (long) {
      type_field <- paste0('DIM_', i, '_CODE')
      member <- paste0('DIM_MEMBER_', i, '_CODE')
      clauses <- vapply(values, function(value) {
        type <- NULL
        if (value %in% c('SEX_MLE', 'SEX_FMLE', 'SEX_BTSX')) {
          native <- sub('^SEX_', '', value)
          standard <- .xmart_legacy_sex(value)
          return(paste0('(', .who_and(.who_in(type_field, c('DIM_SEX', 'SEX')), .who_in(member, standard)),
                        ') or (', .who_and(.who_in(type_field, 'DIM_POP_SEX'), .who_in(member, native)), ')'))
        } else if (startsWith(value, 'AGEGROUP_')) {
          type <- c('DIM_AGE', 'AGEGROUP', 'DIM_POP_AGE_GRP'); value <- .xmart_age_code(value)
        }
        paste0('(', .who_and(.who_in(type_field, type), .who_in(member, value)), ')')
      }, character(1))
      filters <- c(filters, paste0('(', paste(clauses, collapse = ' or '), ')'))
    } else {
      if (i > length(named_fields)) {
        cli::cli_warn('Requested dimension position is absent; no observations returned.')
        return(NULL)
      }
      if (named_fields[i] == 'DIM_SEX') values <- .xmart_legacy_sex(values)
      if (named_fields[i] == 'DIM_AGE') values <- .xmart_age_code(values)
      filters <- c(filters, .who_in(named_fields[i], values))
    }
  }
  if (!is.null(dimensions)) {
    if (!is.list(dimensions) || !length(dimensions) || is.null(names(dimensions)) ||
        anyNA(names(dimensions)) || any(!nzchar(names(dimensions))) || anyDuplicated(names(dimensions))) {
      cli::cli_abort('{.arg dimensions} must be a uniquely named list of exact xMart dimension codes.')
    }
    for (field in names(dimensions)) {
      values <- .who_codes(dimensions[[field]], 'dimensions')
      if (is.null(values)) cli::cli_abort('Each named dimension must contain non-missing codes.')
      if (long) {
        type_context <- route
        type_context$fields <- fields
        ref <- .xmart_long_types(type_context)
        if (is.null(ref) || !nrow(ref)) return(NULL)
        if (!field %in% unlist(ref, use.names = FALSE)) cli::cli_abort('Unknown named dimension {.val {field}}.')
        positions <- names(ref)[vapply(ref, function(x) any(x %in% field), logical(1))]
        clauses <- vapply(positions, function(type_field) {
          member <- .xmart_member_field(type_field, fields)
          paste0('(', .who_in(type_field, field), ' and ', .who_in(member, values), ')')
        }, character(1))
        filters <- c(filters, paste0('(', paste(clauses, collapse = ' or '), ')'))
      } else {
        if (!field %in% named_fields) cli::cli_abort('Unknown named dimension {.val {field}} for this table.')
        filters <- c(filters, .who_in(field, values))
      }
    }
  }
  route$filter <- paste(filters, collapse = ' and ')
  route$fields <- fields
  route$dimensions <- named_fields
  route
}

.xmart_gho_normalize <- function(df, context) {
  if (is.null(df) || !nrow(df)) return(tibble::tibble())
  if (!all(c('DIM_TIME', 'DIM_GEO_CODE_M49') %in% names(df))) {
    cli::cli_warn('Malformed WHO GHO observations; no data returned.')
    return(tibble::tibble())
  }
  pick <- function(field) .dsi_pick_chr(df, field)
  n <- nrow(df)
  long <- 'VALUE_NUMERIC' %in% names(df)
  numeric_fields <- grep('_N$', names(df), value = TRUE)
  if (!long && !length(numeric_fields)) {
    cli::cli_warn('Malformed WHO GHO measure schema; no data returned.')
    return(tibble::tibble())
  }
  numeric_value <- low <- high <- rep(NA_real_, n)
  measure_field <- rep(NA_character_, n)
  if (long) {
    numeric_value <- as.numeric(df$VALUE_NUMERIC)
    if ('VALUE_NUMERIC_LOWER' %in% names(df)) low <- as.numeric(df$VALUE_NUMERIC_LOWER)
    if ('VALUE_NUMERIC_UPPER' %in% names(df)) high <- as.numeric(df$VALUE_NUMERIC_UPPER)
    measure_field[] <- 'VALUE_NUMERIC'
  } else {
    values <- df[, numeric_fields, drop = FALSE]
    active <- rowSums(!is.na(values))
    if (any(active > 1L)) {
      cli::cli_warn('Multiple numeric measure families in a GHO row; ambiguous observations discarded.')
      return(tibble::tibble())
    }
    for (field in numeric_fields) {
      keep <- !is.na(df[[field]])
      numeric_value[keep] <- as.numeric(df[[field]][keep])
      measure_field[keep] <- field
      lower <- sub('_N$', '_NL', field)
      upper <- sub('_N$', '_NU', field)
      if (lower %in% names(df)) low[keep] <- as.numeric(df[[lower]][keep])
      if (upper %in% names(df)) high[keep] <- as.numeric(df[[upper]][keep])
    }
  }
  value <- pick('VALUE_LABEL')
  missing <- is.na(value) | !nzchar(value)
  value[missing] <- as.character(numeric_value[missing])
  out <- tibble::tibble(Id = pick('_RecordID'), IndicatorCode = rep(context$code, n),
                        IndicatorName = rep(context$name, n),
                        SpatialDim = .xmart_geo_code(pick('DIM_GEO_CODE_M49'), inverse = TRUE),
                        SpatialDimType = .xmart_spatial_type(pick('DIM_GEO_CODE_TYPE')),
                        SpatialDimTypeOriginal = pick('DIM_GEO_CODE_TYPE'),
                        SpatialName = pick('GEO_NAME_SHORT'), TimeDim = suppressWarnings(as.integer(pick('DIM_TIME'))),
                        TimeDimType = pick('DIM_TIME_TYPE'), TimeDimensionValue = pick('DIM_TIME'),
                        Value = value, NumericValue = numeric_value,
                        Low = low, High = high, Date = pick('Sys_CommitDateUtc'),
                        Unit = rep(context$unit, n), MeasureField = measure_field,
                        DataSourceDim = pick('VALUE_PROVENANCE'), Comments = pick('VALUE_COMMENTS'))
  for (i in seq_len(3L)) {
    if (long) {
      type <- pick(paste0('DIM_', i, '_CODE'))
      val <- pick(paste0('DIM_MEMBER_', i, '_CODE'))
    } else if (i <= length(context$dimensions)) {
      field <- context$dimensions[i]
      type <- rep(field, n)
      val <- pick(field)
      type[is.na(val)] <- NA_character_
    } else type <- val <- rep(NA_character_, n)
    is_sex <- .xmart_dimension_type(type) %in% 'SEX'
    val[is_sex] <- .xmart_legacy_sex(val[is_sex], inverse = TRUE)
    type[is_sex] <- 'SEX'
    is_age <- .xmart_dimension_type(type) %in% 'AGEGROUP'
    val[is_age] <- .xmart_age_code(val[is_age], inverse = TRUE)
    type[is_age] <- 'AGEGROUP'
    out[[paste0('Dim', i, 'Type')]] <- type
    out[[paste0('Dim', i)]] <- val
  }
  if (long) {
    # Retain every source position, including positions beyond the 15-column core.
    extras <- grep('^DIM_([0-9]+|MEMBER_?[0-9]+)_CODE$', names(df), value = TRUE)
    for (type_field in grep('^DIM_[0-9]+_CODE$', names(df), value = TRUE)) {
      member <- .xmart_member_field(type_field, names(df))
      types <- pick(type_field)
      for (field in unique(types[!is.na(types) & grepl('^DIM_[A-Z_]+$', types)])) {
        if (!field %in% names(out)) out[[field]] <- rep(NA_character_, n)
        keep <- !is.na(types) & types == field
        out[[field]][keep] <- pick(member)[keep]
      }
    }
  } else extras <- .xmart_dimension_fields(names(df))
  for (field in extras) out[[field]] <- pick(field)
  attr(out, 'who_provenance') <- attr(df, 'who_provenance')
  out
}

.xmart_gho_data <- function(...) {
  context <- .xmart_gho_context(...)
  if (is.null(context)) return(tibble::tibble())
  df <- .who_odata(context$path, filter = context$filter)
  if (!is.null(df) && !nrow(df)) .gho_inform_empty('xmart')
  .xmart_gho_normalize(df, context)
}
.xmart_gho_count <- function(...) {
  context <- .xmart_gho_context(...)
  if (is.null(context)) return(NA_integer_)
  out <- .who_odata(context$path, context$filter, mode = 'count')
  if (!is.null(out) && out == 0) .gho_inform_empty('xmart')
  if (is.null(out)) NA_integer_ else out
}
.xmart_gho_has_data <- function(...) {
  context <- .xmart_gho_context(...)
  if (is.null(context)) return(NA)
  out <- .who_odata(context$path, context$filter, mode = 'exists')
  if (identical(out, FALSE)) .gho_inform_empty('xmart')
  if (is.null(out)) NA else out
}
.xmart_gho_coverage <- function(...) {
  context <- .xmart_gho_context(...)
  empty <- tibble::tibble(location = character(), year_min = integer(), year_max = integer(), n_obs = integer())
  if (is.null(context)) return(empty)
  df <- .who_odata(context$path, context$filter, select = c('Sys_PK', 'DIM_GEO_CODE_M49', 'DIM_TIME'))
  if (!is.null(df) && !nrow(df)) .gho_inform_empty('xmart')
  if (is.null(df) || !nrow(df)) return(empty)
  if (!all(c('DIM_GEO_CODE_M49', 'DIM_TIME') %in% names(df))) {
    cli::cli_warn('Malformed WHO GHO coverage response; no data returned.')
    return(empty)
  }
  loc <- .xmart_geo_code(df$DIM_GEO_CODE_M49, inverse = TRUE)
  groups <- split(suppressWarnings(as.integer(df$DIM_TIME)), loc)
  groups <- groups[order(names(groups))]
  year_bound <- function(x, fn) {
    x <- x[!is.na(x)]
    if (length(x)) fn(x) else NA_integer_
  }
  tibble::tibble(location = names(groups),
                 year_min = unname(vapply(groups, year_bound, integer(1), fn = min)),
                 year_max = unname(vapply(groups, year_bound, integer(1), fn = max)),
                 n_obs = unname(vapply(groups, length, integer(1))))
}
.xmart_gho_dimensions <- function(indicator, dimension = 'SpatialDimType') {
  context <- .xmart_gho_context(indicator)
  if (is.null(context)) return(character())
  field <- switch(dimension, SpatialDim = 'DIM_GEO_CODE_M49', SpatialDimType = 'DIM_GEO_CODE_TYPE',
                  TimeDim = 'DIM_TIME', TimeDimType = 'DIM_TIME_TYPE', dimension)
  if ('DIM_1_CODE' %in% context$fields && !field %in% context$fields && startsWith(field, 'DIM_')) {
    types <- .xmart_long_types(context)
    if (is.null(types) || !nrow(types)) return(character())
    positions <- names(types)[vapply(types, function(x) any(x %in% field), logical(1))]
    if (!length(positions)) {
      cli::cli_warn('Unknown dimension {.val {dimension}} for this indicator table.')
      return(character())
    }
    values <- lapply(positions, function(type_field) {
      member <- .xmart_member_field(type_field, context$fields)
      df <- .who_distinct(context$path, member, .who_and(context$filter, .who_in(type_field, field)))
      if (is.null(df)) return(NULL)
      as.character(df[[member]])
    })
    if (any(vapply(values, is.null, logical(1)))) return(character())
    values <- unlist(values, use.names = FALSE)
    return(sort(unique(values[!is.na(values)])))
  }
  type_requested <- dimension %in% paste0('Dim', 1:3, 'Type')
  if (type_requested) {
    i <- as.integer(sub('Dim([1-3])Type', '\\1', dimension))
    if ('DIM_1_CODE' %in% context$fields) field <- paste0('DIM_', i, '_CODE')
    else if (i <= length(context$dimensions)) field <- context$dimensions[i]
    else return(character())
  }
  if (dimension %in% paste0('Dim', 1:3)) {
    i <- as.integer(sub('Dim', '', dimension, fixed = TRUE))
    if ('DIM_1_CODE' %in% context$fields) field <- paste0('DIM_MEMBER_', i, '_CODE')
    else if (i <= length(context$dimensions)) field <- context$dimensions[i]
    else return(character())
  }
  if (!field %in% context$fields) {
    cli::cli_warn('Unknown dimension {.val {dimension}} for this indicator table.')
    return(character())
  }
  type_field <- NULL
  if (dimension %in% paste0('Dim', 1:3) && 'DIM_1_CODE' %in% context$fields) {
    type_field <- paste0('DIM_', sub('Dim', '', dimension, fixed = TRUE), '_CODE')
  }
  df <- .who_distinct(context$path, c(type_field, field), context$filter)
  if (is.null(df) || !nrow(df)) return(character())
  values <- as.character(df[[field]])
  if (type_requested) {
    if ('DIM_1_CODE' %in% context$fields) {
      values <- .xmart_dimension_type(values)
    } else {
      if (!any(!is.na(values))) return(character())
      values <- switch(field, DIM_SEX = 'SEX', DIM_AGE = 'AGEGROUP', field)
    }
  }
  if (dimension == 'SpatialDim') values <- .xmart_geo_code(values, inverse = TRUE)
  if (dimension == 'SpatialDimType') values <- .xmart_spatial_type(values)
  if (dimension %in% paste0('Dim', 1:3) && field == 'DIM_SEX') values <- .xmart_legacy_sex(values, inverse = TRUE)
  if (dimension %in% paste0('Dim', 1:3) && field == 'DIM_AGE') values <- .xmart_age_code(values, inverse = TRUE)
  if (!is.null(type_field)) {
    sex <- .xmart_dimension_type(df[[type_field]]) %in% 'SEX'
    age <- .xmart_dimension_type(df[[type_field]]) %in% 'AGEGROUP'
    values[sex] <- .xmart_legacy_sex(values[sex], inverse = TRUE)
    values[age] <- .xmart_age_code(values[age], inverse = TRUE)
  }
  sort(unique(values[!is.na(values)]))
}
