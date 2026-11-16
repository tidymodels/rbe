#' Fit a RuleFit Model via XGBoost
#'
#' `rule_fit_xgb()` fits a model.
#'
#' @include methods.R
#' @inheritParams parsnip::boost_tree
#' @param mtry The proportion of predictors randomly sampled at each split,
#'   on (0, 1].
#' @param min_n The minimum number of data points in a node needed to
#'   split it further (`min_child_weight` in xgboost).
#' @inheritParams parsnip::linear_reg
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
#' @param ... Named options for the boosting model and the glmnet model,
#'   given together as one set. Each option is sent to one of the two models
#'   by its name:
#'
#'   * Options for xgboost go to the boosting model. These are the arguments
#'     of [xgboost::xgb.params()], [xgboost::xgb.train()], and
#'     [parsnip::xgb_train()] (e.g., `gamma`, `subsample`, etc.).
#'   * Arguments of [glmnet::glmnet()] go to the glmnet model (e.g.,
#'     `standardize` or `penalty.factor`).
#'
#'   A name that is valid for both models goes to the boosting model. An
#'   unknown name is an error. Options that `rule_fit_xgb()` sets itself
#'   (e.g., `nrounds` or `eta`) are also errors; use the main arguments
#'   (e.g., `trees` or `learn_rate`) instead.
#'
#' @section Case weights:
#'
#' Case weights are used to fit both the boosted trees that create the rules
#' and the glmnet model that is fit to the rules. Rows with a weight of zero
#' are not used to decide which rules are removed for having a single unique
#' value or being linear combinations of other columns.
#'
#' For the data frame, matrix, and formula methods, pass the weights to
#' `weights`. A case weights column cannot also be a predictor. For the recipe
#' method, add the weights as a column of `data` that is created by
#' [hardhat::importance_weights()] or [hardhat::frequency_weights()];
#' [recipes::recipe()] gives these columns the `"case_weights"` role, so they
#' are not used as predictors.
#'
#' @return
#'
#' A `rule_fit_xgb` object.
#'
#' @keywords internal
#' @export
rule_fit_xgb <- function(x, ...) {
  UseMethod("rule_fit_xgb")
}

#' @export
#' @rdname rule_fit_xgb
rule_fit_xgb.default <- function(x, ...) {
  cli::cli_abort(
    c(
      "{.fn rule_fit_xgb} is not defined for {.obj_type_friendly {x}}.",
      i = "{.arg x} should be a data frame, matrix, formula, or recipe."
    )
  )
}

# XY method - data frame

#' @export
#' @rdname rule_fit_xgb
rule_fit_xgb.data.frame <- function(
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
  mixture = 1
) {
  processed <- hardhat::mold(x, y)
  rule_fit_xgb_bridge(
    processed,
    weights = weights,
    trees = trees,
    mtry = mtry,
    learn_rate = learn_rate,
    tree_depth = tree_depth,
    min_n = min_n,
    penalty = penalty,
    mixture = mixture,
    ...
  )
}

# XY method - matrix

#' @export
#' @rdname rule_fit_xgb
rule_fit_xgb.matrix <- function(
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
  mixture = 1
) {
  processed <- hardhat::mold(x, y)
  rule_fit_xgb_bridge(
    processed,
    weights = weights,
    trees = trees,
    mtry = mtry,
    learn_rate = learn_rate,
    tree_depth = tree_depth,
    min_n = min_n,
    penalty = penalty,
    mixture = mixture,
    ...
  )
}

# Formula method

#' @export
#' @rdname rule_fit_xgb
rule_fit_xgb.formula <- function(
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
  mixture = 1
) {
  check_formula_weights(formula, data)
  bp <- hardhat::default_formula_blueprint(indicators = "none")
  processed <- hardhat::mold(formula, data, blueprint = bp)
  rule_fit_xgb_bridge(
    processed,
    weights = weights,
    trees = trees,
    mtry = mtry,
    learn_rate = learn_rate,
    tree_depth = tree_depth,
    min_n = min_n,
    penalty = penalty,
    mixture = mixture,
    ...
  )
}

# Recipe method

#' @export
#' @rdname rule_fit_xgb
rule_fit_xgb.recipe <- function(
  x,
  data,
  ...,
  trees = 50,
  mtry = 1,
  learn_rate = 0.01,
  tree_depth = 4,
  min_n = 5,
  penalty = 0.001,
  mixture = 1
) {
  check_recipe_dots(list(...))
  processed <- hardhat::mold(x, data)
  rule_fit_xgb_bridge(
    processed,
    weights = NULL,
    trees = trees,
    mtry = mtry,
    learn_rate = learn_rate,
    tree_depth = tree_depth,
    min_n = min_n,
    penalty = penalty,
    mixture = mixture,
    ...
  )
}

# ------------------------------------------------------------------------------
# Bridge

rule_fit_xgb_bridge <- function(
  processed,
  weights,
  trees,
  mtry,
  learn_rate,
  tree_depth,
  min_n,
  penalty,
  mixture,
  ...
) {
  rlang::check_installed("xgboost", version = "3.0.0")
  args <- split_dots(list(...), engine = "xgb", call = rlang::caller_env())
  if (is.null(args$boost$counts)) {
    args$boost$counts <- FALSE
  }
  outcome <- processed$outcomes[[1]]
  wts <- resolve_weights(processed, weights, call = rlang::caller_env())

  # Temporary (#5): lorax cannot yet extract rules from xgboost models
  # that use native categorical splits, so factors are made into one-hot
  # indicators before boosting. Remove this (and `training$one_hot`) once lorax
  # supports them.
  one_hot_ptype <- predictor_ptype(processed$predictors)
  predictors <- one_hot(processed$predictors, one_hot_ptype)

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
    !!!args$boost
  )

  trees_actual <- lorax::num_ensemble_members(tree_fit)
  rules <- lorax::extract_rules(tree_fit, tree = 1:trees_actual)
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

  new_rule_fit(
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
        mixture = mixture
      ),
      args$boost,
      args$glmnet
    ),
    blueprint = processed$blueprint,
    training = list(
      rows = nrow(train_data),
      ptype = ptype,
      one_hot = one_hot_ptype,
      weights = attr(wts, "weights_class")
    ),
    class = c("rule_fit_xgb", "rulefit")
  )
}

#' @export
print.rule_fit_xgb <- function(x, ...) {
  cli::cli_inform("RuleFit Using XGBoost")
  NextMethod()
}
