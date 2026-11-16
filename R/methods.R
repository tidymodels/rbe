#' @export
print.rule_ensemble <- function(x, ...) {
  cli::cli_inform(" ")
  cli::cli_inform("Training Set:")
  cli::cli_bullets(c(i = "Samples: {x$training$rows}"))
  if (is.null(x$training$one_hot)) {
    num_pred <- ncol(x$training$ptype)
  } else {
    num_pred <- ncol(x$training$one_hot)
  }
  cli::cli_bullets(
    c(
      i = "Predictors: {num_pred}",
      i = "Rules: {nrow(x$rules)}"
    )
  )
  if (!is.null(x$training$weights)) {
    cli::cli_bullets(c(i = "Case weights: {x$training$weights}"))
  }

  vals <- vapply(
    x$arguments,
    function(arg) paste(format(arg), collapse = ", "),
    character(1)
  )
  vals <- gsub("([{}])", "\\1\\1", vals)
  bullets <- stats::setNames(
    paste0("{.field ", names(x$arguments), "}: ", vals),
    rep("*", length(x$arguments))
  )

  cli::cli_inform(" ")
  cli::cli_inform("Arguments:")
  cli::cli_bullets(bullets)

  invisible(x)
}

#' Model predictions across many sub-models
#'
#' For RuleFit models, `multi_predict()` produces predictions from the
#' regularized model for multiple values of the `penalty` parameter without
#' refitting. The same rule set is used for each penalty value.
#'
#' @param object A `rule_ensemble` object created by [rule_ensemble_xgb()],
#'   [rule_ensemble_lgb()], or [rule_ensemble_ctb()].
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
#'   mod <- rule_ensemble_ctb(mpg ~ ., data = mtcars, logging_level = "Silent")
#'
#'   res <- multi_predict(mod, mtcars[1:3, -1], penalty = c(0.01, 0.1))
#'   res
#'   res$.pred[[1]]
#' }
#' @export
multi_predict.rule_ensemble <- function(
  object,
  new_data,
  type = NULL,
  penalty = NULL,
  ...
) {
  pred_data <- predictor_matrix(object, new_data)
  parsnip::multi_predict(
    object$fit,
    new_data = pred_data,
    type = type,
    penalty = penalty,
    ...
  )
}

#' @rdname multi_predict.rule_ensemble
#' @export
has_multi_predict.rule_ensemble <- function(object, ...) {
  TRUE
}

#' @rdname multi_predict.rule_ensemble
#' @export
multi_predict_args.rule_ensemble <- function(object, ...) {
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
predict.rule_ensemble <- function(object, new_data, type = NULL, ...) {
  pred_data <- predictor_matrix(object, new_data)
  stats::predict(object$fit, new_data = pred_data, type = type)
}

#' @export
augment.rule_ensemble <- function(x, new_data, ...) {
  pred_data <- predictor_matrix(x, new_data)
  # parsnip's augment() returns the rule matrix columns; keep only the
  # predictions and attach them to the original data
  res <- augment(x$fit, new_data = as.data.frame(pred_data))
  res <- res[, grepl("^\\.pred", names(res)), drop = FALSE]
  dplyr::bind_cols(res, dplyr::as_tibble(new_data))
}

#' @export
required_pkgs.rule_ensemble <- function(x, ...) {
  if (inherits(x, "rule_ensemble_xgb")) {
    boost_pkgs <- "xgboost"
  } else if (inherits(x, "rule_ensemble_lgb")) {
    boost_pkgs <- c("bonsai", "lightgbm")
  } else if (inherits(x, "rule_ensemble_ctb")) {
    boost_pkgs <- c("bonsai", "catboost")
  } else {
    boost_pkgs <- character(0)
  }
  c("rbe", "glmnet", boost_pkgs)
}

#' @export
tidy.rule_ensemble <- function(
  x,
  penalty = NULL,
  what = c("glmnet", "rules"),
  ...
) {
  what <- rlang::arg_match(what, c("glmnet", "rules"))
  if (what == "rules") {
    return(x$rules)
  } else {
    return(tidy(x$fit, penalty = penalty))
  }
  invisible(NULL)
}

#' Create a ggplot for a glmnet object
#'
#' Shows the regularization path for the glmnet model using the rules and predictors.
#' @return A ggplot2 object.
#' @export
#' @inheritParams parsnip::autoplot.glmnet
autoplot.rule_ensemble <- function(
  object,
  ...,
  min_penalty = 0,
  best_penalty = NULL,
  top_n = 3L
) {
  autoplot(
    object$fit,
    ...,
    min_penalty = min_penalty,
    best_penalty = best_penalty,
    top_n = top_n
  )
}
