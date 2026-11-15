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
