test_that("ggpie returns a ggplot object", {
  df <- data.frame(
    category = c("A", "B", "C"),
    value = c(40, 35, 25)
  )
  p <- ggpie(df, "category", "value")
  expect_s3_class(p, "ggplot")
})

test_that("ggpie validates its inputs", {
  df <- data.frame(a = 1, b = 2)
  expect_error(ggpie(df, "missing", "b"))
  expect_error(ggpie(df, "a", "missing"))
  expect_error(ggpie(list(a = 1, b = 2), "a", "b"))
})

test_that("ggpie .legend and .label toggles work", {
  df <- data.frame(x = c("a", "b"), y = c(1, 2))
  p1 <- ggpie(df, "x", "y", .label = FALSE, .legend = TRUE)
  expect_s3_class(p1, "ggplot")
})
