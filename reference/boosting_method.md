# Parameter for the boosting method

`boosting_method()` is a qualitative parameter for the `method` argument
of [`rule_ensemble()`](rule_ensemble.md), which picks the boosting
library used to make the rules.

## Usage

``` r
boosting_method(values = values_boosting_method)

values_boosting_method
```

## Arguments

- values:

  A character vector of possible boosting methods. The default is
  `values_boosting_method`.

## Value

A `qual_param` object from the dials package.

## Examples

``` r
boosting_method()
#> Boosting Method (qualitative)
#> 3 possible values include:
#> 'xgboost', 'lightgbm', and 'catboost'
boosting_method(c("xgboost", "lightgbm"))
#> Boosting Method (qualitative)
#> 2 possible values include:
#> 'xgboost' and 'lightgbm'
values_boosting_method
#> [1] "xgboost"  "lightgbm" "catboost"
```
