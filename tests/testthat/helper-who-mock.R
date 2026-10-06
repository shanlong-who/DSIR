who_response <- function(body, status = 200L) {
  httr2::response(status_code = status, headers = list('content-type' = 'application/json'), body = charToRaw(body))
}
who_page <- function(body) list(who_response(body))
