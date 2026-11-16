test_that("boosting_method() is a qualitative parameter", {
  param <- boosting_method()
  expect_s3_class(param, c("qual_param", "param"))
  expect_identical(param$type, "character")
  expect_named(param$label, "boosting_method")
  expect_identical(unname(param$label), "Boosting Method")
  expect_null(param$finalize)
  expect_false(dials::has_unknowns(param))
})

test_that("the default values are the three boosting libraries", {
  expect_identical(values_boosting_method, c("xgboost", "lightgbm", "catboost"))
  expect_identical(boosting_method()$values, values_boosting_method)
})

test_that("values can be a subset", {
  param <- boosting_method(c("lightgbm", "catboost"))
  expect_identical(param$values, c("lightgbm", "catboost"))
  expect_identical(boosting_method("catboost")$values, "catboost")
})

test_that("values must be character", {
  expect_snapshot(boosting_method(1:3), error = TRUE)
  expect_snapshot(boosting_method(TRUE), error = TRUE)
})

test_that("grids and samples only use the given values", {
  grid <- dials::grid_regular(boosting_method(), levels = 3)
  expect_named(grid, "boosting_method")
  expect_setequal(grid$boosting_method, values_boosting_method)

  grid <- dials::grid_regular(boosting_method(), levels = 10)
  expect_identical(nrow(grid), 3L)

  set.seed(3188)
  samp <- dials::value_sample(boosting_method(), 20)
  expect_all_true(samp %in% values_boosting_method)

  samp <- dials::value_sample(boosting_method("xgboost"), 5)
  expect_all_equal(samp, "xgboost")
})

test_that("value_seq() and value_validate() work", {
  expect_identical(
    dials::value_seq(boosting_method(), 2),
    c("xgboost", "lightgbm")
  )
  expect_identical(
    dials::value_validate(boosting_method(), c("catboost", "ranger")),
    c(TRUE, FALSE)
  )
})

test_that("print method shows the label and values", {
  expect_snapshot(boosting_method())
})
