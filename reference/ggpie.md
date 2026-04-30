# Create a Pie Chart with ggplot2

Builds a pie chart from a data frame using one categorical column and
one numeric column. Slices are labeled with the category name and
percentage share.

## Usage

``` r
ggpie(
  df,
  .x,
  .y,
  .offset = 1,
  .color = "white",
  .legend = FALSE,
  .label = TRUE,
  .label_size = 3.5
)
```

## Arguments

- df:

  A data frame.

- .x:

  Column name (string) of the categorical variable used for the slices.

- .y:

  Column name (string) of the numeric variable used for the slice
  values.

- .offset:

  Bar `x` position. Default `1`. Increase (e.g. `2`) to carve out a
  donut-chart hole.

- .color:

  Border color between slices. Default `"white"`.

- .legend:

  Logical. Show the legend? Default `FALSE`.

- .label:

  Logical. Draw `"name\n(pct%)"` labels on the slices? Default `TRUE`.

- .label_size:

  Label text size in mm. Default `3.5`.

## Value

A `ggplot` object.

## Examples

``` r
df <- data.frame(
  category = c("A", "B", "C"),
  value = c(40, 35, 25)
)
ggpie(df, "category", "value")
```
