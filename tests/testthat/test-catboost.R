skip_if_not_installed("catboost")

test_that("options are passed to catboost and glmnet", {
  set.seed(7042)
  mod <- fit_ctb(mpg ~ ., mtcars, standardize = FALSE)
  expect_named(mod$fit$spec$eng_args, "standardize")
  expect_false(rlang::eval_tidy(mod$fit$spec$eng_args$standardize))
  expect_equal(mod$arguments$logging_level, "Silent")
  expect_equal(mod$arguments$final_ctr_computation_mode, "Skip")
})

test_that("final_ctr_computation_mode is always 'Skip'", {
  set.seed(1863)
  expect_snapshot_warning(
    mod <- fit_ctb(mpg ~ ., mtcars, final_ctr_computation_mode = "Default")
  )
  expect_equal(mod$arguments$final_ctr_computation_mode, "Skip")
})

test_that("min_n is ignored with a warning", {
  set.seed(4726)
  expect_snapshot_warning(
    mod <- fit_ctb(mpg ~ ., mtcars, min_n = 10)
  )
  expect_null(mod$arguments$min_n)
})

test_that("unknown options error before fitting", {
  expect_snapshot(
    rule_fit_ctb(mpg ~ ., data = mtcars, fooo = 1),
    error = TRUE
  )
})

test_that("factor predictors get separated indicator names", {
  penguins <- penguins_complete()
  set.seed(2817)
  mod <- fit_ctb(body_mass_g ~ ., penguins)

  ptype <- mod$training$ptype
  expect_identical(nrow(ptype), 0L)
  expect_s3_class(ptype$island, "factor")
  expect_identical(levels(ptype$island), levels(penguins$island))
  expect_all_true(grepl("^rule_", mod$rules$label))

  train_mat <- make_rule_matrix(penguins[, -6], mod$rules, ptype)
  expect_all_true(
    c("species_Gentoo", "island_Dream", "sex_male") %in% colnames(train_mat)
  )

  # a single row with one level of each factor
  new_data <- penguins[1, -6]
  expect_identical(nrow(predict(mod, new_data)), 1L)
  res <- multi_predict(mod, new_data, penalty = c(0.01, 0.1))
  expect_identical(nrow(res$.pred[[1]]), 2L)
})

# ------------------------------------------------------------------------------
# Interfaces

test_that("the default method errors for unsupported inputs", {
  expect_snapshot(rule_fit_ctb(1:3), error = TRUE)
  expect_snapshot(rule_fit_ctb(letters), error = TRUE)
  expect_snapshot(rule_fit_ctb(list(a = 1)), error = TRUE)
  expect_snapshot(rule_fit_ctb(NULL), error = TRUE)
})

test_that("data frame, matrix, formula, and recipe interfaces agree", {
  expect_interfaces_agree("ctb")
})

test_that("an outcome given as a data frame or matrix", {
  set.seed(3270)
  vec_mod <- fit_engine("ctb", mtcars[, -1], mtcars$mpg)
  set.seed(3270)
  df_mod <- fit_engine("ctb", mtcars[, -1], mtcars[, "mpg", drop = FALSE])
  set.seed(3270)
  mat_mod <- fit_engine(
    "ctb",
    mtcars[, -1],
    as.matrix(mtcars[, "mpg", drop = FALSE])
  )
  expected <- predict(vec_mod, mtcars[1:3, -1])
  expect_equal(predict(df_mod, mtcars[1:3, -1]), expected)
  expect_equal(predict(mat_mod, mtcars[1:3, -1]), expected)
})

test_that("a formula with a subset of predictors", {
  set.seed(9183)
  mod <- fit_engine("ctb", mpg ~ wt + hp, data = mtcars)
  expect_named(mod$training$ptype, c("wt", "hp"))
  expect_null(mod$training$one_hot)
  # extra columns in new data are ignored
  expect_identical(nrow(predict(mod, mtcars[1:2, ])), 2L)
})

test_that("a single predictor", {
  set.seed(7461)
  mod <- fit_engine("ctb", mpg ~ wt, data = mtcars)
  expect_named(mod$training$ptype, "wt")
  expect_identical(nrow(predict(mod, mtcars[1:5, ])), 5L)
})

# ------------------------------------------------------------------------------
# Outcomes and arguments

test_that("regression, binary, and multiclass outcomes", {
  expect_outcome_types("ctb")
})

test_that("default and main arguments are recorded", {
  set.seed(2604)
  mod <- fit_engine("ctb", mpg ~ ., data = mtcars)
  expect_default_arguments(mod, min_n = FALSE)
  expect_null(mod$arguments$min_n)

  set.seed(2604)
  mod <- rule_fit_ctb(
    mpg ~ .,
    data = mtcars,
    trees = 4,
    mtry = 0.5,
    learn_rate = 0.1,
    tree_depth = 3,
    penalty = 0.05,
    mixture = 0.25,
    logging_level = "Silent",
    allow_writing_files = FALSE
  )
  expect_equal(
    mod$arguments[c(
      "trees",
      "mtry",
      "learn_rate",
      "tree_depth",
      "penalty",
      "mixture"
    )],
    list(
      trees = 4,
      mtry = 0.5,
      learn_rate = 0.1,
      tree_depth = 3,
      penalty = 0.05,
      mixture = 0.25
    )
  )
  expect_equal(rlang::eval_tidy(mod$fit$spec$args$penalty), 0.05)
  expect_equal(rlang::eval_tidy(mod$fit$spec$args$mixture), 0.25)
})

test_that("an explicit 'Skip' for final_ctr_computation_mode is silent", {
  set.seed(4157)
  expect_no_warning(
    mod <- fit_ctb(mpg ~ ., mtcars, final_ctr_computation_mode = "Skip")
  )
  expect_equal(mod$arguments$final_ctr_computation_mode, "Skip")
})

test_that("min_n is ignored with other engine arguments", {
  set.seed(8320)
  expect_snapshot_warning(
    mod <- fit_ctb(mpg ~ ., mtcars, min_n = 3, l2_leaf_reg = 2, thresh = 1e-5)
  )
  expect_null(mod$arguments$min_n)
  expect_equal(mod$arguments$l2_leaf_reg, 2)
  expect_equal(mod$arguments$thresh, 1e-5)
})

test_that("protected and duplicated arguments error before fitting", {
  expect_snapshot(
    rule_fit_ctb(mpg ~ ., data = mtcars, iterations = 10),
    error = TRUE
  )
  expect_snapshot(
    rule_fit_ctb(mpg ~ ., data = mtcars, lambda = 1, alpha = 0.5),
    error = TRUE
  )
})

test_that("rules use the column names of the predictors", {
  set.seed(6927)
  mod <- fit_engine("ctb", mpg ~ ., data = mtcars)
  rule_text <- vapply(mod$rules$rules, rlang::expr_text, character(1))
  used <- unique(unlist(lapply(mod$rules$rules, all.vars)))
  expect_all_true(used %in% names(mtcars)[-1])
  expect_length(rule_text, nrow(mod$rules))
  expect_false(anyDuplicated(mod$rules$label) > 0)
})
