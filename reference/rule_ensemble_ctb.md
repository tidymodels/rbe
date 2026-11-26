# Fit a RuleFit Model via CatBoost

`rule_ensemble_ctb()` fits a model.

## Usage

``` r
rule_ensemble_ctb(x, ...)

# Default S3 method
rule_ensemble_ctb(x, ...)

# S3 method for class 'data.frame'
rule_ensemble_ctb(
  x,
  y,
  ...,
  weights = NULL,
  trees = 50,
  mtry = 1,
  learn_rate = 0.01,
  tree_depth = 4,
  penalty = 0.001,
  mixture = 1,
  verbose = FALSE
)

# S3 method for class 'matrix'
rule_ensemble_ctb(
  x,
  y,
  ...,
  weights = NULL,
  trees = 50,
  mtry = 1,
  learn_rate = 0.01,
  tree_depth = 4,
  penalty = 0.001,
  mixture = 1,
  verbose = FALSE
)

# S3 method for class 'formula'
rule_ensemble_ctb(
  formula,
  data,
  ...,
  weights = NULL,
  trees = 50,
  mtry = 1,
  learn_rate = 0.01,
  tree_depth = 4,
  penalty = 0.001,
  mixture = 1,
  verbose = FALSE
)

# S3 method for class 'recipe'
rule_ensemble_ctb(
  x,
  data,
  ...,
  trees = 50,
  mtry = 1,
  learn_rate = 0.01,
  tree_depth = 4,
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

  - A **recipe** specifying a set of preprocessing steps created from
    [`recipes::recipe()`](https://recipes.tidymodels.org/reference/recipe.html).

- ...:

  Named options for the boosting model and the glmnet model:

  - Options for catboost go to the boosting model. These are catboost's
    training parameters and their aliases, and the arguments of
    [`bonsai::train_catboost()`](https://bonsai.tidymodels.org/reference/train_catboost.html)
    (e.g., `l2_leaf_reg`, `random_strength`, or `logging_level`).

  Options that `rule_ensemble_ctb()` sets itself (e.g., `iterations` or
  `depth`) are errors; use the main arguments (e.g., `trees` or
  `tree_depth`) instead. `min_n` is ignored, with a warning when
  `verbose = TRUE`. See the "Boosting and glmnet options" section for
  how options are routed.

- y:

  When `x` is a **data frame** or **matrix**, `y` is the outcome
  specified as:

  - A **data frame** with 1 numeric column.

  - A **matrix** with 1 numeric column.

  - A numeric **vector**.

- weights:

  An optional vector of non-negative case weights with one value per row
  of the training set. It can be a numeric vector or one created by
  [`hardhat::importance_weights()`](https://hardhat.tidymodels.org/reference/importance_weights.html)
  or
  [`hardhat::frequency_weights()`](https://hardhat.tidymodels.org/reference/frequency_weights.html).
  Not used by the recipe method; see the "Case weights" section.

- trees:

  An integer for the number of trees contained in the ensemble.

- mtry:

  The proportion of predictors randomly sampled for each tree level
  (catboost's `rsm`), on (0, 1\].

- learn_rate:

  A number for the rate at which the boosting algorithm adapts from
  iteration-to-iteration (specific engines only). This is sometimes
  referred to as the shrinkage parameter.

- tree_depth:

  An integer for the maximum depth of the tree (i.e. number of splits)
  (specific engines only).

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
  log, and `rule_ensemble_ctb()` warns when `min_n` is given and
  ignored.

- formula:

  A formula specifying the outcome terms on the left-hand side, and the
  predictor terms on the right-hand side.

- data:

  When a **recipe** or **formula** is used, `data` is specified as:

  - A **data frame** containing both the predictors and the outcome.

## Value

A `rule_ensemble_ctb` object that inherits from `"rule_ensemble"`. See
[rule_ensemble-object](rule_ensemble-object.md) for its elements.

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
  `rule_ensemble_ctb()`.

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

## Examples

``` r
# catboost is not on CRAN; see https://catboost.ai for installation.
if (rlang::is_installed("catboost")) {
  set.seed(1)
  fit <- rule_ensemble_ctb(
    mpg ~ .,
    data = mtcars,
    trees = 5,
    logging_level = "Silent"
  )
  fit
}
#> RuleFit Using CatBoost
#> 
#> Training Set:
#> ℹ Samples: 32
#> ℹ Predictors: 10
#> ℹ Rules: 19
#> 
#> Arguments:
#> • trees: 5
#> • mtry: 1
#> • learn_rate: 0.01
#> • tree_depth: 4
#> • penalty: 0.001
#> • mixture: 1
#> • verbose: FALSE
#> • logging_level: Silent
```
