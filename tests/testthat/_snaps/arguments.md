# split_dots() errors with unnamed or duplicated arguments

    Code
      split_dots(list(1, a = 2), "ctb")
    Condition
      Error:
      ! All arguments passed to `...` must be named.

---

    Code
      split_dots(list(a = 1, a = 2), "ctb")
    Condition
      Error:
      ! Argument `a` was passed to `...` more than once.

# split_dots() errors with protected arguments

    Code
      split_dots(list(nrounds = 10, min_child_samples = 3), "lgb")
    Condition
      Error:
      ! These arguments cannot be passed to `...`:
      * Use `trees` instead of `nrounds`.
      * Use `min_n` instead of `min_child_samples`.

---

    Code
      split_dots(list(eta = 0.1, lambda = 1, od_wait = 3, reg_lambda = 2, x = 1),
      "ctb")
    Condition
      Error:
      ! These arguments cannot be passed to `...`:
      * `x` is set by rbe.
      * Use `penalty` instead of `lambda`.
      * Use `learn_rate` instead of `eta`.
      * Use `early_stopping_rounds` instead of `od_wait`.
      * Use `l2_leaf_reg` instead of `reg_lambda`.

---

    Code
      split_dots(list(max_depth = 2, min_child_weight = 1, params = list()), "xgb")
    Condition
      Error:
      ! These arguments cannot be passed to `...`:
      * Use `tree_depth` instead of `max_depth`.
      * Use `min_n` instead of `min_child_weight`.
      * `params` is set by rbe.

# split_dots() errors with unknown arguments

    Code
      split_dots(list(num_leavs = 1, foo = 2), "lgb")
    Condition
      Error:
      ! `num_leavs` and `foo` are not valid arguments for lightgbm or `glmnet::glmnet()`.
      i Did you mean `num_leaves` instead of `num_leavs`?

---

    Code
      split_dots(list(standardise = TRUE), "xgb")
    Condition
      Error:
      ! `standardise` is not a valid argument for xgboost or `glmnet::glmnet()`.
      i Did you mean `standardize` instead of `standardise`?

---

    Code
      split_dots(list(l2_leaf_rg = 3), "ctb")
    Condition
      Error:
      ! `l2_leaf_rg` is not a valid argument for catboost or `glmnet::glmnet()`.
      i Did you mean `l2_leaf_reg` instead of `l2_leaf_rg`?

# split_dots() errors with an unknown engine

    Code
      split_dots(list(), "gbm")
    Condition
      Error in `split_dots()`:
      ! `engine` must be one of "xgb", "lgb", or "ctb", not "gbm".

# split_dots() errors when all arguments are unnamed

    Code
      split_dots(list(1, 2), "ctb")
    Condition
      Error:
      ! All arguments passed to `...` must be named.

# split_dots() reports each duplicated name once

    Code
      split_dots(list(a = 1, b = 2, a = 3, b = 4, a = 5), "ctb")
    Condition
      Error:
      ! Arguments `a` and `b` were passed to `...` more than once.

# protected arguments set by rbe and renamed ones together

    Code
      split_dots(list(formula = 1, data = 2, iterations = 3), "ctb")
    Condition
      Error:
      ! These arguments cannot be passed to `...`:
      * `data` is set by rbe.
      * `formula` is set by rbe.
      * Use `trees` instead of `iterations`.

# protected arguments are reported before unknown arguments

    Code
      split_dots(list(depth = 2, fooo = 1), "ctb")
    Condition
      Error:
      ! This argument cannot be passed to `...`:
      * Use `tree_depth` instead of `depth`.

# unknown arguments with and without suggestions

    Code
      split_dots(list(stndardize = TRUE, zz = 1, nlambdaa = 5), "ctb")
    Condition
      Error:
      ! `stndardize`, `zz`, and `nlambdaa` are not valid arguments for catboost or `glmnet::glmnet()`.
      i Did you mean `standardize` instead of `stndardize`?
      i Did you mean `nlambda` instead of `nlambdaa`?

# the error call is the caller

    Code
      wrapper(fooo = 1)
    Condition
      Error in `wrapper()`:
      ! `fooo` is not a valid argument for catboost or `glmnet::glmnet()`.

# drop_ctb_min_n() warns about min_n when verbose

    `min_n` is not used by `rule_ensemble_ctb()` and was ignored.
    i catboost's default "SymmetricTree" grow policy does not use a minimum node size.
    i To set one, pass `min_data_in_leaf` along with `grow_policy = "Depthwise"` or `grow_policy = "Lossguide"`.

---

    `min_n` is not used by `rule_ensemble_ctb()` and was ignored.
    i catboost's default "SymmetricTree" grow policy does not use a minimum node size.
    i To set one, pass `min_data_in_leaf` along with `grow_policy = "Depthwise"` or `grow_policy = "Lossguide"`.

