# ------------------------------------------------------------------------------
# Registration

test_that("the rule_ensemble engine is registered for both modes", {
  env <- parsnip::get_model_env()
  modes <- env$rule_fit[env$rule_fit$engine == "rule_ensemble", ]
  expect_setequal(modes$mode, c("classification", "regression"))

  args <- env$rule_fit_args[env$rule_fit_args$engine == "rule_ensemble", ]
  expect_setequal(
    args$parsnip,
    c(
      "trees",
      "mtry",
      "learn_rate",
      "tree_depth",
      "min_n",
      "penalty",
      "mixture",
      "method"
    )
  )
  expect_identical(args$parsnip, args$original)
  expect_identical(args$parsnip[args$has_submodel], "penalty")

  fits <- env$rule_fit_fit[env$rule_fit_fit$engine == "rule_ensemble", ]
  for (val in fits$value) {
    expect_identical(val$interface, "data.frame")
    expect_identical(val$func, c(pkg = "rbe", fun = "rule_ensemble"))
    expect_true("weights" %in% val$protect)
  }

  preds <- env$rule_fit_predict[
    env$rule_fit_predict$engine == "rule_ensemble",
  ]
  expect_setequal(
    paste(preds$mode, preds$type),
    c(
      "regression numeric",
      "classification class",
      "classification prob"
    )
  )
})

test_that("registering the engine again does not fail", {
  expect_no_error(make_rule_fit_rule_ensemble())
  env <- parsnip::get_model_env()
  args <- env$rule_fit_args[env$rule_fit_args$engine == "rule_ensemble", ]
  expect_false(anyDuplicated(args$parsnip) > 0)
})

test_that("translate() maps the arguments to rule_ensemble()", {
  skip_if_no_engine("xgb")
  spec <- parsnip::rule_fit(
    trees = 7,
    mtry = 0.5,
    learn_rate = 0.1,
    tree_depth = 3,
    min_n = 2,
    penalty = 0.01
  ) |>
    parsnip::set_engine(
      "rule_ensemble",
      method = "xgboost",
      mixture = 0.5
    ) |>
    parsnip::set_mode("regression")
  expect_snapshot(parsnip::translate(spec))
})

test_that("unused main arguments are not passed to rule_ensemble()", {
  skip_if_no_engine("xgb")
  spec <- rule_ensemble_spec("xgb", trees = 5)
  fit_args <- parsnip::translate(spec)$method$fit$args
  expect_named(fit_args, c("x", "y", "weights", "trees", "method"))
})

# ------------------------------------------------------------------------------
# Fitting and prediction

test_that("regression fits match rule_ensemble()", {
  new_data <- mtcars[c(4, 15, 27), -1]
  for (engine in engines) {
    spec <- rule_ensemble_spec(engine)
    set.seed(7316)
    via_form <- parsnip::fit(spec, mpg ~ ., data = mtcars)
    set.seed(7316)
    via_xy <- parsnip::fit_xy(spec, x = mtcars[, -1], y = mtcars$mpg)
    set.seed(7316)
    direct <- fit_method(engine, mtcars[, -1], mtcars$mpg)

    for (mod in list(via_form, via_xy)) {
      expect_s3_class(mod, c(paste0("_rule_ensemble_", engine), "model_fit"))
      expect_s3_class(
        mod$fit,
        c(paste0("rule_ensemble_", engine), "rule_ensemble")
      )
      expect_equal(mod$fit$rules, direct$rules)
      pred <- predict(mod, new_data)
      expect_named(pred, ".pred")
      expect_identical(nrow(pred), nrow(new_data))
      expect_equal(pred, predict(direct, new_data))
    }
  }
})

test_that("binary classification fits match rule_ensemble()", {
  two_class <- two_class_data()
  new_data <- two_class[c(2, 90, 455), 1:2]
  for (engine in engines) {
    spec <- rule_ensemble_spec(engine, mode = "classification")
    set.seed(2958)
    mod <- parsnip::fit(spec, Class ~ ., data = two_class)
    set.seed(2958)
    direct <- fit_method(engine, two_class[, 1:2], two_class$Class)

    expect_equal(mod$fit$rules, direct$rules)

    cls <- predict(mod, new_data)
    expect_named(cls, ".pred_class")
    expect_s3_class(cls$.pred_class, "factor")
    expect_identical(levels(cls$.pred_class), levels(two_class$Class))
    expect_equal(cls, predict(direct, new_data))

    prob <- predict(mod, new_data, type = "prob")
    expect_named(prob, c(".pred_Class1", ".pred_Class2"))
    expect_equal(prob, predict(direct, new_data, type = "prob"))
    expect_equal(rowSums(prob), rep(1, nrow(new_data)))
  }
})

test_that("multiclass fits match rule_ensemble()", {
  hpc <- hpc_subset()
  new_data <- hpc[c(3, 64, 251), -6]
  for (engine in engines) {
    spec <- rule_ensemble_spec(engine, mode = "classification")
    set.seed(5841)
    mod <- parsnip::fit(spec, class ~ ., data = hpc)
    set.seed(5841)
    direct <- fit_method(engine, hpc[, -6], hpc$class)

    expect_s3_class(mod$fit$fit$spec, "multinom_reg")
    cls <- predict(mod, new_data)
    expect_identical(levels(cls$.pred_class), levels(hpc$class))
    expect_equal(cls, predict(direct, new_data))

    prob <- predict(mod, new_data, type = "prob")
    expect_named(prob, paste0(".pred_", levels(hpc$class)))
    expect_equal(prob, predict(direct, new_data, type = "prob"))
  }
})

test_that("factor predictors are used without indicators", {
  penguins <- penguins_complete()
  new_data <- penguins[c(5, 199), -6]
  for (engine in engines) {
    spec <- rule_ensemble_spec(engine)
    set.seed(9402)
    mod <- parsnip::fit(spec, body_mass_g ~ ., data = penguins)
    set.seed(9402)
    direct <- fit_method(engine, penguins[, -6], penguins$body_mass_g)

    expect_equal(mod$fit$training$ptype, direct$training$ptype)
    expect_equal(predict(mod, new_data), predict(direct, new_data))
  }
})

test_that("main and engine arguments reach the fitted model", {
  for (engine in engines) {
    spec <- rule_ensemble_spec(
      engine,
      trees = 4,
      mtry = 0.8,
      learn_rate = 0.2,
      tree_depth = 2,
      penalty = 0.02
    ) |>
      parsnip::set_args(mixture = 0.25)
    set.seed(1739)
    mod <- parsnip::fit(spec, mpg ~ ., data = mtcars)
    expected <- list(
      trees = 4,
      mtry = 0.8,
      learn_rate = 0.2,
      tree_depth = 2,
      penalty = 0.02,
      mixture = 0.25
    )
    expect_equal(mod$fit$arguments[names(expected)], expected)
  }
})

test_that("boosting options are passed as engine arguments", {
  for (engine in engines) {
    spec <- rule_ensemble_spec(engine)
    spec <- rlang::exec(
      parsnip::set_args,
      spec,
      !!!engine_option[[engine]]
    )
    set.seed(8265)
    mod <- parsnip::fit(spec, mpg ~ ., data = mtcars)
    opt <- engine_option[[engine]]
    expect_equal(mod$fit$arguments[names(opt)], opt)
  }
})

test_that("the default boosting method is xgboost", {
  skip_if_no_engine("xgb")
  spec <- parsnip::rule_fit(trees = 5) |>
    parsnip::set_engine("rule_ensemble") |>
    parsnip::set_mode("regression")
  set.seed(4471)
  mod <- parsnip::fit(spec, mpg ~ ., data = mtcars)
  expect_s3_class(mod, "_rule_ensemble_xgb")
})

test_that("an invalid method is an error", {
  skip_if_no_engine("xgb")
  spec <- parsnip::rule_fit(trees = 5) |>
    parsnip::set_engine("rule_ensemble", method = "ranger") |>
    parsnip::set_mode("regression")
  expect_snapshot(parsnip::fit(spec, mpg ~ ., data = mtcars), error = TRUE)
})

test_that("an unknown engine argument is an error", {
  skip_if_no_engine("xgb")
  spec <- rule_ensemble_spec("xgb") |>
    parsnip::set_args(not_an_option = 1)
  expect_snapshot(parsnip::fit(spec, mpg ~ ., data = mtcars), error = TRUE)
})

test_that("min_n with catboost is ignored without a warning by default", {
  spec <- rule_ensemble_spec("ctb", min_n = 3)
  set.seed(6620)
  expect_no_warning(fit <- parsnip::fit(spec, mpg ~ ., data = mtcars))
  expect_null(fit$fit$arguments$min_n)
})

test_that("min_n with catboost is ignored with a warning when verbose", {
  spec <- rule_ensemble_spec("ctb", min_n = 3) |>
    parsnip::set_args(verbose = TRUE)
  set.seed(6620)
  expect_snapshot_warning(fit <- parsnip::fit(spec, mpg ~ ., data = mtcars))
  expect_null(fit$fit$arguments$min_n)
  expect_true(fit$fit$arguments$verbose)
})

test_that("catboost does not warn when min_n is not given", {
  spec <- rule_ensemble_spec("ctb")
  set.seed(3054)
  expect_no_warning(parsnip::fit(spec, mpg ~ ., data = mtcars))
})

test_that("predictions work for one row and for missing values", {
  for (engine in engines) {
    spec <- rule_ensemble_spec(engine)
    set.seed(2187)
    mod <- parsnip::fit(spec, mpg ~ ., data = mtcars)
    set.seed(2187)
    direct <- fit_method(engine, mtcars[, -1], mtcars$mpg)

    one <- predict(mod, mtcars[9, -1])
    expect_identical(nrow(one), 1L)
    expect_equal(one, predict(direct, mtcars[9, -1]))

    with_na <- mtcars[1:3, -1]
    with_na$wt[2] <- NA
    expect_equal(predict(mod, with_na), predict(direct, with_na))
  }
})

# ------------------------------------------------------------------------------
# Case weights

test_that("case weights match rule_ensemble() with weights", {
  wts <- mtcars_weights()
  new_data <- mtcars[c(6, 11, 30), -1]
  for (engine in engines) {
    spec <- rule_ensemble_spec(engine)
    set.seed(5513)
    mod <- parsnip::fit(
      spec,
      mpg ~ .,
      data = mtcars,
      case_weights = hardhat::importance_weights(wts)
    )
    set.seed(5513)
    direct <- fit_method(engine, mtcars[, -1], mtcars$mpg, weights = wts)

    expect_equal(mod$fit$rules, direct$rules)
    expect_equal(predict(mod, new_data), predict(direct, new_data))
    expect_equal(glmnet_coefs(mod$fit), glmnet_coefs(direct))
  }
})

test_that("frequency weights are used", {
  wts <- ceiling(mtcars_weights())
  for (engine in engines) {
    spec <- rule_ensemble_spec(engine)
    set.seed(9076)
    mod <- parsnip::fit(
      spec,
      mpg ~ .,
      data = mtcars,
      case_weights = hardhat::frequency_weights(wts)
    )
    set.seed(9076)
    direct <- fit_method(engine, mtcars[, -1], mtcars$mpg, weights = wts)
    expect_equal(glmnet_coefs(mod$fit), glmnet_coefs(direct))
  }
})

# ------------------------------------------------------------------------------
# Submodels

test_that("penalty is a submodel parameter", {
  for (engine in engines) {
    spec <- rule_ensemble_spec(engine)
    set.seed(3329)
    mod <- parsnip::fit(spec, mpg ~ ., data = mtcars)
    expect_true(has_multi_predict(mod))
    expect_identical(multi_predict_args(mod), "penalty")
  }
})

test_that("multi_predict() for regression", {
  pens <- c(0.001, 0.01, 0.1)
  new_data <- mtcars[c(1, 13, 22, 31), -1]
  for (engine in engines) {
    spec <- rule_ensemble_spec(engine, penalty = 0.01)
    set.seed(4816)
    mod <- parsnip::fit(spec, mpg ~ ., data = mtcars)

    res <- multi_predict(mod, new_data, penalty = pens)
    expect_s3_class(res, "tbl_df")
    expect_named(res, ".pred")
    expect_identical(nrow(res), nrow(new_data))
    for (pred in res$.pred) {
      expect_named(pred, c("penalty", ".pred"))
      expect_equal(pred$penalty, pens)
    }
    expect_equal(res, multi_predict(mod$fit, new_data, penalty = pens))

    # matches predict() at the penalty used to fit
    single <- purrr::list_rbind(multi_predict(mod, new_data)$.pred)
    expect_all_equal(single$penalty, 0.01)
    expect_equal(single$.pred, predict(mod, new_data)$.pred)
  }
})

test_that("multi_predict() for classification", {
  two_class <- two_class_data()
  hpc <- hpc_subset()
  pens <- c(0.001, 0.1)
  for (engine in engines) {
    spec <- rule_ensemble_spec(engine, mode = "classification")
    set.seed(1092)
    bin_mod <- parsnip::fit(spec, Class ~ ., data = two_class)
    new_data <- two_class[c(8, 377), 1:2]

    cls <- multi_predict(bin_mod, new_data, type = "class", penalty = pens)
    expect_named(cls$.pred[[1]], c("penalty", ".pred_class"))
    expect_identical(
      levels(cls$.pred[[1]]$.pred_class),
      levels(two_class$Class)
    )

    prob <- multi_predict(bin_mod, new_data, type = "prob", penalty = pens)
    expect_named(prob$.pred[[1]], c("penalty", ".pred_Class1", ".pred_Class2"))
    expect_identical(nrow(prob$.pred[[2]]), length(pens))

    # the default type is "class"
    expect_equal(multi_predict(bin_mod, new_data, penalty = pens), cls)

    set.seed(1092)
    multi_mod <- parsnip::fit(spec, class ~ ., data = hpc)
    multi_prob <- multi_predict(
      multi_mod,
      hpc[1:2, -6],
      type = "prob",
      penalty = pens
    )
    expect_named(
      multi_prob$.pred[[1]],
      c("penalty", paste0(".pred_", levels(hpc$class)))
    )
  }
})

test_that("multi_predict() catches `newdata`", {
  spec <- rule_ensemble_spec("xgb")
  set.seed(7745)
  mod <- parsnip::fit(spec, mpg ~ ., data = mtcars)
  expect_snapshot(
    multi_predict(mod, newdata = mtcars[1:2, -1], penalty = 0.1),
    error = TRUE
  )
})

# ------------------------------------------------------------------------------
# Packages and printing

test_that("required_pkgs() for the specification and the fit", {
  spec <- rule_ensemble_spec("xgb")
  expected <- c("parsnip", "rbe", "glmnet", "bonsai")
  expect_setequal(required_pkgs(spec), expected)
  set.seed(6233)
  mod <- parsnip::fit(spec, mpg ~ ., data = mtcars)
  expect_setequal(required_pkgs(mod), expected)
})

test_that("print() for a specification and a fit", {
  spec <- rule_ensemble_spec("xgb", penalty = 0.01)
  expect_snapshot(print(spec))
  set.seed(8851)
  mod <- parsnip::fit(spec, mpg ~ ., data = mtcars)
  expect_snapshot(print(mod), transform = scrub_rules)
})
