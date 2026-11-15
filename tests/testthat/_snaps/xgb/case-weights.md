# invalid weights error before fitting

    Code
      fit_engine(engine, mpg ~ ., data = mtcars, weights = 1:3)
    Condition
      Error in `rule_fit_xgb()`:
      ! `weights` must have 32 values (one per row), not 3.

---

    Code
      fit_engine(engine, mtcars[, -1], mtcars$mpg, weights = "a")
    Condition
      Error in `rule_fit_xgb()`:
      ! `weights` must be a numeric vector, not a string.
      i Use a numeric vector or one created by `hardhat::importance_weights()` or `hardhat::frequency_weights()`.

---

    Code
      fit_engine(engine, as.matrix(mtcars[, -1]), mtcars$mpg, weights = -
      mtcars_weights())
    Condition
      Error in `rule_fit_xgb()`:
      ! `weights` cannot be negative.

# a case weights column cannot be a predictor

    Code
      fit_engine(engine, mpg ~ ., data = dat)
    Condition
      Error in `rule_fit_xgb()`:
      ! Case weights column `case_wts` cannot be used as a predictor.
      i Remove it from the predictors and pass the weights to `weights`, or use a recipe.

---

    Code
      fit_engine(engine, dat[, -1], dat$mpg)
    Condition
      Error in `rule_fit_xgb()`:
      ! Case weights column `case_wts` cannot be used as a predictor.
      i Remove it from the predictors and pass the weights to `weights`, or use a recipe.

# weights cannot be passed to the recipe method

    Code
      fit_engine(engine, rec, data = mtcars, weights = mtcars_weights())
    Condition
      Error in `rule_fit_xgb()`:
      ! `weights` cannot be used with a recipe.
      i Add the case weights as a column of `data`; recipes give columns made by `hardhat::importance_weights()` or `hardhat::frequency_weights()` the "case_weights" role.

