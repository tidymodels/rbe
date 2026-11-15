# check_weights() errors for the wrong type

    Code
      check_weights(letters[1:3], 3)
    Condition
      Error:
      ! `weights` must be a numeric vector, not a character vector.
      i Use a numeric vector or one created by `hardhat::importance_weights()` or `hardhat::frequency_weights()`.

---

    Code
      check_weights(factor(1:3), 3)
    Condition
      Error:
      ! `weights` must be a numeric vector, not a <factor> object.
      i Use a numeric vector or one created by `hardhat::importance_weights()` or `hardhat::frequency_weights()`.

---

    Code
      check_weights(c(TRUE, FALSE, TRUE), 3)
    Condition
      Error:
      ! `weights` must be a numeric vector, not a logical vector.
      i Use a numeric vector or one created by `hardhat::importance_weights()` or `hardhat::frequency_weights()`.

---

    Code
      check_weights(data.frame(w = 1:3), 3)
    Condition
      Error:
      ! `weights` must be a numeric vector, not a data frame.
      i Use a numeric vector or one created by `hardhat::importance_weights()` or `hardhat::frequency_weights()`.

---

    Code
      check_weights(list(1, 2, 3), 3)
    Condition
      Error:
      ! `weights` must be a numeric vector, not a list.
      i Use a numeric vector or one created by `hardhat::importance_weights()` or `hardhat::frequency_weights()`.

---

    Code
      check_weights(Sys.Date() + 0:2, 3)
    Condition
      Error:
      ! `weights` must be a numeric vector, not a <Date> object.
      i Use a numeric vector or one created by `hardhat::importance_weights()` or `hardhat::frequency_weights()`.

---

    Code
      check_weights(matrix(1:3, ncol = 1), 3)
    Condition
      Error:
      ! `weights` must be a numeric vector, not an integer matrix.
      i Use a numeric vector or one created by `hardhat::importance_weights()` or `hardhat::frequency_weights()`.

# check_weights() errors for the wrong length

    Code
      check_weights(1:2, 3)
    Condition
      Error:
      ! `weights` must have 3 values (one per row), not 2.

---

    Code
      check_weights(1:4, 3)
    Condition
      Error:
      ! `weights` must have 3 values (one per row), not 4.

---

    Code
      check_weights(numeric(0), 1)
    Condition
      Error:
      ! `weights` must have 1 value (one per row), not 0.

---

    Code
      check_weights(1, 3)
    Condition
      Error:
      ! `weights` must have 3 values (one per row), not 1.

# check_weights() errors for invalid values

    Code
      check_weights(c(1, NA, 2), 3)
    Condition
      Error:
      ! `weights` cannot have missing values.

---

    Code
      check_weights(c(1, NaN, 2), 3)
    Condition
      Error:
      ! `weights` cannot have missing values.

---

    Code
      check_weights(c(1, NA_integer_, 2L), 3)
    Condition
      Error:
      ! `weights` cannot have missing values.

---

    Code
      check_weights(c(1, Inf, 2), 3)
    Condition
      Error:
      ! `weights` must be finite.

---

    Code
      check_weights(c(1, -Inf, 2), 3)
    Condition
      Error:
      ! `weights` must be finite.

---

    Code
      check_weights(c(1, -0.5, 2), 3)
    Condition
      Error:
      ! `weights` cannot be negative.

---

    Code
      check_weights(c(0, 0, 0), 3)
    Condition
      Error:
      ! At least one value of `weights` must be positive.

---

    Code
      check_weights(hardhat::frequency_weights(c(0L, 0L)), 2)
    Condition
      Error:
      ! At least one value of `weights` must be positive.

# check_no_weight_predictors() finds case weights columns

    Code
      check_no_weight_predictors(dat)
    Condition
      Error:
      ! Case weights column `case_wts` cannot be used as a predictor.
      i Remove it from the predictors and pass the weights to `weights`, or use a recipe.

---

    Code
      check_no_weight_predictors(dat)
    Condition
      Error:
      ! Case weights columns `case_wts` and `freq` cannot be used as predictors.
      i Remove them from the predictors and pass the weights to `weights`, or use a recipe.

# check_formula_weights() finds case weights predictors

    Code
      check_formula_weights(mpg ~ ., dat)
    Condition
      Error:
      ! Case weights column `case_wts` cannot be used as a predictor.
      i Remove it from the predictors and pass the weights to `weights`, or use a recipe.

---

    Code
      check_formula_weights(mpg ~ cyl + case_wts, dat)
    Condition
      Error:
      ! Case weights column `case_wts` cannot be used as a predictor.
      i Remove it from the predictors and pass the weights to `weights`, or use a recipe.

---

    Code
      check_formula_weights(mpg ~ log(case_wts) + cyl, dat)
    Condition
      Error:
      ! Case weights column `case_wts` cannot be used as a predictor.
      i Remove it from the predictors and pass the weights to `weights`, or use a recipe.

# check_recipe_dots() errors when weights are passed

    Code
      check_recipe_dots(list(weights = 1:3))
    Condition
      Error:
      ! `weights` cannot be used with a recipe.
      i Add the case weights as a column of `data`; recipes give columns made by `hardhat::importance_weights()` or `hardhat::frequency_weights()` the "case_weights" role.

---

    Code
      check_recipe_dots(list(weight = 1:3))
    Condition
      Error:
      ! `weight` cannot be used with a recipe.
      i Add the case weights as a column of `data`; recipes give columns made by `hardhat::importance_weights()` or `hardhat::frequency_weights()` the "case_weights" role.

---

    Code
      check_recipe_dots(list(weights = 1:3, weight = 1:3))
    Condition
      Error:
      ! `weights` and `weight` cannot be used with a recipe.
      i Add the case weights as a column of `data`; recipes give columns made by `hardhat::importance_weights()` or `hardhat::frequency_weights()` the "case_weights" role.

