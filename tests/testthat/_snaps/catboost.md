# min_n is ignored with a warning when verbose

    `min_n` is not used by `rule_ensemble_ctb()` and was ignored.
    i catboost's default "SymmetricTree" grow policy does not use a minimum node size.
    i To set one, pass `min_data_in_leaf` along with `grow_policy = "Depthwise"` or `grow_policy = "Lossguide"`.

# unknown options error before fitting

    Code
      rule_ensemble_ctb(mpg ~ ., data = mtcars, fooo = 1)
    Condition
      Error in `rule_ensemble_ctb()`:
      ! `fooo` is not a valid argument for catboost or `glmnet::glmnet()`.

# the default method errors for unsupported inputs

    Code
      rule_ensemble_ctb(1:3)
    Condition
      Error in `rule_ensemble_ctb()`:
      ! `rule_ensemble_ctb()` is not defined for an integer vector.
      i `x` should be a data frame, matrix, formula, or recipe.

---

    Code
      rule_ensemble_ctb(letters)
    Condition
      Error in `rule_ensemble_ctb()`:
      ! `rule_ensemble_ctb()` is not defined for a character vector.
      i `x` should be a data frame, matrix, formula, or recipe.

---

    Code
      rule_ensemble_ctb(list(a = 1))
    Condition
      Error in `rule_ensemble_ctb()`:
      ! `rule_ensemble_ctb()` is not defined for a list.
      i `x` should be a data frame, matrix, formula, or recipe.

---

    Code
      rule_ensemble_ctb(NULL)
    Condition
      Error in `rule_ensemble_ctb()`:
      ! `rule_ensemble_ctb()` is not defined for NULL.
      i `x` should be a data frame, matrix, formula, or recipe.

# min_n is ignored with other engine arguments

    `min_n` is not used by `rule_ensemble_ctb()` and was ignored.
    i catboost's default "SymmetricTree" grow policy does not use a minimum node size.
    i To set one, pass `min_data_in_leaf` along with `grow_policy = "Depthwise"` or `grow_policy = "Lossguide"`.

# protected and duplicated arguments error before fitting

    Code
      rule_ensemble_ctb(mpg ~ ., data = mtcars, iterations = 10)
    Condition
      Error in `rule_ensemble_ctb()`:
      ! This argument cannot be passed to `...`:
      * Use `trees` instead of `iterations`.

---

    Code
      rule_ensemble_ctb(mpg ~ ., data = mtcars, lambda = 1, alpha = 0.5)
    Condition
      Error in `rule_ensemble_ctb()`:
      ! These arguments cannot be passed to `...`:
      * Use `penalty` instead of `lambda`.
      * Use `mixture` instead of `alpha`.

