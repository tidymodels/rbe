new_rule_fit <- function(rules, fit, arguments, blueprint, training, class) {
  hardhat::new_model(
    rules = rules,
    fit = fit,
    arguments = arguments,
    blueprint = blueprint,
    training = training,
    class = class
  )
}
