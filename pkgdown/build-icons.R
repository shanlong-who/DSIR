# Rebuild committed brand exports from the two approved source images.
# Run from the package root: Rscript pkgdown/build-icons.R
library(magick)
library(jsonlite)

build_icons <- function(root = ".") {
  brand.dir <- file.path(root, "pkgdown", "brand")
  favicon.dir <- file.path(root, "pkgdown", "favicon")
  figure.dir <- file.path(root, "man", "figures")
  hex <- image_read(file.path(brand.dir, "logo-hex.png"))
  cat <- image_trim(image_read(file.path(brand.dir, "icon-cat.png")))

  # The complete badge remains the README, homepage and social-sharing logo.
  logo <- image_strip(image_resize(hex, "768x768"))
  image_write(logo, file.path(figure.dir, "logo.png"), format = "png", depth = 8)

  icon_frame <- function(size, fill = 0.94, background = "none") {
    edge <- round(size * fill)
    icon <- image_resize(cat, paste0(edge, "x", edge))
    icon <- image_extent(icon, paste0(size, "x", size),
                         gravity = "center", color = "none")
    if (background != "none") {
      icon <- image_background(icon, background, flatten = TRUE)
    }
    image_strip(icon)
  }

  image_write(icon_frame(96), file.path(favicon.dir, "favicon-96x96.png"), depth = 8)

  # Opaque cream backgrounds give mobile shortcuts a predictable appearance.
  for (size in c(180, 192, 512)) {
    name <- if (size == 180) "apple-touch-icon.png" else
      paste0("web-app-manifest-", size, "x", size, ".png")
    image_write(icon_frame(size, fill = 0.82, background = "#F6EFDF"),
                file.path(favicon.dir, name), depth = 8)
  }
  manifest <- list(
    name = "DSIR \u2014 Data Science Infrastructure for Global Health",
    short_name = "DSIR",
    icons = lapply(c(192, 512), function(size) list(
      src = paste0("web-app-manifest-", size, "x", size, ".png"),
      sizes = paste0(size, "x", size), type = "image/png", purpose = "any")),
    theme_color = "#ffffff", background_color = "#F6EFDF", display = "standalone"
  )
  write_json(manifest, file.path(favicon.dir, "site.webmanifest"),
             pretty = TRUE, auto_unbox = TRUE)
  message("Built the PNG hexagonal package logo and sleeping-cat favicon set.")
  invisible(favicon.dir)
}

if (sys.nframe() == 0L) build_icons()
