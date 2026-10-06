#' Bind Cleaned Indicator Tibbles
#'
#' Combines two or more tibbles produced by [gho_clean()] or
#' [sdg_clean()] or [ghe_clean()] into a single tibble. All cleaners output the
#' same 15-column core schema. The result is a uniform table that can be
#' filtered, joined, or visualised without source-specific code paths;
#' use the `source` column to identify GHO, SDG and GHE rows.
#'
#' Inputs do not need to be in any particular order. `NULL` inputs are
#' silently dropped, which makes it ergonomic to write code like
#' `bind_indicators(maybe_gho, maybe_sdg)` where some sources may not
#' have been fetched.
#'
#' Additional columns, including named dimensions from
#' `sdg_clean(keep_dimensions = TRUE)`, are preserved. Columns absent
#' from an input are filled with typed missing values. Binding rows
#' does not harmonise dimension codes or indicator definitions across
#' sources.
#'
#' @param ... Two or more tibbles returned by [gho_clean()] or
#'   [sdg_clean()] or [ghe_clean()] (or any data frame containing the core columns). `NULL`
#'   arguments are dropped. Calling with no inputs — or only `NULL`
#'   inputs — returns the empty 15-column tibble.
#'
#' @return A single [tibble][tibble::tibble] with the unified cleaned-
#'   indicator schema (15 core columns), followed by any additional
#'   columns in first-seen order. Row order is `c(input_1, input_2, ...)`,
#'   preserving within-input order.
#' @seealso [gho_clean()], [sdg_clean()], [ghe_clean()].
#' @export
#'
#' @examples
#' \donttest{
#' gho <- gho_data("NCDMORT3070", area = wpro_cty) |> gho_clean()
#' sdg <- sdg_data("3.4.1",        area = wpro_cty) |> sdg_clean()
#' bind_indicators(gho, sdg)
#' }
bind_indicators <- function(...) {
  dfs <- list(...)
  dfs <- dfs[!vapply(dfs, is.null, logical(1))]
  if (length(dfs) == 0L) return(.dsi_empty_clean())

  for (i in seq_along(dfs)) {
    if (!is.data.frame(dfs[[i]])) {
      cli::cli_abort(c(
        "Argument {i} must be a data frame, not {.cls {class(dfs[[i]])[1]}}.",
        "i" = "All inputs should come from {.fn gho_clean}, {.fn sdg_clean} or {.fn ghe_clean}."
      ))
    }
  }

  schema_cols <- names(.dsi_clean_schema())
  for (i in seq_along(dfs)) {
    missing_cols <- setdiff(schema_cols, names(dfs[[i]]))
    if (length(missing_cols) > 0L) {
      cli::cli_abort(c(
        "Argument {i} is missing required column{?s}: {.val {missing_cols}}.",
        "i" = "Did you forget to call {.fn gho_clean}, {.fn sdg_clean} or {.fn ghe_clean} first?"
      ))
    }
    # Keep the core first without discarding optional dimension columns.
    extra_cols <- setdiff(names(dfs[[i]]), schema_cols)
    dfs[[i]] <- dfs[[i]][, c(schema_cols, extra_cols), drop = FALSE]
  }

  out <- do.call(vctrs::vec_rbind, unname(dfs))
  tibble::as_tibble(out)
}
