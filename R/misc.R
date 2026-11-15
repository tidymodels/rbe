model_function <- function(y) {
  # TODO add a type checker
  if (!is.factor(y)) {
    res <- "linear_reg"
  } else {
    lvls <- levels(y)
    if (length(lvls) == 2) {
      res <- "logistic_reg"
    } else {
      res <- "multinom_reg"
    }
  }
  res
}

parsnip_spec <- function(y, args) {
  fn <- model_function(y)
  cl <- rlang::call2(.ns = "parsnip", .fn = fn, !!!args)
  rlang::eval_tidy(cl)
}
