# values must be character

    Code
      boosting_method(1:3)
    Condition
      Error in `boosting_method()`:
      ! `values` must be a character vector, not an integer vector.

---

    Code
      boosting_method(TRUE)
    Condition
      Error in `boosting_method()`:
      ! `values` must be a character vector, not `TRUE`.

# print method shows the label and values

    Code
      boosting_method()
    Message
      Boosting Method (qualitative)
      3 possible values include:
      'xgboost', 'lightgbm', and 'catboost'

