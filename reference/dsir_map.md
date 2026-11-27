# Map an Indicator with Recorded or User-Supplied Boundaries

Draw a choropleth or a point-symbol map from a
[dsir_data](https://shanlong-who.github.io/DSIR/reference/as_dsir_data.md)
object or an ordinary data frame. Polygon maps also accept an `sf` table
or supplied polygons. WHO ADM0 polygons and centre coordinates are
requested only with permission and cached outside the package. Return a
standard ggplot.

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
  crs = NULL,
  type = c("polygon", "point")
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

  Logical, default `FALSE`. Explicitly download fresh WHO polygons or
  centre coordinates even when cached. Download permission is still
  required. Failed or invalid downloads never replace a valid country
  cache.

- crs:

  Optional display coordinate reference system passed to
  [`ggplot2::coord_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html).
  It does not change cached source geometries.

- type:

  Map type. `"polygon"` (default) uses polygons. `"point"` reads the
  published `CENTER_LON` and `CENTER_LAT` fields of the same WHO ADM0
  layer. Use a regular analysis table without supplied boundaries in
  this mode.

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
and duplicate keys cause errors. Geometries are used as supplied. If WHO
ADM0 returns empty or invalid geometry, obtain a corrected WHO boundary
or provide a complete, validated `sf` table using `boundaries`. After a
correction to the WHO service, set `refresh = TRUE` to request a fresh
copy.

Point maps require one finite, in-range coordinate pair per requested
ISO3 code. They cache coordinates separately and emit a message with the
UTC retrieval date or dates and the unverified WHO GIS release status.
These dates also appear in the caption and the map metadata as records
of coordinate retrieval. For Western Pacific codes in
[wpro_cty](https://shanlong-who.github.io/DSIR/reference/who_region_vectors.md),
centres outside the display extent (88°E to 141°W across the date line
and 48°S to 53°N) are flagged in the caption and metadata. Western
Pacific maps using the default projection display flagged points in a
world locator when the main view has points. Other projections display
flagged points at their reported positions. Every requested point
remains in the returned `sf` data.

Boundary validation errors have class `dsir_map_boundary_error` and a
`diagnostics` field with area keys, validation reasons, engine and
version, check time and source context. For geometry downloads, source
context can include the query URL, HTTP status, file size, checksum and
ArcGIS error code. ArcGIS can report a service error, including rate
limiting, in a response with HTTP status 200. Follow the reported retry
interval when the service is rate limiting requests. Catch with
`tryCatch(dsir_map(...), dsir_map_boundary_error = function(e) e)` and
inspect or save the returned condition's `diagnostics` field. S2
validates geographic coordinates when enabled in sf; otherwise GEOS is
used. Structural checks (including empty geometry) are labelled sf. A
boundary can render on a web map while failing topology validation; this
does not mean its geometry is missing. Unknown validity also causes an
error. Successful maps retain validation records in
`dsir_metadata(map)$boundaries$validation`. Cache reads validate again;
invalid-cache warnings retain geometry diagnostics when available.

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
snapshot is required. The GeoJSON reader uses a temporary 512 MiB
feature parsing limit for WHO downloads when `OGR_GEOJSON_MAX_OBJ_SIZE`
is unset. An explicit GDAL setting takes precedence.

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
