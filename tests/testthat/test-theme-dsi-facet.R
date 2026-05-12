test_that("theme_dsi_facet returns a ggplot2 theme", {
  expect_s3_class(theme_dsi_facet(), "theme")
})

test_that("theme_dsi_facet respects strip_fill parameter", {
  th <- theme_dsi_facet(strip_fill = "#E5F4FB")
  expect_equal(th$strip.background$fill, "#E5F4FB")
})

test_that("theme_dsi_facet has panel border (unlike theme_dsi)", {
  expect_s3_class(theme_dsi_facet()$panel.border, "element_rect")
  expect_s3_class(theme_dsi()$panel.border, "element_blank")
})

test_that("theme_dsi axis lines still use the accent colour after refactor", {
  th <- theme_dsi()
  expect_s3_class(th$axis.line.x, "element_line")
  expect_equal(th$axis.line.x$colour, "#0093D5")
})

test_that("theme_dsi_facet default draws grid in both directions", {
  th <- theme_dsi_facet()
  expect_s3_class(th$panel.grid.major.x, "element_line")
  expect_s3_class(th$panel.grid.major.y, "element_line")
})

test_that("theme_dsi_facet(grid = 'y') draws only horizontal grid", {
  th <- theme_dsi_facet(grid = "y")
  expect_s3_class(th$panel.grid.major.x, "element_blank")
  expect_s3_class(th$panel.grid.major.y, "element_line")
})

test_that("theme_dsi_facet(grid = 'none') draws no major grid", {
  th <- theme_dsi_facet(grid = "none")
  expect_s3_class(th$panel.grid.major.x, "element_blank")
  expect_s3_class(th$panel.grid.major.y, "element_blank")
})

test_that("theme_dsi_facet rejects invalid grid value", {
  expect_error(theme_dsi_facet(grid = "diagonal"))
})