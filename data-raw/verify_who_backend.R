# Reproduce the provider/schema investigation for DSIR 0.11.0.
# Official API documentation:
# https://extranet.who.int/xmart4/docs/xmart_api/use_API.html
# Verified production origin on 2026-10-06: https://xmart-api-public.who.int
# Runs only when explicitly sourced. Saves evidence to a temporary directory.
library(httr2)

output_dir <- file.path(tempdir(), 'dsir-who-schema')
dir.create(output_dir, showWarnings = FALSE)
base_url <- 'https://xmart-api-public.who.int'
for (mart in c('DATA_', 'DEX_CMS')) {
  for (suffix in c('', '/$metadata')) {
    response <- request(paste0(base_url, '/', mart, suffix)) |>
      req_timeout(60) |> req_perform()
    name <- paste0(mart, if (nzchar(suffix)) '_metadata.xml' else '_objects.json')
    writeLines(resp_body_string(response), file.path(output_dir, name))
  }
}
for (table in c('DATA_/IND_DIRECTORY_WIDE', 'DATA_/RELAY_WHS', 'DATA_/RELAY_GHO',
                'DEX_CMS/GHE_FULL', 'DEX_CMS/GHE_FULL_FOCUS', 'DEX_CMS/GHE_FULL_DD')) {
  response <- request(paste0(base_url, '/', table)) |>
    req_url_query('$top' = 1L, '$count' = 'true') |> req_timeout(60) |> req_perform()
  writeLines(resp_body_string(response), file.path(output_dir, paste0(gsub('/', '_', table), '.json')))
}
message('WHO schema evidence saved to: ', output_dir)
