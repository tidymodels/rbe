#' Fit a RuleFit Model
#'
#' `rule_ensemble()` fits a RuleFit model with the boosting library chosen by
#' `method`. It passes its arguments to [rule_ensemble_xgb()], [rule_ensemble_lgb()], or
#' [rule_ensemble_ctb()].
#'
#' @inheritParams rule_ensemble_xgb
#' @param x Depending on the context:
#'
#'   * A __data frame__ of predictors.
#'   * A __matrix__ of predictors.
#'   * A __formula__ specifying the outcome terms on the left-hand side,
#'     and the predictor terms on the right-hand side.
#'   * A __recipe__ specifying a set of preprocessing steps
#'     created from [recipes::recipe()].
#'
#' @param ... Other arguments passed to the function chosen by `method`:
#'
#'   * The outcome `y` (for a data frame or matrix `x`), or `data` (for a
#'     formula or recipe `x`).
#'   * `weights`, for case weights (not used with a recipe; see the "Case
#'     weights" section).
#'   * Named options for the boosting model and the glmnet model. The valid
#'     boosting options depend on `method`; see [rule_ensemble_xgb()],
#'     [rule_ensemble_lgb()], and [rule_ensemble_ctb()].
#'
#' @param method A single character string for the boosting library:
#'   `"xgboost"` (the default) uses [rule_ensemble_xgb()], `"lightgbm"` uses
#'   [rule_ensemble_lgb()], and `"catboost"` uses [rule_ensemble_ctb()].
#' @param mtry The proportion of predictors randomly sampled, on (0, 1]. For
#'   xgboost and lightgbm, the predictors are sampled at each split. For
#'   catboost, they are sampled for each tree level (catboost's `rsm`).
#' @param min_n The minimum number of data points in a node needed to split it
#'   further (`min_child_weight` in xgboost and `min_data_in_leaf` in
#'   lightgbm). __catboost does not use `min_n`__; see Details.
#'
#' @details
#'
#' The main arguments (`trees`, `mtry`, etc.) are translated to each library's
#' own parameters.
#'
#' ## catboost and `min_n`
#'
#' catboost does not use `min_n`. Its default `"SymmetricTree"` grow policy
#' has no minimum node size. When `method = "catboost"`, the default value of
#' `min_n` is ignored, and a value that is given is ignored with a warning. To
#' set a minimum node size for catboost, pass `min_data_in_leaf` along with
#' `grow_policy = "Depthwise"` or `grow_policy = "Lossguide"`.
#'
#' ## Using parsnip
#'
#' rbe adds a `"rule_ensemble"` engine to parsnip's [parsnip::rule_fit()] model.
#' The main arguments `trees`, `mtry`, `learn_rate`, `tree_depth`, `min_n`, and
#' `penalty` are used, and `method` and `mixture` are engine arguments. Other
#' engine arguments are passed on as boosting or glmnet options. `penalty` is
#' a submodel parameter, so tuning it with the tune package fits one model for
#' all `penalty` values. When `mtry` is tuned, its values are proportions
#' ([dials::mtry_prop()]).
#'
#' ```r
#' spec <-
#'   rule_fit(trees = 100, penalty = tune()) |>
#'   set_engine("rule_ensemble", method = "lightgbm", mixture = 0.5) |>
#'   set_mode("regression")
#' ```
#'
#' @inheritSection rule_ensemble_xgb Case weights
#'
#' @return
#'
#' A `rule_ensemble_xgb`, `rule_ensemble_lgb`, or `rule_ensemble_ctb` object,
#' depending on `method`.
#'
#' @references
#' Friedman, J, and B Popescu. 2008. "Predictive Learning via Rule Ensembles."
#' _The Annals of Applied Statistics_ 2 (3): 916-54.
#'
#' Chen, T, and G Guestrin. 2016. "XGBoost: A Scalable Tree Boosting System."
#' In _Proceedings of the 22nd ACM SIGKDD International Conference on Knowledge
#' Discovery and Data Mining_, 785-94.
#'
#' Ke, G, Q Meng, T Finley, T Wang, W Chen, W Ma, Q Ye, and TY Liu. 2017.
#' "LightGBM: A Highly Efficient Gradient Boosting Decision Tree." In _Advances
#' in Neural Information Processing Systems_, edited by I Guyon, U Von Luxburg,
#' S Bengio, H Wallach, R Fergus, S Vishwanathan, and R Garnett. Vol. 30.
#' Curran Associates, Inc.
#'
#' Prokhorenkova, L, G Gusev, A Vorobev, AV Dorogush, and A Gulin. 2018.
#' "CatBoost: Unbiased Boosting with Categorical Features." In _Advances in
#' Neural Information Processing Systems_, edited by S Bengio, H Wallach,
#' H Larochelle, K Grauman, N Cesa-Bianchi, and R Garnett. Vol. 31.
#'
#' @seealso [rule_ensemble_xgb()], [rule_ensemble_lgb()], [rule_ensemble_ctb()]
#' @export
rule_ensemble <- function(
  x,
  ...,
  method = c("xgboost", "lightgbm", "catboost"),
  trees = 50,
  mtry = 1,
  learn_rate = 0.01,
  tree_depth = 4,
  min_n = 5,
  penalty = 0.001,
  mixture = 1
) {
  # `arg_match()` gives a misleading message for a vector of valid values
  if (!missing(method) && is.character(method) && length(method) > 1) {
    cli::cli_abort(
      "{.arg method} must be a single string, not a character vector of
       length {length(method)}."
    )
  }
  method <- rlang::arg_match(method)
  main <- list(
    trees = trees,
    mtry = mtry,
    learn_rate = learn_rate,
    tree_depth = tree_depth,
    min_n = min_n,
    penalty = penalty,
    mixture = mixture
  )

  if (method == "xgboost") {
    fn <- "rule_ensemble_xgb"
  } else if (method == "lightgbm") {
    fn <- "rule_ensemble_lgb"
  } else {
    fn <- "rule_ensemble_ctb"
    # Only a user-supplied `min_n` is passed on, so that catboost warns about
    # it; the default value is dropped silently.
    if (missing(min_n)) {
      main$min_n <- NULL
    }
  }

  # A function name, rather than the function, keeps it in error messages
  rlang::exec(fn, x, ..., !!!main)
}
