#' Shared HTTP request configuration for the WHO and SDG clients
#'
#' Every DSIR network call builds its request here so the timeout and
#' retry policy stay identical across `.gho_get()`, the inline call in
#' `gho_count()`, and `.sdg_get()`. The retry settings widen httr2's
#' defaults (429/503 only, no low-level retries): transient server
#' errors (500/502/504) and connection-level failures (timeouts,
#' resets) — the typical presentation of GHO / UN endpoint instability
#' — are retried too. Non-transient statuses (400, 404) still fail
#' fast. `retry_on_failure` needs httr2 (>= 1.0.0); see DESCRIPTION.
#' WHO xMart can redirect an unavailable API query to an HTML error page
#' with HTTP 200. Its adapter opts into retrying this response type within
#' the same bounded retry policy; other clients keep the default behavior.
#'
#' @noRd
.dsi_request <- function(url, retry_on_html = FALSE) {
  httr2::request(url) |>
    httr2::req_headers(Accept = "application/json") |>
    httr2::req_timeout(30) |>
    httr2::req_retry(
      max_tries        = 3,
      backoff          = ~ min(2 ^ .x, 30),
      is_transient     = ~ httr2::resp_status(.x) %in%
        c(429L, 500L, 502L, 503L, 504L) ||
        (retry_on_html && httr2::resp_status(.x) == 200L &&
         httr2::resp_content_type(.x) %in% c("text/html", "application/xhtml+xml")),
      retry_on_failure = TRUE
    )
}
