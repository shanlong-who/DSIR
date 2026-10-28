# DSIR brand assets

Use `logo-hex.png` for the complete DSIR identity: README, website homepages,
presentations and other larger placements. Use `icon-cat.png` for browser tabs,
bookmarks, compact controls and mobile shortcuts. Both approved source images
are 1254 x 1254 transparent PNGs; the outer background and Gemini watermark
are absent from the hexagonal badge.

The sources were created with the built-in image generation tool and approved
for use. R removes near-transparent background residue and makes the interior
opaque before export. The high-resolution badge is a rendered interpretation
of the original, not a pixel-identical enlargement.

## Rebuild

From the repository root, run `Rscript pkgdown/build-icons.R`. This uses the
existing maintenance packages `magick` and `jsonlite`; it adds no
package runtime dependencies and does not call a remote image service.

- `man/figures/logo.png`: transparent 768-pixel package logo.
- `pkgdown/favicon/favicon-96x96.png`: transparent browser icon.
- Mobile icons: the cat with extra margins on a cream background. The manifest
  uses `purpose: any`; these exports do not claim maskable safe-zone support.

Both identities use PNG only. pkgdown copies the favicon set during the
existing multilingual site build, which explicitly links the PNG browser icon.
Do not regenerate it with `pkgdown::build_favicons(overwrite = TRUE)`, which
would derive the browser icons from the hexagonal package logo instead.

The pkgdown sitrep expects `favicon.ico` and can report outdated favicons for
this PNG-only set. Run `Rscript pkgdown/validate-site.R` after building;
it checks the PNG icon links and their actual files.

## Image prompts

The cat was generated from the original logo with this design brief:
"One simplified sleeping orange tabby icon; preserve the curled pose and the
muted orange, cream and deep navy palette; bold clean outline, closed eyes,
tucked paws and curled tail; remove all text, hexagonal frame, blanket,
background network and decorative textures; true transparent background."

The badge was generated from the original logo with this design brief:
"Retain the complete six-sided DSIR badge, sleeping cat, cream blanket, blue
network interior, DSIR lettering and thin navy/gold borders; remove everything
outside the outer hexagon, including the bottom-right Gemini sparkle; use a
true transparent background with no watermark."
