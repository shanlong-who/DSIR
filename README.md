# DSIR <img src="man/figures/logo.jpg" align="right" height="138" alt="DSIR logo" />

> Data Science Infrastructure for Global Health

An R package providing a publication-ready `ggplot2` theme,
`flextable` defaults, a pie-chart helper, built-in regional
country-code datasets, and convenient clients for the
[WHO Global Health Observatory](https://www.who.int/data/gho) and
[UN Sustainable Development Goals](https://unstats.un.org/sdgs)
APIs.

## Installation

```r
# from CRAN
install.packages("DSIR")

# or the development version from GitHub  
# install.packages("remotes")
remotes::install_github("shanlong-who/DSIR")
```

## Features

### Visualization

**`theme_dsi()`** — publication-ready `ggplot2` theme.

```r
library(DSIR)
library(ggplot2)

ggplot(women, aes(height, weight)) +
  geom_point(color = "steelblue") +
  theme_dsi()
```

**`dsi_flextable_defaults()`** — one-line setup for `flextable`
formatting (booktabs style, bold headers). Pass
`font_family = "Cambria"` if you have the font installed.

```r
dsi_flextable_defaults()
```

**`ggpie()`** — quick pie charts with automatic percentage labels.

```r
df <- data.frame(category = c("A", "B", "C"), value = c(40, 35, 25))
ggpie(df, "category", "value")
```

### Data

**`wpro_cty`** — ISO-3 country codes for the WHO Western Pacific
Region.

```r
head(wpro_cty)
#> [1] "AUS" "BRN" "KHM" "CHN" "COK" "FJI"
```

### WHO GHO API

```r
# Search indicators by keyword
gho_indicators("mortality")

# Country-level data for an indicator
gho_data("NCDMORT3070", spatial_type = "country")

# Filter by area and year
gho_data("WHOSIS_000001", area = c("FRA", "DEU"), year_from = 2015)

# Discover available dimensions
gho_dimensions("NCDMORT3070")
gho_dimensions("NCDMORT3070", dimension = "Dim1")
```

### UN SDG API

```r
# Browse goals, targets, indicators, and geographic areas
sdg_goals()
sdg_targets()
sdg_indicators()
sdg_areas()

# Fetch indicator data
sdg_data("3.2.1", area = "156", year_from = 2015, year_to = 2023)
```

## License

MIT
