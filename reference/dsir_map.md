# Map an Indicator with Recorded or User-Supplied Boundaries

Draw a choropleth from a
[dsir_data](https://shanlong-who.github.io/DSIR/reference/as_dsir_data.md)
object, an ordinary data frame or an `sf` table. Return a standard
ggplot. WHO ADM0 boundaries are downloaded by country only with
permission and cached outside the package. Alternatively, supply your
own polygons for an offline map.

## Usage

``` r
dsir_map(
  data,
  value = "value_num",
  country = "iso3",
  year = NULL,
  boundaries = NULL,
  boundary_key = NULL,
  download = c("ask", "allow", "never"),
  cache_dir = NULL,
  refresh = FALSE,
  crs = NULL
)
```

## Arguments

- data:

  A data frame with one row per mapped area. A `dsir_data` object uses
  its existing semantic checks. An `sf` input supplies its own geometry.

- value:

  Name of the numeric value column, default `"value_num"`. For
  `dsir_data`, use `value_num`; for a derived measure, supply an
  ordinary analysis table with its units defined explicitly instead of
  borrowing the original indicator's metadata.

- country:

  Name of the area-key column, default `"iso3"`. WHO downloads require
  uppercase three-letter ISO3 codes. User-supplied boundaries can use
  other character or factor keys; matching is exact.

- year:

  Optional single integer-valued year, selecting the `year` column. If
  that column exists, the selected data must contain one common
  non-missing year. No latest-year selection or aggregation occurs.

- boundaries:

  Optional `sf` polygons. If omitted, use geometry in `data`, or obtain
  WHO ADM0 polygons. No other source is used to fill gaps.

- boundary_key:

  Key column in `boundaries`. Defaults to `country` when present,
  otherwise `"ISO_3_CODE"`. Each requested key must match exactly one
  polygon or multipolygon row. Extra, unrequested areas are not drawn.

- download:

  Download policy: `"ask"` (default) asks interactively when uncached
  countries are needed; in non-interactive sessions it errors with
  guidance. `"allow"` explicitly permits downloads; `"never"` requires a
  valid cache or user-supplied geometry. No downloads occur on package
  load.

- cache_dir:

  Directory for the country cache. Defaults to the `maps` subdirectory
  of `tools::R_user_dir("DSIR", "cache")`. Supply a project directory to
  retain the exact boundaries used by an analysis.

- refresh:

  Logical, default `FALSE`. Explicitly download fresh WHO polygons even
  when cached. Download permission is still required. Failed or invalid
  downloads never replace a valid country cache.

- crs:

  Optional display coordinate reference system passed to
  [`ggplot2::coord_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html).
  It does not change cached source geometries.

## Value

A ggplot using
[`theme_dsi()`](https://shanlong-who.github.io/DSIR/reference/theme_dsi.md)
and a continuous viridis scale. Missing estimates are shown in grey. Its
data is an `sf` table containing the selected analysis columns and
matched geometry.
[`dsir_metadata()`](https://shanlong-who.github.io/DSIR/reference/dsir_metadata.md)
reports map-creation context, input metadata and boundary provenance;
this record does not audit subsequent ggplot modifications.

## Details

The optional package `sf` is required only when this function is used.
Filter to one indicator, measure, unit and population stratum before
mapping. Known semantic fields in ordinary tables are checked as well;
fields absent from such tables cannot be verified. Ordinary tables
should provide a constant `unit` column when units are known. A matching
key alone does not establish geographic or temporal comparability.

Empty or invalid geometries, unknown coordinate systems, missing areas
and duplicate keys cause errors. Geometries are never repaired,
simplified, dissolved or combined with another source automatically. The
WHO ADM0 service returned empty Philippine geometry during development;
a Philippine map therefore requires corrected official data or complete
user-supplied boundaries. This is validated from each response, not a
country blacklist.

Downloads use the public WHO `Detailed_Boundary_ADM0` Feature Service,
layer 0, item `39663258d2b44dcaa28af952ed40760b`, without
authentication. Its item terms require use without modification and link
to <https://data.who.int/about/data/terms-and-conditions>. Consult the
source terms and appropriate cartographic presentation for your output.
Permission to download does not certify geometry completeness.

The downloader verifies one stable feature identifier per country and
checks the returned country, coordinate system and geometry before
caching. Each cache records its endpoint, query, retrieval time, item
modification time, source terms and download checksum. Item modification
time is not an official boundary reference date. Cache use preserves
retrieval time and makes no network calls. Cached countries may have
different retrieval dates; inspect the boundary records when a common
snapshot is required.

## See also

[`plot.dsir_data()`](https://shanlong-who.github.io/DSIR/reference/plot.dsir_data.md),
[`dsir_metadata()`](https://shanlong-who.github.io/DSIR/reference/dsir_metadata.md)

## Examples

``` r
if (requireNamespace("sf", quietly = TRUE)) {
  # Artificial polygons and values for an entirely offline example.
  square <- function(x) sf::st_polygon(list(matrix(
    c(x, 0, x + 1, 0, x + 1, 1, x, 1, x, 0), ncol = 2, byrow = TRUE)))
  borders <- sf::st_sf(code = c("A", "B"),
    geometry = sf::st_sfc(square(0), square(1), crs = 4326))
  values <- data.frame(code = c("A", "B"), rate = c(10, 20), unit = "percent")
  p <- dsir_map(values, value = "rate", country = "code", boundaries = borders)
  p
  dsir_metadata(p)$boundaries
}
```
