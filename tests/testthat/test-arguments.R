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
    list(num_leaves = 7, standardize = FALSE, alpha = 0.5, counts = TRUE),
    "lgb"
  )
  expect_equal(res$boost, list(num_leaves = 7, alpha = 0.5, counts = TRUE))
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

# ------------------------------------------------------------------------------
# split_dots() edge cases

test_that("split_dots() errors with an unknown engine", {
  expect_snapshot(split_dots(list(), "gbm"), error = TRUE)
})

test_that("split_dots() errors when all arguments are unnamed", {
  expect_snapshot(split_dots(list(1, 2), "ctb"), error = TRUE)
})

test_that("split_dots() reports each duplicated name once", {
  expect_snapshot(
    split_dots(list(a = 1, b = 2, a = 3, b = 4, a = 5), "ctb"),
    error = TRUE
  )
})

test_that("split_dots() keeps the order of the arguments", {
  res <- split_dots(
    list(thresh = 1e-4, verbose = 0, maxit = 50, l2_leaf_reg = 1),
    "ctb"
  )
  expect_named(res$boost, c("verbose", "l2_leaf_reg"))
  expect_named(res$glmnet, c("thresh", "maxit"))
})

test_that("split_dots() with only glmnet or only boosting arguments", {
  res <- split_dots(list(intercept = FALSE), "ctb")
  expect_length(res$boost, 0)
  expect_equal(res$glmnet, list(intercept = FALSE))

  res <- split_dots(list(random_seed = 1), "ctb")
  expect_equal(res$boost, list(random_seed = 1))
  expect_length(res$glmnet, 0)
})

test_that("split_dots() keeps NULL and vector values", {
  res <- split_dots(
    list(custom_metric = c("RMSE", "MAE"), exclude = NULL),
    "ctb"
  )
  expect_equal(res$boost, list(custom_metric = c("RMSE", "MAE")))
  expect_named(res$glmnet, "exclude")
  expect_null(res$glmnet$exclude)
})

test_that("protected arguments set by rbe and renamed ones together", {
  expect_snapshot(
    split_dots(list(formula = 1, data = 2, iterations = 3), "ctb"),
    error = TRUE
  )
})

test_that("protected arguments are reported before unknown arguments", {
  expect_snapshot(split_dots(list(depth = 2, fooo = 1), "ctb"), error = TRUE)
})

test_that("unknown arguments with and without suggestions", {
  expect_snapshot(
    split_dots(list(stndardize = TRUE, zz = 1, nlambdaa = 5), "ctb"),
    error = TRUE
  )
})

test_that("the error call is the caller", {
  wrapper <- function(...) {
    split_dots(list(...), "ctb")
  }
  expect_snapshot(wrapper(fooo = 1), error = TRUE)
})

# ------------------------------------------------------------------------------
# Name helpers

test_that("engine_label()", {
  expect_identical(engine_label("xgb"), "xgboost")
  expect_identical(engine_label("lgb"), "lightgbm")
  expect_identical(engine_label("ctb"), "catboost")
})

test_that("suggest_names() finds close matches", {
  res <- suggest_names("l2_leaf_rg", c("l2_leaf_reg", "depth"))
  expect_named(res, "i")
  expect_match(res, "l2_leaf_reg", fixed = TRUE)
})

test_that("suggest_names() returns nothing without a close match", {
  expect_identical(suggest_names("zzzzzz", c("abc", "def")), character(0))
  expect_identical(suggest_names(character(0), c("abc")), character(0))
})

test_that("suggest_names() is stricter for short names", {
  # one edit is allowed for names with up to three characters
  expect_length(suggest_names("ab", "abc"), 1)
  expect_length(suggest_names("ab", "abcd"), 0)
  expect_length(suggest_names("a", "b"), 1)
  # at most two edits for long names
  expect_length(suggest_names("standardizexx", "standardize"), 1)
  expect_length(suggest_names("standardizexxx", "standardize"), 0)
})

test_that("suggest_names() picks the closest candidate and drops duplicates", {
  res <- suggest_names("thresx", c("thres", "thresh", "thresh"))
  expect_length(res, 1)
  res <- suggest_names(c("maxitt", "thrsh"), c("maxit", "thresh"))
  expect_length(res, 2)
  expect_match(res[[1]], "maxit", fixed = TRUE)
  expect_match(res[[2]], "thresh", fixed = TRUE)
})

test_that("glmnet_arg_names() excludes arguments set by rbe", {
  res <- glmnet_arg_names()
  excl <- c("x", "y", "family", "weights", "offset", "alpha", "lambda", "...")
  expect_length(intersect(res, excl), 0)
  expect_all_true(c("standardize", "thresh", "maxit", "intercept") %in% res)
})

test_that("glmnet_arg_names() includes parsnip's `path_values`", {
  expect_true("path_values" %in% glmnet_arg_names())
  expect_false(anyDuplicated(glmnet_arg_names()) > 0)
})

test_that("split_dots() routes `path_values` to glmnet", {
  for (engine in engines) {
    skip_if_no_engine(engine)
    res <- split_dots(list(path_values = 10^(-4:-1)), engine)
    expect_named(res$glmnet, "path_values")
    expect_length(res$boost, 0)
  }
})

test_that("boost_arg_names() never includes dots", {
  for (engine in engines) {
    skip_if_no_engine(engine)
    res <- boost_arg_names(engine)
    expect_false("..." %in% res)
    expect_false(anyDuplicated(res) > 0)
  }
})

test_that("boost_arg_names() includes lightgbm parameter aliases", {
  skip_if_not_installed("lightgbm")
  res <- boost_arg_names("lgb")
  expect_all_true(c("num_leaves", "max_leaves", "quiet", "counts") %in% res)
})

# ------------------------------------------------------------------------------
# Protected arguments

test_that("protected argument tables have unique names", {
  for (engine in engines) {
    skip_if_no_engine(engine)
    prot <- protected_args(engine)
    expect_named(prot, c("name", "use"))
    expect_false(anyDuplicated(prot$name) > 0)
    expect_all_true(c("x", "y", "data", "weights", "formula") %in% prot$name)
  }
})

test_that("main argument aliases point to rbe arguments", {
  skip_if_not_installed("lightgbm")
  lgb <- protected_args("lgb")
  expect_identical(lgb$use[lgb$name == "num_trees"], "trees")
  expect_identical(lgb$use[lgb$name == "min_child_samples"], "min_n")

  ctb <- protected_args("ctb")
  expect_identical(ctb$use[ctb$name == "n_estimators"], "trees")
  expect_identical(ctb$use[ctb$name == "reg_lambda"], "l2_leaf_reg")
})

test_that("bonsai's `quiet` points to `verbose`", {
  for (engine in c("ctb", "lgb")) {
    skip_if_no_engine(engine)
    prot <- protected_args(engine)
    expect_identical(prot$use[prot$name == "quiet"], "verbose")
  }
  skip_if_no_engine("xgb")
  expect_false("quiet" %in% protected_args("xgb")$name)
})

test_that("bonsai_alias_table() prefers rbe's argument names", {
  aliases <- data.frame(
    parsnip = c("trees", "sample_size"),
    alias = c("n_trees", "sub_row"),
    lightgbm = c("num_iterations", "bagging_fraction")
  )
  res <- bonsai_alias_table(aliases, "lightgbm", "trees")
  expect_identical(res$name, c("n_trees", "sub_row"))
  expect_identical(res$use, c("trees", "bagging_fraction"))
})

test_that("check_protected_args() is silent without protected arguments", {
  expect_null(check_protected_args(c("verbose", "thresh"), "ctb"))
  expect_null(check_protected_args(character(0), "ctb"))
})

# ------------------------------------------------------------------------------
# catboost helpers

test_that("drop_ctb_min_n() leaves other arguments alone", {
  dots <- list(l2_leaf_reg = 2, thresh = 1e-4)
  expect_identical(drop_ctb_min_n(dots), dots)
  expect_identical(drop_ctb_min_n(dots, verbose = TRUE), dots)
  expect_identical(drop_ctb_min_n(list()), list())
  expect_identical(drop_ctb_min_n(list(), verbose = TRUE), list())
})

test_that("drop_ctb_min_n() removes min_n silently by default", {
  expect_no_warning(res <- drop_ctb_min_n(list(min_n = 2, l2_leaf_reg = 2)))
  expect_identical(res, list(l2_leaf_reg = 2))
  expect_no_warning(res <- drop_ctb_min_n(list(min_n = 2)))
  expect_length(res, 0)
  expect_no_warning(res <- drop_ctb_min_n(list(min_n = 2), verbose = FALSE))
  expect_length(res, 0)
})

test_that("drop_ctb_min_n() warns about min_n when verbose", {
  expect_snapshot_warning(
    res <- drop_ctb_min_n(list(min_n = 2, l2_leaf_reg = 2), verbose = TRUE)
  )
  expect_identical(res, list(l2_leaf_reg = 2))
  expect_snapshot_warning(
    res <- drop_ctb_min_n(list(min_n = 2), verbose = TRUE)
  )
  expect_length(res, 0)
})

test_that("`path_values` sets the glmnet lambda sequence for each engine", {
  dat <- two_class_data()
  path <- 10^seq(-4, -1, length.out = 7)
  for (engine in engines) {
    res <- fit_engine(
      engine,
      Class ~ .,
      data = dat,
      path_values = path
    )
    expect_equal(res$fit$fit$lambda, rev(path))
    expect_equal(res$arguments$path_values, path)
    pred <- multi_predict(res, dat[1:3, ], penalty = path[2:3])
    expect_equal(nrow(pred), 3)
  }
})
