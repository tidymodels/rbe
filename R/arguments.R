# ------------------------------------------------------------------------------
# Taken from bonsai
# covr start
catboost_aliases <- tibble::tribble(
  ~parsnip      , ~catboost               , ~alias              ,
  "trees"       , "iterations"            , "n_estimators"      ,
  "trees"       , "iterations"            , "num_boost_round"   ,
  "trees"       , "iterations"            , "num_trees"         ,
  "trees"       , "iterations"            , "num_round"         ,
  "trees"       , "iterations"            , "n_iter"            ,
  "learn_rate"  , "learning_rate"         , "eta"               ,
  "tree_depth"  , "depth"                 , "max_depth"         ,
  "mtry"        , "rsm"                   , "colsample_bylevel" ,
  "min_n"       , "min_data_in_leaf"      , "min_child_samples" ,
  "min_n"       , "min_data_in_leaf"      , "min_samples_leaf"  ,
  "sample_size" , "subsample"             , "bagging_fraction"  ,
  "stop_iter"   , "early_stopping_rounds" , "early_stopping"    ,
  "stop_iter"   , "early_stopping_rounds" , "od_wait"
)
# covr end

# ------------------------------------------------------------------------------
# Route the options in `...` to either the boosting function or glmnet

split_dots <- function(dots, engine, call = rlang::caller_env()) {
  engine <- rlang::arg_match0(engine, c("xgb", "lgb", "ctb"))
  res <- list(boost = list(), glmnet = list())
  if (length(dots) == 0) {
    return(res)
  }

  nms <- names(dots)
  if (is.null(nms) || any(nms == "")) {
    cli::cli_abort(
      "All arguments passed to {.arg ...} must be named.",
      call = call
    )
  }
  if (anyDuplicated(nms) > 0) {
    dup <- unique(nms[duplicated(nms)])
    cli::cli_abort(
      "{cli::qty(dup)}Argument{?s} {.arg {dup}} {?was/were} passed to
       {.arg ...} more than once.",
      call = call
    )
  }

  check_protected_args(nms, engine, call = call)

  in_boost <- nms %in% boost_arg_names(engine)
  in_glmnet <- nms %in% glmnet_arg_names() & !in_boost

  unknown <- nms[!in_boost & !in_glmnet]
  if (length(unknown) > 0) {
    candidates <- setdiff(
      c(boost_arg_names(engine), glmnet_arg_names()),
      protected_args(engine)$name
    )
    msg <- c(
      "{cli::qty(unknown)}{.arg {unknown}} {?is not a/are not} valid
       argument{?s} for {engine_label(engine)} or {.fn glmnet::glmnet}."
    )
    msg <- c(msg, suggest_names(unknown, candidates))
    cli::cli_abort(msg, call = call)
  }

  res$boost <- dots[in_boost]
  res$glmnet <- dots[in_glmnet]
  res
}

engine_label <- function(engine) {
  switch(engine, xgb = "xgboost", lgb = "lightgbm", ctb = "catboost")
}

suggest_names <- function(x, candidates, max_dist = 2) {
  candidates <- unique(candidates)
  res <- character(0)
  for (nm in x) {
    dist <- utils::adist(nm, candidates)[1, ]
    # Short names are close to too many unrelated names
    nm_max_dist <- min(max_dist, ceiling(nchar(nm) / 3))
    if (min(dist) <= nm_max_dist) {
      best <- candidates[which.min(dist)]
      res <- c(
        res,
        i = paste0("Did you mean {.arg ", best, "} instead of {.arg ", nm, "}?")
      )
    }
  }
  res
}

glmnet_arg_names <- function() {
  # `alpha` and `lambda` are set via `mixture` and `penalty`
  excl <- c("x", "y", "family", "weights", "offset", "alpha", "lambda", "...")
  # `path_values` is not a glmnet argument, but parsnip's glmnet engine uses
  # it to set the lambda sequence
  c(setdiff(names(formals(glmnet::glmnet)), excl), "path_values")
}

boost_arg_names <- function(engine) {
  if (engine == "xgb") {
    rlang::check_installed("xgboost", version = "3.0.0")
    res <- c(
      names(formals(xgboost::xgb.params)),
      names(formals(xgboost::xgb.train)),
      names(formals(parsnip::xgb_train))
    )
  } else if (engine == "lgb") {
    rlang::check_installed("lightgbm")
    lgb_aliases <- lightgbm_param_aliases()
    res <- c(
      names(lgb_aliases),
      unlist(lgb_aliases, use.names = FALSE),
      names(formals(lightgbm::lgb.train)),
      names(formals(lightgbm::lgb.Dataset)),
      names(formals(bonsai::train_lightgbm))
    )
  } else {
    res <- c(catboost_params$name, names(formals(bonsai::train_catboost)))
  }
  setdiff(unique(res), "...")
}

lightgbm_param_aliases <- function() {
  utils::getFromNamespace(".PARAMETER_ALIASES", "lightgbm")()
}

# Returns a data frame of argument names that cannot be passed through `...`.
# `use` is the argument to use instead, or `NA` when rbe sets the value.
protected_args <- function(engine) {
  internal <- c("x", "y", "data", "weights", "formula")
  res <- data.frame(name = internal, use = NA_character_)

  main_args <- c("trees", "mtry", "learn_rate", "tree_depth")

  if (engine == "xgb") {
    res <- rbind(
      res,
      data.frame(
        name = c(
          "nrounds",
          "eta",
          "learning_rate",
          "max_depth",
          "colsample_bynode",
          "min_child_weight"
        ),
        use = c(
          "trees",
          "learn_rate",
          "learn_rate",
          "tree_depth",
          "mtry",
          "min_n"
        )
      ),
      data.frame(
        name = c("params", "evals", "xgb_model"),
        use = NA_character_
      )
    )
  } else if (engine == "lgb") {
    bonsai_aliases <- utils::getFromNamespace("lightgbm_aliases", "bonsai")
    res <- rbind(
      res,
      data.frame(
        name = c(
          "num_iterations",
          "learning_rate",
          "max_depth",
          "feature_fraction_bynode",
          "min_data_in_leaf"
        ),
        use = c("trees", "learn_rate", "tree_depth", "mtry", "min_n")
      ),
      bonsai_alias_table(bonsai_aliases, "lightgbm", c(main_args, "min_n")),
      # These are either set by bonsai or ignored by it
      data.frame(
        name = c(
          "params",
          "valids",
          "label",
          "reference",
          "group",
          "obj",
          "init_model",
          "colnames",
          "categorical_feature",
          "callbacks",
          "reset_data"
        ),
        use = NA_character_
      ),
      data.frame(name = c("weight", "quiet"), use = c("weights", "verbose"))
    )
  } else {
    bonsai_aliases <- catboost_aliases
    # catboost aliases for arguments of `bonsai::train_catboost()` would be
    # passed alongside bonsai's own value for that argument
    ctb_formals <- names(formals(bonsai::train_catboost))
    is_formal_alias <-
      catboost_params$param %in%
      ctb_formals &
      catboost_params$name != catboost_params$param
    formal_aliases <- catboost_params[is_formal_alias, ]
    formal_aliases <- data.frame(
      name = formal_aliases$name,
      use = formal_aliases$param
    )
    res <- rbind(
      res,
      data.frame(
        name = c(
          "iterations",
          "learning_rate",
          "depth",
          "rsm",
          "lambda",
          "alpha"
        ),
        use = c(
          "trees",
          "learn_rate",
          "tree_depth",
          "mtry",
          "penalty",
          "mixture"
        )
      ),
      bonsai_alias_table(bonsai_aliases, "catboost", main_args),
      formal_aliases,
      data.frame(name = "quiet", use = "verbose")
    )
  }
  res[!duplicated(res$name), ]
}

# bonsai errors when aliases of its main arguments are used, so redirect users
# to rbe's argument or the main engine argument name.
bonsai_alias_table <- function(aliases, engine_col, main_args) {
  use <- ifelse(
    aliases$parsnip %in% main_args,
    aliases$parsnip,
    aliases[[engine_col]]
  )
  data.frame(name = aliases$alias, use = use)
}

check_protected_args <- function(nms, engine, call = rlang::caller_env()) {
  prot <- protected_args(engine)
  prot <- prot[prot$name %in% nms, ]
  if (nrow(prot) == 0) {
    return(invisible(NULL))
  }

  msg <- "{cli::qty(nrow(prot))}{?This argument/These arguments} cannot be
          passed to {.arg ...}:"
  for (i in seq_len(nrow(prot))) {
    if (is.na(prot$use[i])) {
      bullet <- paste0("{.arg ", prot$name[i], "} is set by rbe.")
    } else {
      bullet <- paste0(
        "Use {.arg ",
        prot$use[i],
        "} instead of {.arg ",
        prot$name[i],
        "}."
      )
    }
    msg <- c(msg, "*" = bullet)
  }
  cli::cli_abort(msg, call = call)
}

# catboost's default symmetric trees have no minimum node size, so
# `rule_ensemble_ctb()` has no `min_n` argument. Warn instead of erroring since
# `min_n` is a main argument for the other engines. The warning is only given
# when `verbose = TRUE`.
drop_ctb_min_n <- function(dots, verbose = FALSE, call = rlang::caller_env()) {
  if (!"min_n" %in% names(dots)) {
    return(dots)
  }
  if (!verbose) {
    return(dots[names(dots) != "min_n"])
  }
  cli::cli_warn(
    c(
      "{.arg min_n} is not used by {.fn rule_ensemble_ctb} and was ignored.",
      i = "catboost's default {.val SymmetricTree} grow policy does not use
           a minimum node size.",
      i = "To set one, pass {.arg min_data_in_leaf} along with
           {.code grow_policy = \"Depthwise\"} or
           {.code grow_policy = \"Lossguide\"}."
    ),
    call = call
  )
  dots[names(dots) != "min_n"]
}

# ------------------------------------------------------------------------------
# Valid catboost parameters

# BEGIN GENERATED by data-raw/catboost-params.R: do not edit by hand
# Source: https://github.com/catboost/catboost/tree/8e83b235649315902fa8ee5132e437c971f040ee/catboost/docs/en/references/training-parameters
# Commit date: 2026-11-15T08:48:45Z
# catboost R package version: 1.2.10

# `name` is a parameter or one of its aliases; `param` is the main name.
catboost_params <- data.frame(
  name = c(
    "allow_const_label",
    "allow_writing_files",
    "approx_on_full_history",
    "auto_class_weights",
    "bagging_temperature",
    "best_model_min_trees",
    "boost_from_average",
    "boosting_type",
    "bootstrap_type",
    "border",
    "border_count",
    "max_bin",
    "class_names",
    "class_weights",
    "classes_count",
    "combinations_ctr",
    "counter_calc_method",
    "ctr_leaf_count_limit",
    "ctr_target_border_count",
    "custom_loss",
    "custom_metric",
    "data_partition",
    "depth",
    "max_depth",
    "dev_efb_max_buckets",
    "dev_score_calc_obj_block_size",
    "devices",
    "dictionaries",
    "diffusion_temperature",
    "early_stopping_rounds",
    "eval_metric",
    "feature_border_type",
    "feature_calcers",
    "feature_weights",
    "final_ctr_computation_mode",
    "first_feature_use_penalties",
    "fixed_binary_splits",
    "fold_len_multiplier",
    "fold_permutation_block",
    "gpu_cat_features_storage",
    "gpu_ram_part",
    "grow_policy",
    "has_time",
    "ignored_features",
    "input_borders",
    "iterations",
    "num_boost_round",
    "n_estimators",
    "num_trees",
    "l2_leaf_reg",
    "reg_lambda",
    "langevin",
    "leaf_estimation_backtracking",
    "leaf_estimation_iterations",
    "leaf_estimation_method",
    "learning_rate",
    "eta",
    "logging_level",
    "loss_function",
    "objective",
    "max_ctr_complexity",
    "max_leaves",
    "num_leaves",
    "metric_period",
    "min_data_in_leaf",
    "min_child_samples",
    "model_shrink_mode",
    "model_shrink_rate",
    "model_size_reg",
    "monotone_constraints",
    "mvs_reg",
    "name",
    "nan_mode",
    "od_pval",
    "od_type",
    "od_wait",
    "one_hot_max_size",
    "output_borders",
    "penalties_coefficient",
    "per_feature_ctr",
    "per_float_feature_quantization",
    "per_object_feature_penalties",
    "pinned_memory_size",
    "posterior_sampling",
    "prediction_type",
    "random_seed",
    "random_state",
    "random_strength",
    "roc_file",
    "rsm",
    "colsample_bylevel",
    "sampling_frequency",
    "sampling_unit",
    "save_snapshot",
    "scale_pos_weight",
    "score_function",
    "simple_ctr",
    "snapshot_file",
    "snapshot_interval",
    "sparse_features_conflict_fraction",
    "store_all_simple_ctr",
    "subsample",
    "target_border",
    "task_type",
    "text_processing",
    "thread_count",
    "tokenizers",
    "train_dir",
    "use_best_model",
    "used_ram_limit",
    "verbose",
    "verbose_eval"
  ),
  param = c(
    "allow_const_label",
    "allow_writing_files",
    "approx_on_full_history",
    "auto_class_weights",
    "bagging_temperature",
    "best_model_min_trees",
    "boost_from_average",
    "boosting_type",
    "bootstrap_type",
    "border",
    "border_count",
    "border_count",
    "class_names",
    "class_weights",
    "classes_count",
    "combinations_ctr",
    "counter_calc_method",
    "ctr_leaf_count_limit",
    "ctr_target_border_count",
    "custom_loss",
    "custom_metric",
    "data_partition",
    "depth",
    "depth",
    "dev_efb_max_buckets",
    "dev_score_calc_obj_block_size",
    "devices",
    "dictionaries",
    "diffusion_temperature",
    "early_stopping_rounds",
    "eval_metric",
    "feature_border_type",
    "feature_calcers",
    "feature_weights",
    "final_ctr_computation_mode",
    "first_feature_use_penalties",
    "fixed_binary_splits",
    "fold_len_multiplier",
    "fold_permutation_block",
    "gpu_cat_features_storage",
    "gpu_ram_part",
    "grow_policy",
    "has_time",
    "ignored_features",
    "input_borders",
    "iterations",
    "iterations",
    "iterations",
    "iterations",
    "l2_leaf_reg",
    "l2_leaf_reg",
    "langevin",
    "leaf_estimation_backtracking",
    "leaf_estimation_iterations",
    "leaf_estimation_method",
    "learning_rate",
    "learning_rate",
    "logging_level",
    "loss_function",
    "loss_function",
    "max_ctr_complexity",
    "max_leaves",
    "max_leaves",
    "metric_period",
    "min_data_in_leaf",
    "min_data_in_leaf",
    "model_shrink_mode",
    "model_shrink_rate",
    "model_size_reg",
    "monotone_constraints",
    "mvs_reg",
    "name",
    "nan_mode",
    "od_pval",
    "od_type",
    "od_wait",
    "one_hot_max_size",
    "output_borders",
    "penalties_coefficient",
    "per_feature_ctr",
    "per_float_feature_quantization",
    "per_object_feature_penalties",
    "pinned_memory_size",
    "posterior_sampling",
    "prediction_type",
    "random_seed",
    "random_seed",
    "random_strength",
    "roc_file",
    "rsm",
    "rsm",
    "sampling_frequency",
    "sampling_unit",
    "save_snapshot",
    "scale_pos_weight",
    "score_function",
    "simple_ctr",
    "snapshot_file",
    "snapshot_interval",
    "sparse_features_conflict_fraction",
    "store_all_simple_ctr",
    "subsample",
    "target_border",
    "task_type",
    "text_processing",
    "thread_count",
    "tokenizers",
    "train_dir",
    "use_best_model",
    "used_ram_limit",
    "verbose",
    "verbose"
  )
)
# END GENERATED
