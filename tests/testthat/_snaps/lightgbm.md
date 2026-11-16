# min_n is passed to lightgbm

    Code
      rule_ensemble_lgb(class ~ ., data = hpc_subset(), min_data_in_leaf = 12)
    Condition
      Error in `rule_ensemble_lgb()`:
      ! This argument cannot be passed to `...`:
      * Use `min_n` instead of `min_data_in_leaf`.

# the default method errors for unsupported inputs

    Code
      rule_ensemble_lgb(1:3)
    Condition
      Error in `rule_ensemble_lgb()`:
      ! `rule_ensemble_lgb()` is not defined for an integer vector.
      i `x` should be a data frame, matrix, formula, or recipe.

---

    Code
      rule_ensemble_lgb(letters)
    Condition
      Error in `rule_ensemble_lgb()`:
      ! `rule_ensemble_lgb()` is not defined for a character vector.
      i `x` should be a data frame, matrix, formula, or recipe.

---

    Code
      rule_ensemble_lgb(list(a = 1))
    Condition
      Error in `rule_ensemble_lgb()`:
      ! `rule_ensemble_lgb()` is not defined for a list.
      i `x` should be a data frame, matrix, formula, or recipe.

---

    Code
      rule_ensemble_lgb(NULL)
    Condition
      Error in `rule_ensemble_lgb()`:
      ! `rule_ensemble_lgb()` is not defined for NULL.
      i `x` should be a data frame, matrix, formula, or recipe.

# protected arguments and aliases error before fitting

    Code
      rule_ensemble_lgb(mpg ~ ., data = mtcars, num_trees = 10, eta = 0.1)
    Condition
      Error in `rule_ensemble_lgb()`:
      ! These arguments cannot be passed to `...`:
      * Use `trees` instead of `num_trees`.
      * Use `learn_rate` instead of `eta`.

---

    Code
      rule_ensemble_lgb(mpg ~ ., data = mtcars, subsample = 0.5)
    Condition
      Error in `rule_ensemble_lgb()`:
      ! This argument cannot be passed to `...`:
      * Use `bagging_fraction` instead of `subsample`.

---

    Code
      rule_ensemble_lgb(mpg ~ ., data = mtcars, callbacks = list())
    Condition
      Error in `rule_ensemble_lgb()`:
      ! This argument cannot be passed to `...`:
      * `callbacks` is set by rbe.

---

    Code
      rule_ensemble_lgb(mpg ~ ., data = mtcars, num_leavs = 4)
    Condition
      Error in `rule_ensemble_lgb()`:
      ! `num_leavs` is not a valid argument for lightgbm or `glmnet::glmnet()`.
      i Did you mean `num_leaves` instead of `num_leavs`?

# lightgbm's weight argument points to weights

    Code
      split_dots(list(weight = 1), "lgb")
    Condition
      Error:
      ! This argument cannot be passed to `...`:
      * Use `weights` instead of `weight`.

---

    Code
      rule_ensemble_lgb(rec, data = mtcars, weight = mtcars_weights())
    Condition
      Error in `rule_ensemble_lgb()`:
      ! `weight` cannot be used with a recipe.
      i Add the case weights as a column of `data`; recipes give columns made by `hardhat::importance_weights()` or `hardhat::frequency_weights()` the "case_weights" role.

# weight does not partially match weights

    Code
      rule_ensemble_lgb(mpg ~ ., data = mtcars, weight = mtcars_weights())
    Condition
      Error in `rule_ensemble_lgb()`:
      ! This argument cannot be passed to `...`:
      * Use `weights` instead of `weight`.

