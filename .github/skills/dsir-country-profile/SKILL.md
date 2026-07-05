---
name: dsir-country-profile
description: >-
  Pull WHO Global Health Observatory (GHO) and UN SDG indicator data with the
  DSIR R package, clean it into the unified 15-column schema, and generate a
  country profile (trend charts, AARR progress table, markdown summary). Use
  this skill whenever the user wants health-indicator data for a country or
  region — GHO or SDG data pulls, indicator trends, life expectancy /
  mortality / NCD / immunization series, AARR or progress-toward-2030
  calculations, country profiles or factsheets for WHO Member States — even
  if they never mention DSIR, GHO, or SDG by name. Examples: "get life
  expectancy for the Philippines", "NCD mortality trend in WPRO countries",
  "under-five mortality AARR since 2000", "make a health profile for
  Viet Nam".
---

# DSIR country profile

Wraps the `DSIR` R package (>= 0.8.0) workflow: check indicator
availability, pull GHO/SDG data, clean to the unified 15-column schema,
and produce a per-country profile (PNG trend charts, AARR summary CSV,
and a `profile.md` ready to weave into a report).

## Prerequisites

- R with `DSIR` (>= 0.8.0), `dplyr`, `readr`, `ggplot2` installed.
- Find `Rscript`: try `Rscript` on PATH first; otherwise pick the
  highest-version match of `D:/R/R-*/bin/Rscript.exe` or
  `$env:LOCALAPPDATA/Programs/R/R-*/bin/Rscript.exe` (machines differ).
  Verify with `Rscript -e "packageVersion('DSIR')"`.
- Network access to `ghoapi.azureedge.net` (GHO) and `unstats.un.org`
  (SDG). **DSIR fails soft**: an unreachable API returns an *empty*
  table with a warning, never an error. Row counts are the only
  reliable success signal — the scripts print them; always read them.

## Workflow

Run scripts from anywhere with absolute paths; `<skill-dir>` below is
this skill's directory.

**Step 0 — resolve indicator codes.** Check
[references/indicator-codes.md](references/indicator-codes.md) for
common codes. For anything else, search the catalogs inline:

```r
DSIR::gho_indicators(search = "life expectancy")   # GHO codes
DSIR::sdg_indicators(search = "maternal mortality") # SDG codes (e.g. "3.1.1")
```

**Step 1 — check availability** (optional but recommended before big
pulls or unfamiliar indicators):

```
Rscript "<skill-dir>/scripts/check_availability.R" --gho NCDMORT3070 --area PHL
Rscript "<skill-dir>/scripts/check_availability.R" --sdg 3.4.1 --area PHL --year-from 2000
```

Prints per-location year ranges and observation counts. An empty table
means no data *or* an unreachable API — check stderr for warnings.

**Step 2 — fetch and clean:**

```
Rscript "<skill-dir>/scripts/fetch_indicators.R" --gho WHOSIS_000001,NCDMORT3070 --sdg 3.4.1 --area PHL --year-from 2000 --dim1 SEX_BTSX --out phl_indicators.csv
```

(Keep commands on one line — `^` continuation is cmd-only and backtick
is PowerShell-only.)

Pulls each code, runs `gho_clean()` / `sdg_clean()`, binds with
`bind_indicators()`, and writes one CSV (or `.rds`) in the 15-column
schema. Exits with status 1 if zero rows came back overall. For a whole
WHO region, build the area list in R first, e.g.
`paste(DSIR::wpro_cty, collapse = ",")`.

**Step 3 — generate the profile:**

```
Rscript "<skill-dir>/scripts/country_profile.R" --data phl_indicators.csv --iso3 PHL --out-dir outputs/profile_PHL
```

Writes into `--out-dir`: `profile.md` (summary tables + embedded
figures), `aarr_summary.csv` (per-indicator AARR, notes, 2030
projection), `profile_data.csv` (the country subset), and `figures/`
(one trend PNG per indicator, `theme_dsi()`, Okabe-Ito colors).

**Step 4 — deliverable.** `profile.md` is the raw material. If the user
wants a Word/PDF/slide deliverable, build it from `profile.md` +
`figures/` following the user's document conventions (flextable +
officer/Quarto); that part is project work, not this skill.

## The unified 15-column schema

Both cleaners emit the same shape, so GHO and SDG rows bind directly:

```
source id indicator location iso3 location_name year value value_num
low high series dim1 dim2 dim3
```

- `value` is raw character (preserves SDG entries like `"<0.1"`);
  `value_num` is the numeric coercion (NA where coercion fails).
- `series` is SDG-only (series code, e.g. `SH_DYN_MORT`); `dim1`–`dim3`
  are GHO-only (e.g. sex codes).

## Gotchas — read before debugging

- **GHO sex codes are prefixed**: `SEX_BTSX` / `SEX_MLE` / `SEX_FMLE`.
  A bare `BTSX` silently returns 0 rows (HTTP 200, empty). The scripts
  auto-prefix bare `BTSX`/`MLE`/`FMLE`, but other dimensions get no such
  fix — list valid values with `DSIR::gho_dimensions(code, "Dim1")`.
- **Empty result ≠ error.** Zero rows can mean wrong code, wrong dim
  value, or an unreachable/flaky API (unstats.un.org occasionally times
  out past DSIR's 20 s limit — retrying once is reasonable).
- **Duplicated years = mixed strata.** If `aarr_summary.csv` has an
  `aarr_note` about duplicated years, the group still mixes strata the
  schema can't see (SDG series carry sub-dimensions like sex/age that
  `sdg_clean()` does not extract into columns). Filter the fetched CSV
  down to one stratum (e.g. one `series`, or subset by inspecting the
  raw `sdg_data()` output) before trusting that AARR.
- **AARR sign convention**: positive = declining (progress for
  mortality-type indicators); multiply by 100 for the percent printed
  in published tables. For "higher is better" indicators (coverage,
  life expectancy) a *negative* AARR means improvement.
- **Areas are ISO3** for both APIs (`m49` conversion is handled
  internally for SDG). Regional ISO3 vectors ship with DSIR:
  `wpro_cty`, `searo_cty`, `afro_cty`, `amro_cty`, `euro_cty`,
  `emro_cty`, `pic_cty`.
- **Charts with vertical zigzags** mean multiple observations per year
  per stratum; `country_profile.R` switches to points + annual-mean
  line automatically and says so in the caption, but the real fix is
  filtering to one stratum before profiling.
