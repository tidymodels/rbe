# ------------------------------------------------------------------------------
# Register the "rulefit" engine for parsnip's `rule_fit()` model

make_rule_fit_rulefit <- function() {
  parsnip::set_model_engine("rule_fit", "regression", "rulefit")
  parsnip::set_model_engine("rule_fit", "classification", "rulefit")
  parsnip::set_dependency("rule_fit", "rulefit", "rulefit", "regression")
  parsnip::set_dependency("rule_fit", "rulefit", "glmnet", "regression")
  parsnip::set_dependency("rule_fit", "rulefit", "bonsai", "regression")
  parsnip::set_dependency("rule_fit", "rulefit", "rulefit", "classification")
  parsnip::set_dependency("rule_fit", "rulefit", "glmnet", "classification")
  parsnip::set_dependency("rule_fit", "rulefit", "bonsai", "classification")

  parsnip::set_model_arg(
    model = "rule_fit",
    eng = "rulefit",
    parsnip = "trees",
    original = "trees",
    func = list(pkg = "dials", fun = "trees", range = c(10, 100)),
    has_submodel = FALSE
  )

  parsnip::set_model_arg(
    model = "rule_fit",
    eng = "rulefit",
    parsnip = "mtry",
    original = "mtry",
    func = list(pkg = "dials", fun = "mtry_prop"),
    has_submodel = FALSE
  )

  parsnip::set_model_arg(
    model = "rule_fit",
    eng = "rulefit",
    parsnip = "learn_rate",
    original = "learn_rate",
    func = list(pkg = "dials", fun = "learn_rate", range = c(-3, -1)),
    has_submodel = FALSE
  )

  parsnip::set_model_arg(
    model = "rule_fit",
    eng = "rulefit",
    parsnip = "tree_depth",
    original = "tree_depth",
    func = list(pkg = "dials", fun = "tree_depth", range = c(1, 4)),
    has_submodel = FALSE
  )

  parsnip::set_model_arg(
    model = "rule_fit",
    eng = "rulefit",
    parsnip = "min_n",
    original = "min_n",
    func = list(pkg = "dials", fun = "min_n", range = c(2, 20)),
    has_submodel = FALSE
  )

  parsnip::set_model_arg(
    model = "rule_fit",
    eng = "rulefit",
    parsnip = "penalty",
    original = "penalty",
    func = list(pkg = "dials", fun = "penalty", range = c(-5, -1)),
    has_submodel = TRUE
  )

  parsnip::set_model_arg(
    model = "rule_fit",
    eng = "rulefit",
    parsnip = "mixture",
    original = "mixture",
    func = list(pkg = "dials", fun = "mixture"),
    has_submodel = FALSE
  )

  parsnip::set_model_arg(
    model = "rule_fit",
    eng = "rulefit",
    parsnip = "method",
    original = "method",
    func = list(pkg = "rulefit", fun = "boosting_method"),
    has_submodel = FALSE
  )

  parsnip::set_fit(
    model = "rule_fit",
    eng = "rulefit",
    mode = "regression",
    value = list(
      interface = "data.frame",
      protect = c("x", "y", "weights"),
      func = c(pkg = "rulefit", fun = "rule_fit"),
      defaults = list()
    )
  )

  parsnip::set_encoding(
    model = "rule_fit",
    eng = "rulefit",
    mode = "regression",
    options = list(
      predictor_indicators = "none",
      compute_intercept = FALSE,
      remove_intercept = FALSE,
      allow_sparse_x = FALSE
    )
  )

  parsnip::set_fit(
    model = "rule_fit",
    eng = "rulefit",
    mode = "classification",
    value = list(
      interface = "data.frame",
      protect = c("x", "y", "weights"),
      func = c(pkg = "rulefit", fun = "rule_fit"),
      defaults = list()
    )
  )

  parsnip::set_encoding(
    model = "rule_fit",
    eng = "rulefit",
    mode = "classification",
    options = list(
      predictor_indicators = "none",
      compute_intercept = FALSE,
      remove_intercept = FALSE,
      allow_sparse_x = FALSE
    )
  )

  parsnip::set_pred(
    model = "rule_fit",
    eng = "rulefit",
    mode = "regression",
    type = "numeric",
    value = list(
      pre = NULL,
      post = pull_pred_numeric,
      func = c(fun = "predict"),
      args = list(
        object = quote(object$fit),
        new_data = quote(new_data),
        type = "numeric"
      )
    )
  )

  parsnip::set_pred(
    model = "rule_fit",
    eng = "rulefit",
    mode = "classification",
    type = "class",
    value = list(
      pre = NULL,
      post = pull_pred_class,
      func = c(fun = "predict"),
      args = list(
        object = quote(object$fit),
        new_data = quote(new_data),
        type = "class"
      )
    )
  )

  parsnip::set_pred(
    model = "rule_fit",
    eng = "rulefit",
    mode = "classification",
    type = "prob",
    value = list(
      pre = NULL,
      post = NULL,
      func = c(fun = "predict"),
      args = list(
        object = quote(object$fit),
        new_data = quote(new_data),
        type = "prob"
      )
    )
  )
}

pull_pred_numeric <- function(x, object) {
  unname(x$.pred)
}

pull_pred_class <- function(x, object) {
  x$.pred_class
}

# ------------------------------------------------------------------------------
# Submodel predictions for parsnip model fits

#' Model predictions across many sub-models for parsnip fits
#'
#' These methods are used when a RuleFit model is fit with
#' `parsnip::rule_fit()` and the `"rulefit"` engine. They produce predictions
#' for multiple values of `penalty` without refitting.
#'
#' @param object A `model_fit` object from the `"rulefit"` engine.
#' @inheritParams multi_predict.rulefit
#' @return A tibble with the same number of rows as `new_data` and a list
#'   column `.pred`.
#' @keywords internal
#' @name multi_predict_rulefit_parsnip
#' @export
multi_predict._rule_fit_xgb <- function(
  object,
  new_data,
  type = NULL,
  penalty = NULL,
  ...
) {
  multi_predict_model_fit(object, new_data, type, penalty, ...)
}

#' @rdname multi_predict_rulefit_parsnip
#' @export
multi_predict._rule_fit_lgb <- function(
  object,
  new_data,
  type = NULL,
  penalty = NULL,
  ...
) {
  multi_predict_model_fit(object, new_data, type, penalty, ...)
}

#' @rdname multi_predict_rulefit_parsnip
#' @export
multi_predict._rule_fit_ctb <- function(
  object,
  new_data,
  type = NULL,
  penalty = NULL,
  ...
) {
  multi_predict_model_fit(object, new_data, type, penalty, ...)
}

multi_predict_model_fit <- function(object, new_data, type, penalty, ...) {
  new_data <- parsnip::prepare_data(object, new_data)
  multi_predict(
    object$fit,
    new_data = new_data,
    type = type,
    penalty = penalty,
    ...
  )
}
