# Continuous Scales for DSIR Bar / Column Charts

Thin wrappers around
[`ggplot2::scale_y_continuous()`](https://ggplot2.tidyverse.org/reference/scale_continuous.html)
and
[`ggplot2::scale_x_continuous()`](https://ggplot2.tidyverse.org/reference/scale_continuous.html)
that remove the default lower expansion so that columns sit flush with
the axis — the convention for WHO and most publication-style bar charts.
The upper expansion is preserved at 5% so the tallest column has
breathing room above (or to the right of) it.

## Usage

``` r
scale_y_dsi_col(...)

scale_x_dsi_col(...)
```

## Arguments

- ...:

  Arguments forwarded to the underlying
  [`ggplot2::scale_y_continuous()`](https://ggplot2.tidyverse.org/reference/scale_continuous.html)
  /
  [`ggplot2::scale_x_continuous()`](https://ggplot2.tidyverse.org/reference/scale_continuous.html).

## Value

A `ggplot2` Scale object, to be added to a plot with `+`.

## Details

Use `scale_y_dsi_col()` for vertical bars
([`geom_col()`](https://ggplot2.tidyverse.org/reference/geom_bar.html) /
[`geom_bar()`](https://ggplot2.tidyverse.org/reference/geom_bar.html))
and `scale_x_dsi_col()` when bars are horizontal (via
[`coord_flip()`](https://ggplot2.tidyverse.org/reference/coord_flip.html)
or `geom_col(orientation = "y")`).

Pass any other `scale_*_continuous()` argument (`labels`, `breaks`,
`limits`, ...) through `...`.

## Examples

``` r
library(ggplot2)

# Vertical bars
ggplot(mtcars, aes(factor(cyl))) +
  geom_bar(fill = "#0093D5") +
  scale_y_dsi_col() +
  theme_dsi()

```
