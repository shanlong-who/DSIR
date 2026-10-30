#' Query the Latest GHO Indicator Timestamp
#'
#' Queries the latest non-missing timestamp among the current observations
#' for one Global Health Observatory (GHO) indicator, without downloading
#' its full observation table.
#'
#' This function is **experimental**. Availability and timestamp semantics
#' differ between providers; the result is evidence about the selected API
#' response, not proof of an official WHO data revision.
#'
#' @param indicator A single, non-empty GHO indicator code.
#' @param backend Optional WHO backend: `"auto"`, `"legacy"` or `"xmart"`. An explicit
#'   value overrides `getOption("DSIR.who_backend")` for this call only.
#'   When neither is set, the default is `"auto"`, as in [gho_data()].
#' @param diagnostics Logical; default `FALSE`. If `TRUE`, append diagnostic
#'   columns without making additional requests or changing backend selection.
#'
#' @details
#' The legacy backend orders observations by `Date`; xMart uses
#' `Sys_CommitDateUtc` in the same indicator route selected by [gho_data()].
#' Each date query requests only the latest non-missing value. xMart also
#' consults the existing, session-cached indicator directory and table fields.
#' Automatic selection follows [gho_data()]: a verified absent or completely
#' empty xMart indicator can fall back to legacy, with a warning. Missing
#' timestamps never trigger fallback. Explicit backends never switch.
#' The `who_provenance` attribute records automatic selection and its reason;
#' the `backend` column and timestamp field describe the actual provider.
#'
#' The result describes the selected backend's current observations across
#' all locations, years and dimensions. It is not the latest observation
#' year, a formal publication date, or the update time of the whole GHO.
#' In particular, an xMart system commit can reflect data processing.
#' Backend timestamps need not describe the same release or event.
#' DSIR has not established that legacy `Date` is an official modification
#' or publication date. Several indicators can share the same system commit
#' time without evidence that their published values changed together.
#'
#' `checked_at` is when DSIR started this check, not a source modification
#' time or data retrieval time. The latest observation year describes the
#' period measured. Neither is substituted for a source timestamp. To detect
#' actual differences between retrieved observations, use [data_snapshot()]
#' and [compare_snapshots()].
#'
#' A code absent from the public xMart directory can still be a valid legacy
#' GHO code. A successful directory request does not establish that observation
#' requests work. An HTTP failure does not establish that an indicator is
#' absent. No indicator or backend is silently substituted.
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
#' With `diagnostics = TRUE`, six additional columns are appended:
#' \describe{
#'   \item{reason}{`"timestamp_available"`, `"directory_not_listed"`,
#'     `"http_error"` (an HTTP error response), `"request_failed"` (no HTTP
#'     response), `"timestamp_field_missing"`, `"timestamp_missing"` (no
#'     non-missing timestamp returned), `"unsupported_route"`,
#'     `"lookup_failed"`, `"unexpected_content"` (HTML instead of JSON),
#'     `"invalid_json"`, `"invalid_response"`, `"invalid_timestamp"`, or
#'     `"fallback_incompatible"`.
#'     These explain `status`; they do not replace its existing three values.}
#'   \item{stage}{`"directory"`, `"availability"` (automatic selection),
#'     `"schema"`, or `"timestamp"`: the stage
#'     associated with the result.}
#'   \item{http_status}{Integer HTTP status captured in that stage, or `NA`
#'     if unavailable, including a cached lookup or a transport failure.
#'     HTTP 200 alone does not establish a valid response.}
#'   \item{timestamp_kind}{`"legacy_observation_date"` or
#'     `"xmart_system_commit"`; neither guarantees an official revision date.}
#'   \item{provider_route}{The selected observation table path, when known.
#'     This contains no hostname, query string or credentials.}
#'   \item{provider_indicator}{The exact selected provider identifier: the
#'     legacy GHO code or xMart `IND_ID`, when known.}
#' }
#' @seealso [sdg_last_updated()], [gho_indicators()], [gho_data()].
#' @export
#'
#' @examples
#' \dontrun{
#' gho_last_updated("WHS4_100")
#' gho_last_updated("WHS4_100", backend = "xmart")
#' gho_last_updated("WHS4_100", backend = "xmart", diagnostics = TRUE)
#'
#' # Query several indicators sequentially using the same backend.
#' codes <- c("WHS4_100", "NCDMORT3070")
#' updates <- lapply(codes, gho_last_updated, backend = "legacy")
#' do.call(rbind, updates)
#' }
gho_last_updated <- function(indicator, backend = NULL, diagnostics = FALSE) {
  if (!is.character(indicator) || length(indicator) != 1L ||
      is.na(indicator) || !nzchar(trimws(indicator))) {
    cli::cli_abort("{.arg indicator} must be a single non-empty GHO code.")
  }
  if (!is.logical(diagnostics) || length(diagnostics) != 1L ||
      is.na(diagnostics)) {
    cli::cli_abort("{.arg diagnostics} must be TRUE or FALSE.")
  }
  if (!diagnostics) {
    return(.who_gho("last_updated", indicator = indicator, backend = backend))
  }
  detail <- list(reason = "lookup_failed", stage = NA_character_,
                 http_status = NA_integer_, provider_route = NA_character_,
                 provider_indicator = NA_character_)
  out <- withCallingHandlers(
    .who_gho("last_updated", indicator = indicator, backend = backend),
    dsir_update_diagnostic = function(event) {
      for (name in intersect(names(detail), names(event))) {
        detail[[name]] <<- event[[name]]
      }
    }
  )
  out$reason <- detail$reason
  out$stage <- detail$stage
  out$http_status <- detail$http_status
  out$timestamp_kind <- if (out$backend == "legacy") {
    "legacy_observation_date"
  } else "xmart_system_commit"
  out$provider_route <- detail$provider_route
  out$provider_indicator <- detail$provider_indicator
  out
}


# Call-scoped conditions carry structured diagnostics through fail-soft and
# cached helpers. They do not change their return values or parse warning text.
.dsi_update_note <- function(...) {
  signalCondition(structure(c(list(message = "", call = NULL), list(...)),
    class = c("dsir_update_diagnostic", "condition")))
  invisible(NULL)
}


.dsi_update_request_error <- function(error) {
  status <- if (is.null(error$resp)) NA_integer_ else
    as.integer(httr2::resp_status(error$resp))
  .dsi_update_note(reason = if (is.na(status)) "request_failed" else "http_error",
                   http_status = status)
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
#' @return A one-row tibble with the same default eight column names and types
#'   as [gho_last_updated()]. Here `source` is `"sdg"`, `scope` is `"database"`,
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
      .dsi_update_note(reason = "invalid_json")
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
    .dsi_update_note(reason = "timestamp_missing")
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
    .dsi_update_note(reason = "invalid_timestamp")
    cli::cli_warn("The {out$source} update response contains an invalid timestamp.")
    return(out)
  }
  out$updated <- value
  out$status <- "ok"
  .dsi_update_note(reason = "timestamp_available")
  out
}


.dsi_update_row <- function(out, body) {
  if (is.list(body) && identical(body$value, list())) {
    out$status <- "not_available"
    .dsi_update_note(reason = "timestamp_missing")
    return(out)
  }
  if (!is.list(body) || !is.data.frame(body$value) ||
      nrow(body$value) > 1L ||
      !out$timestamp_field %in% names(body$value)) {
    missing_field <- is.list(body) && is.data.frame(body$value) &&
      nrow(body$value) <= 1L && !out$timestamp_field %in% names(body$value)
    .dsi_update_note(reason = if (missing_field) "timestamp_field_missing" else
      "invalid_response")
    cli::cli_warn("Malformed {out$source} update response; timestamp is unknown.")
    return(out)
  }
  if (!nrow(body$value)) {
    out$status <- "not_available"
    .dsi_update_note(reason = "timestamp_missing")
    return(out)
  }
  .dsi_update_value(out, body$value[[out$timestamp_field]])
}
