# Query the Latest GHO Indicator Timestamp

Queries the latest non-missing timestamp among the current observations
for one Global Health Observatory (GHO) indicator, without downloading
its full observation table.

## Usage

``` r
gho_last_updated(indicator, backend = NULL, diagnostics = FALSE)
```

## Arguments

- indicator:

  A single, non-empty GHO indicator code.

- backend:

  Optional WHO backend: `"legacy"` or `"xmart"`. An explicit value
  overrides `getOption("DSIR.who_backend")` for this call only. When
  neither is set, the compatibility default is `"legacy"`.

- diagnostics:

  Logical; default `FALSE`. If `TRUE`, append diagnostic columns without
  making additional requests or changing backend selection.

## Value

A one-row tibble with columns:

- source:

  `"gho"`.

- backend:

  The selected `"legacy"` or `"xmart"` backend.

- scope:

  `"indicator"`.

- indicator:

  The requested GHO code.

- updated:

  The original timestamp as character, or `NA_character_`. Offsets,
  fractional seconds and an unspecified time zone are preserved.

- timestamp_field:

  `"Date"` or `"Sys_CommitDateUtc"`.

- checked_at:

  The query start time as a UTC `POSIXct` value.

- status:

  `"ok"`, `"not_available"` (a successful response provides no
  timestamp), or `"failed"` (lookup, request, parsing or response
  validation failed). A missing timestamp does not establish that no
  observations exist. Failures warn and retain the same one-row schema.

With `diagnostics = TRUE`, six additional columns are appended:

- reason:

  `"timestamp_available"`, `"directory_not_listed"`, `"http_error"` (an
  HTTP error response), `"request_failed"` (no HTTP response),
  `"timestamp_field_missing"`, `"timestamp_missing"` (no non-missing
  timestamp returned), `"unsupported_route"`, `"lookup_failed"`,
  `"unexpected_content"` (HTML instead of JSON), `"invalid_json"`,
  `"invalid_response"`, or `"invalid_timestamp"`. These explain
  `status`; they do not replace its existing three values.

- stage:

  `"directory"`, `"schema"`, or `"timestamp"`: the stage associated with
  the result.

- http_status:

  Integer HTTP status captured in that stage, or `NA` if unavailable,
  including a cached lookup or a transport failure. HTTP 200 alone does
  not establish a valid response.

- timestamp_kind:

  `"legacy_observation_date"` or `"xmart_system_commit"`; neither
  guarantees an official revision date.

- provider_route:

  The selected observation table path, when known. This contains no
  hostname, query string or credentials.

- provider_indicator:

  The exact selected provider identifier: the legacy GHO code or xMart
  `IND_ID`, when known.

## Details

This function is **experimental**. Availability and timestamp semantics
differ between providers; the result is evidence about the selected API
response, not proof of an official WHO data revision.

The legacy backend orders observations by `Date`; xMart uses
`Sys_CommitDateUtc` in the same indicator route selected by
[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md).
Each date query requests only the latest non-missing value. xMart also
consults the existing, session-cached indicator directory and table
fields. Requests never fall back to the other backend.

The result describes the selected backend's current observations across
all locations, years and dimensions. It is not the latest observation
year, a formal publication date, or the update time of the whole GHO. In
particular, an xMart system commit can reflect data processing. Backend
timestamps need not describe the same release or event. DSIR has not
established that legacy `Date` is an official modification or
publication date. Several indicators can share the same system commit
time without evidence that their published values changed together.

`checked_at` is when DSIR started this check, not a source modification
time or data retrieval time. The latest observation year describes the
period measured. Neither is substituted for a source timestamp. To
detect actual differences between retrieved observations, use
[`data_snapshot()`](https://shanlong-who.github.io/DSIR/reference/data_snapshot.md)
and
[`compare_snapshots()`](https://shanlong-who.github.io/DSIR/reference/compare_snapshots.md).

A code absent from the public xMart directory can still be a valid
legacy GHO code. A successful directory request does not establish that
observation requests work. An HTTP failure does not establish that an
indicator is absent. No indicator or backend is silently substituted.

## See also

[`sdg_last_updated()`](https://shanlong-who.github.io/DSIR/reference/sdg_last_updated.md),
[`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md),
[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md).

## Examples

``` r
if (FALSE) { # \dontrun{
gho_last_updated("WHS4_100")
gho_last_updated("WHS4_100", backend = "xmart")
gho_last_updated("WHS4_100", backend = "xmart", diagnostics = TRUE)

# Query several indicators sequentially using the same backend.
codes <- c("WHS4_100", "NCDMORT3070")
updates <- lapply(codes, gho_last_updated, backend = "legacy")
do.call(rbind, updates)
} # }
```
