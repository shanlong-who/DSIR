# Bind Cleaned Indicator Tibbles

Combines two or more tibbles produced by
[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
or
[`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md)
or
[`ghe_clean()`](https://shanlong-who.github.io/DSIR/reference/ghe_clean.md)
into a single tibble. All cleaners output the same 15-column core
schema. The result is a uniform table that can be filtered, joined, or
visualised without source-specific code paths; use the `source` column
to identify GHO, SDG and GHE rows.

## Usage

``` r
bind_indicators(...)
```

## Arguments

- ...:

  Two or more tibbles returned by
  [`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
  or
  [`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md)
  or
  [`ghe_clean()`](https://shanlong-who.github.io/DSIR/reference/ghe_clean.md)
  (or any data frame containing the core columns). `NULL` arguments are
  dropped. Calling with no inputs — or only `NULL` inputs — returns the
  empty 15-column tibble.

## Value

A single [tibble](https://tibble.tidyverse.org/reference/tibble.html)
with the unified cleaned- indicator schema (15 core columns), followed
by any additional columns in first-seen order. Row order is
`c(input_1, input_2, ...)`, preserving within-input order.

## Details

Inputs do not need to be in any particular order. `NULL` inputs are
silently dropped, which makes it ergonomic to write code like
`bind_indicators(maybe_gho, maybe_sdg)` where some sources may not have
been fetched.

Additional columns, including named dimensions from
`sdg_clean(keep_dimensions = TRUE)`, are preserved. Columns absent from
an input are filled with typed missing values. Binding rows does not
harmonise dimension codes or indicator definitions across sources.
`gho_clean(keep_metadata = TRUE)` retains a row-level `provider` column
so legacy and xMart GHO observations remain distinguishable after
binding. Binding does not merge the input `who_provenance` attributes;
preserve raw pulls or snapshots when request-level provenance is needed.

## See also

[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md),
[`sdg_clean()`](https://shanlong-who.github.io/DSIR/reference/sdg_clean.md),
[`ghe_clean()`](https://shanlong-who.github.io/DSIR/reference/ghe_clean.md).

## Examples

``` r
# \donttest{
gho <- gho_data("NCDMORT3070", area = wpro_cty) |> gho_clean()
sdg <- sdg_data("3.4.1",        area = wpro_cty) |> sdg_clean()
bind_indicators(gho, sdg)
# }
```
