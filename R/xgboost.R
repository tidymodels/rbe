#' Fit a RuleFit Model via XGBoost
#'
#' `rule_ensemble_xgb()` fits a model.
#'
#' @include methods.R
#' @inheritParams rule_ensemble
#' @param mtry The proportion of predictors randomly sampled at each split,
#'   on (0, 1].
#' @param min_n The minimum number of data points in a node needed to
#'   split it further (`min_child_weight` in xgboost).
#' @param x Depending on the context:
#'
#'   * A __data frame__ of predictors.
#'   * A __matrix__ of predictors.
#'   * A __recipe__ specifying a set of preprocessing steps
#'     created from [recipes::recipe()].
#'
#' @param y When `x` is a __data frame__ or __matrix__, `y` is the outcome
#' specified as:
#'
#'   * A __data frame__ with 1 numeric column.
#'   * A __matrix__ with 1 numeric column.
#'   * A numeric __vector__.
#'
#' @param data When a __recipe__ or __formula__ is used, `data` is specified as:
#'
#'   * A __data frame__ containing both the predictors and the outcome.
#'
#' @param weights An optional vector of non-negative case weights with one
#'   value per row of the training set. It can be a numeric vector or one
#'   created by [hardhat::importance_weights()] or
#'   [hardhat::frequency_weights()]. Not used by the recipe method; see the
#'   "Case weights" section.
#'
#' @param formula A formula specifying the outcome terms on the left-hand side,
#' and the predictor terms on the right-hand side.
#'
#' @param ... Named options for the boosting model and the glmnet model:
#'
#'   * Options for xgboost go to the boosting model. These are the arguments
#'     of [xgboost::xgb.params()], [xgboost::xgb.train()], and
#'     [parsnip::xgb_train()] (e.g., `gamma`, `subsample`, etc.).
#'
#'   Options that `rule_ensemble_xgb()` sets itself (e.g., `nrounds` or `eta`)
#'   are errors; use the main arguments (e.g., `trees` or `learn_rate`)
#'   instead. See the "Boosting and glmnet options" section for how options
#'   are routed.
#'
#' @inheritSection rule_ensemble Case weights
#' @inheritSection rule_ensemble Boosting and glmnet options
#'
#' @return
#'
#' A `rule_ensemble_xgb` object that inherits from `"rule_ensemble"`. See
#' [rule_ensemble-object] for its elements.
#'
#' @keywords internal
#' @export
rule_ensemble_xgb <- function(x, ...) {
  UseMethod("rule_ensemble_xgb")
}

#' @export
#' @rdname rule_ensemble_xgb
rule_ensemble_xgb.default <- function(x, ...) {
  cli::cli_abort(
    c(
      "{.fn rule_ensemble_xgb} is not defined for {.obj_type_friendly {x}}.",
      i = "{.arg x} should be a data frame, matrix, formula, or recipe."
    )
  )
}

# XY method - data frame

#' @export
#' @rdname rule_ensemble_xgb
rule_ensemble_xgb.data.frame <- function(
  x,
  y,
  ...,
  weights = NULL,
  trees = 50,
  mtry = 1,
  learn_rate = 0.01,
  tree_depth = 4,
  min_n = 5,
  penalty = 0.001,
  mixture = 1,
  verbose = FALSE
) {
  processed <- hardhat::mold(x, y)
  rule_ensemble_xgb_bridge(
    processed,
    weights = weights,
    trees = trees,
    mtry = mtry,
    learn_rate = learn_rate,
    tree_depth = tree_depth,
    min_n = min_n,
    penalty = penalty,
    mixture = mixture,
    verbose = verbose,
    ...
  )
}

# XY method - matrix

#' @export
#' @rdname rule_ensemble_xgb
rule_ensemble_xgb.matrix <- function(
  x,
  y,
  ...,
  weights = NULL,
  trees = 50,
  mtry = 1,
  learn_rate = 0.01,
  tree_depth = 4,
  min_n = 5,
  penalty = 0.001,
  mixture = 1,
  verbose = FALSE
) {
  processed <- hardhat::mold(x, y)
  rule_ensemble_xgb_bridge(
    processed,
    weights = weights,
    trees = trees,
    mtry = mtry,
    learn_rate = learn_rate,
    tree_depth = tree_depth,
    min_n = min_n,
    penalty = penalty,
    mixture = mixture,
    verbose = verbose,
    ...
  )
}

# Formula method

#' @export
#' @rdname rule_ensemble_xgb
rule_ensemble_xgb.formula <- function(
  formula,
  data,
  ...,
  weights = NULL,
  trees = 50,
  mtry = 1,
  learn_rate = 0.01,
  tree_depth = 4,
  min_n = 5,
  penalty = 0.001,
  mixture = 1,
  verbose = FALSE
) {
  check_formula_weights(formula, data)
  bp <- hardhat::default_formula_blueprint(indicators = "none")
  processed <- hardhat::mold(formula, data, blueprint = bp)
  rule_ensemble_xgb_bridge(
    processed,
    weights = weights,
    trees = trees,
    mtry = mtry,
    learn_rate = learn_rate,
    tree_depth = tree_depth,
    min_n = min_n,
    penalty = penalty,
    mixture = mixture,
    verbose = verbose,
    ...
  )
}

# Recipe method

#' @export
#' @rdname rule_ensemble_xgb
rule_ensemble_xgb.recipe <- function(
  x,
  data,
  ...,
  trees = 50,
  mtry = 1,
  learn_rate = 0.01,
  tree_depth = 4,
  min_n = 5,
  penalty = 0.001,
  mixture = 1,
  verbose = FALSE
) {
  check_recipe_dots(list(...))
  processed <- hardhat::mold(x, data)
  rule_ensemble_xgb_bridge(
    processed,
    weights = NULL,
    trees = trees,
    mtry = mtry,
    learn_rate = learn_rate,
    tree_depth = tree_depth,
    min_n = min_n,
    penalty = penalty,
    mixture = mixture,
    verbose = verbose,
    ...
  )
}

# ------------------------------------------------------------------------------
# Bridge

rule_ensemble_xgb_bridge <- function(
  processed,
  weights,
  trees,
  mtry,
  learn_rate,
  tree_depth,
  min_n,
  penalty,
  mixture,
  verbose,
  ...
) {
  rlang::check_installed("xgboost", version = "3.0.0")
  rlang::check_bool(verbose, call = rlang::caller_env())
  args <- split_dots(list(...), engine = "xgb", call = rlang::caller_env())
  if (is.null(args$boost$counts)) {
    args$boost$counts <- FALSE
  }
  outcome <- processed$outcomes[[1]]
  wts <- resolve_weights(processed, weights, call = rlang::caller_env())

  # xgboost only makes categorical splits for factor columns
  predictors <- processed$predictors
  is_chr <- vapply(predictors, is.character, logical(1))
  predictors[is_chr] <- lapply(predictors[is_chr], factor)

  tree_fit <- rlang::exec(
    parsnip::xgb_train,
    x = predictors,
    y = outcome,
    nrounds = trees,
    colsample_bynode = mtry,
    eta = learn_rate,
    max_depth = tree_depth,
    min_child_weight = min_n,
    weights = as_boost_weights(wts),
    verbose = as.integer(verbose),
    !!!args$boost
  )

  trees_actual <- lorax::num_ensemble_members(tree_fit)
  rules <- lorax::extract_rules(
    tree_fit,
    tree = 1:trees_actual,
    data = predictors
  )
  rules$label <- names0(nrow(rules))

  ptype <- predictor_ptype(predictors)
  train_data <- make_rule_matrix(predictors, rules, ptype)
  train_data <- prune_rules(
    train_data,
    rows = positive_weight_rows(wts, nrow(train_data))
  )

  rule_names <- grep("^rule_", colnames(train_data), value = TRUE)
  rules <- rules[rules$label %in% rule_names, ]

  spec <-
    parsnip_spec(outcome, list(penalty = penalty, mixture = mixture)) |>
    parsnip::set_engine("glmnet", !!!args$glmnet)

  reg_fit <- parsnip::fit_xy(
    spec,
    x = train_data,
    y = outcome,
    case_weights = as_glmnet_weights(wts)
  )

  new_rule_ensemble(
    rules = rules,
    fit = reg_fit,
    arguments = c(
      list(
        trees = trees,
        mtry = mtry,
        learn_rate = learn_rate,
        tree_depth = tree_depth,
        min_n = min_n,
        penalty = penalty,
        mixture = mixture,
        verbose = verbose
      ),
      args$boost,
      args$glmnet
    ),
    blueprint = processed$blueprint,
    training = list(
      rows = nrow(train_data),
      ptype = ptype,
      weights = attr(wts, "weights_class")
    ),
    class = c("rule_ensemble_xgb", "rule_ensemble")
  )
}

#' @export
print.rule_ensemble_xgb <- function(x, ...) {
  cli::cli_inform("RuleFit Using XGBoost")
  NextMethod()
}
