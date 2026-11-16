# ------------------------------------------------------------------------------
# Case weights

# Weights come from the `weights` argument (data frame, matrix, and formula
# methods) or from a recipe column with the "case_weights" role.
resolve_weights <- function(processed, weights, call = rlang::caller_env()) {
  role_wts <- processed$extras$roles$case_weights
  if (!is.null(role_wts) && ncol(role_wts) > 0) {
    if (ncol(role_wts) > 1) {
      cli::cli_abort(
        "Only one column can have the {.val case_weights} role, not
         {ncol(role_wts)}.",
        call = call
      )
    }
    weights <- role_wts[[1]]
  }
  check_no_weight_predictors(processed$predictors, call = call)
  check_weights(weights, nrow(processed$predictors), call = call)
}

check_weights <- function(weights, n, call = rlang::caller_env()) {
  if (is.null(weights)) {
    return(NULL)
  }
  is_hardhat <- hardhat::is_case_weights(weights)
  not_vector <- !is.null(dim(weights))
  if (
    not_vector || !is_hardhat && (!is.numeric(weights) || is.object(weights))
  ) {
    cli::cli_abort(
      c(
        "{.arg weights} must be a numeric vector, not
         {.obj_type_friendly {weights}}.",
        i = "Use a numeric vector or one created by
             {.fn hardhat::importance_weights} or
             {.fn hardhat::frequency_weights}."
      ),
      call = call
    )
  }
  if (length(weights) != n) {
    cli::cli_abort(
      "{.arg weights} must have {n} value{?s} (one per row), not
       {length(weights)}.",
      call = call
    )
  }

  # Frequency weights are kept as integers, as in parsnip
  if (inherits(weights, "hardhat_frequency_weights")) {
    vals <- as.integer(weights)
  } else {
    vals <- as.numeric(weights)
  }

  if (anyNA(vals)) {
    cli::cli_abort("{.arg weights} cannot have missing values.", call = call)
  }
  if (any(!is.finite(vals))) {
    cli::cli_abort("{.arg weights} must be finite.", call = call)
  }
  if (any(vals < 0)) {
    cli::cli_abort("{.arg weights} cannot be negative.", call = call)
  }
  if (sum(vals) <= 0) {
    cli::cli_abort(
      "At least one value of {.arg weights} must be positive.",
      call = call
    )
  }
  attr(vals, "weights_class") <- weights_class(weights)
  vals
}

weights_class <- function(weights) {
  if (inherits(weights, "hardhat_frequency_weights")) {
    res <- "frequency"
  } else if (inherits(weights, "hardhat_importance_weights")) {
    res <- "importance"
  } else {
    res <- "numeric"
  }
  res
}

check_no_weight_predictors <- function(predictors, call = rlang::caller_env()) {
  is_wt <- vapply(predictors, hardhat::is_case_weights, logical(1))
  if (!any(is_wt)) {
    return(invisible(NULL))
  }
  wt_cols <- names(predictors)[is_wt]
  cli::cli_abort(
    c(
      "Case weights column{?s} {.var {wt_cols}} cannot be used as
       {?a predictor/predictors}.",
      i = "Remove {cli::qty(wt_cols)}{?it/them} from the predictors and pass
           the weights to {.arg weights}, or use a recipe."
    ),
    call = call
  )
}

# parsnip's fit_xy() requires a hardhat case weights vector
as_glmnet_weights <- function(wts) {
  if (is.null(wts)) {
    return(NULL)
  }
  if (identical(attr(wts, "weights_class"), "frequency")) {
    res <- hardhat::frequency_weights(as.integer(wts))
  } else {
    res <- hardhat::importance_weights(as.numeric(wts))
  }
  res
}

# The boosting functions expect a plain numeric vector
as_boost_weights <- function(wts) {
  if (is.null(wts)) {
    return(NULL)
  }
  as.numeric(wts)
}

# Rows without weight do not inform glmnet, so they are not used to choose
# which columns to remove
positive_weight_rows <- function(wts, n) {
  if (is.null(wts)) {
    return(seq_len(n))
  }
  which(wts > 0)
}

# Keep the weights class after subsetting rows
subset_weights <- function(wts, rows) {
  if (is.null(wts)) {
    return(NULL)
  }
  res <- wts[rows]
  attr(res, "weights_class") <- attr(wts, "weights_class")
  res
}

# The recipe methods take weights from a "case_weights" role column
check_recipe_dots <- function(dots, call = rlang::caller_env()) {
  wt_args <- intersect(names(dots), c("weights", "weight"))
  if (length(wt_args) == 0) {
    return(invisible(NULL))
  }
  cli::cli_abort(
    c(
      "{.arg {wt_args}} cannot be used with a recipe.",
      i = "Add the case weights as a column of {.arg data}; recipes give
           columns made by {.fn hardhat::importance_weights} or
           {.fn hardhat::frequency_weights} the {.val case_weights} role."
    ),
    call = call
  )
}

# The formula method's model frame drops the case weights class, so the
# predictors are checked before `mold()`
check_formula_weights <- function(formula, data, call = rlang::caller_env()) {
  if (!is.data.frame(data)) {
    return(invisible(NULL))
  }
  is_wt <- vapply(data, hardhat::is_case_weights, logical(1))
  if (!any(is_wt)) {
    return(invisible(NULL))
  }
  # Term labels account for `.` and for terms removed with `-`
  labels <- attr(stats::terms(formula, data = data), "term.labels")
  rhs_vars <- unique(unlist(lapply(labels, function(x) {
    all.vars(rlang::parse_expr(x))
  })))
  used <- names(data)[is_wt & names(data) %in% rhs_vars]
  check_no_weight_predictors(data[used], call = call)
}
