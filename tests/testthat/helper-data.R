fit_ctb <- function(formula, data, ...) {
  rule_fit_ctb(
    formula,
    data = data,
    trees = 5,
    logging_level = "Silent",
    allow_writing_files = FALSE,
    ...
  )
}

# Skip the calling test when the engine's package is not installed
skip_if_no_engine <- function(engine) {
  if (engine == "ctb") {
    testthat::skip_if_not_installed("catboost")
  } else if (engine == "lgb") {
    testthat::skip_if_not_installed("lightgbm")
  } else {
    testthat::skip_if_not_installed("xgboost", minimum_version = "3.0.0")
  }
}

# Fit a small model with any engine and interface; catboost is kept silent
fit_engine <- function(engine, ...) {
  skip_if_no_engine(engine)
  if (engine == "ctb") {
    res <- rule_fit_ctb(
      ...,
      trees = 5,
      logging_level = "Silent",
      allow_writing_files = FALSE
    )
  } else if (engine == "lgb") {
    res <- rule_fit_lgb(..., trees = 5)
  } else {
    res <- rule_fit_xgb(..., trees = 5)
  }
  res
}

engines <- c("ctb", "lgb", "xgb")

# Remove the number of rules from print() output since it depends on the
# boosting library's version
scrub_rules <- function(x) {
  gsub("Rules: [0-9]+", "Rules: <n>", x)
}

# A small four-class data set with numeric predictors
hpc_subset <- function() {
  testthat::skip_if_not_installed("modeldata")
  dat <- modeldata::hpc_data
  dat <- dat[seq(1, nrow(dat), by = 10), ]
  dat[, c(
    "compounds",
    "input_fields",
    "iterations",
    "num_pending",
    "hour",
    "class"
  )]
}

# A two-class data set with two numeric predictors
two_class_data <- function() {
  testthat::skip_if_not_installed("modeldata")
  modeldata::two_class_dat
}

# Penguins without missing values; skips the calling test without modeldata
penguins_complete <- function() {
  testthat::skip_if_not_installed("modeldata")
  stats::na.omit(modeldata::penguins)
}

# Fit with the data frame, matrix, formula, and recipe interfaces and check
# that they give the same model
expect_interfaces_agree <- function(engine) {
  testthat::skip_if_not_installed("recipes")
  x <- mtcars[, -1]
  y <- mtcars$mpg
  new_data <- mtcars[c(3, 17, 29), -1]

  set.seed(5302)
  df_mod <- fit_engine(engine, x, y)
  set.seed(5302)
  mat_mod <- fit_engine(engine, as.matrix(x), y)
  set.seed(5302)
  form_mod <- fit_engine(engine, mpg ~ ., data = mtcars)
  rec <- recipes::recipe(mpg ~ ., data = mtcars)
  set.seed(5302)
  rec_mod <- fit_engine(engine, rec, data = mtcars)

  cls <- c(paste0("rule_fit_", engine), "rule_fit")
  expected <- predict(df_mod, new_data)
  for (mod in list(df_mod, mat_mod, form_mod, rec_mod)) {
    testthat::expect_s3_class(mod, cls)
    testthat::expect_identical(mod$training$rows, nrow(mtcars))
    testthat::expect_equal(mod$rules, df_mod$rules)
    testthat::expect_equal(predict(mod, new_data), expected)
  }
  invisible(df_mod)
}

# Check the glmnet model type and predictions for each type of outcome
expect_outcome_types <- function(engine) {
  set.seed(8714)
  reg_mod <- fit_engine(engine, mpg ~ ., data = mtcars)
  testthat::expect_s3_class(reg_mod$fit$spec, "linear_reg")
  reg_pred <- predict(reg_mod, mtcars[1:4, -1])
  testthat::expect_named(reg_pred, ".pred")
  testthat::expect_identical(nrow(reg_pred), 4L)

  two_class <- two_class_data()
  set.seed(1356)
  bin_mod <- fit_engine(engine, Class ~ ., data = two_class)
  testthat::expect_s3_class(bin_mod$fit$spec, "logistic_reg")
  bin_cls <- predict(bin_mod, two_class[1:4, 1:2])
  testthat::expect_named(bin_cls, ".pred_class")
  testthat::expect_identical(
    levels(bin_cls$.pred_class),
    levels(two_class$Class)
  )
  bin_prob <- predict(bin_mod, two_class[1:4, 1:2], type = "prob")
  testthat::expect_named(bin_prob, c(".pred_Class1", ".pred_Class2"))
  testthat::expect_equal(rowSums(bin_prob), rep(1, 4))

  hpc <- hpc_subset()
  set.seed(6039)
  multi_mod <- fit_engine(engine, class ~ ., data = hpc)
  testthat::expect_s3_class(multi_mod$fit$spec, "multinom_reg")
  multi_prob <- predict(multi_mod, hpc[1:4, -6], type = "prob")
  testthat::expect_named(multi_prob, paste0(".pred_", levels(hpc$class)))
  testthat::expect_equal(rowSums(multi_prob), rep(1, 4))
  multi_cls <- predict(multi_mod, hpc[1:4, -6])
  testthat::expect_identical(levels(multi_cls$.pred_class), levels(hpc$class))
}

# Check the default values recorded in `arguments`
expect_default_arguments <- function(mod, min_n = TRUE) {
  main <- list(
    trees = 5,
    mtry = 1,
    learn_rate = 0.01,
    tree_depth = 4,
    min_n = 5,
    penalty = 0.001,
    mixture = 1
  )
  if (!min_n) {
    main$min_n <- NULL
  }
  testthat::expect_equal(mod$arguments[names(main)], main)
}

# parsnip attaches glmnet the first time, which prints a startup message
tidy_quiet <- function(...) {
  suppressPackageStartupMessages(tidy(...))
}
