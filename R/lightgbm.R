#' Fit a RuleFit Model via LightGBM
#'
#' `rule_ensemble_lgb()` fits a model.
#'
#' @include methods.R
#' @param mtry The proportion of predictors randomly sampled at each split,
#'   on (0, 1].
#' @param min_n The minimum number of data points in a node needed to
#'   split it further (`min_data_in_leaf` in lightgbm).
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
#' @param formula A formula specifying the outcome terms on the left-hand side,
#' and the predictor terms on the right-hand side.
#'
#' @param ... Named options for the boosting model and the glmnet model:
#'
#'   * Options for lightgbm go to the boosting model. These are lightgbm's
#'     parameters and their aliases, and the arguments of
#'     [lightgbm::lgb.train()], [lightgbm::lgb.Dataset()], and
#'     [bonsai::train_lightgbm()] (e.g., `lambda_l2`, `bagging_fraction`, or
#'     `counts`).
#'
#'   Options that `rule_ensemble_lgb()` sets itself (e.g., `num_iterations` or
#'   `learning_rate`) are errors; use the main arguments (e.g., `trees` or
#'   `learn_rate`) instead. Use `verbose` instead of `quiet`. See the
#'   "Boosting and glmnet options" section for how options are routed.
#' @inheritParams rule_ensemble_xgb
#' @inheritParams rule_ensemble
#' @inheritSection rule_ensemble Case weights
#' @inheritSection rule_ensemble Boosting and glmnet options
#'
#' @return
#'
#' A `rule_ensemble_lgb` object that inherits from `"rule_ensemble"`. See
#' [rule_ensemble-object] for its elements.
#'
#' @examples
#' if (rlang::is_installed("lightgbm")) {
#'   set.seed(1)
#'   fit <- rule_ensemble_lgb(mpg ~ ., data = mtcars, trees = 5, min_n = 5)
#'   fit
#' }
#' @keywords internal
#' @export
rule_ensemble_lgb <- function(x, ...) {
  UseMethod("rule_ensemble_lgb")
}

#' @export
#' @rdname rule_ensemble_lgb
rule_ensemble_lgb.default <- function(x, ...) {
  cli::cli_abort(
    c(
      "{.fn rule_ensemble_lgb} is not defined for {.obj_type_friendly {x}}.",
      i = "{.arg x} should be a data frame, matrix, formula, or recipe."
    )
  )
}

# XY method - data frame

#' @export
#' @rdname rule_ensemble_lgb
rule_ensemble_lgb.data.frame <- function(
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
  rule_ensemble_lgb_bridge(
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
#' @rdname rule_ensemble_lgb
rule_ensemble_lgb.matrix <- function(
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
  rule_ensemble_lgb_bridge(
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
#' @rdname rule_ensemble_lgb
rule_ensemble_lgb.formula <- function(
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
  rule_ensemble_lgb_bridge(
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
#' @rdname rule_ensemble_lgb
rule_ensemble_lgb.recipe <- function(
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
  rule_ensemble_lgb_bridge(
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

rule_ensemble_lgb_bridge <- function(
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
  rlang::check_installed("lightgbm")
  rlang::check_bool(verbose, call = rlang::caller_env())
  args <- split_dots(list(...), engine = "lgb", call = rlang::caller_env())
  if (is.null(args$boost$counts)) {
    args$boost$counts <- FALSE
  }
  predictors <- processed$predictors
  outcome <- processed$outcomes[[1]]
  wts <- resolve_weights(processed, weights, call = rlang::caller_env())

  tree_fit <- rlang::exec(
    bonsai::train_lightgbm,
    x = predictors,
    y = outcome,
    num_iterations = trees,
    feature_fraction_bynode = mtry,
    learning_rate = learn_rate,
    max_depth = tree_depth,
    min_data_in_leaf = min_n,
    weights = as_boost_weights(wts),
    quiet = !verbose,
    !!!args$boost
  )

  trees_actual <- lorax::num_ensemble_members(tree_fit)
  rules <- lorax::extract_rules(
    tree_fit,
    tree = 1:trees_actual,
    data = dplyr::bind_cols(predictors, processed$outcomes)
  )
  rules$label <- names0(nrow(rules))

  ptype <- predictor_ptype(predictors)
  train_data <- make_rule_matrix(predictors, rules, ptype)
  which_complete <- which(stats::complete.cases(train_data))
  train_data <- train_data[which_complete, , drop = FALSE]
  outcome <- outcome[which_complete]
  wts <- subset_weights(wts, which_complete)
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
    class = c("rule_ensemble_lgb", "rule_ensemble")
  )
}

#' @export
print.rule_ensemble_lgb <- function(x, ...) {
  cli::cli_inform("RuleFit Using LightGBM")
  NextMethod()
}
