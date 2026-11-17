#' RuleFit Model Objects
#'
#' [rule_ensemble()], [rule_ensemble_xgb()], [rule_ensemble_lgb()], and
#' [rule_ensemble_ctb()] return a list with class `"rule_ensemble"`. This page
#' describes its elements.
#'
#' @section Classes:
#'
#' The first class is specific to the boosting library and is followed by
#' `"rule_ensemble"`, `"hardhat_model"`, and `"hardhat_scalar"`. The first class
#' is `"rule_ensemble_xgb"`, `"rule_ensemble_lgb"`, or `"rule_ensemble_ctb"` for
#' xgboost, lightgbm, and catboost, respectively. Methods such as [predict()], [tidy()], and
#' [multi_predict()] are defined for the `"rule_ensemble"` class.
#'
#' @section Elements:
#'
#' * `rules`: A tibble (a `rule_set` object from the lorax package) with one row
#'   per rule that was retained for the glmnet model. Rules with a single
#'   unique value in the training set, or that are linear combinations of
#'   other columns, are removed. The columns are:
#'
#'   * `tree`: The integer index of the tree that the rule came from.
#'   * `rules`: A list column of R expressions that define the rule (e.g.,
#'     `wt <= 2.26 & qsec <= 19.17`). Use [show_rule()] to print one.
#'   * `id`: The integer identifier of the tree node that defines the rule.
#'   * `label`: A character column of rule names (e.g., `"rule_01"`). These are
#'     the column names of the rule indicators in the glmnet model. The labels
#'     are made before rules are removed, so they may not be consecutive.
#'
#' * `fit`: A parsnip `model_fit` object of the glmnet model. The predictors are
#'   the original predictors (with indicator columns for factors) and one 0/1
#'   column per rule. A numeric outcome uses [parsnip::linear_reg()], a factor
#'   with two levels uses [parsnip::logistic_reg()], and a factor with more
#'   levels uses [parsnip::multinom_reg()].
#'
#' * `arguments`: A named list of the values used to fit the model. It
#'   contains the main arguments (`trees`, `mtry`, `learn_rate`, `tree_depth`,
#'   `min_n`, `penalty`, `mixture`, and `verbose`) followed by any boosting and
#'   glmnet options. `min_n` is not included for catboost models.
#'
#' * `blueprint`: The hardhat blueprint used to process new data with
#'   [hardhat::forge()]. Its type depends on the type of `x` used to fit the
#'   model (data frame, matrix, formula, or recipe).
#'
#' * `training`: A list with information about the training set:
#'
#'   * `rows`: The number of rows used to fit the glmnet model. For lightgbm,
#'     rows with missing values in the predictor or rule columns are removed
#'     first.
#'   * `ptype`: A zero-row data frame of the processed predictors, with
#'     character columns converted to factors. It is used to make the same
#'     indicator columns for new data.
#'   * `weights`: `NULL` when case weights were not used. Otherwise, the type
#'     of case weights: `"frequency"`, `"importance"`, or `"numeric"` (a plain
#'     numeric vector).
#'
#' @examples
#' if (rlang::is_installed(c("modeldata", "xgboost"))) {
#'   data(two_class_dat, package = "modeldata")
#'
#'   fit <- rule_ensemble(Class ~ ., data = two_class_dat, trees = 5)
#'   class(fit)
#'   names(fit)
#'
#'   fit$rules
#'   str(fit$training)
#' }
#' @name rule_ensemble-object
#' @aliases rule_ensemble_object
NULL

new_rule_ensemble <- function(
  rules,
  fit,
  arguments,
  blueprint,
  training,
  class
) {
  hardhat::new_model(
    rules = rules,
    fit = fit,
    arguments = arguments,
    blueprint = blueprint,
    training = training,
    class = class
  )
}
