# multi_predict() errors with a bad prediction type

    Code
      multi_predict(mod, mtcars[1:2, -1], type = "class")
    Condition
      Error in `parsnip::multi_predict()`:
      ! For class predictions, the object should be a classification model.

# print() shows the type of case weights

    Code
      print(mod)
    Message
      RuleFit Using CatBoost
      Training Set:
      i Samples: 32
      i Predictors: 10
      i Rules: <n>
      i Case weights: importance
      Arguments:
      * trees: 5
      * mtry: 1
      * learn_rate: 0.01
      * tree_depth: 4
      * penalty: 0.001
      * mixture: 1
      * logging_level: Silent
      * allow_writing_files: FALSE
      * final_ctr_computation_mode: Skip

# print() counts the original predictors, not indicators

    Code
      print(mod)
    Message
      RuleFit Using XGBoost
      Training Set:
      i Samples: 333
      i Predictors: 6
      i Rules: <n>
      Arguments:
      * trees: 5
      * mtry: 1
      * learn_rate: 0.01
      * tree_depth: 4
      * min_n: 5
      * penalty: 0.001
      * mixture: 1
      * counts: FALSE

# print() with logical, vector, and brace-containing arguments

    Code
      print(mod)
    Message
      RuleFit Using CatBoost
      Training Set:
      i Samples: 32
      i Predictors: 10
      i Rules: <n>
      Arguments:
      * trees: 5
      * mtry: 1
      * learn_rate: 0.01
      * tree_depth: 4
      * penalty: 0.001
      * mixture: 1
      * logging_level: Silent
      * allow_writing_files: FALSE
      * custom_metric: RMSE, MAE
      * name: {experiment}
      * final_ctr_computation_mode: Skip
      * standardize: FALSE

# predict() errors when predictors are missing

    Code
      predict(mod, mtcars[1:2, c("cyl", "disp")])
    Condition
      Error in `hardhat::forge()`:
      ! The required columns "hp", "drat", "wt", "qsec", "vs", "am", "gear", and "carb" are missing.

# predict() errors with a bad prediction type

    Code
      predict(mod, mtcars[1:2, -1], type = "prob")
    Condition
      Error in `predict.model_fit()`:
      ! For probability predictions, the object should be a classification model.

# tidy() errors with a bad `what`

    Code
      tidy(mod, what = "coefs")
    Condition
      Error in `tidy()`:
      ! `what` must be one of "glmnet" or "rules", not "coefs".

