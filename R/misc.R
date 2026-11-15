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

#' Create a model matrix with separated indicator column names
#'
#' [stats::model.matrix()] names indicator columns by pasting the column name
#' and the factor level together (e.g., `speciesGentoo`). This function makes
#' the same matrix but puts a separator between them (e.g., `species_Gentoo`).
#'
#' @param data A data frame of predictors.
#' @param ptype A zero-row data frame with the columns, types, and factor levels
#'   used to make the matrix (e.g., `training_data[0, , drop = FALSE]`). Using
#'   the same `ptype` for the training set and for new data guarantees the
#'   same columns. Character columns are not allowed since their levels are
#'   not retained; convert them to factors first.
#' @param sep A single string placed between the column name and the level.
#' @details
#' Indicators are made with treatment contrasts regardless of
#' `options("contrasts")`. As with `model.matrix(~ . + 0, data)`, the first
#' factor (in `ptype` column order) gets an indicator for every level and
#' later factors drop their first level. Ordered factors are treated as
#' unordered factors. Logical columns are treated as factors with levels
#' `FALSE` and `TRUE`. Missing values are retained as missing rows.
#'
#' Columns of `data` not in `ptype` are ignored. Values of a factor column that
#' are not levels in `ptype` are converted to `NA` with a warning.
#'
#' Column names are found from the position of each column in the matrix, not
#' by parsing names, so a column `x` with a level `"x"` becomes `x_x`.
#' @return A numeric matrix with the same number of rows as `data`.
#' @examples
#' if (rlang::is_installed("modeldata")) {
#'   penguins <- modeldata::penguins
#'   ptype <- penguins[0, c("species", "island", "bill_length_mm")]
#'
#'   train_mat <- model_matrix_sep(penguins, ptype)
#'   head(train_mat)
#'
#'   model_matrix_sep(penguins[1, ], ptype, sep = ".")
#' }
#' @export
model_matrix_sep <- function(data, ptype, sep = "_") {
  if (!is.data.frame(data)) {
    cli::cli_abort(
      "{.arg data} must be a data frame, not {.obj_type_friendly {data}}."
    )
  }
  if (!is.data.frame(ptype)) {
    cli::cli_abort(
      "{.arg ptype} must be a data frame, not {.obj_type_friendly {ptype}}."
    )
  }
  if (!is.character(sep) || length(sep) != 1 || is.na(sep)) {
    cli::cli_abort(
      "{.arg sep} must be a single string, not {.obj_type_friendly {sep}}."
    )
  }

  vars <- names(ptype)
  missing_vars <- setdiff(vars, names(data))
  if (length(missing_vars) > 0) {
    cli::cli_abort(
      "{.arg data} is missing column{?s} {.var {missing_vars}}."
    )
  }

  is_chr <- vapply(ptype, is.character, logical(1))
  if (any(is_chr)) {
    chr_vars <- vars[is_chr]
    cli::cli_abort(
      c(
        "Column{?s} {.var {chr_vars}} in {.arg ptype} {?is/are} character.",
        i = "Convert {cli::qty(chr_vars)}{?it/them} to {?a factor/factors} so
             that the levels are retained."
      )
    )
  }

  is_fac <- vapply(ptype, is.factor, logical(1))
  is_lgl <- vapply(ptype, is.logical, logical(1))
  num_lvl <- vapply(ptype, nlevels, integer(1))
  too_few <- vars[is_fac & num_lvl < 2]
  if (length(too_few) > 0) {
    cli::cli_abort(
      "Factor column{?s} {.var {too_few}} in {.arg ptype} must have at least
       two levels."
    )
  }

  data <- as.data.frame(data)[vars]
  is_ind <- is_fac | is_lgl
  novel <- character(0)
  for (var in vars[is_ind]) {
    if (is_lgl[[var]]) {
      lvls <- c("FALSE", "TRUE")
    } else {
      lvls <- levels(ptype[[var]])
    }
    vals <- as.character(data[[var]])
    # `exclude = NULL` keeps an explicit `NA` level (e.g. from `addNA()`)
    new_vals <- factor(vals, levels = lvls, exclude = NULL)
    if (any(is.na(unclass(new_vals)) & !is.na(vals))) {
      novel <- c(novel, var)
    }
    data[[var]] <- new_vals
  }
  if (length(novel) > 0) {
    cli::cli_warn(
      "Column{?s} {.var {novel}} {?has/have} values that are not levels in
       {.arg ptype}; they were converted to {.code NA}."
    )
  }

  contr <- NULL
  if (any(is_ind)) {
    contr <- rep(list("contr.treatment"), sum(is_ind))
    names(contr) <- vars[is_ind]
  }

  form <- stats::as.formula("~ . + 0", env = rlang::base_env())
  withr::with_options(
    list(na.action = "na.pass"),
    mm <- stats::model.matrix(form, data = data, contrasts.arg = contr)
  )

  # Names are rebuilt from each column's term because model.matrix() names
  # can be ambiguous (e.g. variable `a`/level `b1` vs. variable `ab`/level `1`)
  term_labels <- attr(stats::terms(form, data = data), "term.labels")
  term_index <- attr(mm, "assign")
  raw_names <- colnames(mm)
  new_names <- raw_names
  for (i in seq_along(raw_names)) {
    j <- term_index[[i]]
    var <- vars[[j]]
    if (is_ind[[var]]) {
      lvl <- substring(raw_names[[i]], nchar(term_labels[[j]]) + 1)
      new_names[[i]] <- paste0(var, sep, lvl)
    } else {
      new_names[[i]] <- var
    }
  }

  dups <- unique(new_names[duplicated(new_names)])
  if (length(dups) > 0) {
    cli::cli_abort(
      c(
        "Using {.code sep = {.str {sep}}} creates duplicate column name{?s}
         {.val {dups}}.",
        i = "Use a different value of {.arg sep}."
      )
    )
  }

  colnames(mm) <- new_names
  attr(mm, "assign") <- NULL
  attr(mm, "contrasts") <- NULL
  mm
}

# A zero-row data frame for model_matrix_sep(); character columns are made into
# factors first so that their training set levels are kept.
predictor_ptype <- function(x) {
  is_chr <- vapply(x, is.character, logical(1))
  x[is_chr] <- lapply(x[is_chr], factor)
  x[0, , drop = FALSE]
}
