# Cleaning records describe the input at cleaning time, not a hidden copy of it.

.dsi_clean_context <- function(df, source) {
  empty <- tibble::new_tibble(list(), nrow = nrow(df))
  aliases <- character()
  if (source == "gho") {
    context <- .gho_append_dimensions(empty, df)
    mapping <- c(unit = "Unit", measure_field = "MeasureField",
                 spatial_type = "SpatialDimType", time_type = "TimeDimType")
    for (nm in names(mapping)) context[[nm]] <- .dsi_pick_chr(df, mapping[[nm]])
    context$provider <- .gho_provider(df)
    # Native xMart dimensions may duplicate a normalized core position.
    # Establish aliases from the recorded type and values, never code spelling.
    for (i in seq_len(3L)) {
      type <- unique(.dsi_pick_chr(df, paste0("Dim", i, "Type")))
      if (length(type) != 1L || is.na(type)) next
      fields <- grep("^DIM_", names(df), value = TRUE)
      fields <- fields[.xmart_dimension_type(fields) == .xmart_dimension_type(type)]
      for (field in fields) {
        value <- .dsi_pick_chr(df, field)
        normalized <- switch(.xmart_dimension_type(type),
          SEX = .xmart_legacy_sex(value, inverse = TRUE),
          AGEGROUP = .xmart_age_code(value, inverse = TRUE), value)
        if (identical(normalized, .dsi_pick_chr(df, paste0("Dim", i)))) {
          aliases[[paste0("dim_", tolower(sub("^DIM_", "", field)))]] <- paste0("dim", i)
        }
      }
    }
  } else if (source == "sdg") {
    context <- .sdg_append_dimensions(empty, df)
    attrs <- .sdg_nested_frame(df, "attributes")
    names(attrs) <- .sdg_field_names(names(attrs), "attr_")
    for (nm in names(attrs)) context[[nm]] <- attrs[[nm]]
    context$base_period <- .dsi_pick_chr(df, "basePeriod")
  } else {
    context <- tibble::tibble(dim_sex = .dsi_pick_chr(df, "sex"),
                             dim_age = .dsi_pick_chr(df, "age"),
                             unit = .dsi_pick_chr(df, "unit"))
    aliases <- c(dim_sex = "dim1", dim_age = "dim2")
  }
  list(data = context, aliases = aliases)
}

.dsi_finish_clean <- function(out, df, source, output, options) {
  context <- .dsi_clean_context(df, source)
  fields <- context$data
  retained <- ifelse(names(fields) %in% names(out), names(fields), NA_character_)
  alias <- context$aliases[match(names(fields), names(context$aliases))]
  retained[is.na(retained) & !is.na(alias)] <- alias[is.na(retained) & !is.na(alias)]
  distinct <- vapply(fields, function(x) length(unique(x)), integer(1))
  profile <- tibble::tibble(
    column = names(fields), role = .dsi_data_roles(names(fields)),
    retained_as = unname(retained), distinct = unname(distinct),
    missing = unname(vapply(fields, function(x) sum(is.na(x) | !nzchar(trimws(x))), integer(1))),
    constant = unname(vapply(fields, function(x) {
      if (length(unique(x)) == 1L) x[[1L]] else NA_character_
    }, character(1)))
  )
  time.field <- switch(source, gho = "TimeDim", sdg = "timePeriodStart", ghe = "year")
  time <- .dsi_pick_chr(df, time.field)
  # A compact integer year must not silently legitimize fractional periods.
  number <- suppressWarnings(as.numeric(time))
  lost <- !is.na(time) & (is.na(number) | !is.finite(number) | number != trunc(number))
  if (source == "gho" && "TimeDimensionValue" %in% names(df)) {
    detail <- .dsi_pick_chr(df, "TimeDimensionValue")
    numeric.detail <- suppressWarnings(as.numeric(detail))
    known <- !is.na(detail) & nzchar(trimws(detail))
    lost <- lost | (known & (is.na(numeric.detail) | !is.finite(numeric.detail) |
      numeric.detail != trunc(numeric.detail) | (!is.na(number) & numeric.detail != number)))
  }
  if (source %in% c("gho", "sdg")) out <- out[order(out$location, out$year), , drop = FALSE]
  out <- .dsi_copy_metadata(out, df)
  metadata <- attr(out, "dsir_metadata", exact = TRUE)
  if (is.null(metadata)) metadata <- list(schema_version = 1L)
  metadata$layout <- "cleaning"
  metadata$cleaning <- list(
    function_name = paste0(source, "_clean"), cleaned_at = .dsi_timestamp(),
    package_version = as.character(utils::packageVersion("DSIR")),
    input_rows = nrow(df), output_rows = nrow(out), input_columns = names(df),
    output_columns = names(out), options = options, fields = profile,
    aliases = context$aliases, year_precision_lost = sum(lost)
  )
  attr(out, "dsir_metadata") <- metadata
  if (output == "dsir_data") as_dsir_data(out) else out
}
