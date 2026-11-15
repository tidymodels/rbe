#' @export
print.rule_fit <- function(x, ...) {
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

  # unlist() would coerce mixed types (e.g. FALSE to 0) and misalign
  # vector-valued arguments; braces are escaped for cli
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
  pred_data <- predictor_matrix(object, new_data)
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
  pred_data <- predictor_matrix(object, new_data)
  stats::predict(object$fit, new_data = pred_data, type = type)
}

#' @export
augment.rule_fit <- function(x, new_data, ...) {
  pred_data <- predictor_matrix(x, new_data)
  # parsnip's augment() returns the rule matrix columns; keep only the
  # predictions and attach them to the original data
  res <- augment(x$fit, new_data = as.data.frame(pred_data))
  res <- res[, grepl("^\\.pred", names(res)), drop = FALSE]
  dplyr::bind_cols(res, dplyr::as_tibble(new_data))
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
}
