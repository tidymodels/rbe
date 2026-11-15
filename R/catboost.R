#' Fit a `rule_fit_ctb`
#'
#' `rule_fit_ctb()` fits a model.
#'
#' @include methods.R
#' @inheritParams parsnip::boost_tree
#' @param mtry The proportion of predictors randomly sampled for each tree
#'   level (catboost's `rsm`), on (0, 1].
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
#' @param formula A formula specifying the outcome terms on the left-hand side,
#' and the predictor terms on the right-hand side.
#'
#' @param ... Not currently used, but required for extensibility.
#'
#' @return
#'
#' A `rule_fit_ctb` object.
#'
#' @export
rule_fit_ctb <- function(x, ...) {
  UseMethod("rule_fit_ctb")
}

#' @export
#' @rdname rule_fit_ctb
rule_fit_ctb.default <- function(x, ...) {
  stop(
    "`rule_fit_ctb()` is not defined for a '",
    class(x)[1],
    "'.",
    call. = FALSE
  )
}

# XY method - data frame

#' @export
#' @rdname rule_fit_ctb
rule_fit_ctb.data.frame <- function(
  x,
  y,
  trees = 50,
  mtry = 1,
  learn_rate = 0.01,
  tree_depth = 4,
  penalty = 0.001,
  mixture = 1,
  ...
) {
  processed <- hardhat::mold(x, y)
  rule_fit_ctb_bridge(
    processed,
    trees = trees,
    mtry = mtry,
    learn_rate = learn_rate,
    tree_depth = tree_depth,
    penalty = penalty,
    mixture = mixture,
    ...
  )
}

# XY method - matrix

#' @export
#' @rdname rule_fit_ctb
rule_fit_ctb.matrix <- function(
  x,
  y,
  trees = 50,
  mtry = 1,
  learn_rate = 0.01,
  tree_depth = 4,
  penalty = 0.001,
  mixture = 1,
  ...
) {
  processed <- hardhat::mold(x, y)
  rule_fit_ctb_bridge(
    processed,
    trees = trees,
    mtry = mtry,
    learn_rate = learn_rate,
    tree_depth = tree_depth,
    penalty = penalty,
    mixture = mixture,
    ...
  )
}

# Formula method

#' @export
#' @rdname rule_fit_ctb
rule_fit_ctb.formula <- function(
  formula,
  data,
  trees = 50,
  mtry = 1,
  learn_rate = 0.01,
  tree_depth = 4,
  penalty = 0.001,
  mixture = 1,
  ...
) {
  bp <- hardhat::default_formula_blueprint(indicators = "none")
  processed <- hardhat::mold(formula, data, blueprint = bp)
  rule_fit_ctb_bridge(
    processed,
    trees = trees,
    mtry = mtry,
    learn_rate = learn_rate,
    tree_depth = tree_depth,
    penalty = penalty,
    mixture = mixture,
    ...
  )
}

# Recipe method

#' @export
#' @rdname rule_fit_ctb
rule_fit_ctb.recipe <- function(
  x,
  data,
  trees = 50,
  mtry = 1,
  learn_rate = 0.01,
  tree_depth = 4,
  penalty = 0.001,
  mixture = 1,
  ...
) {
  processed <- hardhat::mold(x, data)
  rule_fit_ctb_bridge(
    processed,
    trees = trees,
    mtry = mtry,
    learn_rate = learn_rate,
    tree_depth = tree_depth,
    penalty = penalty,
    mixture = mixture,
    ...
  )
}

# ------------------------------------------------------------------------------
# Bridge

rule_fit_ctb_bridge <- function(
  processed,
  trees,
  mtry,
  learn_rate,
  tree_depth,
  penalty,
  mixture,
  ...
) {
  rlang::check_installed("catboost")
  dots <- drop_ctb_min_n(list(...), call = rlang::caller_env())
  args <- split_dots(dots, engine = "ctb", call = rlang::caller_env())
  args$boost <- force_ctb_args(args$boost, call = rlang::caller_env())
  predictors <- processed$predictors
  outcome <- processed$outcomes[[1]]

  tree_fit <- rlang::exec(
    bonsai::train_catboost,
    x = predictors,
    y = outcome,
    iterations = trees,
    rsm = mtry,
    learning_rate = learn_rate,
    depth = tree_depth,
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
  train_data <- prune_rules(train_data)

  rule_names <- grep("^rule_", colnames(train_data), value = TRUE)
  rules <- rules[rules$label %in% rule_names, ]

  spec <-
    parsnip_spec(outcome, list(penalty = penalty, mixture = mixture)) |>
    parsnip::set_engine("glmnet", !!!args$glmnet)

  reg_fit <- parsnip::fit_xy(spec, x = train_data, y = outcome)

  new_rule_fit(
    rules = rules,
    fit = reg_fit,
    arguments = c(
      list(
        trees = trees,
        mtry = mtry,
        learn_rate = learn_rate,
        tree_depth = tree_depth,
        penalty = penalty,
        mixture = mixture
      ),
      args$boost,
      args$glmnet
    ),
    blueprint = processed$blueprint,
    training = list(
      rows = nrow(train_data),
      ptype = ptype
    ),
    class = c("rule_fit_ctb", "rule_fit")
  )
}

#' @export
print.rule_fit_ctb <- function(x, ...) {
  cli::cli_inform("RuleFit Using CatBoost")
  NextMethod()
}
