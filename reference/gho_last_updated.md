# Query the Latest GHO Indicator Timestamp

Queries the latest non-missing timestamp among the current observations
for one Global Health Observatory (GHO) indicator, without downloading
its full observation table.

## Usage

``` r
gho_last_updated(indicator, backend = NULL)
```

## Arguments

- indicator:

  A single, non-empty GHO indicator code.

- backend:

  Optional WHO backend: `"legacy"` or `"xmart"`. An explicit value
  overrides `getOption("DSIR.who_backend")` for this call only. When
  neither is set, the compatibility default is `"legacy"`.

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

## Details

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
timestamps need not describe the same release or event.

## See also

[`sdg_last_updated()`](https://shanlong-who.github.io/DSIR/reference/sdg_last_updated.md),
[`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md),
[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md).

## Examples

``` r
if (FALSE) { # \dontrun{
gho_last_updated("WHS4_100")
gho_last_updated("WHS4_100", backend = "xmart")

# Query several indicators sequentially using the same backend.
codes <- c("WHS4_100", "NCDMORT3070")
updates <- lapply(codes, gho_last_updated, backend = "legacy")
do.call(rbind, updates)
} # }
```
