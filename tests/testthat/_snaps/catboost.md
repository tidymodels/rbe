# final_ctr_computation_mode is always 'Skip'

    `final_ctr_computation_mode` is always set to "Skip"; the value "Default" was ignored.

# min_n is ignored with a warning

    `min_n` is not used by `rule_fit_ctb()` and was ignored.
    i catboost's default "SymmetricTree" grow policy does not use a minimum node size.
    i To set one, pass `min_data_in_leaf` along with `grow_policy = "Depthwise"` or `grow_policy = "Lossguide"`.

# unknown options error before fitting

    Code
      rule_fit_ctb(mpg ~ ., data = mtcars, fooo = 1)
    Condition
      Error in `rule_fit_ctb()`:
      ! `fooo` is not a valid argument for catboost or `glmnet::glmnet()`.

