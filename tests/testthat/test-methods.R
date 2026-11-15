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

# ------------------------------------------------------------------------------
# multi_predict() with other engines

test_that("multi_predict() for every engine", {
  pens <- c(0.002, 0.02, 0.2)
  new_data <- mtcars[c(2, 9, 30), -1]
  for (engine in engines) {
    set.seed(4826)
    mod <- fit_engine(engine, mpg ~ ., data = mtcars)
    expect_true(has_multi_predict(mod))
    expect_identical(multi_predict_args(mod), "penalty")

    res <- multi_predict(mod, new_data, penalty = pens)
    expect_identical(nrow(res), nrow(new_data))
    expect_all_equal(vapply(res$.pred, nrow, integer(1)), length(pens))
    expect_equal(res$.pred[[2]]$penalty, pens)
  }
})

test_that("multi_predict() with a single row and a single penalty", {
  set.seed(7390)
  mod <- fit_ctb(mpg ~ ., mtcars)
  res <- multi_predict(mod, mtcars[7, -1], penalty = 0.05)
  expect_identical(nrow(res), 1L)
  expect_identical(nrow(res$.pred[[1]]), 1L)
  expect_equal(res$.pred[[1]]$penalty, 0.05)
})

# ------------------------------------------------------------------------------
# print()

test_that("print() for every engine", {
  for (engine in engines) {
    set.seed(1938)
    mod <- fit_engine(engine, mpg ~ ., data = mtcars)
    expect_snapshot(print(mod), transform = scrub_rules, variant = engine)
  }
})

test_that("print() returns the object invisibly", {
  set.seed(5604)
  mod <- fit_ctb(mpg ~ ., mtcars)
  expect_invisible(suppressMessages(res <- print(mod)))
  expect_identical(res, mod)
})

test_that("print() counts the original predictors, not indicators", {
  penguins <- penguins_complete()
  set.seed(2177)
  mod <- fit_engine("xgb", body_mass_g ~ ., data = penguins)
  expect_snapshot(print(mod), transform = scrub_rules)
})

test_that("print() with logical, vector, and brace-containing arguments", {
  set.seed(6741)
  mod <- fit_ctb(
    mpg ~ .,
    mtcars,
    custom_metric = c("RMSE", "MAE"),
    name = "{experiment}",
    standardize = FALSE
  )
  expect_snapshot(print(mod), transform = scrub_rules)
})

# ------------------------------------------------------------------------------
# predict()

test_that("predict() for regression", {
  set.seed(3359)
  mod <- fit_ctb(mpg ~ ., mtcars)
  pred <- predict(mod, mtcars[, -1])
  expect_s3_class(pred, "tbl_df")
  expect_named(pred, ".pred")
  expect_identical(nrow(pred), nrow(mtcars))
  expect_true(is.numeric(pred$.pred))

  # the outcome and extra columns in new data are ignored
  expect_equal(predict(mod, mtcars), pred)
  expect_equal(predict(mod, cbind(mtcars, extra = 1)), pred)
  # columns in a different order
  expect_equal(predict(mod, mtcars[, rev(names(mtcars))]), pred)
  expect_equal(predict(mod, mtcars[, -1], type = "numeric"), pred)
})

test_that("predict() with one row", {
  set.seed(9013)
  mod <- fit_ctb(mpg ~ ., mtcars)
  one <- predict(mod, mtcars[12, -1])
  expect_identical(nrow(one), 1L)
  expect_equal(one$.pred, predict(mod, mtcars[, -1])$.pred[12])
})

test_that("predict() errors when predictors are missing", {
  set.seed(4460)
  mod <- fit_ctb(mpg ~ ., mtcars)
  expect_snapshot(predict(mod, mtcars[1:2, c("cyl", "disp")]), error = TRUE)
})

test_that("predict() errors with a bad prediction type", {
  set.seed(7175)
  mod <- fit_ctb(mpg ~ ., mtcars)
  expect_snapshot(predict(mod, mtcars[1:2, -1], type = "prob"), error = TRUE)
})

# ------------------------------------------------------------------------------
# augment()

test_that("augment() for regression", {
  set.seed(8562)
  mod <- fit_ctb(mpg ~ ., mtcars)
  new_data <- mtcars[1:5, ]
  res <- augment(mod, new_data)
  expect_s3_class(res, "tbl_df")
  expect_named(res, c(".pred", names(mtcars)))
  expect_identical(nrow(res), 5L)
  expect_equal(res$.pred, predict(mod, new_data)$.pred)
  expect_equal(as.data.frame(res[, -1]), new_data, ignore_attr = TRUE)
})

test_that("augment() keeps only the original columns of new data", {
  set.seed(1520)
  mod <- fit_ctb(mpg ~ wt + hp, mtcars)
  res <- augment(mod, mtcars[1:3, c("hp", "wt")])
  expect_named(res, c(".pred", "hp", "wt"))
  expect_false(any(grepl("^rule_", names(res))))
})

test_that("augment() with a single row", {
  set.seed(6093)
  mod <- fit_ctb(mpg ~ ., mtcars)
  res <- augment(mod, mtcars[20, -1])
  expect_identical(nrow(res), 1L)
  expect_named(res, c(".pred", names(mtcars)[-1]))
})

test_that("augment() for binary classification", {
  two_class <- two_class_data()
  set.seed(3725)
  mod <- fit_ctb(Class ~ ., two_class)
  res <- augment(mod, two_class[1:4, ])
  expect_named(
    res,
    c(".pred_class", ".pred_Class1", ".pred_Class2", "A", "B", "Class")
  )
  expect_equal(res$.pred_class, predict(mod, two_class[1:4, ])$.pred_class)
  expect_equal(
    res$.pred_Class2,
    predict(mod, two_class[1:4, ], type = "prob")$.pred_Class2
  )
})

test_that("augment() for multiclass classification", {
  hpc <- hpc_subset()
  set.seed(5048)
  mod <- fit_ctb(class ~ ., hpc)
  res <- augment(mod, hpc[1:3, -6])
  expect_named(
    res,
    c(".pred_class", paste0(".pred_", levels(hpc$class)), names(hpc)[-6])
  )
})

test_that("augment() for every engine", {
  new_data <- mtcars[c(4, 18), ]
  for (engine in engines) {
    set.seed(2967)
    mod <- fit_engine(engine, mpg ~ ., data = mtcars)
    res <- augment(mod, new_data)
    expect_named(res, c(".pred", names(mtcars)))
    expect_equal(res$.pred, predict(mod, new_data)$.pred)
  }
})

test_that("augment() with factor predictors and missing values", {
  penguins <- penguins_complete()
  set.seed(4319)
  mod <- fit_engine("xgb", body_mass_g ~ ., data = penguins)
  new_data <- penguins[1:3, -6]
  new_data$bill_length_mm[2] <- NA
  res <- augment(mod, new_data)
  expect_named(res, c(".pred", names(new_data)))
  expect_identical(nrow(res), 3L)
  expect_s3_class(res$species, "factor")
})

# ------------------------------------------------------------------------------
# tidy()

test_that("tidy() returns the glmnet coefficients by default", {
  set.seed(7816)
  mod <- fit_ctb(mpg ~ ., mtcars)
  res <- tidy_quiet(mod)
  expect_s3_class(res, "tbl_df")
  expect_named(res, c("term", "estimate", "penalty"))
  expect_all_equal(res$penalty, mod$arguments$penalty)
  expect_identical(res$term[1], "(Intercept)")
  rule_terms <- grep("^rule_", res$term, value = TRUE)
  expect_setequal(rule_terms, mod$rules$label)
  expect_equal(tidy_quiet(mod, what = "glmnet"), res)
})

test_that("tidy() at another penalty", {
  set.seed(2539)
  mod <- fit_ctb(mpg ~ ., mtcars)
  res <- tidy_quiet(mod, penalty = 0.5)
  expect_all_equal(res$penalty, 0.5)
  # a larger penalty gives at least as many zero coefficients
  default <- tidy_quiet(mod)
  expect_gte(sum(res$estimate == 0), sum(default$estimate == 0))
})

test_that("tidy() returns the rules", {
  set.seed(9647)
  mod <- fit_ctb(mpg ~ ., mtcars)
  res <- tidy_quiet(mod, what = "rules")
  expect_identical(res, mod$rules)
  expect_true("label" %in% names(res))
  # the penalty is ignored for rules
  expect_identical(tidy_quiet(mod, what = "rules", penalty = 0.5), res)
})

test_that("tidy() errors with a bad `what`", {
  set.seed(1174)
  mod <- fit_ctb(mpg ~ ., mtcars)
  expect_snapshot(tidy(mod, what = "coefs"), error = TRUE)
})

# ------------------------------------------------------------------------------
# required_pkgs()

test_that("required_pkgs() for every engine", {
  for (engine in engines) {
    set.seed(8091)
    mod <- fit_engine(engine, mpg ~ ., data = mtcars)
    expect_identical(required_pkgs(mod), c("rulefit", "glmnet"))
  }
})
