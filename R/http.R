#' Shared HTTP request configuration for the GHO and SDG clients
#'
#' Every DSIR network call builds its request here so the timeout and
#' retry policy stay identical across `.gho_get()`, the inline call in
#' `gho_count()`, and `.sdg_get()`. The retry settings widen httr2's
#' defaults (429/503 only, no low-level retries): transient server
#' errors (500/502/504) and connection-level failures (timeouts,
#' resets) — the typical presentation of GHO / UN endpoint instability
#' — are retried too. Non-transient statuses (400, 404) still fail
#' fast. `retry_on_failure` needs httr2 (>= 1.0.0); see DESCRIPTION.
#'
#' @noRd
.dsi_request <- function(url) {
  httr2::request(url) |>
    httr2::req_headers(Accept = "application/json") |>
    httr2::req_timeout(30) |>
    httr2::req_retry(
      max_tries        = 3,
      backoff          = ~ min(2 ^ .x, 30),
      is_transient     = ~ httr2::resp_status(.x) %in%
        c(429L, 500L, 502L, 503L, 504L),
      retry_on_failure = TRUE
    )
}
