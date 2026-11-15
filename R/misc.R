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

split_dots <- function(...) {
  dots <- list(...)

  glmnet <- boost <- list()
  if (length(dots) == 0) {
    return(list(glmnet = glmnet, boost = boost))
  }

  glmn <- names(formals(glmnet::glmnet))
  glmn_out <- c("x", "y", "family", "weights", "offset", "...", "alpha")
  glmn <- glmn[!glmn %in% glmn_out]


  dot_nms <- names(dots)
  bst <- c("iterations", "rsm", "learning_rate", "depth")
  dots <- dots[!dot_nms %in% bst]

  glmnet <-  dots[dot_nms %in% glmn]
  dots <- dots[!names(dots) %in% names(glmnet)]

  if (length(dots) == 0) {
    return(list(glmnet = glmnet, boost = boost))
  }

  boost_nms <- dot_nms[!dot_nms %in% glmn]
  boost <- dots[boost_nms]

  list(glmnet = glmnet, boost = boost)
}
