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
