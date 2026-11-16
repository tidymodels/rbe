# translate() maps the arguments to rule_ensemble()

    Code
      parsnip::translate(spec)
    Output
      RuleFit Model Specification (regression)
      
      Main Arguments:
        mtry = 0.5
        trees = 7
        min_n = 2
        tree_depth = 3
        learn_rate = 0.1
        penalty = 0.01
      
      Engine-Specific Arguments:
        method = xgboost
        mixture = 0.5
      
      Computational engine: rule_ensemble 
      
      Model fit template:
      rbe::rule_ensemble(x = missing_arg(), y = missing_arg(), weights = missing_arg(), 
          mtry = 0.5, trees = 7, min_n = 2, tree_depth = 3, learn_rate = 0.1, 
          penalty = 0.01, method = "xgboost", mixture = 0.5)

# an invalid method is an error

    Code
      parsnip::fit(spec, mpg ~ ., data = mtcars)
    Condition
      Error in `rbe::rule_ensemble()`:
      ! `method` must be one of "xgboost", "lightgbm", or "catboost", not "ranger".

# an unknown engine argument is an error

    Code
      parsnip::fit(spec, mpg ~ ., data = mtcars)
    Condition
      Error in `rule_ensemble_xgb()`:
      ! `not_an_option` is not a valid argument for xgboost or `glmnet::glmnet()`.

# min_n with catboost is ignored with a warning

    `min_n` is not used by `rule_ensemble_ctb()` and was ignored.
    i catboost's default "SymmetricTree" grow policy does not use a minimum node size.
    i To set one, pass `min_data_in_leaf` along with `grow_policy = "Depthwise"` or `grow_policy = "Lossguide"`.

# multi_predict() catches `newdata`

    Code
      multi_predict(mod, newdata = mtcars[1:2, -1], penalty = 0.1)
    Condition
      Error in `multi_predict()`:
      ! Please use `new_data` instead of `newdata`.

# print() for a specification and a fit

    Code
      print(spec)
    Output
      RuleFit Model Specification (regression)
      
      Main Arguments:
        trees = 5
        penalty = 0.01
      
      Engine-Specific Arguments:
        method = xgboost
      
      Computational engine: rule_ensemble 
      

---

    Code
      print(mod)
    Output
      parsnip model object
      
    Message
      RuleFit Using XGBoost
      Training Set:
      i Samples: 32
      i Predictors: 10
      i Rules: <n>
      Arguments:
      * trees: 5
      * mtry: 1
      * learn_rate: 0.01
      * tree_depth: 4
      * min_n: 5
      * penalty: 0.01
      * mixture: 1
      * counts: FALSE

