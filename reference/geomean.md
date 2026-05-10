# Geometric Mean

Computes the geometric mean of a numeric vector, with optional weights.
Useful for aggregating multiplicative quantities such as ratio-based
health indicators (e.g. UHC service-coverage tracers, where the
composite index is the geometric mean of component coverage values).

## Usage

``` r
geomean(x, w = NULL, na.rm = TRUE)
```

## Arguments

- x:

  A numeric vector. Zeros produce a result of `0`. Negative values
  produce `NaN` with a warning, since the geometric mean is undefined
  for negative numbers.

- w:

  Optional numeric vector of weights, the same length as `x`. Must be
  non-negative. If `NULL` (default), the unweighted geometric mean is
  returned.

- na.rm:

  Logical. Should missing values in `x` (and `w`, if provided) be
  removed before computation? Default `TRUE`.

## Value

A numeric scalar. Returns `NA_real_` when the input is empty, when it is
entirely `NA`, or when `na.rm = FALSE` and any element is `NA`. Returns
`NaN` with a warning when `x` contains negative values, or when all
weights are zero.

## Details

Pass `w` to compute a weighted geometric mean, defined as
`exp(weighted.mean(log(x), w))`.

## Examples

``` r
# Unweighted
geomean(c(1, 4, 16))                # 4
#> [1] 4
geomean(c(0.6, 0.8, 0.95))          # ~0.772 — typical UHC tracer aggregation
#> [1] 0.7697002
geomean(c(1, NA, 4))                # 2
#> [1] 2
geomean(c(1, NA, 4), na.rm = FALSE) # NA_real_
#> [1] NA
geomean(c(1, 0, 4))                 # 0
#> [1] 0

# Weighted
geomean(c(1, 4, 16), w = c(1, 1, 1))     # 4 (equal weights = unweighted)
#> [1] 4
geomean(c(1, 4, 16), w = c(1, 2, 1))     # weighted toward 4
#> [1] 4
geomean(c(0.6, 0.8, 0.95), w = c(2, 1, 1))
#> [1] 0.7232343
```
