test_that("theme_dsi returns a ggplot theme", {
  th <- theme_dsi()
  expect_s3_class(th, "theme")
  expect_s3_class(th, "gg")
})

test_that("theme_dsi respects base_size and accent args", {
  th <- theme_dsi(base_size = 16, accent = "darkred")
  
  expect_equal(th$text$size, 16)
  
  expect_equal(th$axis.line.x$colour, "darkred")
  expect_equal(th$axis.line.y$colour, "darkred")
  
  expect_equal(th$text$colour, "grey20")
})