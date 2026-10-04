# DSIR design notes

Reviewed against main at `634c2bf` (DSIR 0.10.0) on 2026-10-04.

These notes preserve useful decisions from the former
`conversation-export.md`, `development_proposals.md`, and development
sections of `AGENTS.md` and `CLAUDE.md`. They are a maintenance record,
not a commitment to add features. Current behavior is defined by the source,
tests, help pages, and [release notes](../../NEWS.md).

## Implemented proposals

| Earlier proposal | Current status and evidence |
| --- | --- |
| Download only the requested GHO dimension column | Implemented in 0.8.0: `gho_dimensions()` uses `.gho_build_url(select = dimension)`. See [GHO source](../../R/gho.R) and [dimension tests](../../tests/testthat/test-gho-dimensions.R). |
| Add server-side GHO breakdown filters | Implemented in 0.8.0 with explicit `dim1`, `dim2`, and `dim3` arguments. The generic `filter_extra` sketch was not adopted. See [availability tests](../../tests/testthat/test-gho-availability.R). |
| Keep plotting guidance in a vignette | Implemented in [visualizing indicators](../../vignettes/visualizing-indicators.Rmd): interval ribbons, facets, forest comparisons, dumbbell plots, and progress tracking. No separate forest or dumbbell export was added. |
| Add average annual rate of reduction | Implemented as [`aarr()`](../../R/aarr.R) in 0.8.0. It returns a fraction: the regression method is `1 - exp(slope)`; the endpoint method is `1 - (last / first)^(1 / elapsed_years)`. |
| Share HTTP configuration between fetching and counting | Implemented in 0.9.0 through [`.dsi_request()`](../../R/http.R), used by GHO fetch/count and SDG fetch. Response parsing remains specific to each endpoint. |

## Settled feature boundaries

| Idea | Decision and rationale |
| --- | --- |
| `get_latest()`, `ggdot()` | Declined in the 2026-05-13 development record. Straightforward data selection and chart recipes belong in analysis code. Do not reopen without a user request. |
| `ggbar()`, `ggcol()` | Deferred as thin wrappers around explicit ggplot code; no export is planned. |
| `ggforest()`, `ggdumbbell()` | The 0.8.0 development record chose vignette recipes rather than new exports. |
| `project_indicator()` | A separate export was not adopted. AARR-based projection is documented in examples and the vignette; model choice and assumptions belong in the analysis. |
| `aggregate_regions()` | Not adopted in the 0.8.0 review: aggregation rules depend on the indicator and population weights require continuing maintenance. `who_countries` provides identifiers and regions, not an annual population-weight series. Supply suitable weights and document the aggregation method in each analysis. |
| `gho_indicators(force_refresh = ...)` | Not adopted in the 0.8.0 review. The actual cache defect was fixed: failed/empty catalog fetches are not cached, so the next cleaner call can retry. A successful catalog remains session-cached; refreshing that cache is a separate, unimplemented capability. |
| `who_iso3()`, `standardize_country_names()`, WHO name override vectors | Deferred. Existing `countrycode()` custom matches cover typical needs. Consider a small override vector only if repeated WHO-specific naming needs justify maintenance; no new export is planned. |
| Excess-mortality/ACM event and validation helpers | Deferred until the source calculator and its input-template assumptions are stable. Do not extract project-specific helpers prematurely. |

## Contracts worth preserving

- **Default cleaned schema:** the 15-column order and types are defined in
  [`R/clean_schema.R`](../../R/clean_schema.R). Empty cleaner output has
  these same types. The 0.10.0 optional dimensions and metadata add columns
  without changing that default; `bind_indicators()` preserves extra fields.
- **Values and labels:** preserve raw `value` alongside numeric
  `value_num`. WHO Member State labels come from `who_countries$name_short`.
  GHO additionally resolves its region/world codes; SDG falls back to raw
  `geoAreaName` for non-Member areas. SDG's human indicator label comes
  from observation `seriesDescription` and may be missing.
- **Country codes:** `who_countries$m49_code` is the M49 source, not
  `un_m49`. It uses three-character zero-padded values.
  `m49_to_iso3()` accepts padded and bare forms; aggregates and non-Member
  areas return NA. SDG area resolution rejects mixed ISO3 and M49 input,
  warns and drops unknown ISO3 codes, and errors if none remain.
- **GHO discovery:** supplying `area` without `spatial_type` assumes
  country data and informs the caller. Use `gho_dimensions()` to discover
  actual codes; sex codes include prefixes such as `SEX_BTSX`.
  A missing or invalid requested column can produce an API error, which
  follows the documented fail-soft behavior.
- **Failure shapes:** raw `gho_data()` can return a zero-column empty
  tibble; `gho_clean()` converts empty input to the typed default schema.
  Cleaning may fetch the indicator catalog on its first call.
- **Catalog caching:** cache only successful non-empty results. The
  [cache regressions](../../tests/testthat/test-gho-catalog-cache.R)
  protect recovery after an offline first call.
- **Paging:** GHO follows OData next links. SDG validates page and row
  counts, combines unlike nested columns with `vctrs::vec_rbind()`, and
  applies local filters only after retrieval is complete. Coverage must
  preserve warnings and genuine missing series codes.
- **HTTP and parsing:** keep timeout/retry policy in `R/http.R`.
  Preserve fail-soft handling for request and JSON errors, and interpolate
  external error messages through variables to avoid interpreting braces
  as cli/glue expressions.
- **Package size and portability:** keep vignette-only data manipulation
  packages in Suggests, use portable font defaults, and avoid hidden network
  or population-data dependencies in new analytical helpers.

## Provenance

The earlier proposal document described 0.7.1 and contained conceptual code
and local file links; the conversation export contained a GHO review plus
tool records. The agent files mixed lasting rules with 0.7.0–0.9.0 session
status and machine-specific setup. This review reconciled those records
with the implemented 0.10.0 source rather than treating old suggestions as
open work.

The original text remains available in Git history at
[the pre-cleanup commit](https://github.com/shanlong-who/DSIR/tree/634c2bf).
Historical release notes, package source, tests, data, and releases are
unchanged by this documentation cleanup.
