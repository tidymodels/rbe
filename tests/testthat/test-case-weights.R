# ------------------------------------------------------------------------------
# check_weights()

test_that("check_weights() returns NULL without weights", {
  expect_null(check_weights(NULL, 10))
})

test_that("check_weights() converts numeric and hardhat weights", {
  dbl <- check_weights(c(0.5, 1, 2), 3)
  expect_identical(as.vector(dbl), c(0.5, 1, 2))
  expect_type(dbl, "double")
  expect_identical(attr(dbl, "weights_class"), "numeric")

  int <- check_weights(1:3, 3)
  expect_type(int, "double")
  expect_identical(attr(int, "weights_class"), "numeric")

  imp <- check_weights(hardhat::importance_weights(c(0.5, 1, 2)), 3)
  expect_type(imp, "double")
  expect_false(hardhat::is_case_weights(imp))
  expect_identical(attr(imp, "weights_class"), "importance")

  freq <- check_weights(hardhat::frequency_weights(c(0L, 1L, 4L)), 3)
  expect_type(freq, "integer")
  expect_identical(as.vector(freq), c(0L, 1L, 4L))
  expect_identical(attr(freq, "weights_class"), "frequency")
})

test_that("check_weights() allows zero weights when one is positive", {
  res <- check_weights(c(0, 0, 0.1), 3)
  expect_identical(as.vector(res), c(0, 0, 0.1))
  expect_identical(as.vector(check_weights(1, 1)), 1)
})

test_that("check_weights() errors for the wrong type", {
  expect_snapshot(check_weights(letters[1:3], 3), error = TRUE)
  expect_snapshot(check_weights(factor(1:3), 3), error = TRUE)
  expect_snapshot(check_weights(c(TRUE, FALSE, TRUE), 3), error = TRUE)
  expect_snapshot(check_weights(data.frame(w = 1:3), 3), error = TRUE)
  expect_snapshot(check_weights(list(1, 2, 3), 3), error = TRUE)
  expect_snapshot(check_weights(Sys.Date() + 0:2, 3), error = TRUE)
  expect_snapshot(check_weights(matrix(1:3, ncol = 1), 3), error = TRUE)
})

test_that("check_weights() errors for the wrong length", {
  expect_snapshot(check_weights(1:2, 3), error = TRUE)
  expect_snapshot(check_weights(1:4, 3), error = TRUE)
  expect_snapshot(check_weights(numeric(0), 1), error = TRUE)
  expect_snapshot(check_weights(1, 3), error = TRUE)
})

test_that("check_weights() errors for invalid values", {
  expect_snapshot(check_weights(c(1, NA, 2), 3), error = TRUE)
  expect_snapshot(check_weights(c(1, NaN, 2), 3), error = TRUE)
  expect_snapshot(check_weights(c(1, NA_integer_, 2L), 3), error = TRUE)
  expect_snapshot(check_weights(c(1, Inf, 2), 3), error = TRUE)
  expect_snapshot(check_weights(c(1, -Inf, 2), 3), error = TRUE)
  expect_snapshot(check_weights(c(1, -0.5, 2), 3), error = TRUE)
  expect_snapshot(check_weights(c(0, 0, 0), 3), error = TRUE)
  expect_snapshot(
    check_weights(hardhat::frequency_weights(c(0L, 0L)), 2),
    error = TRUE
  )
})

# ------------------------------------------------------------------------------
# Other helpers

test_that("weights_class() for each type of weights", {
  expect_identical(weights_class(c(1, 2)), "numeric")
  expect_identical(weights_class(1:2), "numeric")
  expect_identical(
    weights_class(hardhat::importance_weights(c(1, 2))),
    "importance"
  )
  expect_identical(
    weights_class(hardhat::frequency_weights(1:2)),
    "frequency"
  )
})

test_that("check_no_weight_predictors() finds case weights columns", {
  dat <- mtcars_with_weights()
  expect_null(check_no_weight_predictors(mtcars))
  expect_null(check_no_weight_predictors(mtcars[0, ]))
  expect_snapshot(check_no_weight_predictors(dat), error = TRUE)

  dat$freq <- hardhat::frequency_weights(rep(1L, nrow(dat)))
  expect_snapshot(check_no_weight_predictors(dat), error = TRUE)
})

test_that("check_formula_weights() finds case weights predictors", {
  dat <- mtcars_with_weights()
  expect_null(check_formula_weights(mpg ~ ., mtcars))
  expect_null(check_formula_weights(mpg ~ cyl + disp, dat))
  expect_null(check_formula_weights(case_wts ~ ., dat))
  expect_null(check_formula_weights(mpg ~ ., as.matrix(mtcars)))
  expect_snapshot(check_formula_weights(mpg ~ ., dat), error = TRUE)
  expect_snapshot(
    check_formula_weights(mpg ~ cyl + case_wts, dat),
    error = TRUE
  )
  expect_snapshot(
    check_formula_weights(mpg ~ log(case_wts) + cyl, dat),
    error = TRUE
  )
  expect_null(check_formula_weights(mpg ~ . - case_wts, dat))
})

test_that("as_glmnet_weights() makes hardhat weights", {
  expect_null(as_glmnet_weights(NULL))

  num <- as_glmnet_weights(check_weights(c(0.5, 2), 2))
  expect_s3_class(num, "hardhat_importance_weights")
  expect_identical(as.numeric(num), c(0.5, 2))

  imp <- as_glmnet_weights(
    check_weights(hardhat::importance_weights(c(0.5, 2)), 2)
  )
  expect_s3_class(imp, "hardhat_importance_weights")

  freq <- as_glmnet_weights(
    check_weights(hardhat::frequency_weights(c(3L, 2L)), 2)
  )
  expect_s3_class(freq, "hardhat_frequency_weights")
  expect_identical(as.integer(freq), c(3L, 2L))
})

test_that("as_boost_weights() makes a plain numeric vector", {
  expect_null(as_boost_weights(NULL))
  res <- as_boost_weights(check_weights(hardhat::frequency_weights(1:3), 3))
  expect_identical(res, c(1, 2, 3))
})

test_that("positive_weight_rows() skips rows with zero weight", {
  expect_identical(positive_weight_rows(NULL, 4), 1:4)
  expect_identical(positive_weight_rows(NULL, 0), integer(0))
  expect_identical(positive_weight_rows(c(0, 1, 0, 2), 4), c(2L, 4L))
  expect_identical(positive_weight_rows(c(1, 1), 2), 1:2)
})

test_that("subset_weights() keeps the type of weights", {
  expect_null(subset_weights(NULL, 1:2))
  wts <- check_weights(hardhat::frequency_weights(c(1L, 2L, 3L)), 3)
  res <- subset_weights(wts, c(1, 3))
  expect_identical(as.vector(res), c(1L, 3L))
  expect_identical(attr(res, "weights_class"), "frequency")
})

test_that("check_recipe_dots() errors when weights are passed", {
  expect_null(check_recipe_dots(list()))
  expect_null(check_recipe_dots(list(thresh = 1e-5)))
  expect_snapshot(check_recipe_dots(list(weights = 1:3)), error = TRUE)
  expect_snapshot(check_recipe_dots(list(weight = 1:3)), error = TRUE)
  expect_snapshot(
    check_recipe_dots(list(weights = 1:3, weight = 1:3)),
    error = TRUE
  )
})

test_that("prune_rules() uses only the given rows to find columns", {
  x <- cbind(
    a = c(1, 2, 3, 4),
    # constant in the first two rows
    b = c(1, 1, 0, 1),
    # equal to `a` in the first two rows
    c = c(1, 2, 0, 0)
  )
  expect_identical(colnames(prune_rules(x)), c("a", "b", "c"))
  res <- prune_rules(x, rows = 1:2)
  expect_identical(colnames(res), "a")
  expect_identical(nrow(res), 4L)
  expect_identical(res[, "a"], x[, "a"])
})

# ------------------------------------------------------------------------------
# Fitting with weights

test_that("models without weights do not record them", {
  for (engine in engines) {
    set.seed(9061)
    mod <- fit_engine(engine, mpg ~ ., data = mtcars)
    expect_null(mod$training$weights)
    set.seed(9061)
    null_mod <- fit_engine(engine, mpg ~ ., data = mtcars, weights = NULL)
    expect_null(null_mod$training$weights)
    expect_equal(null_mod$rules, mod$rules)
    expect_equal(predict(null_mod, mtcars), predict(mod, mtcars))
  }
})

test_that("weights of one give the same model as no weights", {
  for (engine in engines) {
    set.seed(3847)
    mod <- fit_engine(engine, mtcars[, -1], mtcars$mpg)
    set.seed(3847)
    wt_mod <- fit_engine(
      engine,
      mtcars[, -1],
      mtcars$mpg,
      weights = rep(1, nrow(mtcars))
    )
    expect_identical(wt_mod$training$weights, "numeric")
    expect_equal(wt_mod$rules, mod$rules)
    expect_equal(glmnet_coefs(wt_mod), glmnet_coefs(mod))
    expect_equal(predict(wt_mod, mtcars[, -1]), predict(mod, mtcars[, -1]))
  }
})

test_that("unequal weights change the model", {
  for (engine in engines) {
    set.seed(6128)
    mod <- fit_engine(engine, mtcars[, -1], mtcars$mpg)
    set.seed(6128)
    wt_mod <- fit_engine(
      engine,
      mtcars[, -1],
      mtcars$mpg,
      weights = mtcars_weights()
    )
    expect_false(isTRUE(all.equal(
      predict(wt_mod, mtcars[, -1]),
      predict(mod, mtcars[, -1])
    )))
  }
})

test_that("the type of weights is recorded", {
  wts <- mtcars_weights()
  for (engine in engines) {
    set.seed(5503)
    num_mod <- fit_engine(engine, mpg ~ ., data = mtcars, weights = wts)
    expect_identical(num_mod$training$weights, "numeric")

    set.seed(5503)
    imp_mod <- fit_engine(
      engine,
      mpg ~ .,
      data = mtcars,
      weights = hardhat::importance_weights(wts)
    )
    expect_identical(imp_mod$training$weights, "importance")
    expect_equal(predict(imp_mod, mtcars), predict(num_mod, mtcars))

    set.seed(5503)
    freq_mod <- fit_engine(
      engine,
      mpg ~ .,
      data = mtcars,
      weights = hardhat::frequency_weights(ceiling(wts))
    )
    expect_identical(freq_mod$training$weights, "frequency")
    expect_s3_class(freq_mod, "rule_fit")
  }
})

test_that("weights give the same model with every interface", {
  skip_if_not_installed("recipes")
  dat <- mtcars_with_weights()
  wts <- as.numeric(dat$case_wts)
  new_data <- mtcars[c(4, 12, 27), -1]

  for (engine in engines) {
    set.seed(7316)
    df_mod <- fit_engine(engine, mtcars[, -1], mtcars$mpg, weights = wts)
    set.seed(7316)
    mat_mod <- fit_engine(
      engine,
      as.matrix(mtcars[, -1]),
      mtcars$mpg,
      weights = wts
    )
    set.seed(7316)
    form_mod <- fit_engine(engine, mpg ~ ., data = mtcars, weights = wts)
    rec <- recipes::recipe(mpg ~ ., data = dat)
    set.seed(7316)
    rec_mod <- fit_engine(engine, rec, data = dat)

    expect_identical(rec_mod$training$weights, "importance")
    expected <- predict(df_mod, new_data)
    for (mod in list(mat_mod, form_mod, rec_mod)) {
      expect_equal(mod$rules, df_mod$rules)
      expect_equal(predict(mod, new_data), expected)
    }
  }
})

test_that("recipes use the case weights column but not as a predictor", {
  skip_if_not_installed("recipes")
  dat <- mtcars_with_weights(hardhat::frequency_weights)
  rec <- recipes::recipe(mpg ~ ., data = dat)

  for (engine in engines) {
    set.seed(2650)
    mod <- fit_engine(engine, rec, data = dat)
    expect_identical(mod$training$weights, "frequency")
    expect_false("case_wts" %in% names(mod$training$ptype))
    used <- unique(unlist(lapply(mod$rules$rules, all.vars)))
    expect_false("case_wts" %in% used)

    pred <- predict(mod, mtcars[1:3, -1])
    expect_identical(nrow(pred), 3L)
    expect_equal(predict(mod, dat[1:3, ]), pred)
  }
})

test_that("a case weights column can be removed from a formula", {
  dat <- mtcars_with_weights()
  wts <- as.numeric(dat$case_wts)
  for (engine in engines) {
    set.seed(6295)
    mod <- fit_engine(engine, mpg ~ ., data = mtcars, weights = wts)
    set.seed(6295)
    rm_mod <- fit_engine(engine, mpg ~ . - case_wts, data = dat, weights = wts)
    expect_false("case_wts" %in% names(rm_mod$training$ptype))
    expect_equal(predict(rm_mod, dat[1:4, ]), predict(mod, mtcars[1:4, ]))
  }
})

test_that("recipes without a case weights column are unweighted", {
  skip_if_not_installed("recipes")
  rec <- recipes::recipe(mpg ~ ., data = mtcars)
  for (engine in engines) {
    set.seed(4182)
    mod <- fit_engine(engine, rec, data = mtcars)
    expect_null(mod$training$weights)
  }
})

test_that("zero weights are allowed and not used for pruning", {
  wts <- mtcars_weights()
  wts[seq(1, nrow(mtcars), by = 3)] <- 0
  pos <- wts > 0

  for (engine in engines) {
    set.seed(8854)
    mod <- fit_engine(engine, mtcars[, -1], mtcars$mpg, weights = wts)
    expect_identical(mod$training$rows, nrow(mtcars))

    rule_mat <- make_rule_matrix(mtcars[, -1], mod$rules, mod$training$ptype)
    rule_mat <- rule_mat[pos, mod$rules$label, drop = FALSE]
    num_unique <- apply(rule_mat, 2, vctrs::vec_unique_count)
    expect_all_true(num_unique > 1)
    expect_identical(nrow(predict(mod, mtcars[, -1])), nrow(mtcars))
  }
})

test_that("a single row with a positive weight", {
  wts <- rep(0, nrow(mtcars))
  wts[[5]] <- 1
  expect_identical(positive_weight_rows(wts, nrow(mtcars)), 5L)
  res <- prune_rules(as.matrix(mtcars), rows = 5L)
  expect_identical(dim(res), c(nrow(mtcars), 0L))
})

test_that("weights for regression, binary, and multiclass outcomes", {
  two_class <- two_class_data()
  hpc <- hpc_subset()
  bin_wts <- withr::with_seed(1093, stats::runif(nrow(two_class)))
  multi_wts <- withr::with_seed(3361, stats::runif(nrow(hpc)))

  for (engine in engines) {
    set.seed(7720)
    reg_mod <- fit_engine(
      engine,
      mpg ~ .,
      data = mtcars,
      weights = mtcars_weights()
    )
    expect_s3_class(reg_mod$fit$spec, "linear_reg")
    expect_named(predict(reg_mod, mtcars[1:2, -1]), ".pred")

    set.seed(7720)
    bin_mod <- fit_engine(
      engine,
      Class ~ .,
      data = two_class,
      weights = bin_wts
    )
    expect_s3_class(bin_mod$fit$spec, "logistic_reg")
    bin_prob <- predict(bin_mod, two_class[1:4, 1:2], type = "prob")
    expect_equal(rowSums(bin_prob), rep(1, 4))

    set.seed(7720)
    multi_mod <- fit_engine(
      engine,
      class ~ .,
      data = hpc,
      weights = hardhat::importance_weights(multi_wts)
    )
    expect_s3_class(multi_mod$fit$spec, "multinom_reg")
    multi_prob <- predict(multi_mod, hpc[1:4, -6], type = "prob")
    expect_equal(rowSums(multi_prob), rep(1, 4))
    expect_identical(multi_mod$training$weights, "importance")
  }
})

# ------------------------------------------------------------------------------
# Errors

test_that("invalid weights error before fitting", {
  for (engine in engines) {
    skip_if_no_engine(engine)
    expect_snapshot(
      fit_engine(engine, mpg ~ ., data = mtcars, weights = 1:3),
      error = TRUE,
      variant = engine
    )
    expect_snapshot(
      fit_engine(engine, mtcars[, -1], mtcars$mpg, weights = "a"),
      error = TRUE,
      variant = engine
    )
    expect_snapshot(
      fit_engine(
        engine,
        as.matrix(mtcars[, -1]),
        mtcars$mpg,
        weights = -mtcars_weights()
      ),
      error = TRUE,
      variant = engine
    )
  }
})

test_that("a case weights column cannot be a predictor", {
  dat <- mtcars_with_weights()
  for (engine in engines) {
    skip_if_no_engine(engine)
    expect_snapshot(
      fit_engine(engine, mpg ~ ., data = dat),
      error = TRUE,
      variant = engine
    )
    expect_snapshot(
      fit_engine(engine, dat[, -1], dat$mpg),
      error = TRUE,
      variant = engine
    )
  }
})

test_that("weights cannot be passed to the recipe method", {
  skip_if_not_installed("recipes")
  rec <- recipes::recipe(mpg ~ ., data = mtcars)
  for (engine in engines) {
    skip_if_no_engine(engine)
    expect_snapshot(
      fit_engine(engine, rec, data = mtcars, weights = mtcars_weights()),
      error = TRUE,
      variant = engine
    )
  }
})
