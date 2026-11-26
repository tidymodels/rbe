# Fit a RuleFit Model

`rule_ensemble()` fits a RuleFit model with the boosting library chosen
by `method`. It passes its arguments to
[`rule_ensemble_xgb()`](rule_ensemble_xgb.md),
[`rule_ensemble_lgb()`](rule_ensemble_lgb.md), or
[`rule_ensemble_ctb()`](rule_ensemble_ctb.md).

## Usage

``` r
rule_ensemble(
  x,
  ...,
  method = c("xgboost", "lightgbm", "catboost"),
  trees = 50,
  mtry = 1,
  learn_rate = 0.01,
  tree_depth = 4,
  min_n = 5,
  penalty = 0.001,
  mixture = 1,
  verbose = FALSE
)
```

## Arguments

- x:

  Depending on the context:

  - A **data frame** of predictors.

  - A **matrix** of predictors.

  - A **formula** specifying the outcome terms on the left-hand side,
    and the predictor terms on the right-hand side.

  - A **recipe** specifying a set of preprocessing steps created from
    [`recipes::recipe()`](https://recipes.tidymodels.org/reference/recipe.html).

- ...:

  Other arguments passed to the function chosen by `method`:

  - The outcome `y` (for a data frame or matrix `x`), or `data` (for a
    formula or recipe `x`).

  - `weights`, for case weights (not used with a recipe; see the "Case
    weights" section).

  - Named options for the boosting model and the glmnet model; see the
    "Boosting and glmnet options" section.

- method:

  A single character string for the boosting library: `"xgboost"` (the
  default) uses [`rule_ensemble_xgb()`](rule_ensemble_xgb.md),
  `"lightgbm"` uses [`rule_ensemble_lgb()`](rule_ensemble_lgb.md), and
  `"catboost"` uses [`rule_ensemble_ctb()`](rule_ensemble_ctb.md).

- trees:

  An integer for the number of trees contained in the ensemble.

- mtry:

  The proportion of predictors randomly sampled, on (0, 1\]. For xgboost
  and lightgbm, the predictors are sampled at each split. For catboost,
  they are sampled for each tree level (catboost's `rsm`).

- learn_rate:

  A number for the rate at which the boosting algorithm adapts from
  iteration-to-iteration (specific engines only). This is sometimes
  referred to as the shrinkage parameter.

- tree_depth:

  An integer for the maximum depth of the tree (i.e. number of splits)
  (specific engines only).

- min_n:

  The minimum number of data points in a node needed to split it further
  (`min_child_weight` in xgboost and `min_data_in_leaf` in lightgbm).
  **catboost does not use `min_n`**; see Details.

- penalty:

  A non-negative number representing the total amount of regularization
  (specific engines only).

- mixture:

  A number between zero and one (inclusive) denoting the proportion of
  L1 regularization (i.e. lasso) in the model.

  - `mixture = 1` specifies a pure lasso model,

  - `mixture = 0` specifies a ridge regression model, and

  - `0 < mixture < 1` specifies an elastic net model, interpolating
    lasso and ridge.

  Available for specific engines only.

- verbose:

  A single logical. If `TRUE`, the boosting library prints its training
  log, and [`rule_ensemble_ctb()`](rule_ensemble_ctb.md) warns when
  `min_n` is given and ignored.

## Value

A `rule_ensemble_xgb`, `rule_ensemble_lgb`, or `rule_ensemble_ctb`
object, depending on `method`. Each inherits from `"rule_ensemble"`; see
[rule_ensemble-object](rule_ensemble-object.md) for their elements.

## Details

The main arguments (`trees`, `mtry`, etc.) are translated to each
library's own parameters.

### catboost and `min_n`

catboost does not use `min_n`. Its default `"SymmetricTree"` grow policy
has no minimum node size. When `method = "catboost"`, the default value
of `min_n` is ignored silently. A value that is given is also ignored,
with a warning when `verbose = TRUE`. To set a minimum node size for
catboost, pass `min_data_in_leaf` along with `grow_policy = "Depthwise"`
or `grow_policy = "Lossguide"`.

## Case weights

Case weights are used to fit both the boosted trees that create the
rules and the glmnet model that is fit to the rules. Rows with a weight
of zero are not used to decide which rules are removed for having a
single unique value or being linear combinations of other columns.

For the data frame, matrix, and formula methods, pass the weights to
`weights`. A case weights column cannot also be a predictor. For the
recipe method, add the weights as a column of `data` that is created by
[`hardhat::importance_weights()`](https://hardhat.tidymodels.org/reference/importance_weights.html)
or
[`hardhat::frequency_weights()`](https://hardhat.tidymodels.org/reference/frequency_weights.html);
[`recipes::recipe()`](https://recipes.tidymodels.org/reference/recipe.html)
gives these columns the `"case_weights"` role, so they are not used as
predictors.

## Boosting and glmnet options

Named options for the boosting model and the glmnet model are given
together as one set in `...`. Each option is sent to one of the two
models by its name:

- Options for the boosting library go to the boosting model. The valid
  names depend on the library; see the `...` argument of
  [`rule_ensemble_xgb()`](rule_ensemble_xgb.md),
  [`rule_ensemble_lgb()`](rule_ensemble_lgb.md), or
  [`rule_ensemble_ctb()`](rule_ensemble_ctb.md).

- Arguments of
  [`glmnet::glmnet()`](https://glmnet.stanford.edu/reference/glmnet.html)
  go to the glmnet model (e.g., `standardize` or `penalty.factor`).
  `path_values`, a numeric vector of penalty values for the glmnet path,
  also goes to the glmnet model; see
  [parsnip::glmnet-details](https://parsnip.tidymodels.org/reference/glmnet-details.html)
  for how it is used.

A name that is valid for both models goes to the boosting model. An
unknown name is an error. Options that rbe sets itself are also errors;
use the main arguments (e.g., `trees` or `learn_rate`) instead.

## References

Friedman, J, and B Popescu. 2008. "Predictive Learning via Rule
Ensembles." *The Annals of Applied Statistics* 2 (3): 916-54.

Chen, T, and G Guestrin. 2016. "XGBoost: A Scalable Tree Boosting
System." In *Proceedings of the 22nd ACM SIGKDD International Conference
on Knowledge Discovery and Data Mining*, 785-94.

Ke, G, Q Meng, T Finley, T Wang, W Chen, W Ma, Q Ye, and TY Liu. 2017.
"LightGBM: A Highly Efficient Gradient Boosting Decision Tree." In
*Advances in Neural Information Processing Systems*, edited by I Guyon,
U Von Luxburg, S Bengio, H Wallach, R Fergus, S Vishwanathan, and R
Garnett. Vol. 30. Curran Associates, Inc.

Prokhorenkova, L, G Gusev, A Vorobev, AV Dorogush, and A Gulin. 2018.
"CatBoost: Unbiased Boosting with Categorical Features." In *Advances in
Neural Information Processing Systems*, edited by S Bengio, H Wallach, H
Larochelle, K Grauman, N Cesa-Bianchi, and R Garnett. Vol. 31.

## See also

[`rule_ensemble_xgb()`](rule_ensemble_xgb.md),
[`rule_ensemble_lgb()`](rule_ensemble_lgb.md),
[`rule_ensemble_ctb()`](rule_ensemble_ctb.md)

## Examples

``` r
if (rlang::is_installed("xgboost")) {
  set.seed(1)
  fit <- rule_ensemble(mpg ~ ., data = mtcars, trees = 5, penalty = 0.1)
  fit

  predict(fit, mtcars[1:3, -1])
}
#> # A tibble: 3 × 1
#>   .pred
#>   <dbl>
#> 1  20.5
#> 2  20.2
#> 3  23.5
```
