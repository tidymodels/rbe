skip_if_not_installed("lightgbm")
skip_if_not_installed("modeldata")

test_that("options are passed to lightgbm and glmnet", {
  set.seed(3591)
  mod <- rule_ensemble_lgb(
    class ~ .,
    data = hpc_subset(),
    trees = 5,
    num_leaves = 4,
    control = list(thresh = 1e-6)
  )
  expect_named(mod$fit$spec$eng_args, "control")
  expect_equal(mod$arguments$num_leaves, 4)
})

test_that("verbose and counts have rbe defaults", {
  set.seed(6427)
  mod <- rule_ensemble_lgb(
    class ~ .,
    data = hpc_subset(),
    trees = 5,
    mtry = 0.5
  )
  expect_false(mod$arguments$verbose)
  expect_null(mod$arguments$quiet)
  expect_false(mod$arguments$counts)
  expect_equal(mod$arguments$min_n, 5)
})

test_that("small data sets can be split with the default min_n", {
  # lightgbm's own default of 20 cannot split 32 rows, so no rules are made
  set.seed(2394)
  mod <- rule_ensemble_lgb(mpg ~ ., data = mtcars, trees = 5)
  expect_gt(nrow(mod$rules), 0)
})

test_that("min_n is passed to lightgbm", {
  set.seed(5861)
  mod <- rule_ensemble_lgb(
    class ~ .,
    data = hpc_subset(),
    trees = 5,
    min_n = 12
  )
  expect_equal(mod$arguments$min_n, 12)
  expect_snapshot(
    rule_ensemble_lgb(class ~ ., data = hpc_subset(), min_data_in_leaf = 12),
    error = TRUE
  )
})

test_that("counts can be changed", {
  set.seed(8150)
  mod <- rule_ensemble_lgb(
    class ~ .,
    data = hpc_subset(),
    trees = 5,
    mtry = 2,
    counts = TRUE
  )
  expect_true(mod$arguments$counts)
})

test_that("factor predictors get separated indicator names", {
  penguins <- penguins_complete()
  set.seed(6650)
  mod <- rule_ensemble_lgb(body_mass_g ~ ., data = penguins, trees = 5)

  ptype <- mod$training$ptype
  expect_s3_class(ptype$island, "factor")
  train_mat <- make_rule_matrix(penguins[, -6], mod$rules, ptype)
  expect_all_true(
    c("species_Gentoo", "island_Dream", "sex_male") %in% colnames(train_mat)
  )
  expect_identical(nrow(predict(mod, penguins[1, -6])), 1L)
})

# ------------------------------------------------------------------------------
# Interfaces

test_that("the default method errors for unsupported inputs", {
  expect_snapshot(rule_ensemble_lgb(1:3), error = TRUE)
  expect_snapshot(rule_ensemble_lgb(letters), error = TRUE)
  expect_snapshot(rule_ensemble_lgb(list(a = 1)), error = TRUE)
  expect_snapshot(rule_ensemble_lgb(NULL), error = TRUE)
})

test_that("data frame, matrix, formula, and recipe interfaces agree", {
  expect_interfaces_agree("lgb")
})

test_that("an outcome given as a data frame or matrix", {
  set.seed(1748)
  vec_mod <- fit_engine("lgb", mtcars[, -1], mtcars$mpg)
  set.seed(1748)
  df_mod <- fit_engine("lgb", mtcars[, -1], mtcars[, "mpg", drop = FALSE])
  set.seed(1748)
  mat_mod <- fit_engine(
    "lgb",
    mtcars[, -1],
    as.matrix(mtcars[, "mpg", drop = FALSE])
  )
  expected <- predict(vec_mod, mtcars[1:3, -1])
  expect_equal(predict(df_mod, mtcars[1:3, -1]), expected)
  expect_equal(predict(mat_mod, mtcars[1:3, -1]), expected)
})

# ------------------------------------------------------------------------------
# Outcomes and arguments

test_that("regression, binary, and multiclass outcomes", {
  expect_outcome_types("lgb")
})

test_that("default and main arguments are recorded", {
  set.seed(9425)
  mod <- fit_engine("lgb", mpg ~ ., data = mtcars)
  expect_default_arguments(mod)

  set.seed(9425)
  mod <- rule_ensemble_lgb(
    mpg ~ .,
    data = mtcars,
    trees = 4,
    mtry = 0.5,
    learn_rate = 0.1,
    tree_depth = 3,
    min_n = 4,
    penalty = 0.05,
    mixture = 0.25
  )
  expect_equal(
    mod$arguments[c(
      "trees",
      "mtry",
      "learn_rate",
      "tree_depth",
      "min_n",
      "penalty",
      "mixture"
    )],
    list(
      trees = 4,
      mtry = 0.5,
      learn_rate = 0.1,
      tree_depth = 3,
      min_n = 4,
      penalty = 0.05,
      mixture = 0.25
    )
  )
  expect_equal(rlang::eval_tidy(mod$fit$spec$args$penalty), 0.05)
  expect_equal(rlang::eval_tidy(mod$fit$spec$args$mixture), 0.25)
})

test_that("protected arguments and aliases error before fitting", {
  expect_snapshot(
    rule_ensemble_lgb(mpg ~ ., data = mtcars, num_trees = 10, eta = 0.1),
    error = TRUE
  )
  expect_snapshot(
    rule_ensemble_lgb(mpg ~ ., data = mtcars, subsample = 0.5),
    error = TRUE
  )
  expect_snapshot(
    rule_ensemble_lgb(mpg ~ ., data = mtcars, callbacks = list()),
    error = TRUE
  )
  expect_snapshot(
    rule_ensemble_lgb(mpg ~ ., data = mtcars, num_leavs = 4),
    error = TRUE
  )
})

# ------------------------------------------------------------------------------
# Missing values

test_that("rows with missing predictors are removed before glmnet", {
  dat <- mtcars
  dat$wt[c(2, 11)] <- NA
  set.seed(5517)
  mod <- fit_engine("lgb", dat[, -1], dat$mpg)
  expect_identical(mod$training$rows, nrow(dat) - 2L)

  pred <- predict(mod, dat[1:3, -1])
  expect_identical(nrow(pred), 3L)
  expect_identical(is.na(pred$.pred), c(FALSE, TRUE, FALSE))
})

test_that("rows with missing predictors for a classification model", {
  two_class <- two_class_data()
  two_class$A[c(1, 5, 9)] <- NA
  set.seed(2093)
  mod <- fit_engine("lgb", Class ~ ., data = two_class)
  expect_identical(mod$training$rows, nrow(two_class) - 3L)
  prob <- predict(mod, two_class[1:2, ], type = "prob")
  expect_identical(is.na(prob$.pred_Class1), c(TRUE, FALSE))
})

test_that("weights are removed with the rows that have missing predictors", {
  dat <- mtcars
  dat$wt[c(4, 19)] <- NA
  wts <- mtcars_weights()
  set.seed(3072)
  mod <- fit_engine("lgb", dat[, -1], dat$mpg, weights = wts)
  expect_identical(mod$training$rows, nrow(dat) - 2L)
  expect_identical(mod$training$weights, "numeric")

  # Changing the weights of the removed rows does not change the glmnet model
  wts[c(4, 19)] <- 50
  set.seed(3072)
  other_mod <- fit_engine("lgb", dat[, -1], dat$mpg, weights = wts)
  expect_identical(other_mod$training$rows, nrow(dat) - 2L)
  expect_identical(nrow(predict(other_mod, dat[, -1])), nrow(dat))
})

# ------------------------------------------------------------------------------
# Case weights

test_that("lightgbm's weight argument points to weights", {
  expect_snapshot(split_dots(list(weight = 1), "lgb"), error = TRUE)
  skip_if_not_installed("recipes")
  rec <- recipes::recipe(mpg ~ ., data = mtcars)
  expect_snapshot(
    rule_ensemble_lgb(rec, data = mtcars, weight = mtcars_weights()),
    error = TRUE
  )
})

test_that("weight does not partially match weights", {
  expect_snapshot(
    rule_ensemble_lgb(mpg ~ ., data = mtcars, weight = mtcars_weights()),
    error = TRUE
  )
})

# ------------------------------------------------------------------------------
# Verbose

test_that("verbose prints the training log with every interface", {
  expect_verbose_engine("lgb")
})
