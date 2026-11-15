make_rule_matrix <- function(dat, rules) {
  binary <- purrr::map(rules$rules, ~ as.numeric(rlang::eval_tidy(.x, dat)))
  if (nrow(dat) == 1) {
    binary <- as.integer(binary)
    binary <- matrix(binary, nrow = 1)
  } else {
    binary <- do.call("cbind", binary)
  }

  colnames(binary) <- rules$label
  # TODO separator for dummies
  pred_mat <- stats::model.matrix(~ . + 0, data = dat)

  pred_mat <- cbind(pred_mat, binary)
  pred_mat
}

prune_rules <- function(x) {
  is_zv <- apply(x, 2, function(x) vctrs::vec_unique_count(x) == 1L)
  x <- x[, !is_zv, drop = FALSE]
  lc_cols <- iter_lc_rm(x)
  x <- x[, !colnames(x) %in% lc_cols, drop = FALSE]
  x
}
