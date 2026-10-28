#' Query the Latest GHO Indicator Timestamp
#'
#' Queries the latest non-missing timestamp among the current observations
#' for one Global Health Observatory (GHO) indicator, without downloading
#' its full observation table.
#'
#' @param indicator A single, non-empty GHO indicator code.
#' @param backend Optional WHO backend: `"legacy"` or `"xmart"`. An explicit
#'   value overrides `getOption("DSIR.who_backend")` for this call only.
#'   When neither is set, the compatibility default is `"legacy"`.
#'
#' @details
#' The legacy backend orders observations by `Date`; xMart uses
#' `Sys_CommitDateUtc` in the same indicator route selected by [gho_data()].
#' Each date query requests only the latest non-missing value. xMart also
#' consults the existing, session-cached indicator directory and table fields.
#' Requests never fall back to the other backend.
#'
#' The result describes the selected backend's current observations across
#' all locations, years and dimensions. It is not the latest observation
#' year, a formal publication date, or the update time of the whole GHO.
#' In particular, an xMart system commit can reflect data processing.
#' Backend timestamps need not describe the same release or event.
#'
#' @return A one-row tibble with columns:
#' \describe{
#'   \item{source}{`"gho"`.}
#'   \item{backend}{The selected `"legacy"` or `"xmart"` backend.}
#'   \item{scope}{`"indicator"`.}
#'   \item{indicator}{The requested GHO code.}
#'   \item{updated}{The original timestamp as character, or `NA_character_`.
#'     Offsets, fractional seconds and an unspecified time zone are preserved.}
#'   \item{timestamp_field}{`"Date"` or `"Sys_CommitDateUtc"`.}
#'   \item{checked_at}{The query start time as a UTC `POSIXct` value.}
#'   \item{status}{`"ok"`, `"not_available"` (a successful response provides
#'     no timestamp), or `"failed"` (lookup, request, parsing or response
#'     validation failed). A missing timestamp does not establish that no
#'     observations exist. Failures warn and retain the same one-row schema.}
#' }
#' @seealso [sdg_last_updated()], [gho_indicators()], [gho_data()].
#' @export
#'
#' @examples
#' \dontrun{
#' gho_last_updated("WHS4_100")
#' gho_last_updated("WHS4_100", backend = "xmart")
#'
#' # Query several indicators sequentially using the same backend.
#' codes <- c("WHS4_100", "NCDMORT3070")
#' updates <- lapply(codes, gho_last_updated, backend = "legacy")
#' do.call(rbind, updates)
#' }
gho_last_updated <- function(indicator, backend = NULL) {
  if (!is.character(indicator) || length(indicator) != 1L ||
      is.na(indicator) || !nzchar(trimws(indicator))) {
    cli::cli_abort("{.arg indicator} must be a single non-empty GHO code.")
  }
  .who_gho("last_updated", indicator = indicator, backend = backend)
}


#' Query the SDG Database Update Timestamp
#'
#' Retrieves the update timestamp reported for the whole UN Sustainable
#' Development Goals (SDG) database by the current V5 API.
#'
#' @details
#' The `Series/LastUpdated` endpoint accepts no indicator, series or country
#' filter. Its database-level timestamp does not mean that every indicator
#' changed at that time. Series release codes and the `META_LAST_UPDATE`
#' metadata-document date are not substituted for data update timestamps.
#' The timestamp is queried on every call and is not cached by DSIR.
#'
#' @return A one-row tibble with the same column names and types as
#'   [gho_last_updated()]. Here `source` is `"sdg"`, `scope` is `"database"`,
#'   `backend` and `indicator` are `NA_character_`, and `timestamp_field`
#'   is `"Series/LastUpdated"`. `updated` preserves the original timestamp
#'   string, including an unspecified time zone. `checked_at` is a UTC
#'   `POSIXct` query start time. `status` is `"ok"`, `"not_available"` for
#'   a missing timestamp, or `"failed"` on request, parsing or validation
#'   failure. Failures warn and keep `updated = NA_character_`.
#' @seealso [gho_last_updated()], [sdg_indicators()], [sdg_data()].
#' @export
#'
#' @examples
#' \dontrun{
#' sdg_last_updated()
#' }
sdg_last_updated <- function() {
  out <- .dsi_update_result("sdg", NA_character_, "database",
                            NA_character_, "Series/LastUpdated")
  url <- paste0("https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/",
                "Series/LastUpdated")
  resp <- tryCatch(httr2::req_perform(.dsi_request(url)), error = function(e) {
    msg <- conditionMessage(e)
    cli::cli_warn(c("SDG update request failed.", "x" = "{msg}"))
    NULL
  })
  if (is.null(resp)) return(out)
  parsed <- .dsi_update_json(resp, "SDG")
  if (is.null(parsed)) return(out)
  .dsi_update_value(out, parsed$value)
}


.dsi_update_result <- function(source, backend, scope, indicator, field) {
  checked_at <- Sys.time()
  attr(checked_at, "tzone") <- "UTC"
  tibble::tibble(source = source, backend = backend, scope = scope,
                 indicator = indicator, updated = NA_character_,
                 timestamp_field = field, checked_at = checked_at,
                 status = "failed")
}


.dsi_update_json <- function(resp, source) {
  tryCatch(list(value = httr2::resp_body_json(resp, simplifyVector = TRUE)),
    error = function(e) {
      msg <- conditionMessage(e)
      cli::cli_warn(c("{source} update response could not be parsed as JSON.",
                      "x" = "{msg}"))
      NULL
    })
}


.dsi_update_value <- function(out, value) {
  if (is.null(value) || (is.atomic(value) && length(value) == 1L &&
      (is.na(value) || (is.character(value) && !nzchar(trimws(value)))))) {
    out$status <- "not_available"
    return(out)
  }
  # Validate the date-time shape without assigning a zone to the source value.
  pattern <- paste0("^[0-9]{4}-[0-9]{2}-[0-9]{2}T",
                    "([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]",
                    "(\\.[0-9]+)?(Z|[+-](0[0-9]|1[0-4]):[0-5][0-9])?$")
  valid <- is.character(value) && length(value) == 1L &&
    grepl(pattern, value) &&
    !is.na(as.Date(substr(value, 1L, 10L), format = "%Y-%m-%d"))
  if (!valid) {
    cli::cli_warn("The {out$source} update response contains an invalid timestamp.")
    return(out)
  }
  out$updated <- value
  out$status <- "ok"
  out
}


.dsi_update_row <- function(out, body) {
  if (is.list(body) && identical(body$value, list())) {
    out$status <- "not_available"
    return(out)
  }
  if (!is.list(body) || !is.data.frame(body$value) ||
      nrow(body$value) > 1L ||
      !out$timestamp_field %in% names(body$value)) {
    cli::cli_warn("Malformed {out$source} update response; timestamp is unknown.")
    return(out)
  }
  if (!nrow(body$value)) {
    out$status <- "not_available"
    return(out)
  }
  .dsi_update_value(out, body$value[[out$timestamp_field]])
}
