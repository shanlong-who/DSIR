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
#> Assuming `spatial_type` = "country" since `area` was given.
#> ℹ Pass `spatial_type` explicitly to silence this message.
#> Fetching:
#> <https://ghoapi.azureedge.net/api/NCDMORT3070?$filter=SpatialDimType%20eq%20%27COUNTRY%27%20and%20SpatialDim%20in%20%28%27AUS%27%2C%27BRN%27%2C%27CHN%27%2C%27COK%27%2C%27FJI%27%2C%27FSM%27%2C%27IDN%27%2C%27JPN%27%2C%27KHM%27%2C%27KIR%27%2C%27KOR%27%2C%27LAO%27%2C%27MHL%27%2C%27MNG%27%2C%27MYS%27%2C%27NIU%27%2C%27NRU%27%2C%27NZL%27%2C%27PHL%27%2C%27PLW%27%2C%27PNG%27%2C%27SGP%27%2C%27SLB%27%2C%27TON%27%2C%27TUV%27%2C%27VNM%27%2C%27VUT%27%2C%27WSM%27%29>
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■                 
#> Waiting 2s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■                 
#> Waiting 4s for retry backoff ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■  
#> Warning: GHO request failed.
#> ℹ URL:
#>   <https://ghoapi.azureedge.net/api/NCDMORT3070?$filter=SpatialDimType%20eq%20%27COUNTRY%27%20and%20SpatialDim%20in%20%28%27AUS%27%2C%27BRN%27%2C%27CHN%27%2C%27COK%27%2C%27FJI%27%2C%27FSM%27%2C%27IDN%27%2C%27JPN%27%2C%27KHM%27%2C%27KIR%27%2C%27KOR%27%2C%27LAO%27%2C%27MHL%27%2C%27MNG%27%2C%27MYS%27%2C%27NIU%27%2C%27NRU%27%2C%27NZL%27%2C%27PHL%27%2C%27PLW%27%2C%27PNG%27%2C%27SGP%27%2C%27SLB%27%2C%27TON%27%2C%27TUV%27%2C%27VNM%27%2C%27VUT%27%2C%27WSM%27%29>
#> ✖ HTTP 502 Bad Gateway.
sdg <- sdg_data("3.4.1",        area = wpro_cty) |> sdg_clean()
#> Fetching:
#> <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Indicator/Data?indicator=3.4.1&pageSize=1000&areaCode=036&areaCode=096&areaCode=156&areaCode=184&areaCode=242&areaCode=583&areaCode=360&areaCode=392&areaCode=116&areaCode=296&areaCode=410&areaCode=418&areaCode=584&areaCode=496&areaCode=458&areaCode=570&areaCode=520&areaCode=554&areaCode=608&areaCode=585&areaCode=598&areaCode=702&areaCode=090&areaCode=776&areaCode=798&areaCode=704&areaCode=548&areaCode=882&page=1>
bind_indicators(gho, sdg)
#> # A tibble: 462 × 15
#>    source id    indicator     location iso3  location_name  year value value_num
#>    <chr>  <chr> <chr>         <chr>    <chr> <chr>         <int> <chr>     <dbl>
#>  1 sdg    3.4.1 Mortality ra… 116      KHM   Cambodia       2000 28.1       28.1
#>  2 sdg    3.4.1 Mortality ra… 116      KHM   Cambodia       2000 25.4       25.4
#>  3 sdg    3.4.1 Mortality ra… 116      KHM   Cambodia       2000 31.8       31.8
#>  4 sdg    3.4.1 Mortality ra… 116      KHM   Cambodia       2005 22.5       22.5
#>  5 sdg    3.4.1 Mortality ra… 116      KHM   Cambodia       2005 25.6       25.6
#>  6 sdg    3.4.1 Mortality ra… 116      KHM   Cambodia       2005 29.7       29.7
#>  7 sdg    3.4.1 Mortality ra… 116      KHM   Cambodia       2010 24.4       24.4
#>  8 sdg    3.4.1 Mortality ra… 116      KHM   Cambodia       2010 20.9       20.9
#>  9 sdg    3.4.1 Mortality ra… 116      KHM   Cambodia       2010 29.1       29.1
#> 10 sdg    3.4.1 Mortality ra… 116      KHM   Cambodia       2015 28.3       28.3
#> # ℹ 452 more rows
#> # ℹ 6 more variables: low <dbl>, high <dbl>, series <chr>, dim1 <chr>,
#> #   dim2 <chr>, dim3 <chr>
# }
```
