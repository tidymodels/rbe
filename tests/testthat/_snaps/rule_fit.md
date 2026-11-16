# unsupported `x` uses the engine's error

    Code
      rule_fit(letters, method = engine_method[[engine]])
    Condition
      Error in `rule_fit_ctb()`:
      ! `rule_fit_ctb()` is not defined for a character vector.
      i `x` should be a data frame, matrix, formula, or recipe.

---

    Code
      rule_fit(letters, method = engine_method[[engine]])
    Condition
      Error in `rule_fit_lgb()`:
      ! `rule_fit_lgb()` is not defined for a character vector.
      i `x` should be a data frame, matrix, formula, or recipe.

---

    Code
      rule_fit(letters, method = engine_method[[engine]])
    Condition
      Error in `rule_fit_xgb()`:
      ! `rule_fit_xgb()` is not defined for a character vector.
      i `x` should be a data frame, matrix, formula, or recipe.

# catboost warns about a min_n that is given

    `min_n` is not used by `rule_fit_ctb()` and was ignored.
    i catboost's default "SymmetricTree" grow policy does not use a minimum node size.
    i To set one, pass `min_data_in_leaf` along with `grow_policy = "Depthwise"` or `grow_policy = "Lossguide"`.

# catboost warns about a given min_n equal to the default

    `min_n` is not used by `rule_fit_ctb()` and was ignored.
    i catboost's default "SymmetricTree" grow policy does not use a minimum node size.
    i To set one, pass `min_data_in_leaf` along with `grow_policy = "Depthwise"` or `grow_policy = "Lossguide"`.

# catboost warns about min_n with other options

    `min_n` is not used by `rule_fit_ctb()` and was ignored.
    i catboost's default "SymmetricTree" grow policy does not use a minimum node size.
    i To set one, pass `min_data_in_leaf` along with `grow_policy = "Depthwise"` or `grow_policy = "Lossguide"`.

# an option for one engine is an error for another

    Code
      rule_fit(mpg ~ ., data = mtcars, method = "xgboost", l2_leaf_reg = 2)
    Condition
      Error in `rule_fit_xgb()`:
      ! `l2_leaf_reg` is not a valid argument for xgboost or `glmnet::glmnet()`.

# unknown options are errors

    Code
      rule_fit(mpg ~ ., data = mtcars, method = engine_method[[engine]], fooo = 1)
    Condition
      Error in `rule_fit_ctb()`:
      ! `fooo` is not a valid argument for catboost or `glmnet::glmnet()`.

---

    Code
      rule_fit(mpg ~ ., data = mtcars, method = engine_method[[engine]], fooo = 1)
    Condition
      Error in `rule_fit_lgb()`:
      ! `fooo` is not a valid argument for lightgbm or `glmnet::glmnet()`.

---

    Code
      rule_fit(mpg ~ ., data = mtcars, method = engine_method[[engine]], fooo = 1)
    Condition
      Error in `rule_fit_xgb()`:
      ! `fooo` is not a valid argument for xgboost or `glmnet::glmnet()`.

# protected options are errors

    Code
      rlang::exec(rule_fit, mpg ~ ., data = mtcars, method = engine_method[[engine]],
      !!!protected[[engine]])
    Condition
      Error in `rule_fit_ctb()`:
      ! This argument cannot be passed to `...`:
      * Use `trees` instead of `iterations`.

---

    Code
      rlang::exec(rule_fit, mpg ~ ., data = mtcars, method = engine_method[[engine]],
      !!!protected[[engine]])
    Condition
      Error in `rule_fit_lgb()`:
      ! This argument cannot be passed to `...`:
      * Use `trees` instead of `num_iterations`.

---

    Code
      rlang::exec(rule_fit, mpg ~ ., data = mtcars, method = engine_method[[engine]],
      !!!protected[[engine]])
    Condition
      Error in `rule_fit_xgb()`:
      ! This argument cannot be passed to `...`:
      * Use `trees` instead of `nrounds`.

# main arguments cannot also be given in `...` by engine name

    Code
      rule_fit(mpg ~ ., data = mtcars, eta = 0.1)
    Condition
      Error in `rule_fit_xgb()`:
      ! This argument cannot be passed to `...`:
      * Use `learn_rate` instead of `eta`.

# `weights` cannot be used with a recipe

    Code
      rule_fit(rec, data = mtcars, weights = mtcars_weights())
    Condition
      Error in `rule_fit_xgb()`:
      ! `weights` cannot be used with a recipe.
      i Add the case weights as a column of `data`; recipes give columns made by `hardhat::importance_weights()` or `hardhat::frequency_weights()` the "case_weights" role.

# `method` must be one of the supported values

    Code
      rule_fit(mpg ~ ., data = mtcars, method = "ranger")
    Condition
      Error in `rule_fit()`:
      ! `method` must be one of "xgboost", "lightgbm", or "catboost", not "ranger".

---

    Code
      rule_fit(mpg ~ ., data = mtcars, method = "xgb")
    Condition
      Error in `rule_fit()`:
      ! `method` must be one of "xgboost", "lightgbm", or "catboost", not "xgb".
      i Did you mean "xgboost"?

---

    Code
      rule_fit(mpg ~ ., data = mtcars, method = "XGBoost")
    Condition
      Error in `rule_fit()`:
      ! `method` must be one of "xgboost", "lightgbm", or "catboost", not "XGBoost".
      i Did you mean "xgboost"?

---

    Code
      rule_fit(mpg ~ ., data = mtcars, method = "")
    Condition
      Error in `rule_fit()`:
      ! `method` must be one of "xgboost", "lightgbm", or "catboost", not "".

# `method` must be a single string

    Code
      rule_fit(mpg ~ ., data = mtcars, method = NA)
    Condition
      Error in `rule_fit()`:
      ! `method` must be a character vector, not `NA`.

---

    Code
      rule_fit(mpg ~ ., data = mtcars, method = NA_character_)
    Condition
      Error in `rule_fit()`:
      ! `method` must be a single string, not a character `NA`.

---

    Code
      rule_fit(mpg ~ ., data = mtcars, method = NULL)
    Condition
      Error in `rule_fit()`:
      ! `method` must be a character vector, not `NULL`.

---

    Code
      rule_fit(mpg ~ ., data = mtcars, method = 1)
    Condition
      Error in `rule_fit()`:
      ! `method` must be a character vector, not the number 1.

---

    Code
      rule_fit(mpg ~ ., data = mtcars, method = c("xgboost", "lightgbm"))
    Condition
      Error in `rule_fit()`:
      ! `method` must be a single string, not a character vector of length 2.

---

    Code
      rule_fit(mpg ~ ., data = mtcars, method = character())
    Condition
      Error in `rule_fit()`:
      ! `method` must be length 1, not length 0

