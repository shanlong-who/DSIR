#' Continuous Scales for DSIR Bar / Column Charts
#'
#' Thin wrappers around [ggplot2::scale_y_continuous()] and
#' [ggplot2::scale_x_continuous()] that remove the default lower expansion
#' so that columns sit flush with the axis — the convention for WHO and
#' most publication-style bar charts. The upper expansion is preserved at
#' 5% so the tallest column has breathing room above (or to the right of) it.
#'
#' Use `scale_y_dsi_col()` for vertical bars (`geom_col()` / `geom_bar()`)
#' and `scale_x_dsi_col()` when bars are horizontal (via `coord_flip()` or
#' `geom_col(orientation = "y")`).
#'
#' Pass any other `scale_*_continuous()` argument
#' (`labels`, `breaks`, `limits`, ...) through `...`.
#'
#' @param ... Arguments forwarded to the underlying
#'   [ggplot2::scale_y_continuous()] / [ggplot2::scale_x_continuous()].
#'
#' @return A `ggplot2` Scale object, to be added to a plot with `+`.
#'
#' @examples
#' library(ggplot2)
#'
#' # Vertical bars
#' ggplot(mtcars, aes(factor(cyl))) +
#'   geom_bar(fill = "#0093D5") +
#'   scale_y_dsi_col() +
#'   theme_dsi()
#'
#' @name scale_dsi_col
NULL

#' @rdname scale_dsi_col
#' @export
scale_y_dsi_col <- function(...) {
  ggplot2::scale_y_continuous(
    expand = ggplot2::expansion(mult = c(0, 0.05)),
    ...
  )
}

#' @rdname scale_dsi_col
#' @export
scale_x_dsi_col <- function(...) {
  ggplot2::scale_x_continuous(
    expand = ggplot2::expansion(mult = c(0, 0.05)),
    ...
  )
}
