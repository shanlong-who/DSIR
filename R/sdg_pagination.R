#' Retrieve complete SDG pages, or return an empty result with a warning
#'
#' @noRd
.sdg_collect_pages <- function(url, indicator) {
  fail <- function(reason) {
    cli::cli_warn(c(
      "SDG download is incomplete or invalid: {reason}",
      "i" = "Returning no rows; partial data must not be used as a complete download."
    ), class = "dsir_incomplete_data")
    tibble::tibble()
  }
  valid_count <- function(x, minimum = 0) {
    is.numeric(x) && length(x) == 1L && is.finite(x) &&
      x >= minimum && x == floor(x)
  }

  all_data <- list()
  expected_pages <- NULL
  expected_rows <- NULL
  received_rows <- 0
  page <- 1L

  repeat {
    body <- .sdg_get(paste0(url, "&page=", page))
    if (is.null(body)) return(tibble::tibble())
    if (!is.list(body) || !"data" %in% names(body)) {
      return(fail("the response has no data field."))
    }
    for (field in c("totalPages", "totalElements", "pageNumber")) {
      if (!is.null(body[[field]]) &&
          !valid_count(body[[field]], if (field == "pageNumber") 1 else 0)) {
        return(fail(paste0("invalid ", field, " on page ", page, ".")))
      }
    }
    if (!is.null(body$pageNumber) && body$pageNumber != page) {
      return(fail(paste0("requested page ", page, " but received page ", body$pageNumber, ".")))
    }
    if (!is.null(body$totalPages)) {
      if (!is.null(expected_pages) && body$totalPages != expected_pages) {
        return(fail("totalPages changed during the download."))
      }
      expected_pages <- body$totalPages
    }
    if (!is.null(body$totalElements)) {
      if (!is.null(expected_rows) && body$totalElements != expected_rows) {
        return(fail("totalElements changed during the download."))
      }
      expected_rows <- body$totalElements
    }

    rows <- body$data
    empty_page <- is.null(rows) || (is.list(rows) && length(rows) == 0L) ||
      (is.data.frame(rows) && nrow(rows) == 0L)
    if (empty_page) {
      if (page > 1L || (!is.null(expected_pages) && expected_pages > 1L) ||
          (!is.null(expected_rows) && expected_rows > 0)) {
        return(fail(paste0("page ", page, " is empty before the declared data were received.")))
      }
      cli::cli_warn("No data returned for indicator {.val {indicator}}.")
      return(tibble::tibble())
    }
    if (!is.data.frame(rows)) return(fail("data is not an observation table."))
    if (!is.null(expected_pages) && page > expected_pages) {
      return(fail("non-empty data exceeds the declared page count."))
    }

    received_rows <- received_rows + nrow(rows)
    all_data[[page]] <- tibble::as_tibble(rows)
    if (!is.null(expected_rows) && received_rows > expected_rows) {
      return(fail("received more rows than totalElements."))
    }
    if (page >= (expected_pages %||% 1L)) break
    page <- page + 1L
  }

  if (!is.null(expected_rows) && received_rows != expected_rows) {
    return(fail(paste0("expected ", expected_rows, " rows but received ", received_rows, ".")))
  }
  # Different series can have different nested dimension/attribute columns.
  # Preserve their union and fill absent fields, rather than using base rbind.
  tryCatch(
    tibble::as_tibble(do.call(vctrs::vec_rbind, all_data)),
    error = function(e) {
      fail(paste0("pages could not be combined: ", conditionMessage(e)))
    }
  )
}
