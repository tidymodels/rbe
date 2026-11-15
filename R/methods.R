#' @export
print.rule_fit <- function(x, ...) {
  cli::cli_inform(" ")
  cli::cli_inform("Training Set:")
  cli::cli_bullets(c(i = "Samples: {x$training$rows}"))
  cli::cli_bullets(
    c(
      i = "Predictors: {ncol(x$training$ptype)}",
      i = "Rules: {nrow(x$rules)}"
    )
  )

  bullets <- stats::setNames(
    paste0("{.field ", names(x$arguments), "}: ", unlist(x$arguments)),
    rep("*", length(x$arguments))
  )

  cli::cli_inform(" ")
  cli::cli_inform("Arguments:")
  cli::cli_bullets(bullets)

  invisible(x)
}

# TODO add autoplot mirroring parsnip

# TODO add min_grid mirroring parsnip

#' Model predictions across many sub-models
#'
#' For RuleFit models, `multi_predict()` produces predictions from the
#' regularized model for multiple values of the `penalty` parameter without
#' refitting. The same rule set is used for each penalty value.
#'
#' @param object A `rule_fit` object created by [rule_fit_xgb()],
#'   [rule_fit_lgb()], or [rule_fit_ctb()].
#' @param new_data A data frame of predictors.
#' @param type A single character value or `NULL`. Possible values are
#'   `"numeric"`, `"class"`, `"prob"`, or `"raw"`. When `NULL`, `"numeric"` is
#'   used for regression and `"class"` for classification.
#' @param penalty A numeric vector of penalty values. When `NULL`, the penalty
#'   value used to fit the model is used.
#' @param ... Not currently used.
#' @return A tibble with the same number of rows as `new_data` and a list
#'   column `.pred`. Each element is a tibble with a `penalty` column and the
#'   prediction column(s) for that value.
#' @examples
#' if (rlang::is_installed("catboost")) {
#'   mod <- rule_fit_ctb(mpg ~ ., data = mtcars, logging_level = "Silent")
#'
#'   res <- multi_predict(mod, mtcars[1:3, -1], penalty = c(0.01, 0.1))
#'   res
#'   res$.pred[[1]]
#' }
#' @export
multi_predict.rule_fit <- function(
  object,
  new_data,
  type = NULL,
  penalty = NULL,
  ...
) {
  forged <- hardhat::forge(new_data, object$blueprint)
  pred_data <- make_rule_matrix(
    forged$predictors,
    object$rules,
    object$training$ptype
  )
  parsnip::multi_predict(
    object$fit,
    new_data = pred_data,
    type = type,
    penalty = penalty,
    ...
  )
}

#' @rdname multi_predict.rule_fit
#' @export
has_multi_predict.rule_fit <- function(object, ...) {
  TRUE
}

#' @rdname multi_predict.rule_fit
#' @export
multi_predict_args.rule_fit <- function(object, ...) {
  "penalty"
}

#' @importFrom parsnip multi_predict
#' @export
parsnip::multi_predict

#' @importFrom parsnip has_multi_predict
#' @export
parsnip::has_multi_predict

#' @importFrom parsnip multi_predict_args
#' @export
parsnip::multi_predict_args

#' @export
predict.rule_fit <- function(object, new_data, type = NULL, ...) {
  forged <- hardhat::forge(new_data, object$blueprint)
  pred_data <- make_rule_matrix(
    forged$predictors,
    object$rules,
    object$training$ptype
  )
  stats::predict(object$fit, new_data = pred_data, type = type)
}

#' @export
augment.rule_fit <- function(x, new_data, ...) {
  forged <- hardhat::forge(new_data, x$blueprint)
  pred_data <- make_rule_matrix(forged$predictors, x$rules, x$training$ptype)
  augment(x$fit, new_data = pred_data)
}

#' @export
required_pkgs.rule_fit <- function(x, ...) {
  c("rulefit", "glmnet")
}

#' @export
tidy.rule_fit <- function(x, penalty = NULL, what = c("glmnet", "rules"), ...) {
  what <- rlang::arg_match(what, c("glmnet", "rules"))
  if (what == "rules") {
    return(x$rules)
  } else {
    return(tidy(x$fit, penalty = penalty))
  }
  invisible(NULL)
}
