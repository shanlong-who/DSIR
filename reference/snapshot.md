# Snapshot an Expensive Expression to a Local File

Evaluates an expression — typically an API pull such as a
[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md)
/
[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
pipeline — and saves the result to an `.rds` file. On later calls, the
saved snapshot is read back instead of re-evaluating the expression, so
analyses re-run reproducibly and offline once the data have been
fetched.

## Usage

``` r
snapshot(expr, file, refresh = FALSE, max_age = Inf)
```

## Arguments

- expr:

  An expression producing the object to snapshot. Evaluated lazily —
  only when no usable snapshot exists (see Details).

- file:

  Path of the snapshot file (conventionally `.rds`). Read with
  [`readRDS()`](https://rdrr.io/r/base/readRDS.html) and written with
  [`saveRDS()`](https://rdrr.io/r/base/readRDS.html).

- refresh:

  Logical. Re-evaluate `expr` even if a snapshot exists? Default
  `FALSE`.

- max_age:

  Numeric. Maximum acceptable snapshot age in **days**; an older
  snapshot triggers re-evaluation as if `refresh = TRUE`. Default `Inf`
  (a snapshot never expires).

## Value

The snapshotted object: either the value of `expr` or the contents of
`file`, per the logic above. A message states which of the two was used.

## Details

The decision logic is:

1.  If `file` exists, `refresh = FALSE`, and the snapshot is younger
    than `max_age` days, the snapshot is read and returned. `expr` is
    **not** evaluated.

2.  Otherwise `expr` is evaluated. A usable result (anything other than
    `NULL`, a 0-row data frame, or an empty list) is written to `file`
    (directories are created as needed) and returned.

3.  An *empty* result — the signature of an unreachable API, since
    DSIR's network functions fail soft — is never written, so a failed
    refresh cannot destroy a good snapshot. If an older snapshot exists
    it is returned instead, with a warning; otherwise the empty result
    is returned as-is.

`snapshot()` deliberately does **not** invent file names, manage a cache
directory, or hash arguments: you choose the path, so a project can use
a fixed name (`data/indicators.rds`) or a dated one, and the file is
plain [`saveRDS()`](https://rdrr.io/r/base/readRDS.html) output readable
without DSIR.

To force a re-fetch, pass `refresh = TRUE` (or delete the file).

## See also

[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md),
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md),
[`bind_indicators()`](https://shanlong-who.github.io/DSIR/reference/bind_indicators.md)
— the typical producers of snapshotted objects.

## Examples

``` r
path <- tempfile(fileext = ".rds")

# First call evaluates the expression and writes the snapshot
x <- snapshot(data.frame(a = 1:3), path)
#> Snapshot written to /tmp/RtmpCwTqs6/file1a8056703f65.rds.

# Second call reads the snapshot; the expression is not evaluated
y <- snapshot(stop("not evaluated"), path)
#> Using snapshot /tmp/RtmpCwTqs6/file1a8056703f65.rds (saved 2026-07-05
#> 22:56:30).
identical(x, y)
#> [1] TRUE

# Force a refresh
z <- snapshot(data.frame(a = 1:5), path, refresh = TRUE)
#> Snapshot written to /tmp/RtmpCwTqs6/file1a8056703f65.rds.
nrow(z)
#> [1] 5

unlink(path)
# \donttest{
# Typical use: pin an API pull for a reproducible report
ncd <- snapshot(
  gho_clean(gho_data("NCDMORT3070", "country", wpro_cty)),
  file.path(tempdir(), "ncdmort3070.rds")
)
#> Fetching:
#> <https://ghoapi.azureedge.net/api/NCDMORT3070?$filter=SpatialDimType%20eq%20%27COUNTRY%27%20and%20SpatialDim%20in%20%28%27AUS%27%2C%27BRN%27%2C%27CHN%27%2C%27COK%27%2C%27FJI%27%2C%27FSM%27%2C%27IDN%27%2C%27JPN%27%2C%27KHM%27%2C%27KIR%27%2C%27KOR%27%2C%27LAO%27%2C%27MHL%27%2C%27MNG%27%2C%27MYS%27%2C%27NIU%27%2C%27NRU%27%2C%27NZL%27%2C%27PHL%27%2C%27PLW%27%2C%27PNG%27%2C%27SGP%27%2C%27SLB%27%2C%27TON%27%2C%27TUV%27%2C%27VNM%27%2C%27VUT%27%2C%27WSM%27%29>
#> Snapshot written to /tmp/RtmpCwTqs6/ncdmort3070.rds.
# }
```
