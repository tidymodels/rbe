# duplicate names caused by the separator are an error

    Code
      model_matrix_sep(dat, zero_row(dat))
    Condition
      Error in `model_matrix_sep()`:
      ! Using `sep = "_"` creates duplicate column name "x_y".
      i Use a different value of `sep`.

# invalid separators

    Code
      model_matrix_sep(dat, zero_row(dat), sep = NA)
    Condition
      Error in `model_matrix_sep()`:
      ! `sep` must be a single string, not `NA`.

---

    Code
      model_matrix_sep(dat, zero_row(dat), sep = NA_character_)
    Condition
      Error in `model_matrix_sep()`:
      ! `sep` must be a single string, not a character `NA`.

---

    Code
      model_matrix_sep(dat, zero_row(dat), sep = character(0))
    Condition
      Error in `model_matrix_sep()`:
      ! `sep` must be a single string, not an empty character vector.

---

    Code
      model_matrix_sep(dat, zero_row(dat), sep = c("a", "b"))
    Condition
      Error in `model_matrix_sep()`:
      ! `sep` must be a single string, not a character vector.

---

    Code
      model_matrix_sep(dat, zero_row(dat), sep = 1)
    Condition
      Error in `model_matrix_sep()`:
      ! `sep` must be a single string, not a number.

# single-level factors are an error

    Code
      model_matrix_sep(dat, zero_row(dat))
    Condition
      Error in `model_matrix_sep()`:
      ! Factor columns `x` and `y` in `ptype` must have at least two levels.

# character columns in the ptype are an error

    Code
      model_matrix_sep(dat, zero_row(dat))
    Condition
      Error in `model_matrix_sep()`:
      ! Columns `x` and `y` in `ptype` are character.
      i Convert them to factors so that the levels are retained.

---

    Code
      model_matrix_sep(dat[, -2], zero_row(dat[, -2]))
    Condition
      Error in `model_matrix_sep()`:
      ! Column `x` in `ptype` is character.
      i Convert it to a factor so that the levels are retained.

# new data with values that are not levels

    Columns `x` and `y` have values that are not levels in `ptype`; they were converted to `NA`.

# new data missing columns

    Code
      model_matrix_sep(dat[, c("x", "z")], ptype)
    Condition
      Error in `model_matrix_sep()`:
      ! `data` is missing columns `y` and `l`.

---

    Code
      model_matrix_sep(dat[, "z", drop = FALSE], ptype)
    Condition
      Error in `model_matrix_sep()`:
      ! `data` is missing columns `x`, `y`, and `l`.

# non-data frame inputs

    Code
      model_matrix_sep(as.matrix(dat), zero_row(dat))
    Condition
      Error in `model_matrix_sep()`:
      ! `data` must be a data frame, not a character matrix.

---

    Code
      model_matrix_sep(dat, NULL)
    Condition
      Error in `model_matrix_sep()`:
      ! `ptype` must be a data frame, not NULL.

---

    Code
      model_matrix_sep(dat)
    Condition
      Error in `model_matrix_sep()`:
      ! argument "ptype" is missing, with no default

