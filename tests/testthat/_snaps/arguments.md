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
      * `x` is set by rulefit.
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
      * `params` is set by rulefit.

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

