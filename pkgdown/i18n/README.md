# Website translations

The English site remains at the existing URL. `zh/` and `fr/` contain the
homepage, tutorial index and three tutorials. Function references, the full
technical overview and release notes remain in English. Language menus on
those pages explicitly link to the Chinese or French tutorial index.

Run from the package root with the current DSIR package installed:

```r
source("pkgdown/build-site.R")
build_multilingual_site()
source("pkgdown/validate-site.R")
validate_multilingual_site()
```

The scripts use pkgdown's website dependencies; they add no package Imports.
Pandoc is required. GitHub Actions supplies it with `setup-pandoc`. Locally,
use the Pandoc installation bundled with RStudio, locating it on your machine
and setting `RSTUDIO_PANDOC` for that session if it is not discovered.
The configured web fonts may require an internet connection on the first build.
On Linux, install `zh_CN.UTF-8` and `fr_FR.UTF-8` with `locale-gen` first.
The workflow does this automatically; the renderer sets the message locale
and the language inherited by article subprocesses. Merely setting `LANGUAGE`
under a C message locale does not translate the generated interface.

## Maintaining content

- `home.yml` translates the existing homepage without duplicating its layout.
- `navigation.yml` holds navigation labels and document language metadata.
- The `zh/` and `fr/` Markdown files contain translated tutorial prose.
  Each `<!-- chunk:N -->` inserts the complete Nth fenced code block from
  the corresponding English vignette. Every source block must appear once
  and in order. Do not translate API identifiers, code comments, or data codes.
- The original code, including chart labels and results, is shared. Changing
  the website language does not translate upstream data labels.
- `sources.yml` records SHA-256 hashes of the English sources, with line
  endings normalized. A source change stops the website build. Review both
  translations, then update the hash with `source_hash("path/to/source")`.
  Never refresh hashes merely to bypass review.

Use the same terms throughout: indicator / 指标 / indicateur;
dimension / 维度 / dimension; stratum / 分层 / strate;
estimate / 估计值 / estimation; uncertainty interval / 不确定性区间 /
intervalle d'incertitude; age standardization / 年龄标准化 /
standardisation sur l'âge. French prose uses OMS and ODD; official service
names and code identifiers retain WHO and SDG.

The build uses temporary input trees, leaving English package documentation
in place. It adds canonical URLs and reciprocal language alternates only for
pages with complete translations. Language switches are static links and work
without a translation service. Each language has a separate search index.
No preference-based automatic redirect is applied.

`validate-site.R` checks generated navigation, internal links and anchors,
assets, document languages, alternate URLs and exact code-chunk reuse.
Live data examples keep their existing opt-in execution guards.
