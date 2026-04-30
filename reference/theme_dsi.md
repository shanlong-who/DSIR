# DSIR ggplot2 theme — WHO publication-style

A clean, modern theme tuned for WHO and global-health publications.
Removes the panel border, retains only horizontal grid lines, and uses a
muted text colour so that the data — not the chart chrome — is the
visual focus.

## Usage

``` r
theme_dsi(
  base_size = 12,
  base_family = "",
  accent = "#0093D5",
  grid_color = "grey92",
  legend_position = "bottom"
)
```

## Arguments

- base_size:

  Base font size in points. Default `12`.

- base_family:

  Base font family. Default `""` (system default). Set to `"sans"`,
  `"Arial"`, `"Helvetica"`, or `"Calibri"` for a specific look. Empty
  default keeps the package portable on CRAN's Linux check machines,
  where Calibri is unavailable.

- accent:

  Accent colour used for axis lines and as a default for highlight
  elements. Default `"#0093D5"` (WHO blue). Pass any colour string.

- grid_color:

  Colour of the (horizontal) major grid. Default `"grey92"` — a very
  light grey, close to bbplot and OECD style.

- legend_position:

  Position of the legend. Default `"bottom"`. Pass `"none"`, `"top"`,
  `"right"`, or a numeric vector `c(x, y)`.

## Value

A `ggplot2` theme object.

## Examples

``` r
library(ggplot2)
ggplot(mtcars, aes(wt, mpg, color = factor(cyl))) +
  geom_point(size = 3) +
  theme_dsi() +
  labs(title = "Fuel efficiency by weight",
       subtitle = "From the mtcars dataset",
       x = "Weight (1000 lbs)", y = "Miles per gallon",
       color = "Cylinders")

```
