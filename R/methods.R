#' @export
print.rule_fit <- function(x, ...) {
  cli::cli_inform(" ")
  cli::cli_inform("Training Set:")
  cli::cli_bullets(c(i = "Samples: {x$training$rows}"))
  cli::cli_bullets(
    c(
      i = "Predictors: {length(x$training$names)}, including {sum(grepl('^rule_', x$training$names))} rules"
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

# TODO add multipredict mirroring parsnip
#' @export
predict.rule_fit <- function(object, new_data, type = NULL, ...) {
  forged <- hardhat::forge(new_data, object$blueprint)
  pred_data <- make_rule_matrix(forged$predictors, object$rules)
  stats::predict(object$fit, new_data = pred_data, type = type)
}

#' @export
augment.rule_fit <- function(x, new_data, ...) {
  forged <- hardhat::forge(new_data, x$blueprint)
  pred_data <- make_rule_matrix(forged$predictors, x$rules)
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
