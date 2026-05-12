#' DSIR ggplot2 theme — WHO publication-style
#'
#' A clean, modern theme tuned for WHO and global-health publications.
#' Removes the panel border, draws light grid lines, and uses a muted
#' text colour so that the data — not the chart chrome — is the visual
#' focus. The `grid` argument controls which direction(s) the grid
#' lines run, so the theme works equally well for vertical bars,
#' horizontal bars (via `coord_flip()`), scatter plots, and line charts.
#'
#' @param base_size Base font size in points. Default `12`.
#' @param base_family Base font family. Default `""` (system default).
#'   Set to `"sans"`, `"Arial"`, `"Helvetica"`, or `"Calibri"` for a
#'   specific look. Empty default keeps the package portable on CRAN's
#'   Linux check machines, where Calibri is unavailable.
#' @param accent Accent colour used for axis lines and as a default for
#'   highlight elements. Default `"#0093D5"` (WHO blue). Pass any colour
#'   string.
#' @param grid_color Colour of the major grid. Default
#'   `"grey92"` — a very light grey, close to bbplot and OECD style.
#' @param grid Which direction(s) to draw major grid lines. One of
#'   `"both"` (default — draws both horizontal and vertical, works
#'   correctly under `coord_flip()`), `"y"` (only horizontal grid lines,
#'   the look used in DSIR <= 0.5.x), `"x"` (only vertical grid lines),
#'   or `"none"`.
#' @param legend_position Position of the legend. Default `"bottom"`.
#'   Pass `"none"`, `"top"`, `"right"`, or a numeric vector `c(x, y)`.
#'
#' @return A `ggplot2` theme object.
#'
#' @seealso [theme_dsi_facet()] for a sibling theme tuned for faceted plots.
#'
#' @examples
#' library(ggplot2)
#'
#' # Default — grid in both directions, works under coord_flip()
#' ggplot(mtcars, aes(wt, mpg, color = factor(cyl))) +
#'   geom_point(size = 3) +
#'   theme_dsi() +
#'   labs(title = "Fuel efficiency by weight",
#'        x = "Weight (1000 lbs)", y = "Miles per gallon",
#'        color = "Cylinders")
#'
#' # Minimal look — only horizontal grid lines
#' ggplot(mtcars, aes(wt, mpg)) +
#'   geom_point(size = 3, color = "#0093D5") +
#'   theme_dsi(grid = "y") +
#'   labs(x = "Weight (1000 lbs)", y = "Miles per gallon")
#'
#' @export
theme_dsi <- function(base_size = 12,
                      base_family = "",
                      accent = "#0093D5",
                      grid_color = "grey92",
                      grid = c("both", "x", "y", "none"),
                      legend_position = "bottom") {

  grid <- match.arg(grid)

  .theme_dsi_base(base_size       = base_size,
                  base_family     = base_family,
                  accent          = accent,
                  legend_position = legend_position) +
    ggplot2::theme(
      # ── axes (line, no border) ─────────────────────────────────
      panel.border = ggplot2::element_blank(),
      axis.line.x  = ggplot2::element_line(color = accent,
                                           linewidth = 0.3),
      axis.line.y  = ggplot2::element_line(color = accent,
                                           linewidth = 0.3),
      axis.ticks   = ggplot2::element_line(color = accent,
                                           linewidth = 0.3),

      # ── grid ───────────────────────────────────────────────────
      panel.grid.major.x = if (grid %in% c("both", "x")) {
        ggplot2::element_line(color = grid_color, linewidth = 0.3)
      } else {
        ggplot2::element_blank()
      },
      panel.grid.major.y = if (grid %in% c("both", "y")) {
        ggplot2::element_line(color = grid_color, linewidth = 0.3)
      } else {
        ggplot2::element_blank()
      },

      # ── strip (for facet_wrap) ─────────────────────────────────
      strip.text       = ggplot2::element_text(face = "bold",
                                               size = base_size * 0.9,
                                               color = "grey20",
                                               margin = ggplot2::margin(t = 4, b = 4)),
      strip.background = ggplot2::element_blank()
    )
}


#' DSIR ggplot2 theme for faceted plots
#'
#' A sibling of [theme_dsi()] tuned for faceted plots. Where `theme_dsi()`
#' uses half-frame axis lines and only horizontal grid lines — a look that
#' suits a single panel — repeating those across every facet looks heavy
#' and the panels run together. `theme_dsi_facet()` replaces the axis
#' lines with a light panel border, draws grid lines on both axes, gives
#' the strip a soft background, and inserts whitespace between panels.
#'
#' Use `theme_dsi()` for single-panel plots and `theme_dsi_facet()` for
#' plots with `facet_wrap()` or `facet_grid()`. Shared elements (text
#' styles, title block, legend, plot margins) match `theme_dsi()` exactly,
#' so the two themes feel like the same family.
#'
#' @param base_size Base font size in points. Default `12`.
#' @param base_family Base font family. Default `""` (system default).
#'   Set to `"sans"`, `"Arial"`, `"Helvetica"`, or `"Calibri"` for a
#'   specific look. Empty default keeps the package portable on CRAN's
#'   Linux check machines, where Calibri is unavailable.
#' @param accent Accent colour, kept for parity with [theme_dsi()] so
#'   that the argument set is interchangeable. Not currently used in the
#'   facet variant — the panel border replaces the accent-coloured axis
#'   lines. Default `"#0093D5"` (WHO blue).
#' @param grid_color Colour of the major grid (both axes). Default
#'   `"grey92"`.
#' @param strip_fill Background fill colour for facet strips. Default
#'   `"grey95"` — a light neutral grey. Avoid blues, which clash with
#'   the WHO-blue `accent`.
#' @param strip_color Text colour inside facet strips. Default `"grey20"`.
#' @param grid Which direction(s) to draw major grid lines. One of
#'   `"both"` (default — both horizontal and vertical), `"y"` (only
#'   horizontal), `"x"` (only vertical), or `"none"`. Matches the
#'   identical argument on [theme_dsi()] so the two themes can be
#'   swapped without changing other settings.
#' @param legend_position Position of the legend. Default `"bottom"`.
#'   Pass `"none"`, `"top"`, `"right"`, or a numeric vector `c(x, y)`.
#'
#' @return A `ggplot2` theme object.
#'
#' @seealso [theme_dsi()] for the single-panel sibling.
#'
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(wt, mpg)) +
#'   geom_point(size = 2, color = "#0093D5") +
#'   facet_wrap(~ cyl, labeller = label_both) +
#'   theme_dsi_facet() +
#'   labs(title = "Fuel efficiency by cylinder count",
#'        x = "Weight (1000 lbs)", y = "Miles per gallon")
#'
#' @export
theme_dsi_facet <- function(base_size = 12,
                            base_family = "",
                            accent = "#0093D5",
                            grid_color = "grey92",
                            strip_fill = "grey95",
                            strip_color = "grey20",
                            grid = c("both", "x", "y", "none"), 
                            legend_position = "bottom") {
  grid <- match.arg(grid)

  .theme_dsi_base(base_size       = base_size,
                  base_family     = base_family,
                  accent          = accent,
                  legend_position = legend_position) +
    ggplot2::theme(
      # ── panel border replaces axis lines ───────────────────────
      panel.border = ggplot2::element_rect(color = "grey80",
                                           fill = NA,
                                           linewidth = 0.4),
      axis.line    = ggplot2::element_blank(),
      axis.ticks   = ggplot2::element_line(color = "grey60",
                                           linewidth = 0.3),

      # ── grid (configurable; default "both" matches facet conventions) ──
      panel.grid.major.x = if (grid %in% c("both", "x")) {
        ggplot2::element_line(color = grid_color, linewidth = 0.3)
      } else {
        ggplot2::element_blank()
      },
      panel.grid.major.y = if (grid %in% c("both", "y")) {
        ggplot2::element_line(color = grid_color, linewidth = 0.3)
      } else {
        ggplot2::element_blank()
      },

      # ── strip ──────────────────────────────────────────────────
      strip.background = ggplot2::element_rect(fill = strip_fill,
                                               color = NA),
      strip.text       = ggplot2::element_text(face = "bold",
                                               size = base_size * 0.9,
                                               color = strip_color,
                                               margin = ggplot2::margin(t = 6, r = 6,
                                                                        b = 6, l = 6)),

      # ── panel spacing (so panels don't run together) ───────────
      panel.spacing = grid::unit(8, "pt")
    )
}


# Internal helper. Holds every theme element that is identical between
# theme_dsi() and theme_dsi_facet() — text styles, title block, legend,
# plot margins, plot background. The two wrappers then add the elements
# that differ (axis line vs panel border, one-axis vs two-axis grid,
# transparent vs filled strip background).
#
# `accent` is plumbed through for forward compatibility even though this
# helper does not currently use it directly.
.theme_dsi_base <- function(base_size,
                            base_family,
                            accent,
                            legend_position) {

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

      # ── shared axis spacing / minor grid ───────────────────────
      axis.ticks.length = grid::unit(3, "pt"),
      panel.grid.minor  = ggplot2::element_blank(),

      # ── legend ─────────────────────────────────────────────────
      legend.position  = legend_position,
      legend.title     = ggplot2::element_text(face = "bold",
                                               size = base_size * 0.85),
      legend.text      = ggplot2::element_text(size = base_size * 0.85),
      legend.key.size  = grid::unit(12, "pt"),
      legend.margin    = ggplot2::margin(t = 6),

      # ── plot area ──────────────────────────────────────────────
      plot.background  = ggplot2::element_blank(),
      panel.background = ggplot2::element_blank(),
      plot.margin      = ggplot2::margin(t = 12, r = 16, b = 12, l = 12)
    )
}
