# min_n is passed to lightgbm

    Code
      rule_fit_lgb(class ~ ., data = hpc_subset(), min_data_in_leaf = 12)
    Condition
      Error in `rule_fit_lgb()`:
      ! This argument cannot be passed to `...`:
      * Use `min_n` instead of `min_data_in_leaf`.

