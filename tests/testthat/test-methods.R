skip_if_not_installed("catboost")
skip_if_not_installed("modeldata")

test_that("multi_predict() for regression", {
  set.seed(6194)
  mod <- fit_ctb(mpg ~ ., mtcars)
  pens <- c(0.001, 0.01, 0.1)
  new_data <- mtcars[1:4, -1]

  res <- multi_predict(mod, new_data, penalty = pens)
  expect_s3_class(res, "tbl_df")
  expect_named(res, ".pred")
  expect_equal(nrow(res), nrow(new_data))

  expect_named(res$.pred[[1]], c("penalty", ".pred"))
  expect_equal(nrow(res$.pred[[1]]), length(pens))
  expect_equal(res$.pred[[1]]$penalty, pens)

  # matches predict() at the penalty used to fit
  single <- multi_predict(mod, new_data)
  single <- purrr::list_rbind(single$.pred)
  expect_equal(single$penalty, rep(mod$arguments$penalty, nrow(new_data)))
  expect_equal(single$.pred, predict(mod, new_data)$.pred)
})

test_that("multi_predict() for binary classification", {
  two_class <- modeldata::two_class_dat
  set.seed(3807)
  mod <- fit_ctb(Class ~ ., two_class)
  pens <- c(0.001, 0.1)
  new_data <- two_class[1:3, -3]

  prob <- multi_predict(mod, new_data, type = "prob", penalty = pens)
  expect_equal(nrow(prob), nrow(new_data))
  expect_named(prob$.pred[[1]], c("penalty", ".pred_Class1", ".pred_Class2"))
  expect_equal(nrow(prob$.pred[[1]]), length(pens))

  cls <- multi_predict(mod, new_data, type = "class", penalty = pens)
  expect_named(cls$.pred[[1]], c("penalty", ".pred_class"))
  expect_s3_class(cls$.pred[[1]]$.pred_class, "factor")
  expect_equal(levels(cls$.pred[[1]]$.pred_class), levels(two_class$Class))

  # matches predict() at the penalty used to fit
  single <- multi_predict(mod, new_data, type = "prob")
  single <- purrr::list_rbind(single$.pred)
  expect_equal(
    single$.pred_Class1,
    predict(mod, new_data, type = "prob")$.pred_Class1
  )
})

test_that("multi_predict() for multiclass classification", {
  hpc <- hpc_subset()
  set.seed(9471)
  mod <- fit_ctb(class ~ ., hpc)
  pens <- c(0.001, 0.1)
  new_data <- hpc[1:3, names(hpc) != "class"]

  cls <- multi_predict(mod, new_data, penalty = pens)
  expect_equal(nrow(cls), nrow(new_data))
  expect_named(cls$.pred[[1]], c("penalty", ".pred_class"))
  expect_equal(levels(cls$.pred[[1]]$.pred_class), levels(hpc$class))

  prob <- multi_predict(mod, new_data, type = "prob", penalty = pens)
  expect_named(
    prob$.pred[[1]],
    c("penalty", paste0(".pred_", levels(hpc$class)))
  )
  expect_equal(nrow(prob$.pred[[1]]), length(pens))
})

test_that("multi_predict() helpers", {
  set.seed(2756)
  mod <- fit_ctb(mpg ~ ., mtcars)

  expect_true(has_multi_predict(mod))
  expect_equal(multi_predict_args(mod), "penalty")
})

test_that("multi_predict() errors with a bad prediction type", {
  set.seed(5138)
  mod <- fit_ctb(mpg ~ ., mtcars)

  expect_snapshot(
    multi_predict(mod, mtcars[1:2, -1], type = "class"),
    error = TRUE
  )
})
