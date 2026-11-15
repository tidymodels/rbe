make_rule_matrix <- function(dat, rules, ptype) {
  binary <- purrr::map(rules$rules, ~ as.numeric(rlang::eval_tidy(.x, dat)))
  if (nrow(dat) == 1) {
    binary <- as.integer(binary)
    binary <- matrix(binary, nrow = 1)
  } else {
    binary <- do.call("cbind", binary)
  }

  colnames(binary) <- rules$label
  pred_mat <- model_matrix_sep(dat, ptype)

  pred_mat <- cbind(pred_mat, binary)
  pred_mat
}

# `rows` are the rows used to find columns to remove; all rows are returned
prune_rules <- function(x, rows = seq_len(nrow(x))) {
  x_rows <- x[rows, , drop = FALSE]
  is_zv <- apply(x_rows, 2, function(x) vctrs::vec_unique_count(x) == 1L)
  x <- x[, !is_zv, drop = FALSE]
  x_rows <- x_rows[, !is_zv, drop = FALSE]
  lc_cols <- iter_lc_rm(x_rows)
  x <- x[, !colnames(x) %in% lc_cols, drop = FALSE]
  x
}

# Convert new data to the matrix used by the glmnet model
predictor_matrix <- function(object, new_data) {
  predictors <- hardhat::forge(new_data, object$blueprint)$predictors
  if (!is.null(object$training$one_hot)) {
    predictors <- one_hot(predictors, object$training$one_hot)
  }
  make_rule_matrix(predictors, object$rules, object$training$ptype)
}
