# Query the SDG Database Update Timestamp

Retrieves the update timestamp reported for the whole UN Sustainable
Development Goals (SDG) database by the current V5 API.

## Usage

``` r
sdg_last_updated()
```

## Value

A one-row tibble with the same default eight column names and types as
[`gho_last_updated()`](https://shanlong-who.github.io/DSIR/reference/gho_last_updated.md).
Here `source` is `"sdg"`, `scope` is `"database"`, `backend` and
`indicator` are `NA_character_`, and `timestamp_field` is
`"Series/LastUpdated"`. `updated` preserves the original timestamp
string, including an unspecified time zone. `checked_at` is a UTC
`POSIXct` query start time. `status` is `"ok"`, `"not_available"` for a
missing timestamp, or `"failed"` on request, parsing or validation
failure. Failures warn and keep `updated = NA_character_`.

## Details

The `Series/LastUpdated` endpoint accepts no indicator, series or
country filter. Its database-level timestamp does not mean that every
indicator changed at that time. Series release codes and the
`META_LAST_UPDATE` metadata-document date are not substituted for data
update timestamps. The timestamp is queried on every call and is not
cached by DSIR.

## See also

[`gho_last_updated()`](https://shanlong-who.github.io/DSIR/reference/gho_last_updated.md),
[`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md),
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md).

## Examples

``` r
if (FALSE) { # \dontrun{
sdg_last_updated()
} # }
```
