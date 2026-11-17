skip_if_not_installed("xgboost")

test_that("factor predictors are used for categorical splits", {
  penguins <- penguins_complete()
  set.seed(4093)
  mod <- rule_ensemble_xgb(body_mass_g ~ ., data = penguins, trees = 5)

  expect_null(mod$training$one_hot)
  expect_named(mod$training$ptype, names(penguins)[-6], ignore.order = TRUE)
  for (var in c("species", "island", "sex")) {
    expect_s3_class(mod$training$ptype[[var]], "factor")
    expect_identical(levels(mod$training$ptype[[var]]), levels(penguins[[var]]))
  }
  expect_true(any(c("species", "island", "sex") %in% rule_variables(mod)))
  expect_all_true(rule_variables(mod) %in% names(penguins)[-6])
  # rules use the factor levels and not xgboost's integer codes
  expect_all_true(
    rule_strings(mod) %in% unlist(lapply(penguins, levels), use.names = FALSE)
  )

  new_data <- penguins[c(1, 300), -6]
  expect_identical(nrow(predict(mod, new_data)), 2L)
  res <- multi_predict(mod, new_data, penalty = c(0.01, 0.1))
  expect_identical(nrow(res$.pred[[1]]), 2L)
})

test_that("each row satisfies one rule per tree with categorical splits", {
  penguins <- penguins_complete()
  set.seed(6641)
  # the fitted object does not keep the booster, so the rule matrix is made
  # from a booster in the same way as the bridge function. The numeric
  # predictor is integer-valued since xgboost compares thresholds as floats.
  x <- penguins[, c("species", "island", "sex", "flipper_length_mm")]
  boost <- parsnip::xgb_train(x, penguins$body_mass_g, nrounds = 3)
  rules <- lorax::extract_rules(boost, tree = 1:3, data = x)
  rules$label <- names0(nrow(rules))
  rule_mat <- make_rule_matrix(x, rules, predictor_ptype(x))
  rule_mat <- rule_mat[, rules$label, drop = FALSE]

  leaves <- predict(boost, xgboost::xgb.DMatrix(x), predleaf = TRUE)
  for (i in 1:3) {
    in_tree <- rules$tree == i
    tree_mat <- rule_mat[, in_tree, drop = FALSE]
    expect_all_equal(rowSums(tree_mat), 1)
    # lorax node ids are one-based
    expect_identical(
      rules$id[in_tree][max.col(tree_mat)],
      as.integer(leaves[, i]) + 1L
    )
  }
})

test_that("xy and recipe interfaces with factor predictors", {
  skip_if_not_installed("recipes")
  penguins <- penguins_complete()
  new_data <- penguins[1, -6]

  set.seed(7735)
  xy_mod <- rule_ensemble_xgb(penguins[, -6], penguins$body_mass_g, trees = 5)
  expect_identical(nrow(predict(xy_mod, new_data)), 1L)

  rec <- recipes::recipe(body_mass_g ~ ., data = penguins)
  set.seed(1590)
  rec_mod <- rule_ensemble_xgb(rec, penguins, trees = 5)
  expect_identical(nrow(predict(rec_mod, new_data)), 1L)
})

test_that("numeric predictors are unchanged", {
  set.seed(2261)
  mod <- rule_ensemble_xgb(mpg ~ ., data = mtcars, trees = 5)
  expect_identical(names(mod$training$ptype), names(mtcars)[-1])
  expect_identical(nrow(predict(mod, mtcars[1:2, -1])), 2L)
})

# ------------------------------------------------------------------------------
# Interfaces

test_that("the default method errors for unsupported inputs", {
  expect_snapshot(rule_ensemble_xgb(1:3), error = TRUE)
  expect_snapshot(rule_ensemble_xgb(letters), error = TRUE)
  expect_snapshot(rule_ensemble_xgb(list(a = 1)), error = TRUE)
  expect_snapshot(rule_ensemble_xgb(NULL), error = TRUE)
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
  mod <- rule_ensemble_xgb(
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
  mod <- rule_ensemble_xgb(
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
    rule_ensemble_xgb(
      mpg ~ .,
      data = mtcars,
      nrounds = 10,
      learning_rate = 0.1
    ),
    error = TRUE
  )
  expect_snapshot(
    rule_ensemble_xgb(mpg ~ ., data = mtcars, evals = list()),
    error = TRUE
  )
})

# ------------------------------------------------------------------------------
# Factor predictors

test_that("character predictors are converted to factors", {
  penguins <- penguins_complete()
  penguins$species <- as.character(penguins$species)
  set.seed(3916)
  mod <- fit_engine("xgb", penguins[, -6], penguins$body_mass_g)

  expect_s3_class(mod$training$ptype$species, "factor")
  expect_identical(
    levels(mod$training$ptype$species),
    sort(unique(penguins$species))
  )
  expect_true("species" %in% rule_variables(mod))
  expect_all_true(
    rule_strings(mod) %in%
      c(unique(penguins$species), levels(penguins$island), levels(penguins$sex))
  )
  expect_identical(nrow(predict(mod, penguins[c(5, 200), -6])), 2L)

  # the same model as when the column is a factor
  fct_data <- penguins
  fct_data$species <- factor(fct_data$species)
  set.seed(3916)
  fct_mod <- fit_engine("xgb", fct_data[, -6], fct_data$body_mass_g)
  expect_equal(mod$rules, fct_mod$rules)
  expect_equal(
    predict(mod, penguins[c(5, 200), -6]),
    predict(fct_mod, fct_data[c(5, 200), -6])
  )
})

test_that("ordered factors and unused levels", {
  penguins <- penguins_complete()
  penguins$island <- factor(penguins$island, ordered = TRUE)
  penguins$species <- factor(
    penguins$species,
    levels = c("Adelie", "Unseen", "Chinstrap", "Gentoo")
  )
  set.seed(5518)
  mod <- fit_engine("xgb", body_mass_g ~ ., data = penguins)

  expect_s3_class(mod$training$ptype$island, "ordered")
  expect_identical(levels(mod$training$ptype$species), levels(penguins$species))
  pred <- predict(mod, penguins[c(1, 150, 300), -6])
  expect_false(anyNA(pred$.pred))

  # a level that was not in the training set values is not a novel level
  new_data <- penguins[1, -6]
  new_data$species[1] <- "Unseen"
  expect_no_warning(pred <- predict(mod, new_data))
  expect_false(anyNA(pred$.pred))
})

test_that("only factor predictors", {
  penguins <- penguins_complete()
  set.seed(7093)
  mod <- fit_engine("xgb", body_mass_g ~ species + sex, data = penguins)
  expect_named(mod$training$ptype, c("species", "sex"))
  expect_all_true(rule_variables(mod) %in% c("species", "sex"))
  expect_identical(nrow(predict(mod, penguins[1:3, ])), 3L)

  set.seed(7093)
  one_mod <- fit_engine("xgb", body_mass_g ~ species, data = penguins)
  expect_named(one_mod$training$ptype, "species")
  # every rule is a linear combination of the species indicators
  expect_identical(nrow(one_mod$rules), 0L)
  expect_identical(nrow(predict(one_mod, penguins[1:3, ])), 3L)
})

test_that("missing factor values in new data give missing predictions", {
  penguins <- penguins_complete()
  set.seed(2954)
  mod <- fit_engine("xgb", body_mass_g ~ ., data = penguins)
  new_data <- penguins[1:3, -6]
  new_data$sex[2] <- NA
  pred <- predict(mod, new_data)
  expect_identical(is.na(pred$.pred), c(FALSE, TRUE, FALSE))
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
  expect_false("species" %in% names(mod$training$ptype))
  expect_s3_class(mod$training$ptype$island, "factor")
  prob <- predict(mod, penguins[c(1, 330), ], type = "prob")
  expect_named(prob, paste0(".pred_", levels(penguins$species)))
})

test_that("a factor named like an indicator of another factor is an error", {
  dat <- data.frame(
    a = factor(c("b", "c", "b", "c", "b", "c")),
    a_b = c(0.1, 0.4, 0.3, 0.9, 0.2, 0.5),
    y = c(1.2, 3.4, 2.2, 5.1, 0.7, 4.4)
  )
  expect_snapshot(rule_ensemble_xgb(y ~ ., data = dat, trees = 2), error = TRUE)
})

# ------------------------------------------------------------------------------
# Verbose

test_that("verbose prints the training log with every interface", {
  expect_verbose_engine("xgb")
})
