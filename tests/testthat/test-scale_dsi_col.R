test_that("scale_y_dsi_col returns a continuous Y scale", {
  s <- scale_y_dsi_col()
  expect_s3_class(s, "ScaleContinuous")
  expect_true("y" %in% s$aesthetics)
})

test_that("scale_x_dsi_col returns a continuous X scale", {
  s <- scale_x_dsi_col()
  expect_s3_class(s, "ScaleContinuous")
  expect_true("x" %in% s$aesthetics)
})

test_that("scale_*_dsi_col use c(0, 0.05) expansion to flush columns to the axis", {
  # The whole point: lower-side multiplicative expansion is 0.
  s_y <- scale_y_dsi_col()
  s_x <- scale_x_dsi_col()
  expect_equal(s_y$expand, ggplot2::expansion(mult = c(0, 0.05)))
  expect_equal(s_x$expand, ggplot2::expansion(mult = c(0, 0.05)))
})

test_that("scale_*_dsi_col forward extra arguments to scale_*_continuous", {
  # Passing `limits` should be forwarded so users can override the
  # default scale range without losing the flush expansion.
  s <- scale_y_dsi_col(limits = c(0, 100))
  expect_equal(s$limits, c(0, 100))
})
