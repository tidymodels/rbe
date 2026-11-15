fit_ctb <- function(formula, data, ...) {
  rule_fit_ctb(
    formula,
    data = data,
    trees = 5,
    logging_level = "Silent",
    allow_writing_files = FALSE,
    ...
  )
}

# A small four-class data set with numeric predictors
hpc_subset <- function() {
  dat <- modeldata::hpc_data
  dat <- dat[seq(1, nrow(dat), by = 10), ]
  dat[, c(
    "compounds",
    "input_fields",
    "iterations",
    "num_pending",
    "hour",
    "class"
  )]
}
