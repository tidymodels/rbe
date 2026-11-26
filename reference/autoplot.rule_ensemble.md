# Create a ggplot for a glmnet object

Shows the regularization path for the glmnet model using the rules and
predictors.

## Usage

``` r
# S3 method for class 'rule_ensemble'
autoplot(object, ..., min_penalty = 0, best_penalty = NULL, top_n = 3L)
```

## Arguments

- object:

  A model fit object.

- ...:

  For
  [`autoplot.glmnet()`](https://parsnip.tidymodels.org/reference/autoplot.model_fit.html),
  options to pass to
  [`ggrepel::geom_label_repel()`](https://ggrepel.slowkow.com/reference/geom_text_repel.html).
  Otherwise, this argument is ignored.

- min_penalty:

  A single, non-negative number for the smallest penalty value that
  should be shown in the plot. If left `NULL`, the whole data range is
  used.

- best_penalty:

  A single, non-negative number that will show a vertical line marker.
  If left `NULL`, no line is shown. When this argument is used, the
  ggrepl package is required.

- top_n:

  A non-negative integer for how many model predictors to label. The top
  predictors are ranked by their absolute coefficient value. For
  multinomial or multivariate models, the `top_n` terms are selected
  within class or response, respectively.

## Value

A ggplot2 object.

## Examples

``` r
if (rlang::is_installed(c("xgboost", "ggrepl"))) {
  set.seed(1)
  fit <- rule_ensemble(mpg ~ ., data = mtcars, trees = 5)
  autoplot(fit)
}
```
