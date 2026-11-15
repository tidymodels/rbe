skip_if_not_installed("lightgbm")
skip_if_not_installed("modeldata")

test_that("options are passed to lightgbm and glmnet", {
  set.seed(3591)
  mod <- rule_fit_lgb(
    class ~ .,
    data = hpc_subset(),
    trees = 5,
    num_leaves = 4,
    quiet = TRUE,
    thresh = 1e-6
  )
  expect_named(mod$fit$spec$eng_args, "thresh")
  expect_equal(mod$arguments$num_leaves, 4)
  expect_true(mod$arguments$quiet)
})

test_that("quiet and counts have rulefit defaults", {
  set.seed(6427)
  mod <- rule_fit_lgb(class ~ ., data = hpc_subset(), trees = 5, mtry = 0.5)
  expect_true(mod$arguments$quiet)
  expect_false(mod$arguments$counts)
  expect_equal(mod$arguments$min_n, 5)
})

test_that("small data sets can be split with the default min_n", {
  # lightgbm's own default of 20 cannot split 32 rows, so no rules are made
  set.seed(2394)
  mod <- rule_fit_lgb(mpg ~ ., data = mtcars, trees = 5)
  expect_gt(nrow(mod$rules), 0)
})

test_that("min_n is passed to lightgbm", {
  set.seed(5861)
  mod <- rule_fit_lgb(class ~ ., data = hpc_subset(), trees = 5, min_n = 12)
  expect_equal(mod$arguments$min_n, 12)
  expect_snapshot(
    rule_fit_lgb(class ~ ., data = hpc_subset(), min_data_in_leaf = 12),
    error = TRUE
  )
})

test_that("counts can be changed", {
  set.seed(8150)
  mod <- rule_fit_lgb(
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
  mod <- rule_fit_lgb(body_mass_g ~ ., data = penguins, trees = 5)

  ptype <- mod$training$ptype
  expect_s3_class(ptype$island, "factor")
  train_mat <- make_rule_matrix(penguins[, -6], mod$rules, ptype)
  expect_all_true(
    c("species_Gentoo", "island_Dream", "sex_male") %in% colnames(train_mat)
  )
  expect_identical(nrow(predict(mod, penguins[1, -6])), 1L)
})
