skip_if_not_installed("xgboost")

test_that("factor predictors are converted to one-hot indicators", {
  penguins <- penguins_complete()
  set.seed(4093)
  mod <- rule_fit_xgb(body_mass_g ~ ., data = penguins, trees = 5)

  expect_s3_class(mod$training$one_hot$species, "factor")
  expect_all_true(
    c("species_Adelie", "species_Gentoo", "island_Biscoe", "sex_female") %in%
      names(mod$training$ptype)
  )
  expect_all_false(vapply(mod$training$ptype, is.factor, logical(1)))

  new_data <- penguins[c(1, 300), -6]
  expect_identical(nrow(predict(mod, new_data)), 2L)
  res <- multi_predict(mod, new_data, penalty = c(0.01, 0.1))
  expect_identical(nrow(res$.pred[[1]]), 2L)
})

test_that("xy and recipe interfaces with factor predictors", {
  skip_if_not_installed("recipes")
  penguins <- penguins_complete()
  new_data <- penguins[1, -6]

  set.seed(7735)
  xy_mod <- rule_fit_xgb(penguins[, -6], penguins$body_mass_g, trees = 5)
  expect_identical(nrow(predict(xy_mod, new_data)), 1L)

  rec <- recipes::recipe(body_mass_g ~ ., data = penguins)
  set.seed(1590)
  rec_mod <- rule_fit_xgb(rec, penguins, trees = 5)
  expect_identical(nrow(predict(rec_mod, new_data)), 1L)
})

test_that("numeric predictors are unchanged", {
  set.seed(2261)
  mod <- rule_fit_xgb(mpg ~ ., data = mtcars, trees = 5)
  expect_identical(names(mod$training$ptype), names(mtcars)[-1])
  expect_identical(nrow(predict(mod, mtcars[1:2, -1])), 2L)
})
