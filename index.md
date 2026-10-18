# From Global Health Data to Clear Insights

DSIR

Data Science Infrastructure for Global Health

DSIR is an open-source R package that simplifies access to global health
data, supports consistent data processing, and provides reusable tools
for analysis and visualization.

[Explore Features](#core-capabilities) [Get Started](#getting-started)

[Technical Documentation
→](https://shanlong-who.github.io/DSIR/articles/DSIR.md) [GitHub
→](https://github.com/shanlong-who/DSIR)

Open source · Available on CRAN · MIT licence

1.  01
    **Access**WHO GHO · WHO GHE · UN SDG
2.  02
    **Prepare**Clean tables, country codes and data context
3.  03
    **Analyse**Health indicators, mortality and progress
4.  04
    **Present**Consistent charts and analytical tables

Reusable tools for each stage of your analysis.

A consistent R workflow

The everyday challenge

## Why DSIR?

Health data are spread across platforms, with different table structures
and geographical identifiers. Analysts repeatedly retrieve, clean and
format data, while keeping their work reproducible and their reports
consistent.

DSIR brings commonly used global health data sources and analytical
utilities into a consistent R workflow, reducing repetitive data
preparation and supporting reproducible analyses.

For technical teams preparing country comparisons, monitoring indicators
and producing public health reports.

What you can do

## Core capabilities

01 / ACCESS

### Access Global Health Data

Retrieve observations from WHO Global Health Observatory (GHO), WHO
Global Health Estimates (GHE), and UN Sustainable Development Goals
(SDG) services. Select countries, years and population breakdowns.

[Explore WHO data access
→](https://shanlong-who.github.io/DSIR/articles/ghe-xmart.md)

02 / PREPARE

### Harmonize Data

Work with a consistent cleaned table structure, WHO Member State
metadata and country identifiers. Keep additional dimensions and source
information when needed.

[See data preparation tools
→](https://shanlong-who.github.io/DSIR/reference/bind_indicators.md)

03 / ANALYSE

### Analyse Health Indicators

Use life tables, direct age standardization and measures of annual
progress to support mortality analysis and indicator monitoring.

[Explore analytical methods
→](https://shanlong-who.github.io/DSIR/reference/index.html#demographic-methods)

04 / PRESENT

### Visualize and Present Results

Apply reusable ggplot2 themes and flextable formatting to create
consistent charts and analytical tables for technical reports.

[View visualization examples
→](https://shanlong-who.github.io/DSIR/articles/visualizing-indicators.md)

A common table structure does not make indicator definitions or
estimation methods comparable. Check source methods, population
breakdowns and units before comparing results.

From tools to tasks

## Practical applications

For WHO technical teams and public health researchers working with
international health data.

- ### Monitor health indicators

  Explore observations across countries and years, keeping population
  groups and data sources visible.

- ### Explore mortality and disease burden

  Examine WHO estimates by cause, age, sex, country and year.

- ### Assess progress towards SDG targets

  Retrieve health-related SDG series and analyse changes over time.

- ### Prepare reproducible reports

  Reuse data preparation steps, charts and table styles across
  analytical outputs.

These are potential uses of the package, not claims of official adoption
by WHO.

Ongoing development

## Development roadmap

DSIR continues to evolve in response to practical needs in global health
data analysis. Future development is planned to include GIS-related
functions to support geospatial data processing, mapping and spatial
analysis.

GIS capabilities are a future direction and are not part of the current
release.

The person behind the project

## Developed and maintained by Shanlong Ding

Technical Officer (Data Analyst)  
WHO Regional Office for the Western Pacific

[View GitHub profile →](https://github.com/shanlong-who)

DSIR is a personally maintained open-source project. It is not an
official WHO software product and is not endorsed or published by WHO.

Start with the package

## Getting started

Install DSIR from CRAN, then follow the technical guide for data access,
analysis and presentation.

``` r

install.packages("DSIR")
library(DSIR)
```

[CRAN Package →](https://CRAN.R-project.org/package=DSIR) [Function
Reference →](https://shanlong-who.github.io/DSIR/reference/index.md)
[Tutorials / Articles
→](https://shanlong-who.github.io/DSIR/articles/index.md) [Full
Technical Documentation
→](https://shanlong-who.github.io/DSIR/articles/DSIR.md) [GitHub
Repository & Technical README
→](https://github.com/shanlong-who/DSIR#readme) [Release Notes
→](https://shanlong-who.github.io/DSIR/news/index.md)
