#' DSIR ggplot2 theme — WHO publication-style
#'
#' A clean, modern theme tuned for WHO and global-health publications.
#' Removes the panel border, retains only horizontal grid lines, and uses
#' a muted text colour so that the data — not the chart chrome — is the
#' visual focus.
#'
#' @param base_size Base font size in points. Default `12`.
#' @param base_family Base font family. Default `""` (system default).
#'   Set to `"sans"`, `"Arial"`, `"Helvetica"`, or `"Calibri"` for a
#'   specific look. Empty default keeps the package portable on CRAN's
#'   Linux check machines, where Calibri is unavailable.
#' @param accent Accent colour used for axis lines and as a default for
#'   highlight elements. Default `"#0093D5"` (WHO blue). Pass any colour
#'   string.
#' @param grid_color Colour of the (horizontal) major grid. Default
#'   `"grey92"` — a very light grey, close to bbplot and OECD style.
#' @param legend_position Position of the legend. Default `"bottom"`.
#'   Pass `"none"`, `"top"`, `"right"`, or a numeric vector `c(x, y)`.
#'
#' @return A `ggplot2` theme object.
#'
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(wt, mpg, color = factor(cyl))) +
#'   geom_point(size = 3) +
#'   theme_dsi() +
#'   labs(title = "Fuel efficiency by weight",
#'        subtitle = "From the mtcars dataset",
#'        x = "Weight (1000 lbs)", y = "Miles per gallon",
#'        color = "Cylinders")
#'
#' @export
theme_dsi <- function(base_size = 12,
                      base_family = "",
                      accent = "#0093D5",
                      grid_color = "grey92",
                      legend_position = "bottom") {
  
  ggplot2::theme_minimal(
    base_size   = base_size,
    base_family = base_family
  ) +
    ggplot2::theme(
      # ── text ────────────────────────────────────────────────────
      text         = ggplot2::element_text(color = "grey20"),
      axis.text    = ggplot2::element_text(color = "grey30",
                                           size = base_size * 0.85),
      axis.title   = ggplot2::element_text(color = "grey20",
                                           face = "bold",
                                           size = base_size * 0.9),
      axis.title.x = ggplot2::element_text(margin = ggplot2::margin(t = 10)),
      axis.title.y = ggplot2::element_text(margin = ggplot2::margin(r = 10)),
      
      # ── title block ─────────────────────────────────────────────
      plot.title       = ggplot2::element_text(face   = "bold",
                                               size   = base_size * 1.4,
                                               color  = "grey10",
                                               margin = ggplot2::margin(b = 4)),
      plot.subtitle    = ggplot2::element_text(size   = base_size * 1.0,
                                               color  = "grey40",
                                               margin = ggplot2::margin(b = 12)),
      plot.caption     = ggplot2::element_text(size   = base_size * 0.75,
                                               color  = "grey50",
                                               hjust  = 1,
                                               margin = ggplot2::margin(t = 12)),
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      
      # ── axes (line, no border) ─────────────────────────────────
      panel.border = ggplot2::element_blank(),
      axis.line.x  = ggplot2::element_line(color = accent,
                                           linewidth = 0.3),
      axis.line.y  = ggplot2::element_line(color = accent,
                                           linewidth = 0.3),
      axis.ticks   = ggplot2::element_line(color = accent,
                                           linewidth = 0.3),
      axis.ticks.length = grid::unit(3, "pt"),
      
      # ── grid ───────────────────────────────────────────────────
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(color = grid_color,
                                                 linewidth = 0.3),
      panel.grid.minor   = ggplot2::element_blank(),
      
      # ── legend ─────────────────────────────────────────────────
      legend.position  = legend_position,
      legend.title     = ggplot2::element_text(face = "bold",
                                               size = base_size * 0.85),
      legend.text      = ggplot2::element_text(size = base_size * 0.85),
      legend.key.size  = grid::unit(12, "pt"),
      legend.margin    = ggplot2::margin(t = 6),
      
      # ── strip (for facet_wrap) ─────────────────────────────────
      strip.text       = ggplot2::element_text(face = "bold",
                                               size = base_size * 0.9,
                                               color = "grey20",
                                               margin = ggplot2::margin(t = 4, b = 4)),
      strip.background = ggplot2::element_blank(),
      
      # ── plot area ──────────────────────────────────────────────
      plot.background  = ggplot2::element_blank(),
      panel.background = ggplot2::element_blank(),
      plot.margin      = ggplot2::margin(t = 12, r = 16, b = 12, l = 12)
    )
}