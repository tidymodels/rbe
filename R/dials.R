#' Parameter for the boosting method
#'
#' `boosting_method()` is a qualitative parameter for the `method` argument of
#' `rule_ensemble()`, which picks the boosting library used to make the rules.
#'
#' @param values A character vector of possible boosting methods. The default
#'   is `values_boosting_method`.
#'
#' @return A `qual_param` object from the dials package.
#'
#' @examples
#' boosting_method()
#' boosting_method(c("xgboost", "lightgbm"))
#' values_boosting_method
#' @export
boosting_method <- function(values = values_boosting_method) {
  dials::new_qual_param(
    type = "character",
    values = values,
    label = c(boosting_method = "Boosting Method"),
    finalize = NULL
  )
}

#' @rdname boosting_method
#' @export
values_boosting_method <- c("xgboost", "lightgbm", "catboost")
