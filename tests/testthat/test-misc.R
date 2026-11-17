# ------------------------------------------------------------------------------
# Helpers

zero_row <- function(x) {
  x[0, , drop = FALSE]
}

# model.matrix() with the attributes that model_matrix_sep() drops removed
base_mm <- function(dat) {
  withr::local_options(list(na.action = "na.pass"))
  res <- stats::model.matrix(~ . + 0, data = dat)
  res[,, drop = FALSE]
}

expect_same_values <- function(dat, sep = "_") {
  res <- model_matrix_sep(dat, zero_row(dat), sep = sep)
  expect_equal(unname(res), unname(base_mm(dat)))
  invisible(res)
}

# ------------------------------------------------------------------------------
# Basic behavior

test_that("default separator is an underscore", {
  dat <- data.frame(
    x = factor(c("a", "b", "c", "a")),
    y = factor(c("p", "q", "p", "q")),
    z = c(1.5, 2.5, 3.5, 4.5)
  )
  res <- expect_same_values(dat)
  expect_identical(colnames(res), c("x_a", "x_b", "x_c", "y_q", "z"))
  expect_identical(nrow(res), nrow(dat))
  expect_true(is.matrix(res))
  expect_true(is.numeric(res))
})

test_that("assign and contrasts attributes are removed", {
  dat <- data.frame(x = factor(c("a", "b")), z = 1:2)
  res <- model_matrix_sep(dat, zero_row(dat))
  expect_null(attr(res, "assign"))
  expect_null(attr(res, "contrasts"))
})

test_that("penguins data", {
  penguins <- penguins_complete()
  res <- expect_same_values(penguins)
  expect_identical(
    colnames(res),
    c(
      "species_Adelie",
      "species_Chinstrap",
      "species_Gentoo",
      "island_Dream",
      "island_Torgersen",
      "bill_length_mm",
      "bill_depth_mm",
      "flipper_length_mm",
      "body_mass_g",
      "sex_male"
    )
  )
})

# ------------------------------------------------------------------------------
# Name collisions and prefix ambiguity

test_that("a variable with a level equal to its name", {
  dat <- data.frame(x = factor(c("x", "y", "x")))
  res <- expect_same_values(dat)
  expect_identical(colnames(res), c("x_x", "x_y"))
})

test_that("levels that repeat the variable name and the separator", {
  dat <- data.frame(x = factor(c("x", "xx", "x_x", "x")))
  res <- expect_same_values(dat)
  expect_identical(colnames(res), c("x_x", "x_x_x", "x_xx"))
})

test_that("variable/level pairs that model.matrix() names identically", {
  dat <- data.frame(
    z = factor(c("p", "q", "p", "q")),
    a = factor(c("a0", "b1", "a0", "b1")),
    ab = factor(c("0", "1", "1", "0"))
  )
  # model.matrix() gives two columns named `ab1`
  expect_identical(sum(colnames(base_mm(dat)) == "ab1"), 2L)

  res <- expect_same_values(dat)
  expect_identical(colnames(res), c("z_p", "z_q", "a_b1", "ab_1"))
  expect_equal(unname(res[, "a_b1"]), c(0, 1, 0, 1))
  expect_equal(unname(res[, "ab_1"]), c(0, 1, 1, 0))
})

test_that("factor level pasted to its name matches a numeric column name", {
  dat <- data.frame(
    a = factor(c("b", "c", "b")),
    ab = c(1, 2, 3),
    ac = c(4, 5, 6)
  )
  res <- expect_same_values(dat)
  expect_identical(colnames(res), c("a_b", "a_c", "ab", "ac"))
  expect_equal(unname(res[, "ab"]), c(1, 2, 3))
})

test_that("duplicate names caused by the separator are an error", {
  dat <- data.frame(x = factor(c("y", "z")), x_y = c(1, 2))
  expect_snapshot(model_matrix_sep(dat, zero_row(dat)), error = TRUE)
  # a different separator avoids the collision
  res <- model_matrix_sep(dat, zero_row(dat), sep = ".")
  expect_identical(colnames(res), c("x.y", "x.z", "x_y"))
})

test_that("variable names that are prefixes of each other", {
  dat <- data.frame(
    x = factor(c("0", "1", "10", "0")),
    x1 = factor(c("0", "1", "10", "1")),
    x10 = factor(c("0", "1", "10", "10"))
  )
  res <- expect_same_values(dat)
  expect_identical(
    colnames(res),
    c("x_0", "x_1", "x_10", "x1_1", "x1_10", "x10_1", "x10_10")
  )
})

test_that("levels that are prefixes of each other", {
  dat <- data.frame(
    z = factor(c("p", "q", "p")),
    x = factor(c("a", "ab", "abc"))
  )
  res <- expect_same_values(dat)
  expect_identical(colnames(res), c("z_p", "z_q", "x_ab", "x_abc"))
})

# ------------------------------------------------------------------------------
# Unusual names and levels

test_that("non-syntactic column names never include backticks", {
  dat <- data.frame(
    `my var` = factor(c("a", "b")),
    `1x` = factor(c("a", "b")),
    `a-b` = factor(c("a", "b")),
    `a+b` = factor(c("a", "b")),
    `if` = factor(c("a", "b")),
    `x\`y` = factor(c("a", "b")),
    `num var` = c(1, 2),
    check.names = FALSE
  )
  res <- expect_same_values(dat)
  expect_identical(
    colnames(res),
    c(
      "my var_a",
      "my var_b",
      "1x_b",
      "a-b_b",
      "a+b_b",
      "if_b",
      "x`y_b",
      "num var"
    )
  )
})

test_that("levels with unusual characters", {
  lvls <- c(
    "base",
    "has space",
    ".",
    "a.b",
    "(x)",
    "[",
    "^",
    "$",
    "*",
    "é",
    "日本",
    "1st",
    "a_b",
    paste(rep("long", 50), collapse = "")
  )
  dat <- data.frame(
    z = factor(c("p", rep("q", length(lvls) - 1))),
    x = factor(lvls, levels = lvls)
  )
  res <- expect_same_values(dat)
  expect_identical(colnames(res), c("z_p", "z_q", paste0("x_", lvls[-1])))
})

test_that("an empty string level", {
  dat <- data.frame(x = factor(c("", "a", ""), levels = c("", "a")))
  res <- expect_same_values(dat)
  expect_identical(colnames(res), c("x_", "x_a"))
})

test_that("an explicit missing value level", {
  dat <- data.frame(x = addNA(factor(c("a", NA, "b"))))
  res <- expect_same_values(dat)
  expect_identical(colnames(res), c("x_a", "x_b", "x_NA"))
  expect_equal(unname(res[2, ]), c(0, 0, 1))

  new_res <- model_matrix_sep(dat[2, , drop = FALSE], zero_row(dat))
  expect_identical(colnames(new_res), colnames(res))
  expect_equal(unname(new_res[1, ]), c(0, 0, 1))
})

# ------------------------------------------------------------------------------
# Separators

test_that("other separators", {
  dat <- data.frame(
    x = factor(c("a", "b")),
    y = factor(c("c", "d")),
    z = 1:2
  )
  seps <- c(".", "__", ":", " ", "-sep-")
  for (sep in seps) {
    res <- expect_same_values(dat, sep = sep)
    expect_identical(
      colnames(res),
      c(paste0("x", sep, c("a", "b")), paste0("y", sep, "d"), "z")
    )
  }
})

test_that("an empty separator reproduces model.matrix() names", {
  dat <- data.frame(
    x = factor(c("x", "xx", "x_x")),
    `my var` = factor(c("a", "b", "a")),
    `if` = c(TRUE, FALSE, NA),
    e = factor(c("", "z", ""), levels = c("", "z")),
    n = addNA(factor(c("u", NA, "v"))),
    num = c(1, 2, 3),
    check.names = FALSE
  )
  res <- model_matrix_sep(dat, zero_row(dat), sep = "")
  expected <- gsub("`", "", colnames(base_mm(dat)))
  expect_identical(colnames(res), expected)
})

test_that("invalid separators", {
  dat <- data.frame(x = factor(c("a", "b")))
  expect_snapshot(model_matrix_sep(dat, zero_row(dat), sep = NA), error = TRUE)
  expect_snapshot(
    model_matrix_sep(dat, zero_row(dat), sep = NA_character_),
    error = TRUE
  )
  expect_snapshot(
    model_matrix_sep(dat, zero_row(dat), sep = character(0)),
    error = TRUE
  )
  expect_snapshot(
    model_matrix_sep(dat, zero_row(dat), sep = c("a", "b")),
    error = TRUE
  )
  expect_snapshot(model_matrix_sep(dat, zero_row(dat), sep = 1), error = TRUE)
})

# ------------------------------------------------------------------------------
# Column types

test_that("only numeric columns", {
  dat <- data.frame(a = c(1.5, 2.5), b = 3:4, `c d` = 5:6, check.names = FALSE)
  res <- expect_same_values(dat)
  expect_identical(colnames(res), c("a", "b", "c d"))
})

test_that("a single factor gets all indicators", {
  dat <- data.frame(x = factor(c("a", "b", "c")))
  res <- expect_same_values(dat)
  expect_identical(colnames(res), c("x_a", "x_b", "x_c"))
  expect_equal(unname(res), diag(3))
})

test_that("the first factor in ptype gets all levels", {
  dat <- data.frame(
    x = factor(c("a", "b", "a")),
    y = factor(c("p", "q", "r"))
  )
  res_xy <- model_matrix_sep(dat, zero_row(dat))
  expect_identical(colnames(res_xy), c("x_a", "x_b", "y_q", "y_r"))

  ptype_yx <- zero_row(dat[, c("y", "x")])
  res_yx <- model_matrix_sep(dat, ptype_yx)
  expect_identical(colnames(res_yx), c("y_p", "y_q", "y_r", "x_b"))

  # a numeric column first does not change that
  dat$num <- 1:3
  ptype_num <- zero_row(dat[, c("num", "x", "y")])
  res_num <- model_matrix_sep(dat, ptype_num)
  expect_identical(colnames(res_num), c("num", "x_a", "x_b", "y_q", "y_r"))
})

test_that("logical columns", {
  dat <- data.frame(z = factor(c("a", "b", "a")), l = c(TRUE, FALSE, NA))
  res <- expect_same_values(dat)
  expect_identical(colnames(res), c("z_a", "z_b", "l_TRUE"))
  expect_equal(unname(res[, "l_TRUE"]), c(1, 0, NA))

  first <- data.frame(l = c(TRUE, FALSE, NA))
  res_first <- expect_same_values(first)
  expect_identical(colnames(res_first), c("l_FALSE", "l_TRUE"))

  # new data with only one logical value has the same columns
  new_res <- model_matrix_sep(first[1, , drop = FALSE], zero_row(first))
  expect_identical(colnames(new_res), c("l_FALSE", "l_TRUE"))
  expect_equal(unname(new_res[1, ]), c(0, 1))
})

test_that("integer and double columns are unchanged", {
  dat <- data.frame(i = 1:3, d = c(0.5, 1.5, 2.5), x = factor(c("a", "b", "a")))
  res <- expect_same_values(dat)
  expect_identical(colnames(res), c("i", "d", "x_a", "x_b"))
  expect_equal(unname(res[, "i"]), c(1, 2, 3))
  expect_equal(unname(res[, "d"]), c(0.5, 1.5, 2.5))
})

test_that("ordered factors give indicators", {
  dat <- data.frame(
    z = factor(c("p", "q", "p")),
    o = factor(c("low", "mid", "high"), levels = c("low", "mid", "high"))
  )
  dat$o <- as.ordered(dat$o)
  res <- model_matrix_sep(dat, zero_row(dat))
  expect_identical(colnames(res), c("z_p", "z_q", "o_mid", "o_high"))
  expect_equal(unname(res[, "o_mid"]), c(0, 1, 0))
  expect_equal(unname(res[, "o_high"]), c(0, 0, 1))
})

test_that("the contrasts option does not change the results", {
  dat <- data.frame(
    x = factor(c("a", "b", "c")),
    y = factor(c("p", "q", "r")),
    o = as.ordered(factor(c("lo", "hi", "lo"), levels = c("lo", "hi"))),
    l = c(TRUE, FALSE, TRUE)
  )
  expected <- model_matrix_sep(dat, zero_row(dat))
  withr::local_options(contrasts = c("contr.sum", "contr.poly"))
  expect_identical(model_matrix_sep(dat, zero_row(dat)), expected)
})

test_that("unused levels still produce columns", {
  dat <- data.frame(
    x = factor(c("a", "b"), levels = c("a", "b", "c")),
    y = factor(c("p", "q"), levels = c("p", "q", "r"))
  )
  res <- model_matrix_sep(dat, zero_row(dat))
  expect_identical(colnames(res), c("x_a", "x_b", "x_c", "y_q", "y_r"))
  expect_all_equal(res[, "x_c"], 0)
  expect_all_equal(res[, "y_r"], 0)
})

test_that("single-level factors are an error", {
  dat <- data.frame(x = factor(c("a", "a")), y = factor(c("b", "b")), z = 1:2)
  expect_snapshot(model_matrix_sep(dat, zero_row(dat)), error = TRUE)
})

test_that("character columns in the ptype are an error", {
  dat <- data.frame(x = c("a", "b"), y = c("c", "d"), z = 1:2)
  expect_snapshot(model_matrix_sep(dat, zero_row(dat)), error = TRUE)
  expect_snapshot(
    model_matrix_sep(dat[, -2], zero_row(dat[, -2])),
    error = TRUE
  )
})

test_that("tibbles and data frames give the same results", {
  dat <- data.frame(
    x = factor(c("a", "b", "c")),
    `my var` = c(1, 2, 3),
    check.names = FALSE
  )
  tbl <- dplyr::as_tibble(dat)
  expect_identical(
    model_matrix_sep(tbl, zero_row(tbl)),
    model_matrix_sep(dat, zero_row(dat))
  )
  expect_identical(
    model_matrix_sep(dat, zero_row(tbl)),
    model_matrix_sep(tbl, zero_row(dat))
  )
})

test_that("zero-row data", {
  dat <- data.frame(x = factor(c("a", "b")), y = factor(c("c", "d")), z = 1:2)
  res <- model_matrix_sep(zero_row(dat), zero_row(dat))
  expect_identical(nrow(res), 0L)
  expect_identical(colnames(res), c("x_a", "x_b", "y_d", "z"))
})

test_that("missing values give missing rows", {
  dat <- data.frame(
    x = factor(c("a", NA, "b", "a")),
    y = factor(c("c", "d", NA, "c")),
    z = c(1, 2, 3, NA)
  )
  res <- expect_same_values(dat)
  expect_identical(nrow(res), 4L)
  expect_all_true(is.na(res[2, c("x_a", "x_b")]))
  expect_all_true(is.na(res[3, "y_d"]))
  expect_all_true(is.na(res[4, "z"]))
  expect_all_false(as.vector(is.na(res[1, ])))
})

# ------------------------------------------------------------------------------
# New data

new_data_setup <- function() {
  data.frame(
    x = factor(c("a", "b", "c", "a")),
    y = factor(c("p", "q", "r", "r")),
    l = c(TRUE, FALSE, TRUE, FALSE),
    z = c(1, 2, 3, 4)
  )
}

test_that("new data with one row", {
  dat <- new_data_setup()
  ptype <- zero_row(dat)
  train <- model_matrix_sep(dat, ptype)
  for (i in seq_len(nrow(dat))) {
    res <- model_matrix_sep(dat[i, ], ptype)
    expect_identical(colnames(res), colnames(train))
    expect_equal(unname(res[1, ]), unname(train[i, ]))
  }
})

test_that("new data with a subset of levels", {
  dat <- new_data_setup()
  ptype <- zero_row(dat)
  train <- model_matrix_sep(dat, ptype)
  new_dat <- droplevels(dat[c(1, 4), ])
  expect_identical(levels(new_dat$x), "a")

  res <- model_matrix_sep(new_dat, ptype)
  expect_identical(colnames(res), colnames(train))
  expect_equal(unname(res), unname(train[c(1, 4), ]))
})

test_that("new data with factor levels in a different order", {
  dat <- new_data_setup()
  ptype <- zero_row(dat)
  train <- model_matrix_sep(dat, ptype)
  new_dat <- dat
  new_dat$x <- factor(as.character(dat$x), levels = c("c", "b", "a"))
  new_dat$y <- factor(as.character(dat$y), levels = c("r", "q", "p", "s"))

  res <- model_matrix_sep(new_dat, ptype)
  expect_identical(colnames(res), colnames(train))
  expect_equal(unname(res), unname(train))
})

test_that("new data with reordered and extra columns", {
  dat <- new_data_setup()
  ptype <- zero_row(dat)
  train <- model_matrix_sep(dat, ptype)
  new_dat <- dat[, rev(names(dat))]
  new_dat$extra <- factor(letters[1:4])
  new_dat$x_a <- 1:4

  res <- model_matrix_sep(new_dat, ptype)
  expect_identical(colnames(res), colnames(train))
  expect_equal(unname(res), unname(train))
})

test_that("new data with factors stored as characters", {
  dat <- new_data_setup()
  ptype <- zero_row(dat)
  train <- model_matrix_sep(dat, ptype)
  new_dat <- dat
  new_dat$x <- as.character(dat$x)
  new_dat$y <- as.character(dat$y)

  res <- model_matrix_sep(new_dat[2:3, ], ptype)
  expect_identical(colnames(res), colnames(train))
  expect_equal(unname(res), unname(train[2:3, ]))
})

test_that("new data with values that are not levels", {
  dat <- new_data_setup()
  ptype <- zero_row(dat)
  new_dat <- dat
  new_dat$x <- factor(c("a", "zz", "c", "a"))
  new_dat$y <- c("p", "q", "nope", "r")

  expect_snapshot_warning(res <- model_matrix_sep(new_dat, ptype))
  expect_all_true(is.na(res[2, c("x_a", "x_b", "x_c")]))
  expect_all_true(is.na(res[3, c("y_q", "y_r")]))
  expect_all_false(as.vector(is.na(res[c(1, 4), ])))

  # existing missing values are not reported as new levels
  na_dat <- dat
  na_dat$x[1] <- NA
  expect_no_warning(model_matrix_sep(na_dat, ptype))
})

test_that("new data missing columns", {
  dat <- new_data_setup()
  ptype <- zero_row(dat)
  expect_snapshot(model_matrix_sep(dat[, c("x", "z")], ptype), error = TRUE)
  expect_snapshot(
    model_matrix_sep(dat[, "z", drop = FALSE], ptype),
    error = TRUE
  )
})

test_that("non-data frame inputs", {
  dat <- new_data_setup()
  expect_snapshot(model_matrix_sep(as.matrix(dat), zero_row(dat)), error = TRUE)
  expect_snapshot(model_matrix_sep(dat, NULL), error = TRUE)
  expect_snapshot(model_matrix_sep(dat), error = TRUE)
})

test_that("hardhat formula and xy blueprints", {
  penguins <- penguins_complete()
  penguins$island <- as.character(penguins$island)

  bp <- hardhat::default_formula_blueprint(indicators = "none")
  form <- hardhat::mold(body_mass_g ~ ., penguins, blueprint = bp)
  xy <- hardhat::mold(penguins[, -6], penguins$body_mass_g)

  for (processed in list(form, xy)) {
    ptype <- predictor_ptype(processed$predictors)
    train <- model_matrix_sep(processed$predictors, ptype)
    expect_true("island_Dream" %in% colnames(train))
    expect_true("species_Gentoo" %in% colnames(train))

    new_dat <- penguins[c(1, 200), -6]
    forged <- hardhat::forge(new_dat, processed$blueprint)
    res <- model_matrix_sep(forged$predictors, ptype)
    expect_identical(colnames(res), colnames(train))
    expect_equal(unname(res), unname(train[c(1, 200), ]))
  }
})

# ------------------------------------------------------------------------------
# predictor_ptype()

test_that("predictor_ptype() keeps the levels of character columns", {
  dat <- data.frame(
    x = c("b", "a", "b"),
    y = factor(c("p", "q", "p"), levels = c("q", "p")),
    z = 1:3
  )
  res <- predictor_ptype(dat)
  expect_identical(nrow(res), 0L)
  expect_named(res, c("x", "y", "z"))
  expect_identical(levels(res$x), c("a", "b"))
  expect_identical(levels(res$y), c("q", "p"))
  expect_type(res$z, "integer")
})
