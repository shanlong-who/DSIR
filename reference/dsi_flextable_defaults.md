# Set DSIR Flextable Defaults

Applies a consistent set of `flextable` formatting defaults for
publication-ready tables (booktabs theme, bold headers, modest padding).
Pick any font you like — the default `""` leaves the `flextable` default
in place so the call is safe on systems where Cambria is not installed.

## Usage

``` r
dsi_flextable_defaults(
  font_size = 12,
  font_family = "",
  font_color = "#333333",
  border_color = "black",
  padding = c(3, 3, 4, 4)
)
```

## Arguments

- font_size:

  Font size in points. Default `12`.

- font_family:

  Font family name. Default `""` keeps the existing `flextable` default;
  try `"Cambria"` for the original DSIR look on Windows.

- font_color:

  Font color. Default `"#333333"`.

- border_color:

  Border color. Default `"black"`.

- padding:

  Numeric vector of length 1 (applied to all sides) or length 4 (`top`,
  `bottom`, `left`, `right`). Default `c(3, 3, 4, 4)`.

## Value

Invisibly returns `NULL`. Called for its side effect of mutating the
`flextable` global defaults via
[`flextable::set_flextable_defaults()`](https://davidgohel.github.io/flextable/reference/set_flextable_defaults.html).

## Examples

``` r
dsi_flextable_defaults()
```
