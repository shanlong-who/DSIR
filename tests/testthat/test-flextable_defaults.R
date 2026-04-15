test_that("dsi_flextable_defaults runs without error", {
  old <- flextable::get_flextable_defaults()
  on.exit(do.call(flextable::set_flextable_defaults, old), add = TRUE)
  expect_null(dsi_flextable_defaults())
  expect_null(dsi_flextable_defaults(padding = 2))
})
