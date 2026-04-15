#' DSIR ggplot2 Theme
#'
#' A clean, publication-ready `ggplot2` theme based on
#' [ggplot2::theme_minimal()] with a consistent color accent and
#' bordered panels.
#'
#' @details
#' The default `base_family = ""` uses the graphics device's default
#' font so the theme works on any system (including CRAN's Linux test
#' machines). For the original DSIR look, pass
#' `base_family = "Cambria"` on a system where that font is
#' installed and registered with R (see [grDevices::postscriptFonts()]
#' or the `systemfonts` package).
#'
#' @param base_size Base font size in points. Default `12`.
#' @param base_family Base font family. Default `""` (device default).
#' @param color Accent color for text and panel borders.
#'   Default `"steelblue"`.
#' @param grid_color Color for major grid lines. Default `"grey85"`.
#'
#' @return A `ggplot2` theme object that can be added to a plot with
#'   `+`.
#' @export
#'
#' @examples
#' library(ggplot2)
#' ggplot(women, aes(height, weight)) +
#'   geom_point(color = "steelblue") +
#'   theme_dsi()
theme_dsi <- function(base_size = 12, base_family = "",
                      color = "steelblue", grid_color = "grey85") {
  ggplot2::theme_minimal(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      text             = ggplot2::element_text(color = color),
      axis.text        = ggplot2::element_text(color = color),
      axis.title       = ggplot2::element_text(face = "bold"),
      plot.title       = ggplot2::element_text(face = "bold", size = base_size * 1.2),
      plot.subtitle    = ggplot2::element_text(size = base_size * 0.9, color = "grey40"),
      plot.caption     = ggplot2::element_text(size = base_size * 0.75, color = "grey50",
                                               hjust = 1),
      panel.border     = ggplot2::element_rect(color = color, fill = NA, linewidth = 0.6),
      panel.grid.major = ggplot2::element_line(color = grid_color, linewidth = 0.3),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position  = "bottom",
      legend.title     = ggplot2::element_text(face = "bold"),
      plot.margin      = ggplot2::margin(10, 10, 10, 10)
    )
}
