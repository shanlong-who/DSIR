test_that("theme_dsi returns a ggplot theme", {
  th <- theme_dsi()
  expect_s3_class(th, "theme")
  expect_s3_class(th, "gg")
})

test_that("theme_dsi respects base_size and color args", {
  th <- theme_dsi(base_size = 16, color = "darkred")
  expect_s3_class(th, "theme")
  expect_equal(th$text$colour, "darkred")
})
