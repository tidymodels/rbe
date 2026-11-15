test_that("split_dots() with no arguments", {
  res <- split_dots(list(), "ctb")
  expect_named(res, c("boost", "glmnet"))
  expect_length(res$boost, 0)
  expect_length(res$glmnet, 0)
})

test_that("split_dots() routes catboost arguments", {
  res <- split_dots(
    list(standardize = FALSE, l2_leaf_reg = 5, thresh = 1e-5, verbose = 0),
    "ctb"
  )
  expect_equal(res$boost, list(l2_leaf_reg = 5, verbose = 0))
  expect_equal(res$glmnet, list(standardize = FALSE, thresh = 1e-5))
})

test_that("split_dots() routes lightgbm arguments", {
  skip_if_not_installed("lightgbm")

  res <- split_dots(
    list(num_leaves = 7, standardize = FALSE, alpha = 0.5, quiet = FALSE),
    "lgb"
  )
  expect_equal(res$boost, list(num_leaves = 7, alpha = 0.5, quiet = FALSE))
  expect_equal(res$glmnet, list(standardize = FALSE))
})

test_that("split_dots() routes xgboost arguments", {
  skip_if_not_installed("xgboost", minimum_version = "3.0.0")

  # `lambda` and `alpha` are xgboost parameters here, not glmnet's
  res <- split_dots(
    list(maxit = 1000, lambda = 2, gamma = 3, alpha = 1),
    "xgb"
  )
  expect_equal(res$boost, list(lambda = 2, gamma = 3, alpha = 1))
  expect_equal(res$glmnet, list(maxit = 1000))
})

test_that("glmnet arguments do not overlap with boosting arguments", {
  skip_if_not_installed("lightgbm")
  skip_if_not_installed("xgboost", minimum_version = "3.0.0")

  glmn <- glmnet_arg_names()
  expect_length(intersect(glmn, boost_arg_names("ctb")), 0)
  expect_length(intersect(glmn, boost_arg_names("lgb")), 0)
  expect_length(intersect(glmn, boost_arg_names("xgb")), 0)
})

test_that("all documented catboost parameters are accepted", {
  prot <- protected_args("ctb")$name
  ok <- setdiff(catboost_params$name, prot)
  args <- rlang::set_names(as.list(seq_along(ok)), ok)
  res <- split_dots(args, "ctb")
  expect_named(res$boost, ok)
  expect_length(res$glmnet, 0)
})

test_that("split_dots() errors with unnamed or duplicated arguments", {
  expect_snapshot(split_dots(list(1, a = 2), "ctb"), error = TRUE)
  expect_snapshot(split_dots(list(a = 1, a = 2), "ctb"), error = TRUE)
})

test_that("split_dots() errors with protected arguments", {
  skip_if_not_installed("lightgbm")
  skip_if_not_installed("xgboost", minimum_version = "3.0.0")

  expect_snapshot(
    split_dots(list(nrounds = 10, min_child_samples = 3), "lgb"),
    error = TRUE
  )
  expect_snapshot(
    split_dots(
      list(eta = 0.1, lambda = 1, od_wait = 3, reg_lambda = 2, x = 1),
      "ctb"
    ),
    error = TRUE
  )
  expect_snapshot(
    split_dots(
      list(max_depth = 2, min_child_weight = 1, params = list()),
      "xgb"
    ),
    error = TRUE
  )
})

test_that("split_dots() errors with unknown arguments", {
  skip_if_not_installed("lightgbm")
  skip_if_not_installed("xgboost", minimum_version = "3.0.0")

  expect_snapshot(split_dots(list(num_leavs = 1, foo = 2), "lgb"), error = TRUE)
  expect_snapshot(split_dots(list(standardise = TRUE), "xgb"), error = TRUE)
  expect_snapshot(split_dots(list(l2_leaf_rg = 3), "ctb"), error = TRUE)
})
