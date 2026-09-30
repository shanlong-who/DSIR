#' @noRd
.dsi_check_flag <- function(value, name) {
  if (!isTRUE(value) && !isFALSE(value)) {
    cli::cli_abort("{.arg {name}} must be a single logical value.")
  }
}


#' @noRd
.dsi_pick_chr <- function(df, src) {
  if (!src %in% names(df)) return(rep(NA_character_, nrow(df)))
  as.character(df[[src]])
}


#' Preserve multiple notes or indicator links without concatenating them
#'
#' @noRd
.dsi_pick_list <- function(df, src) {
  if (!src %in% names(df)) return(rep(list(character()), nrow(df)))
  lapply(df[[src]], as.character)
}


#' @noRd
.sdg_append_metadata <- function(out, df) {
  attrs <- .sdg_nested_frame(df, "attributes")
  attr_names <- .sdg_field_names(names(attrs), "attr_")
  for (i in seq_along(attrs)) out[[attr_names[[i]]]] <- attrs[[i]]
  mapping <- c(
    data_source = "source", time_detail = "time_detail",
    time_coverage = "timeCoverage", base_period = "basePeriod",
    value_type = "valueType", geo_info_url = "geoInfoUrl"
  )
  for (nm in names(mapping)) out[[nm]] <- .dsi_pick_chr(df, mapping[[nm]])
  out$footnotes <- .dsi_pick_list(df, "footnotes")
  out$indicator_codes <- .dsi_pick_list(df, "indicator")
  out$goal_codes <- .dsi_pick_list(df, "goal")
  out$target_codes <- .dsi_pick_list(df, "target")
  out
}


#' @noRd
.gho_append_dimensions <- function(out, df) {
  for (i in seq_len(3L)) {
    out[[paste0("dim", i, "_type")]] <- .dsi_pick_chr(df, paste0("Dim", i, "Type"))
  }
  out
}


#' @noRd
.gho_append_metadata <- function(out, df) {
  mapping <- c(
    observation_id = "Id", spatial_type = "SpatialDimType",
    time_type = "TimeDimType", data_source_type = "DataSourceDimType",
    data_source = "DataSourceDim", updated = "Date",
    parent_location = "ParentLocationCode", parent_location_name = "ParentLocation",
    time_detail = "TimeDimensionValue", time_start = "TimeDimensionBegin",
    time_end = "TimeDimensionEnd"
  )
  for (nm in names(mapping)) out[[nm]] <- .dsi_pick_chr(df, mapping[[nm]])
  out$footnotes <- .dsi_pick_list(df, "Comments")
  out
}
