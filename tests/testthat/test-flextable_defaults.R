test_that("dsi_flextable_defaults runs without error", {
  skip_if_not_installed("flextable", minimum_version = "0.9.0")
  old <- flextable::get_flextable_defaults()
  on.exit(do.call(flextable::set_flextable_defaults, old), add = TRUE)
  expect_null(dsi_flextable_defaults())
  expect_null(dsi_flextable_defaults(padding = 2))
})

test_that("dsi_flextable_defaults accepts length-4 padding (top/bottom/left/right)", {
  skip_if_not_installed("flextable", minimum_version = "0.9.0")
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
  skip_if_not_installed("flextable", minimum_version = "0.9.0")
  old <- flextable::get_flextable_defaults()
  on.exit(do.call(flextable::set_flextable_defaults, old), add = TRUE)

  expect_null(dsi_flextable_defaults(padding = 5))
  d <- flextable::get_flextable_defaults()
  expect_equal(d$padding.top,    5)
  expect_equal(d$padding.bottom, 5)
  expect_equal(d$padding.left,   5)
  expect_equal(d$padding.right,  5)
})

# Isolate dependency availability without changing installed packages or base.
flextable_dependency_case <- function(available, version = "0.9.0") {
  helper <- dsi_flextable_defaults
  environment(helper) <- list2env(list(
    requireNamespace = function(...) available,
    getNamespaceVersion = function(...) package_version(version)
  ), parent = environment(helper))
  helper
}

test_that("the table helper gives installation guidance when flextable is absent", {
  helper <- flextable_dependency_case(FALSE)
  error <- expect_error(helper(), class = "dsir_flextable_unavailable")
  expect_match(conditionMessage(error), 'install.packages("flextable")', fixed = TRUE)
  expect_match(conditionMessage(error), "dsi_flextable_defaults", fixed = TRUE)
})

test_that("the table helper retains the minimum supported flextable version", {
  helper <- flextable_dependency_case(TRUE, "0.8.9")
  error <- expect_error(helper(), class = "dsir_flextable_unavailable")
  expect_match(conditionMessage(error), ">= 0.9.0", fixed = TRUE)
  expect_match(conditionMessage(error), 'install.packages("flextable")', fixed = TRUE)
})
