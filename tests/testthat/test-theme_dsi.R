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

test_that("theme_dsi default draws grid in both directions", {
  th <- theme_dsi()
  expect_s3_class(th$panel.grid.major.x, "element_line")
  expect_s3_class(th$panel.grid.major.y, "element_line")
})

test_that("theme_dsi(grid = 'y') draws only horizontal grid", {
  th <- theme_dsi(grid = "y")
  expect_s3_class(th$panel.grid.major.x, "element_blank")
  expect_s3_class(th$panel.grid.major.y, "element_line")
})

test_that("theme_dsi(grid = 'x') draws only vertical grid", {
  th <- theme_dsi(grid = "x")
  expect_s3_class(th$panel.grid.major.x, "element_line")
  expect_s3_class(th$panel.grid.major.y, "element_blank")
})

test_that("theme_dsi(grid = 'none') draws no major grid", {
  th <- theme_dsi(grid = "none")
  expect_s3_class(th$panel.grid.major.x, "element_blank")
  expect_s3_class(th$panel.grid.major.y, "element_blank")
})

test_that("theme_dsi rejects invalid grid value", {
  expect_error(theme_dsi(grid = "diagonal"))
})