# Model predictions across many sub-models for parsnip fits

These methods are used when a RuleFit model is fit with
[`parsnip::rule_fit()`](https://parsnip.tidymodels.org/reference/rule_fit.html)
and the `"rule_ensemble"` engine. They produce predictions for multiple
values of `penalty` without refitting.

## Usage

``` r
# S3 method for class '`_rule_ensemble_xgb`'
multi_predict(object, new_data, type = NULL, penalty = NULL, ...)

# S3 method for class '`_rule_ensemble_lgb`'
multi_predict(object, new_data, type = NULL, penalty = NULL, ...)

# S3 method for class '`_rule_ensemble_ctb`'
multi_predict(object, new_data, type = NULL, penalty = NULL, ...)
```

## Arguments

- object:

  A `model_fit` object from the `"rule_ensemble"` engine.

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
`.pred`.
