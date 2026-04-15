#' Set DSIR Flextable Defaults
#'
#' Applies a consistent set of `flextable` formatting defaults for
#' publication-ready tables (booktabs theme, bold headers, modest
#' padding). Pick any font you like — the default `""` leaves the
#' `flextable` default in place so the call is safe on systems where
#' Cambria is not installed.
#'
#' @param font_size Font size in points. Default `12`.
#' @param font_family Font family name. Default `""` keeps the
#'   existing `flextable` default; try `"Cambria"` for the original
#'   DSIR look on Windows.
#' @param font_color Font color. Default `"#333333"`.
#' @param border_color Border color. Default `"black"`.
#' @param padding Numeric vector of length 1 (applied to all sides)
#'   or length 4 (`top`, `bottom`, `left`, `right`).
#'   Default `c(3, 3, 4, 4)`.
#'
#' @return Invisibly returns `NULL`. Called for its side effect of
#'   mutating the `flextable` global defaults via
#'   [flextable::set_flextable_defaults()].
#' @export
#'
#' @examples
#' dsi_flextable_defaults()
dsi_flextable_defaults <- function(font_size = 12,
                                   font_family = "",
                                   font_color = "#333333",
                                   border_color = "black",
                                   padding = c(3, 3, 4, 4)) {
  if (length(padding) == 1) padding <- rep(padding, 4)

  args <- list(
    font.size      = font_size,
    font.color     = font_color,
    border.color   = border_color,
    padding.top    = padding[1],
    padding.bottom = padding[2],
    padding.left   = padding[3],
    padding.right  = padding[4],
    theme_fun      = function(x) flextable::theme_booktabs(x, bold_header = TRUE)
  )
  if (nzchar(font_family)) args$font.family <- font_family

  do.call(flextable::set_flextable_defaults, args)
  invisible(NULL)
}
