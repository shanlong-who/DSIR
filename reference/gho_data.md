# Fetch GHO Data

Retrieves observations for a specific indicator from the WHO GHO OData
API, with optional filters by spatial level, country / region and year
range.

## Usage

``` r
gho_data(
  indicator,
  spatial_type = NULL,
  area = NULL,
  year_from = NULL,
  year_to = NULL,
  dim1 = NULL,
  dim2 = NULL,
  dim3 = NULL,
  dimensions = NULL,
  backend = NULL
)
```

## Arguments

- indicator:

  Character scalar. The indicator code (e.g. `"NCDMORT3070"`). Use
  [`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md)
  to find codes.

- spatial_type:

  Character. Spatial dimension to filter on: one of `"country"`,
  `"region"`, `"global"`, or `NULL` (all levels, the default).

- area:

  Character vector of country or region codes (e.g. `c("FRA", "DEU")`).
  Default `NULL` returns all areas.

- year_from:

  Numeric. Start year filter (inclusive). Default `NULL`.

- year_to:

  Numeric. End year filter (inclusive). Default `NULL`.

- dim1, dim2, dim3:

  Character vector of values to keep for the `Dim1` / `Dim2` / `Dim3`
  breakdown columns, filtered server-side (e.g. `dim1 = "SEX_BTSX"` for
  both-sexes rows only, or `dim1 = c("SEX_MLE", "SEX_FMLE")`). The
  meaning of each dimension varies by indicator (`Dim1` is sex for one
  indicator, an age group for another); use
  [`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md)
  to discover the values available for a given indicator. Rows where the
  dimension is empty (`null`) are excluded by the filter. Default `NULL`
  (no filtering). On xMart wide tables, positions follow named
  dimensions in the source table schema (sex, age, then alphabetical).
  These positions can differ from the legacy API. Prefer `dimensions`.
  Canonical sex codes and the `AGEGROUP_` namespace remain supported in
  positional filters. Named filters use the provider's exact native
  codes.

- dimensions:

  Optional named list of exact xMart dimension fields and values, e.g.
  `list(DIM_SEX = 'TOTAL')`. Requires xMart; automatic selection never
  translates these filters to legacy.

- backend:

  Character scalar. `"auto"`, `"xmart"` or `"legacy"`. Default `NULL`
  uses the `DSIR.who_backend` option, or `"auto"` when that option is
  unset. An explicit argument overrides the option for this call without
  changing it. Use the same backend for discovery and retrieval.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) of
indicator observations, or an empty tibble when the service is
unreachable or no observations match. The raw `Provider` column records
`"legacy"` or `"xmart"` per row. A `who_provenance` attribute records
the selected backend and, for successful downloads, the request context
and retrieval time. Automatic queries also record
`requested_backend = "auto"` and, when fallback is attempted,
`fallback_reason` (`"directory_not_listed"` or `"indicator_empty"`). The
same selection metadata is attached to automatic counts, availability,
coverage, dimension and timestamp results, including scalar results.
Failed selection records the attempted xMart backend.

## Details

Since 0.13.0, automatic selection prefers the public WHO xMart service.
It first checks the directory and, for a listed code, requests at most
one observation with a row count for the entire indicator, before
applying user filters. Only a code absent from a successfully read,
non-empty directory or a verified zero-row indicator can trigger legacy
fallback. This adds a small availability request to each automatic
indicator query; that decision is not cached. An HTTP/transport/parsing
failure, unsupported schema/route, or a valid empty filtered result
never triggers fallback. Partial xMart coverage is not filled from
legacy. Each call uses a single provider.

Fallback warns and preserves country/region and year filters. It
requires known WHO ISO3 or region codes. M49/native area codes, named
dimensions and positional `dim1`-`dim3` filters block automatic fallback
because equivalent interpretation cannot be guaranteed. For dimension
discovery, only `SpatialDim`, `SpatialDimType`, `TimeDim` and
`TimeDimType` allow fallback. Incompatible fallback warns and returns
the operation's failed empty/NA result without dropping any filters.
Select a provider explicitly to use its own dimension and geography
conventions.

Explicit `backend = "xmart"` or `"legacy"` fixes the provider and avoids
the automatic availability request. `gho_indicators(backend = "auto")`
searches the xMart catalog only. GHE always uses xMart.
`DSIR.who_base_url` selects another compatible HTTPS xMart origin.
Public directory coverage differs from the legacy catalog, and published
estimates can differ. Unknown xMart directory codes warn; legacy HTTP
404 responses are checked against its directory before being classified
as absent codes. A successful query with no matching observations emits
an informational message. Request or parsing failures warn, and do not
establish that no data exist. Reference lookups are cached only in
memory; no credentials or startup requests are required.

## See also

[`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md),
[`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md).

## Examples

``` r
# \donttest{
# Country-level data for one indicator
gho_data("NCDMORT3070", spatial_type = "country")

# Specific countries and years
gho_data("WHOSIS_000001", area = c("FRA", "DEU"), year_from = 2015)

# Keep only the both-sexes breakdown, filtered server-side
gho_data("NCDMORT3070", spatial_type = "country", dim1 = "SEX_BTSX")

# Select xMart for one call without changing the session default
gho_data("NCDMORT3070", area = "PHL", year_from = 2020, year_to = 2021,
         dimensions = list(DIM_SEX = "TOTAL"), backend = "xmart")
# }
```
