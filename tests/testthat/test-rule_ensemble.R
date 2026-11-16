# ------------------------------------------------------------------------------
# Dispatch to the engine functions

test_that("each method gives the same model as its engine function", {
  for (engine in engines) {
    expect_method_matches(engine, mpg ~ ., data = mtcars)
  }
})

test_that("methods agree with engine functions for every interface", {
  skip_if_not_installed("recipes")
  rec <- recipes::recipe(mpg ~ ., data = mtcars)
  for (engine in engines) {
    expect_method_matches(engine, mtcars[, -1], mtcars$mpg)
    expect_method_matches(engine, as.matrix(mtcars[, -1]), mtcars$mpg)
    expect_method_matches(engine, mpg ~ ., data = mtcars)
    expect_method_matches(engine, rec, data = mtcars)
  }
})

test_that("methods agree with engine functions for factor predictors", {
  penguins <- penguins_complete()
  for (engine in engines) {
    expect_method_matches(
      engine,
      body_mass_g ~ .,
      data = penguins,
      new_data = penguins[c(1, 300), -6]
    )
  }
})

test_that("methods agree with engine functions for classification", {
  two_class <- two_class_data()
  hpc <- hpc_subset()
  for (engine in engines) {
    expect_method_matches(
      engine,
      Class ~ .,
      data = two_class,
      new_data = two_class[1:3, 1:2]
    )
    expect_method_matches(
      engine,
      class ~ .,
      data = hpc,
      new_data = hpc[1:3, -6]
    )
  }
})

test_that("the default method is xgboost", {
  skip_if_no_engine("xgb")
  set.seed(3907)
  via <- rule_ensemble(mpg ~ ., data = mtcars, trees = 5)
  set.seed(3907)
  direct <- rule_ensemble_xgb(mpg ~ ., data = mtcars, trees = 5)
  expect_s3_class(via, c("rule_ensemble_xgb", "rule_ensemble"))
  expect_equal(via$rules, direct$rules)
})

test_that("data and outcomes can be passed by position", {
  for (engine in engines) {
    set.seed(8250)
    form_mod <- fit_method(engine, mpg ~ ., mtcars)
    expect_identical(form_mod$training$rows, nrow(mtcars))
    set.seed(8250)
    xy_mod <- fit_method(engine, mtcars[, -1], mtcars$mpg)
    expect_equal(xy_mod$rules, form_mod$rules)
  }
})

test_that("unsupported `x` uses the engine's error", {
  for (engine in engines) {
    skip_if_no_engine(engine)
    expect_snapshot(
      rule_ensemble(letters, method = engine_method[[engine]]),
      error = TRUE
    )
  }
})

# ------------------------------------------------------------------------------
# Main arguments

test_that("default main arguments are passed on", {
  for (engine in engines) {
    mod <- fit_method(engine, mpg ~ ., data = mtcars)
    expect_default_arguments(mod, min_n = engine != "ctb")
  }
})

test_that("non-default main arguments are passed on", {
  main <- list(
    mtry = 0.5,
    learn_rate = 0.1,
    tree_depth = 2,
    penalty = 0.01,
    mixture = 0.5
  )
  for (engine in engines) {
    set.seed(1472)
    mod <- rlang::exec(fit_method, engine, mpg ~ ., data = mtcars, !!!main)
    expect_equal(mod$arguments[names(main)], main)
    expect_identical(mod$arguments$trees, 5)
  }
})

test_that("min_n is passed on to xgboost and lightgbm", {
  for (engine in c("lgb", "xgb")) {
    set.seed(5521)
    via <- fit_method(engine, mpg ~ ., data = mtcars, min_n = 3)
    expect_identical(via$arguments$min_n, 3)
    expect_method_matches(engine, mpg ~ ., data = mtcars, min_n = 3)
  }
})

# ------------------------------------------------------------------------------
# catboost and min_n

test_that("catboost ignores the default min_n without a warning", {
  skip_if_no_engine("ctb")
  set.seed(9034)
  expect_no_warning(mod <- fit_method("ctb", mpg ~ ., data = mtcars))
  expect_null(mod$arguments$min_n)
})

test_that("catboost warns about a min_n that is given", {
  skip_if_no_engine("ctb")
  set.seed(2618)
  expect_snapshot_warning(
    mod <- fit_method("ctb", mpg ~ ., data = mtcars, min_n = 10)
  )
  expect_null(mod$arguments$min_n)
})

test_that("catboost warns about a given min_n equal to the default", {
  skip_if_no_engine("ctb")
  set.seed(7346)
  expect_snapshot_warning(
    mod <- fit_method("ctb", mpg ~ ., data = mtcars, min_n = 5)
  )
  expect_null(mod$arguments$min_n)
})

test_that("catboost warns about min_n with other options", {
  skip_if_no_engine("ctb")
  set.seed(4180)
  expect_snapshot_warning(
    mod <- fit_method(
      "ctb",
      mpg ~ .,
      data = mtcars,
      min_n = 3,
      l2_leaf_reg = 2,
      thresh = 1e-5
    )
  )
  expect_null(mod$arguments$min_n)
  expect_identical(mod$arguments$l2_leaf_reg, 2)
  expect_identical(mod$arguments$thresh, 1e-5)
})

# ------------------------------------------------------------------------------
# Options in `...`

test_that("boosting and glmnet options are passed on", {
  for (engine in engines) {
    opts <- c(engine_option[[engine]], list(standardize = FALSE))
    set.seed(6693)
    mod <- rlang::exec(fit_method, engine, mpg ~ ., data = mtcars, !!!opts)
    expect_equal(
      mod$arguments[names(engine_option[[engine]])],
      engine_option[[engine]]
    )
    expect_named(mod$fit$spec$eng_args, "standardize")
    expect_false(rlang::eval_tidy(mod$fit$spec$eng_args$standardize))
  }
})

test_that("an option for one engine is an error for another", {
  skip_if_no_engine("xgb")
  expect_snapshot(
    rule_ensemble(mpg ~ ., data = mtcars, method = "xgboost", l2_leaf_reg = 2),
    error = TRUE
  )
})

test_that("unknown options are errors", {
  for (engine in engines) {
    skip_if_no_engine(engine)
    expect_snapshot(
      rule_ensemble(
        mpg ~ .,
        data = mtcars,
        method = engine_method[[engine]],
        fooo = 1
      ),
      error = TRUE
    )
  }
})

test_that("protected options are errors", {
  protected <- list(
    ctb = list(iterations = 10),
    lgb = list(num_iterations = 10),
    xgb = list(nrounds = 10)
  )
  for (engine in engines) {
    skip_if_no_engine(engine)
    expect_snapshot(
      rlang::exec(
        rule_ensemble,
        mpg ~ .,
        data = mtcars,
        method = engine_method[[engine]],
        !!!protected[[engine]]
      ),
      error = TRUE
    )
  }
})

test_that("main arguments cannot also be given in `...` by engine name", {
  skip_if_no_engine("xgb")
  expect_snapshot(
    rule_ensemble(mpg ~ ., data = mtcars, eta = 0.1),
    error = TRUE
  )
})

# ------------------------------------------------------------------------------
# Case weights

test_that("case weights are passed on", {
  wts <- mtcars_weights()
  for (engine in engines) {
    mod <- expect_method_matches(engine, mpg ~ ., data = mtcars, weights = wts)
    expect_identical(mod$training$weights, "numeric")
    expect_method_matches(engine, mtcars[, -1], mtcars$mpg, weights = wts)
  }
})

test_that("case weights columns are used with a recipe", {
  skip_if_not_installed("recipes")
  dat <- mtcars_with_weights()
  rec <- recipes::recipe(mpg ~ ., data = dat)
  for (engine in engines) {
    mod <- expect_method_matches(
      engine,
      rec,
      data = dat,
      new_data = dat[c(2, 21), ]
    )
    expect_identical(mod$training$weights, "importance")
  }
})

test_that("`weights` cannot be used with a recipe", {
  skip_if_not_installed("recipes")
  skip_if_no_engine("xgb")
  rec <- recipes::recipe(mpg ~ ., data = mtcars)
  expect_snapshot(
    rule_ensemble(rec, data = mtcars, weights = mtcars_weights()),
    error = TRUE
  )
})

# ------------------------------------------------------------------------------
# `method` validation

test_that("`method` must be one of the supported values", {
  expect_snapshot(
    rule_ensemble(mpg ~ ., data = mtcars, method = "ranger"),
    error = TRUE
  )
  expect_snapshot(
    rule_ensemble(mpg ~ ., data = mtcars, method = "xgb"),
    error = TRUE
  )
  expect_snapshot(
    rule_ensemble(mpg ~ ., data = mtcars, method = "XGBoost"),
    error = TRUE
  )
  expect_snapshot(
    rule_ensemble(mpg ~ ., data = mtcars, method = ""),
    error = TRUE
  )
})

test_that("`method` must be a single string", {
  expect_snapshot(
    rule_ensemble(mpg ~ ., data = mtcars, method = NA),
    error = TRUE
  )
  expect_snapshot(
    rule_ensemble(mpg ~ ., data = mtcars, method = NA_character_),
    error = TRUE
  )
  expect_snapshot(
    rule_ensemble(mpg ~ ., data = mtcars, method = NULL),
    error = TRUE
  )
  expect_snapshot(
    rule_ensemble(mpg ~ ., data = mtcars, method = 1),
    error = TRUE
  )
  expect_snapshot(
    rule_ensemble(mpg ~ ., data = mtcars, method = c("xgboost", "lightgbm")),
    error = TRUE
  )
  expect_snapshot(
    rule_ensemble(mpg ~ ., data = mtcars, method = character()),
    error = TRUE
  )
})
