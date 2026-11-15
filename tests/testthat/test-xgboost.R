skip_if_not_installed("xgboost")

test_that("factor predictors are converted to one-hot indicators", {
  penguins <- penguins_complete()
  set.seed(4093)
  mod <- rule_fit_xgb(body_mass_g ~ ., data = penguins, trees = 5)

  expect_s3_class(mod$training$one_hot$species, "factor")
  expect_all_true(
    c("species_Adelie", "species_Gentoo", "island_Biscoe", "sex_female") %in%
      names(mod$training$ptype)
  )
  expect_all_false(vapply(mod$training$ptype, is.factor, logical(1)))

  new_data <- penguins[c(1, 300), -6]
  expect_identical(nrow(predict(mod, new_data)), 2L)
  res <- multi_predict(mod, new_data, penalty = c(0.01, 0.1))
  expect_identical(nrow(res$.pred[[1]]), 2L)
})

test_that("xy and recipe interfaces with factor predictors", {
  skip_if_not_installed("recipes")
  penguins <- penguins_complete()
  new_data <- penguins[1, -6]

  set.seed(7735)
  xy_mod <- rule_fit_xgb(penguins[, -6], penguins$body_mass_g, trees = 5)
  expect_identical(nrow(predict(xy_mod, new_data)), 1L)

  rec <- recipes::recipe(body_mass_g ~ ., data = penguins)
  set.seed(1590)
  rec_mod <- rule_fit_xgb(rec, penguins, trees = 5)
  expect_identical(nrow(predict(rec_mod, new_data)), 1L)
})

test_that("numeric predictors are unchanged", {
  set.seed(2261)
  mod <- rule_fit_xgb(mpg ~ ., data = mtcars, trees = 5)
  expect_identical(names(mod$training$ptype), names(mtcars)[-1])
  expect_identical(nrow(predict(mod, mtcars[1:2, -1])), 2L)
})

# ------------------------------------------------------------------------------
# Interfaces

test_that("the default method errors for unsupported inputs", {
  expect_snapshot(rule_fit_xgb(1:3), error = TRUE)
  expect_snapshot(rule_fit_xgb(letters), error = TRUE)
  expect_snapshot(rule_fit_xgb(list(a = 1)), error = TRUE)
  expect_snapshot(rule_fit_xgb(NULL), error = TRUE)
})

test_that("data frame, matrix, formula, and recipe interfaces agree", {
  expect_interfaces_agree("xgb")
})

test_that("an outcome given as a data frame or matrix", {
  set.seed(6382)
  vec_mod <- fit_engine("xgb", mtcars[, -1], mtcars$mpg)
  set.seed(6382)
  df_mod <- fit_engine("xgb", mtcars[, -1], mtcars[, "mpg", drop = FALSE])
  set.seed(6382)
  mat_mod <- fit_engine(
    "xgb",
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
  expect_outcome_types("xgb")
})

test_that("default and main arguments are recorded", {
  set.seed(7704)
  mod <- fit_engine("xgb", mpg ~ ., data = mtcars)
  expect_default_arguments(mod)
  expect_false(mod$arguments$counts)

  set.seed(7704)
  mod <- rule_fit_xgb(
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
})

test_that("options are passed to xgboost and glmnet", {
  set.seed(2481)
  mod <- rule_fit_xgb(
    mpg ~ .,
    data = mtcars,
    trees = 3,
    mtry = 3,
    counts = TRUE,
    gamma = 0.5,
    standardize = FALSE
  )
  expect_true(mod$arguments$counts)
  expect_equal(mod$arguments$gamma, 0.5)
  expect_named(mod$fit$spec$eng_args, "standardize")
})

test_that("protected arguments error before fitting", {
  expect_snapshot(
    rule_fit_xgb(mpg ~ ., data = mtcars, nrounds = 10, learning_rate = 0.1),
    error = TRUE
  )
  expect_snapshot(
    rule_fit_xgb(mpg ~ ., data = mtcars, evals = list()),
    error = TRUE
  )
})

# ------------------------------------------------------------------------------
# Indicators

test_that("character predictors are converted to one-hot indicators", {
  penguins <- penguins_complete()
  penguins$species <- as.character(penguins$species)
  set.seed(3916)
  mod <- fit_engine("xgb", penguins[, -6], penguins$body_mass_g)

  expect_s3_class(mod$training$one_hot$species, "factor")
  expect_identical(
    levels(mod$training$one_hot$species),
    sort(unique(penguins$species))
  )
  expect_identical(nrow(predict(mod, penguins[c(5, 200), -6])), 2L)
})

test_that("new factor levels give missing predictions with a warning", {
  penguins <- penguins_complete()
  set.seed(8257)
  mod <- fit_engine("xgb", body_mass_g ~ ., data = penguins)

  new_data <- penguins[1:2, -6]
  new_data$island <- as.character(new_data$island)
  new_data$island[2] <- "Anvers"
  expect_snapshot_warning(pred <- predict(mod, new_data))
  expect_identical(is.na(pred$.pred), c(FALSE, TRUE))
})

test_that("factor predictors in a classification model", {
  penguins <- penguins_complete()
  set.seed(1205)
  mod <- fit_engine("xgb", species ~ ., data = penguins)
  expect_s3_class(mod$fit$spec, "multinom_reg")
  expect_false("species" %in% names(mod$training$one_hot))
  expect_s3_class(mod$training$one_hot$island, "factor")
  prob <- predict(mod, penguins[c(1, 330), ], type = "prob")
  expect_named(prob, paste0(".pred_", levels(penguins$species)))
})

test_that("a factor named like an indicator of another factor is an error", {
  dat <- data.frame(
    a = factor(c("b", "c", "b", "c", "b", "c")),
    a_b = c(0.1, 0.4, 0.3, 0.9, 0.2, 0.5),
    y = c(1.2, 3.4, 2.2, 5.1, 0.7, 4.4)
  )
  expect_snapshot(rule_fit_xgb(y ~ ., data = dat, trees = 2), error = TRUE)
})
