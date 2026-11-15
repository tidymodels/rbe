# the default method errors for unsupported inputs

    Code
      rule_fit_xgb(1:3)
    Condition
      Error in `rule_fit_xgb()`:
      ! `rule_fit_xgb()` is not defined for an integer vector.
      i `x` should be a data frame, matrix, formula, or recipe.

---

    Code
      rule_fit_xgb(letters)
    Condition
      Error in `rule_fit_xgb()`:
      ! `rule_fit_xgb()` is not defined for a character vector.
      i `x` should be a data frame, matrix, formula, or recipe.

---

    Code
      rule_fit_xgb(list(a = 1))
    Condition
      Error in `rule_fit_xgb()`:
      ! `rule_fit_xgb()` is not defined for a list.
      i `x` should be a data frame, matrix, formula, or recipe.

---

    Code
      rule_fit_xgb(NULL)
    Condition
      Error in `rule_fit_xgb()`:
      ! `rule_fit_xgb()` is not defined for NULL.
      i `x` should be a data frame, matrix, formula, or recipe.

# protected arguments error before fitting

    Code
      rule_fit_xgb(mpg ~ ., data = mtcars, nrounds = 10, learning_rate = 0.1)
    Condition
      Error in `rule_fit_xgb()`:
      ! These arguments cannot be passed to `...`:
      * Use `trees` instead of `nrounds`.
      * Use `learn_rate` instead of `learning_rate`.

---

    Code
      rule_fit_xgb(mpg ~ ., data = mtcars, evals = list())
    Condition
      Error in `rule_fit_xgb()`:
      ! This argument cannot be passed to `...`:
      * `evals` is set by rulefit.

# new factor levels give missing predictions with a warning

    Novel level found in column "island": "Anvers".
    i The level has been removed, and values have been coerced to <NA>.

# a factor named like an indicator of another factor is an error

    Code
      rule_fit_xgb(y ~ ., data = dat, trees = 2)
    Condition
      Error in `one_hot()`:
      ! Converting factors to indicators creates duplicate column name "a_b".

