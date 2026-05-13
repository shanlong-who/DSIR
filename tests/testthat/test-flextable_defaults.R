test_that("dsi_flextable_defaults runs without error", {
  old <- flextable::get_flextable_defaults()
  on.exit(do.call(flextable::set_flextable_defaults, old), add = TRUE)
  expect_null(dsi_flextable_defaults())
  expect_null(dsi_flextable_defaults(padding = 2))
})

test_that("dsi_flextable_defaults accepts length-4 padding (top/bottom/left/right)", {
  old <- flextable::get_flextable_defaults()
  on.exit(do.call(flextable::set_flextable_defaults, old), add = TRUE)

  expect_null(dsi_flextable_defaults(padding = c(1, 2, 3, 4)))
  d <- flextable::get_flextable_defaults()
  expect_equal(d$padding.top,    1)
  expect_equal(d$padding.bottom, 2)
  expect_equal(d$padding.left,   3)
  expect_equal(d$padding.right,  4)
})

test_that("dsi_flextable_defaults length-1 padding broadcasts to all four sides", {
  old <- flextable::get_flextable_defaults()
  on.exit(do.call(flextable::set_flextable_defaults, old), add = TRUE)

  expect_null(dsi_flextable_defaults(padding = 5))
  d <- flextable::get_flextable_defaults()
  expect_equal(d$padding.top,    5)
  expect_equal(d$padding.bottom, 5)
  expect_equal(d$padding.left,   5)
  expect_equal(d$padding.right,  5)
})
