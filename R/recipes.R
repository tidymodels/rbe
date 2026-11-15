# nocov start
# Functions swiped from the recipes package

names0 <- function(num, prefix = "rule_", call = rlang::caller_env()) {
  rlang::check_number_whole(num, min = 1, call = call)
  ind <- format(seq_len(num))
  ind <- gsub(" ", "0", ind)
  paste0(prefix, ind)
}

recommend_rm <- function(x, eps = 1e-6, ...) {
  if (!is.matrix(x)) {
    x <- as.matrix(x)
  }

  qr_decomp <- qr(x)
  qr_decomp_R <- qr.R(qr_decomp) # extract R matrix
  num_cols <- ncol(qr_decomp_R) # number of columns in R
  rank <- qr_decomp$rank # number of independent columns
  pivot <- qr_decomp$pivot # get the pivot vector

  if (is.null(num_cols) || rank == num_cols) {
    rm_list <- character(0) # there are no linear combinations
  } else {
    p1 <- seq_len(rank)
    X <- qr_decomp_R[p1, p1] # extract the independent columns
    Y <- qr_decomp_R[p1, -p1, drop = FALSE] # extract the dependent columns
    b <- qr(X) # factor the independent columns
    b <- qr.coef(b, Y) # get regression coefficients of
    # the dependent columns
    b[abs(b) < eps] <- 0 # zap small values

    # generate a list with one element for each dependent column
    combos <- lapply(
      seq_len(ncol(Y)),
      function(i) {
        c(pivot[rank + i], pivot[which(b[, i] != 0)])
      }
    )
    rm_list <- unlist(
      lapply(combos, function(x) {
        x[1]
      })
    )
    rm_list <- colnames(x)[rm_list]
  }
  rm_list
}

iter_lc_rm <- function(x, max_steps = 10, verbose = FALSE) {
  if (ncol(x) == 0L) {
    # Empty selection
    return(character())
  }

  orig_names <- colnames(x)
  if (!is.matrix(x)) {
    x <- as.matrix(x)
  }

  # converting to matrix may alter column names
  name_df <- data.frame(
    orig = orig_names,
    current = colnames(x),
    stringsAsFactors = FALSE
  )

  for (i in seq_len(max_steps)) {
    if (verbose) {
      cat(i)
    }
    if (i == max_steps) {
      break()
    }
    lcs <- recommend_rm(x)
    if (length(lcs) == 0) {
      break()
    } else {
      if (verbose) {
        cat(" removing", length(lcs), "\n")
      }
      x <- x[, !(colnames(x) %in% lcs), drop = FALSE]
    }
  }
  if (verbose) {
    cat("\n")
  }
  name_df <- name_df[!(name_df$current %in% colnames(x)), ]
  name_df$orig
}

# nocov end
