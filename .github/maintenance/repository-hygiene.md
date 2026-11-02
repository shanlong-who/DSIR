# Repository layout and maintenance

DSIR uses the standard R package layout. Keep the package source on `main`,
the generated website on `gh-pages`, and local development output untracked.
The current version and runtime dependencies are defined in `DESCRIPTION`;
released changes are described in `NEWS.md`.

The GitHub source tree is public independently of R package builds.
`.Rbuildignore` controls package contents; it does not hide tracked files
on GitHub. `.gitignore` prevents accidental addition of untracked files;
it does not remove files already tracked.

## Where maintained material belongs

| Location | Responsibility |
| --- | --- |
| `R/` | Package functions, internal adapters, S3 methods and roxygen help sources. |
| `tests/testthat/` | Regression tests and reusable offline fixtures. Live API tests require explicit opt-in. |
| `data/` | Public bundled datasets, including country metadata and the three discovery catalogs. |
| `data-raw/` | Reusable data rebuild scripts and the explicitly invoked WHO schema probe described below. |
| `inst/` | Citation, spelling dictionary and the internal legacy catalog file in `extdata/`. |
| `man/`, `NAMESPACE` | Generated function documentation and registrations. Regenerate from roxygen comments. |
| `README.md` | Complete technical introduction, installation instructions and examples. |
| `vignettes/` | Package tutorials; `articles/technical-overview.Rmd` is a website-only wrapper around the README. |
| `pkgdown/`, `_pkgdown.yml` | Website sources, navigation, translations, branding and build/validation scripts. |
| `demo/` | The registered theme demonstration. |
| `.github/workflows/`, `.github/scripts/` | Package checks, website deployment and separate live API health checks. |
| `.github/maintenance/` | Lasting design decisions, repository guidance and API health documentation. |
| `cran-comments.md`, `CRAN-SUBMISSION` | The last CRAN submission record, which may precede the version on `main`. |
| `docs/` | Ignored generated website output; published to `gh-pages` by the website workflow. |
| `scratch/` | Ignored local investigations, check results and examples; never a package or website source. |
| Local `AGENTS.md`, RStudio state | Ignored working preferences and editor state. |

Maintenance documents live here because `docs/` is generated website
output. `.github/` is already excluded from package builds.

Keep assistant-specific skill bundles, duplicate agent guidance, local test
data, generated check output and one-time analytical exports outside the
maintained source tree. Retain Git metadata, CI workflows, data preparation,
website sources and local working rules needed for package maintenance.
The DSIR badge and cat-only icons use PNG sources and PNG exports only.

## Package modules

Keep `R/` flat and group related functions by file. The main analysis path is
acquisition, cleaning with metadata, then analysis or presentation. Offline
catalogs support discovery; they do not establish observation availability.

| Responsibility | Main source files |
| --- | --- |
| Public GHO, GHE and SDG interfaces | `gho.R`, `ghe.R`, `sdg.R` and the `sdg_*.R` helpers. |
| WHO backend selection and adapters | `who_auto.R`, `who_gho.R`, `who_legacy.R`, `who_backend.R`. |
| Shared HTTP policy and acquisition records | `http.R`, `retrieval_metadata.R`. |
| Typed cleaning and cleaning records | `clean_schema.R`, `clean_metadata.R`, `clean_result.R`, `bind_indicators.R`. |
| Data objects, print/summary and transformation rules | `dsir_data.R`, `dsir_data_methods.R`. |
| Indicator plots and maps | `dsir_plot.R`, `dsir_map.R`, `map_boundaries.R`. |
| Public discovery catalogs and bundled data help | `catalogs.R`, `data.R`. |
| Saved extracts and offline comparison | `snapshot.R`, `data_snapshot.R`, `compare_snapshots.R`, `last_updated.R`. |
| Analytical and presentation helpers | The individual statistical, country-code, theme, scale and table files. |

The similarly named metadata files serve different purposes:
`retrieval_metadata.R` records acquisition; `clean_metadata.R` builds optional
columns; `clean_result.R` records cleaning; `sdg_metadata.R` retrieves SDG code
lists; `dsir_data.R` exposes metadata and tracks the current object's state.
The behavioral contracts are recorded in [design notes](design-notes.md).

## Documentation sources

| Output or task | Edit or run |
| --- | --- |
| GitHub README and website Technical Overview | Edit `README.md`; the overview wrapper reads it during the build. |
| Website homepage | Edit `pkgdown/index.md`; review the Chinese and French text in `pkgdown/i18n/home.yml`. |
| Package and website tutorials | Edit the corresponding `vignettes/*.Rmd`; review translated prose where present. |
| Translated pages and navigation | Follow [translation maintenance](../../pkgdown/i18n/README.md), including source hashes and shared example chunks. |
| Function help and website reference | Edit roxygen comments in `R/`, then run `devtools::document()`. Update `_pkgdown.yml` for public API changes. |
| Release history | Edit `NEWS.md`; historical entries keep their original version context. |
| Brand images and icons | Follow the [brand asset guide](../../pkgdown/brand/README.md). |

Do not edit generated HTML or `gh-pages` as the normal way to update content.
Use a GitHub URL when linking from the README to maintenance files that are
not published as website pages.

## Data preparation

Run these scripts explicitly from the package root when the corresponding
bundled data need to change. Do not run live refreshes during routine builds.

| Script | Maintained output or purpose |
| --- | --- |
| `data-raw/who_countries.R` | Rebuild `who_countries` and all regional country vectors in `data/`. |
| `data-raw/who_std_pop.R` | Rebuild the documented WHO standard population in `data/`. |
| `data-raw/catalogs.R` | Rebuild public `gho_catalog`, `ghe_catalog` and `sdg_catalog`, retaining source and version metadata. |
| `data-raw/gho_indicators.R` | Refresh `inst/extdata/gho-indicators.rds`, the internal legacy discovery/label fallback. |
| `data-raw/verify_who_backend.R` | Investigate live WHO schemas and save temporary evidence; it does not rebuild bundled datasets. |

The public catalogs and internal legacy fallback have different contracts.
Preserve their original retrieval dates and only replace snapshots after a
successful, validated refresh. WHO boundary files stay outside the package;
`dsir_map()` downloads requested countries into its explicit local cache.

## Website publication

Run the build and validation from the package root with the current DSIR
version installed:

```r
source("pkgdown/build-site.R")
build_multilingual_site()
source("pkgdown/validate-site.R")
validate_multilingual_site()
```

`pkgdown/site-sources.R` stages only the documented package directories and
root files in a temporary source tree. This prevents pkgdown's automatic
Markdown discovery from publishing ignored local development documents.
Both the builder and validator reject `AGENTS`, `CLAUDE`,
`conversation-export` and `development_proposals` HTML/Markdown files,
including files inside language directories.

The workflow builds all languages before deployment. Its `clean: true`
setting makes `gh-pages` follow the validated complete build, removing
obsolete pages and assets. Keep required website files in the maintained
sources or build steps; do not store unrelated files on `gh-pages`.
This removes files from the current website, not from Git history.

## Local working files

Keep `TMPDIR`, `TMP` and `TEMP` outside the package source tree during builds.
An in-tree temporary directory can make a package build copy its own working
files recursively before exclusions are applied, producing oversized trees
and paths that cannot be synchronized. Use a system temporary directory for
the build and retain only the resulting reports or artifacts in `scratch/`.

Before removing a local directory, verify its resolved path and check
`git worktree list`. An ignored directory can still contain a registered
worktree, a useful analytical example or a boundary cache. Remove registered
worktrees with Git after checking their changes; do not treat the whole
`scratch/` directory as disposable. Remove completed remote branches only
after confirming their work was merged; a squash merge may not make the
original branch head an ancestor of `main`.

## Before publishing future changes

- Review the staged file list and diff. Keep raw conversations, credentials,
  machine paths, generated check output, and local probes out of commits.
- Turn a useful discovery into a maintained test, example, or concise design
  note before dropping the scratch copy.
- Run existing tests and the configured R CMD check after material edits.
  State the check environment and any skipped live API tests.
- If actual secrets are found, stop publication, arrange revocation/rotation,
  and assess whether coordinated history removal is necessary.
