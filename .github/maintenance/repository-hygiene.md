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
| Shared agent development rules | `AGENTS.md` |
| Local probes, handoffs, raw AI conversations | Untracked local files |
| Generated pkgdown website | Ignored `docs/`; published by the existing workflow |

Maintenance documents live here because `docs/` is generated website
output. `.github/` is already excluded from package builds.

Keep assistant-specific skill bundles, duplicate agent guidance, local test
data, generated check output and one-time analytical exports outside the
maintained source tree. Retain Git metadata, CI workflows, data preparation,
website sources and shared working rules needed for package maintenance.
The DSIR badge and cat-only icons use PNG sources and PNG exports only.

## Before publishing future changes

- Review the staged file list and diff. Keep raw conversations, credentials,
  machine paths, generated check output, and local probes out of commits.
- Turn a useful discovery into a maintained test, example, or concise design
  note before dropping the scratch copy.
- Run existing tests and the configured R CMD check after material edits.
  State the check environment and any skipped live API tests.
- If actual secrets are found, stop publication, arrange revocation/rotation,
  and assess whether coordinated history removal is necessary.
