# multi_predict() errors with a bad prediction type

    Code
      multi_predict(mod, mtcars[1:2, -1], type = "class")
    Condition
      Error in `parsnip::multi_predict()`:
      ! For class predictions, the object should be a classification model.

