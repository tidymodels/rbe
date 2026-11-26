# Create a model matrix with separated indicator column names

[`stats::model.matrix()`](https://rdrr.io/r/stats/model.matrix.html)
names indicator columns by pasting the column name and the factor level
together (e.g., `speciesGentoo`). This function makes the same matrix
but puts a separator between them (e.g., `species_Gentoo`).

## Usage

``` r
model_matrix_sep(data, ptype, sep = "_")
```

## Arguments

- data:

  A data frame of predictors.

- ptype:

  A zero-row data frame with the columns, types, and factor levels used
  to make the matrix (e.g., `training_data[0, , drop = FALSE]`). Using
  the same `ptype` for the training set and for new data guarantees the
  same columns. Character columns are not allowed since their levels are
  not retained; convert them to factors first.

- sep:

  A single string placed between the column name and the level.

## Value

A numeric matrix with the same number of rows as `data`.

## Details

Indicators are made with treatment contrasts regardless of
`options("contrasts")`. As with `model.matrix(~ . + 0, data)`, the first
factor (in `ptype` column order) gets an indicator for every level and
later factors drop their first level. Ordered factors are treated as
unordered factors. Logical columns are treated as factors with levels
`FALSE` and `TRUE`. Missing values are retained as missing rows.

Columns of `data` not in `ptype` are ignored. Values of a factor column
that are not levels in `ptype` are converted to `NA` with a warning.

Column names are found from the position of each column in the matrix,
not by parsing names, so a column `x` with a level `"x"` becomes `x_x`.

## Examples

``` r
if (rlang::is_installed("modeldata")) {
  penguins <- modeldata::penguins
  ptype <- penguins[0, c("species", "island", "bill_length_mm")]

  train_mat <- model_matrix_sep(penguins, ptype)
  head(train_mat)

  model_matrix_sep(penguins[1, ], ptype, sep = ".")
}
#>   species.Adelie species.Chinstrap species.Gentoo island.Dream
#> 1              1                 0              0            0
#>   island.Torgersen bill_length_mm
#> 1                1           39.1
```
