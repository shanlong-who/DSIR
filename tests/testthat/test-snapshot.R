test_that("snapshot evaluates once and reuses the file", {
  path  <- withr::local_tempfile(fileext = ".rds")
  calls <- 0L

  r1 <- suppressMessages(
    snapshot({ calls <- calls + 1L; data.frame(x = 1) }, path)
  )
  expect_equal(calls, 1L)
  expect_true(file.exists(path))
  expect_equal(r1$x, 1)

  # Second call must read the snapshot, not evaluate the expression
  r2 <- suppressMessages(
    snapshot({ calls <- calls + 1L; data.frame(x = 2) }, path)
  )
  expect_equal(calls, 1L)
  expect_equal(r2$x, 1)
})

test_that("snapshot expr is truly lazy when the snapshot is used", {
  path <- withr::local_tempfile(fileext = ".rds")
  suppressMessages(snapshot(data.frame(x = 1), path))
  # An expression that would error is never touched
  out <- suppressMessages(snapshot(stop("should not be evaluated"), path))
  expect_equal(out$x, 1)
})

test_that("snapshot refresh re-evaluates and overwrites", {
  path <- withr::local_tempfile(fileext = ".rds")
  suppressMessages(snapshot(data.frame(x = 1), path))
  out <- suppressMessages(snapshot(data.frame(x = 2), path, refresh = TRUE))
  expect_equal(out$x, 2)
  expect_equal(suppressMessages(snapshot(stop("no"), path))$x, 2)
})

test_that("snapshot max_age expires old snapshots", {
  path <- withr::local_tempfile(fileext = ".rds")
  suppressMessages(snapshot(data.frame(x = 1), path))
  # Back-date the snapshot by 40 days
  Sys.setFileTime(path, Sys.time() - 40 * 86400)

  fresh <- suppressMessages(
    snapshot(data.frame(x = 2), path, max_age = 30)
  )
  expect_equal(fresh$x, 2)

  # Within max_age the (now fresh) snapshot is reused
  again <- suppressMessages(
    snapshot(data.frame(x = 3), path, max_age = 30)
  )
  expect_equal(again$x, 2)
})

test_that("snapshot never writes an empty result", {
  path <- withr::local_tempfile(fileext = ".rds")
  expect_warning(
    out <- snapshot(data.frame(), path),
    "empty result"
  )
  expect_false(file.exists(path))
  expect_equal(nrow(out), 0L)

  expect_warning(out_null <- snapshot(NULL, path), "empty result")
  expect_null(out_null)
  expect_false(file.exists(path))

  expect_warning(out_list <- snapshot(list(), path), "empty result")
  expect_equal(out_list, list())
  expect_false(file.exists(path))
})

test_that("snapshot falls back to the existing file on an empty refresh", {
  path <- withr::local_tempfile(fileext = ".rds")
  suppressMessages(snapshot(data.frame(x = 1), path))

  expect_warning(
    out <- snapshot(data.frame(), path, refresh = TRUE),
    "not updated"
  )
  # The good snapshot is preserved and returned
  expect_true(file.exists(path))
  expect_equal(out$x, 1)
})

test_that("snapshot creates missing directories", {
  dir  <- withr::local_tempdir()
  path <- file.path(dir, "a", "b", "data.rds")
  out  <- suppressMessages(snapshot(data.frame(x = 1), path))
  expect_true(file.exists(path))
  expect_equal(out$x, 1)
})

test_that("snapshot keeps non-data-frame objects (lists, vectors)", {
  path <- withr::local_tempfile(fileext = ".rds")
  bundle <- list(a = data.frame(x = 1), b = data.frame(y = 2))
  out <- suppressMessages(snapshot(bundle, path))
  expect_equal(out, bundle)
  expect_equal(suppressMessages(snapshot(stop("no"), path)), bundle)

  path2 <- withr::local_tempfile(fileext = ".rds")
  vec <- c(a = 1, b = 2)
  expect_equal(suppressMessages(snapshot(vec, path2)), vec)
})

test_that("snapshot validates inputs", {
  expect_error(snapshot(1, file = 1), "file path")
  expect_error(snapshot(1, file = c("a", "b")), "file path")
  expect_error(snapshot(1, file = ""), "file path")
  expect_error(snapshot(1, file = NA_character_), "file path")
  path <- withr::local_tempfile(fileext = ".rds")
  expect_error(snapshot(1, path, refresh = NA), "single logical")
  expect_error(snapshot(1, path, max_age = 0), "positive")
  expect_error(snapshot(1, path, max_age = "x"), "positive")
})
