# ------------------------------------------------------------------------------
# Submodel predictions for parsnip model fits

#' Model predictions across many sub-models for parsnip fits
#'
#' These methods are used when a RuleFit model is fit with
#' `parsnip::rule_fit()` and the `"rule_ensemble"` engine. They produce predictions
#' for multiple values of `penalty` without refitting.
#'
#' @param object A `model_fit` object from the `"rule_ensemble"` engine.
#' @inheritParams multi_predict.rule_ensemble
#' @return A tibble with the same number of rows as `new_data` and a list
#'   column `.pred`.
#' @keywords internal
#' @name multi_predict_rule_ensemble_parsnip
#' @export
multi_predict._rule_ensemble_xgb <- function(
  object,
  new_data,
  type = NULL,
  penalty = NULL,
  ...
) {
  multi_predict_model_fit(object, new_data, type, penalty, ...)
}

#' @rdname multi_predict_rule_ensemble_parsnip
#' @export
multi_predict._rule_ensemble_lgb <- function(
  object,
  new_data,
  type = NULL,
  penalty = NULL,
  ...
) {
  multi_predict_model_fit(object, new_data, type, penalty, ...)
}

#' @rdname multi_predict_rule_ensemble_parsnip
#' @export
multi_predict._rule_ensemble_ctb <- function(
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
