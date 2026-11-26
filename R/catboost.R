#' Fit a RuleFit Model via CatBoost
#'
#' `rule_ensemble_ctb()` fits a model.
#'
#' @include methods.R
#' @param mtry The proportion of predictors randomly sampled for each tree
#'   level (catboost's `rsm`), on (0, 1].
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
#'   * Options for catboost go to the boosting model. These are catboost's
#'     training parameters and their aliases, and the arguments of
#'     [bonsai::train_catboost()] (e.g., `l2_leaf_reg`, `random_strength`, or
#'     `logging_level`).
#'
#'   Options that `rule_ensemble_ctb()` sets itself (e.g., `iterations` or
#'   `depth`) are errors; use the main arguments (e.g., `trees` or
#'   `tree_depth`) instead. `min_n` is ignored, with a warning when
#'   `verbose = TRUE`. See the "Boosting and glmnet options" section for how
#'   options are routed.
#' @inheritParams rule_ensemble_xgb
#' @inheritParams rule_ensemble
#' @inheritSection rule_ensemble Case weights
#' @inheritSection rule_ensemble Boosting and glmnet options
#'
#' @return
#'
#' A `rule_ensemble_ctb` object that inherits from `"rule_ensemble"`. See
#' [rule_ensemble-object] for its elements.
#'
#' @examples
#' # catboost is not on CRAN; see https://catboost.ai for installation.
#' if (rlang::is_installed("catboost")) {
#'   set.seed(1)
#'   fit <- rule_ensemble_ctb(
#'     mpg ~ .,
#'     data = mtcars,
#'     trees = 5,
#'     logging_level = "Silent"
#'   )
#'   fit
#' }
#' @keywords internal
#' @export
rule_ensemble_ctb <- function(x, ...) {
  UseMethod("rule_ensemble_ctb")
}

#' @export
#' @rdname rule_ensemble_ctb
rule_ensemble_ctb.default <- function(x, ...) {
  cli::cli_abort(
    c(
      "{.fn rule_ensemble_ctb} is not defined for {.obj_type_friendly {x}}.",
      i = "{.arg x} should be a data frame, matrix, formula, or recipe."
    )
  )
}

# XY method - data frame

#' @export
#' @rdname rule_ensemble_ctb
rule_ensemble_ctb.data.frame <- function(
  x,
  y,
  ...,
  weights = NULL,
  trees = 50,
  mtry = 1,
  learn_rate = 0.01,
  tree_depth = 4,
  penalty = 0.001,
  mixture = 1,
  verbose = FALSE
) {
  processed <- hardhat::mold(x, y)
  rule_ensemble_ctb_bridge(
    processed,
    weights = weights,
    trees = trees,
    mtry = mtry,
    learn_rate = learn_rate,
    tree_depth = tree_depth,
    penalty = penalty,
    mixture = mixture,
    verbose = verbose,
    ...
  )
}

# XY method - matrix

#' @export
#' @rdname rule_ensemble_ctb
rule_ensemble_ctb.matrix <- function(
  x,
  y,
  ...,
  weights = NULL,
  trees = 50,
  mtry = 1,
  learn_rate = 0.01,
  tree_depth = 4,
  penalty = 0.001,
  mixture = 1,
  verbose = FALSE
) {
  processed <- hardhat::mold(x, y)
  rule_ensemble_ctb_bridge(
    processed,
    weights = weights,
    trees = trees,
    mtry = mtry,
    learn_rate = learn_rate,
    tree_depth = tree_depth,
    penalty = penalty,
    mixture = mixture,
    verbose = verbose,
    ...
  )
}

# Formula method

#' @export
#' @rdname rule_ensemble_ctb
rule_ensemble_ctb.formula <- function(
  formula,
  data,
  ...,
  weights = NULL,
  trees = 50,
  mtry = 1,
  learn_rate = 0.01,
  tree_depth = 4,
  penalty = 0.001,
  mixture = 1,
  verbose = FALSE
) {
  check_formula_weights(formula, data)
  bp <- hardhat::default_formula_blueprint(indicators = "none")
  processed <- hardhat::mold(formula, data, blueprint = bp)
  rule_ensemble_ctb_bridge(
    processed,
    weights = weights,
    trees = trees,
    mtry = mtry,
    learn_rate = learn_rate,
    tree_depth = tree_depth,
    penalty = penalty,
    mixture = mixture,
    verbose = verbose,
    ...
  )
}

# Recipe method

#' @export
#' @rdname rule_ensemble_ctb
rule_ensemble_ctb.recipe <- function(
  x,
  data,
  ...,
  trees = 50,
  mtry = 1,
  learn_rate = 0.01,
  tree_depth = 4,
  penalty = 0.001,
  mixture = 1,
  verbose = FALSE
) {
  check_recipe_dots(list(...))
  processed <- hardhat::mold(x, data)
  rule_ensemble_ctb_bridge(
    processed,
    weights = NULL,
    trees = trees,
    mtry = mtry,
    learn_rate = learn_rate,
    tree_depth = tree_depth,
    penalty = penalty,
    mixture = mixture,
    verbose = verbose,
    ...
  )
}

# ------------------------------------------------------------------------------
# Bridge

rule_ensemble_ctb_bridge <- function(
  processed,
  weights,
  trees,
  mtry,
  learn_rate,
  tree_depth,
  penalty,
  mixture,
  verbose,
  ...
) {
  rlang::check_installed("catboost")
  rlang::check_bool(verbose, call = rlang::caller_env())
  dots <- drop_ctb_min_n(
    list(...),
    verbose = verbose,
    call = rlang::caller_env()
  )
  args <- split_dots(dots, engine = "ctb", call = rlang::caller_env())
  predictors <- processed$predictors
  outcome <- processed$outcomes[[1]]
  wts <- resolve_weights(processed, weights, call = rlang::caller_env())

  tree_fit <- rlang::exec(
    bonsai::train_catboost,
    x = predictors,
    y = outcome,
    iterations = trees,
    rsm = mtry,
    learning_rate = learn_rate,
    depth = tree_depth,
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
    class = c("rule_ensemble_ctb", "rule_ensemble")
  )
}

#' @export
print.rule_ensemble_ctb <- function(x, ...) {
  cli::cli_inform("RuleFit Using CatBoost")
  NextMethod()
}
