# Show a Specific Rule

`show_rule()` prints the logical expression that defines one rule of a
fitted model. The rule identifiers are in the `label` column of the
`rules` element of the model (see
[rule_ensemble-object](https://tidymodels.github.io/rbe/reference/rule_ensemble-object.md)).

## Usage

``` r
show_rule(x, id)
```

## Arguments

- x:

  An object with class `"rule_ensemble"`.

- id:

  A single character value for the rule identifier (e.g. `"rule_01"`).

## Value

The rule expression, invisibly.

## Examples

``` r
if (rlang::is_installed("xgboost")) {
  set.seed(1)
  fit <- rule_ensemble(mpg ~ ., data = mtcars, trees = 5)
  show_rule(fit, fit$rules$label[1])
}
#> Rule: "rule_01"
#> cyl < 6 & wt < 2.31999993
```
