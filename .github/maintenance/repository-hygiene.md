# Public repository hygiene

The GitHub source tree is public independently of R package builds.
`.Rbuildignore` controls package contents; it does not hide tracked files
on GitHub. `.gitignore` prevents accidental addition of untracked files;
it does not remove files already tracked.

## Where maintained material belongs

| Material | Location |
| --- | --- |
| Package implementation and regression tests | `R/`, `tests/testthat/` |
| Reusable scripts that rebuild bundled data | `data-raw/` |
| User documentation and examples | `README.md`, `man/`, `vignettes/` |
| Lasting development decisions | `.github/maintenance/design-notes.md` |
| Shared agent development rules | `AGENTS.md`; `CLAUDE.md` points there |
| Distributable country-profile skills | `.claude/skills/`, `.github/skills/` |
| Local probes, handoffs, raw AI conversations | Untracked local files |
| Generated pkgdown website | Ignored `docs/`; published by the existing workflow |

Maintenance documents live here because `docs/` is generated website
output. `.github/` is already excluded from package builds.

## 2026-10-04 cleanup record

Audited the tracked tree at `634c2bf` (DSIR 0.10.0).
The following files were temporary development artifacts:

| Removed path | Finding and retained value |
| --- | --- |
| `conversation-export.md` | Raw AI GHO design discussion with tool/thinking markup and a copied source preview. Useful conclusions are reconciled in the design notes; optimization and shared HTTP policy are already implemented. |
| `development_proposals.md` | Old 0.7.1 brainstorming with local file links and hypothetical code. Implemented, declined, and deferred ideas are retained in the design notes. |
| `scratch/probe_m49.R` | One-time data-column exploration; uses the obsolete `un_m49` name. Current identifier behavior is covered by `test-who_countries.R`, `test-iso3-to-m49.R`, and `test-m49_to_iso3.R`. |
| `scratch/probe_sdg.R` | One-time live API response exploration. Current contracts are covered by the SDG indicator, cleaning, metadata, and pagination tests. |
| `scratch/sanity_3b1.R` | Printed multi-series coverage for a live example. The `3.b.1` example remains in README and the main vignette; formal coverage tests protect behavior. |
| `scratch/sanity_check.R` | Manual search/coverage checks that print results. Formal `test-sdg-indicators.R` and `test-sdg-coverage.R` already cover these behaviors. |
| `scratch/sanity_iso3_m49.R` | Manual code-conversion and live-fetch checks. Formal conversion and area-resolution tests cover these behaviors. |
| `scratch/sanity_year_filter.R` | One-time live timing/year-range probes. Formal `test-sdg-year-filter.R` remains; its live tests keep their existing guards. |

No package build, test, vignette, workflow, or distributable skill depends
on these scripts. They are not reusable data preparation or missing
regression fixtures, so they were not moved into `data-raw/` or `tests/`.
The review also removed outdated session status and machine-specific
paths from the two agent guidance files while preserving lasting rules.

Content review and a scan for common credentials/private-key patterns
found no material requiring destructive history removal. This was a
current-tree cleanup. Existing commits and release tags were retained;
the removed originals remain retrievable from the pre-cleanup commit.

## Before publishing future changes

- Review the staged file list and diff. Keep raw conversations, credentials,
  machine paths, generated check output, and local probes out of commits.
- Turn a useful discovery into a maintained test, example, or concise design
  note before dropping the scratch copy.
- Run existing tests and the configured R CMD check after material edits.
  State the check environment and any skipped live API tests.
- If actual secrets are found, stop publication, arrange revocation/rotation,
  and assess whether coordinated history removal is necessary.
