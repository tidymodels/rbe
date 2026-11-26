# Model predictions across many sub-models

For RuleFit models,
[`multi_predict()`](https://parsnip.tidymodels.org/reference/multi_predict.html)
produces predictions from the regularized model for multiple values of
the `penalty` parameter without refitting. The same rule set is used for
each penalty value.

## Usage

``` r
# S3 method for class 'rule_ensemble'
multi_predict(object, new_data, type = NULL, penalty = NULL, ...)

# S3 method for class 'rule_ensemble'
has_multi_predict(object, ...)

# S3 method for class 'rule_ensemble'
multi_predict_args(object, ...)
```

## Arguments

- object:

  A `rule_ensemble` object created by
  [`rule_ensemble_xgb()`](https://tidymodels.github.io/rbe/reference/rule_ensemble_xgb.md),
  [`rule_ensemble_lgb()`](https://tidymodels.github.io/rbe/reference/rule_ensemble_lgb.md),
  or
  [`rule_ensemble_ctb()`](https://tidymodels.github.io/rbe/reference/rule_ensemble_ctb.md).

- new_data:

  A data frame of predictors.

- type:

  A single character value or `NULL`. Possible values are `"numeric"`,
  `"class"`, `"prob"`, or `"raw"`. When `NULL`, `"numeric"` is used for
  regression and `"class"` for classification.

- penalty:

  A numeric vector of penalty values. When `NULL`, the penalty value
  used to fit the model is used.

- ...:

  Not currently used.

## Value

A tibble with the same number of rows as `new_data` and a list column
`.pred`. Each element is a tibble with a `penalty` column and the
prediction column(s) for that value.

## Examples

``` r
if (rlang::is_installed("xgboost")) {
  set.seed(1)
  mod <- rule_ensemble_xgb(mpg ~ ., data = mtcars, trees = 5)

  res <- multi_predict(mod, mtcars[1:3, -1], penalty = c(0.01, 0.1))
  res
  res$.pred[[1]]
}
#> # A tibble: 2 × 2
#>   penalty .pred
#>     <dbl> <dbl>
#> 1    0.01  20.2
#> 2    0.1   20.5
```
