#' Create a Pie Chart with ggplot2
#'
#' Builds a pie chart from a data frame using one categorical column
#' and one numeric column. Slices are labeled with the category
#' name and percentage share.
#'
#' @param df A data frame.
#' @param .x Column name (string) of the categorical variable used
#'   for the slices.
#' @param .y Column name (string) of the numeric variable used for
#'   the slice values.
#' @param .offset Bar `x` position. Default `1`. Increase (e.g.
#'   `2`) to carve out a donut-chart hole.
#' @param .color Border color between slices. Default `"white"`.
#' @param .legend Logical. Show the legend? Default `FALSE`.
#' @param .label Logical. Draw `"name\n(pct%)"` labels on the
#'   slices? Default `TRUE`.
#' @param .label_size Label text size in mm. Default `3.5`.
#'
#' @return A `ggplot` object.
#' @export
#'
#' @examples
#' df <- data.frame(
#'   category = c("A", "B", "C"),
#'   value = c(40, 35, 25)
#' )
#' ggpie(df, "category", "value")
ggpie <- function(df, .x, .y, .offset = 1, .color = "white",
                  .legend = FALSE, .label = TRUE, .label_size = 3.5) {
  stopifnot(
    is.data.frame(df),
    is.character(.x), length(.x) == 1L, .x %in% names(df),
    is.character(.y), length(.y) == 1L, .y %in% names(df)
  )

  df_plot <- df
  vals <- df_plot[[.y]]
  total <- sum(vals)

  df_plot[[".dsir_perc"]]  <- round(vals / total * 100, 1)
  df_plot[[".dsir_label"]] <- paste0(df_plot[[.x]], "\n(", df_plot[[".dsir_perc"]], "%)")
  df_plot[[".dsir_y_pos"]] <- total - cumsum(vals) + vals / 2

  p <- ggplot2::ggplot(df_plot, ggplot2::aes(
    x = .offset,
    y = .data[[.y]],
    fill = .data[[.x]]
  )) +
    ggplot2::geom_col(color = .color, linewidth = 0.5) +
    ggplot2::coord_polar("y") +
    ggplot2::labs(x = NULL, y = NULL, fill = NULL) +
    ggplot2::theme_void() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold")
    )

  if (.label) {
    p <- p + ggplot2::geom_text(
      ggplot2::aes(
        label = .data[[".dsir_label"]],
        y     = .data[[".dsir_y_pos"]]
      ),
      size = .label_size
    )
  }

  if (!.legend) {
    p <- p + ggplot2::theme(legend.position = "none")
  }

  p
}
