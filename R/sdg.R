#' List SDG Goals
#'
#' Fetches the list of Sustainable Development Goals from the UN
#' SDG API.
#'
#' @param include_children Logical. Include targets and indicators
#'   nested under each goal? Default `FALSE`.
#'
#' @return A list (or data frame) of SDG goals, or `NULL` when the
#'   service is unreachable.
#' @seealso [sdg_targets()], [sdg_indicators()], [sdg_data()].
#' @export
#'
#' @examples
#' \dontrun{
#' sdg_goals()
#' sdg_goals(include_children = TRUE)
#' }
sdg_goals <- function(include_children = FALSE) {
  url <- paste0(
    "https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Goal/List",
    "?includechildren=", tolower(as.character(include_children))
  )
  .sdg_get(url)
}


#' List SDG Targets
#'
#' Fetches the list of SDG targets from the UN SDG API.
#'
#' @param include_children Logical. Include indicators nested under
#'   each target? Default `FALSE`.
#'
#' @return A list (or data frame) of SDG targets, or `NULL` when
#'   the service is unreachable.
#' @seealso [sdg_goals()], [sdg_indicators()].
#' @export
#'
#' @examples
#' \dontrun{
#' sdg_targets()
#' }
sdg_targets <- function(include_children = FALSE) {
  url <- paste0(
    "https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Target/List",
    "?includechildren=", tolower(as.character(include_children))
  )
  .sdg_get(url)
}


#' List SDG Indicators
#'
#' Fetches the list of SDG indicators from the UN SDG API.
#'
#' @return A list (or data frame) of SDG indicators, or `NULL`
#'   when the service is unreachable.
#' @seealso [sdg_targets()], [sdg_data()].
#' @export
#'
#' @examples
#' \dontrun{
#' sdg_indicators()
#' }
sdg_indicators <- function() {
  .sdg_get("https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/List")
}


#' List SDG Geographic Areas
#'
#' Fetches the list of geographic areas available from the UN SDG
#' database.
#'
#' @return A data frame with area codes and names, or `NULL` when
#'   the service is unreachable.
#' @seealso [sdg_data()].
#' @export
#'
#' @examples
#' \dontrun{
#' sdg_areas()
#' }
sdg_areas <- function() {
  .sdg_get("https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/GeoArea/List")
}


#' Fetch SDG Data
#'
#' Retrieves data for one or more SDG indicators from the UN SDG
#' API, with optional filters by area and year.
#'
#' @param indicator Character vector of indicator codes
#'   (e.g. `"1.1.1"`). Use [sdg_indicators()] to find codes.
#' @param area Character vector of area codes (e.g.
#'   `c("32", "76")`). Use [sdg_areas()] to find codes.
#'   Default `NULL` returns all areas.
#' @param year_from Numeric. Start year filter (inclusive).
#'   Default `NULL`.
#' @param year_to Numeric. End year filter (inclusive).
#'   Default `NULL`.
#' @param page_size Integer. Number of records per page.
#'   Default `1000`, maximum `10000`.
#'
#' @return A data frame of indicator observations, or an empty
#'   data frame when the service is unreachable or there are no
#'   matching rows.
#' @seealso [sdg_indicators()], [sdg_areas()].
#' @export
#'
#' @examples
#' \dontrun{
#' # All data for indicator 1.1.1
#' sdg_data("1.1.1")
#'
#' # Specific area and year range
#' sdg_data("3.2.1", area = "156", year_from = 2015, year_to = 2023)
#' }
sdg_data <- function(indicator, area = NULL,
                     year_from = NULL, year_to = NULL,
                     page_size = 1000L) {
  stopifnot(is.character(indicator), length(indicator) >= 1L)
  params <- list(
    indicator = paste(indicator, collapse = ","),
    pageSize  = page_size
  )

  if (!is.null(area))      params$areaCode        <- paste(area, collapse = ",")
  if (!is.null(year_from)) params$timePeriodStart <- year_from
  if (!is.null(year_to))   params$timePeriodEnd   <- year_to

  base_url <- "https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/Data"

  query <- paste(
    names(params),
    vapply(params, as.character, character(1)),
    sep = "=",
    collapse = "&"
  )
  url <- paste0(base_url, "?", query)

  all_data <- list()
  page <- 1

  repeat {
    page_url <- paste0(url, "&page=", page)
    body <- .sdg_get(page_url)
    if (is.null(body)) return(data.frame())
    if (is.null(body$data) || length(body$data) == 0) break

    all_data <- c(all_data, list(body$data))

    total_pages <- body$totalPages %||% 1
    if (page >= total_pages) break
    page <- page + 1
  }

  if (length(all_data) == 0) {
    cli::cli_warn("No data returned for indicator {.val {indicator}}.")
    return(data.frame())
  }

  out <- do.call(rbind, c(all_data, list(make.row.names = FALSE)))
  rownames(out) <- NULL
  out
}


#' @noRd
.sdg_get <- function(url) {
  cli::cli_inform("Fetching: {.url {url}}")

  resp <- tryCatch(
    httr2::request(url) |>
      httr2::req_headers(Accept = "application/json") |>
      httr2::req_retry(max_tries = 3) |>
      httr2::req_perform(),
    error = function(e) {
      cli::cli_warn(c(
        "SDG request failed.",
        "i" = "URL: {.url {url}}",
        "x" = conditionMessage(e)
      ))
      NULL
    }
  )
  if (is.null(resp)) return(NULL)

  httr2::resp_body_json(resp, simplifyVector = TRUE)
}
