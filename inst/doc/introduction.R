## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## -----------------------------------------------------------------------------
library(dplyr, warn.conflicts = FALSE)
group_by(mtcars, vs)

## ----echo=FALSE---------------------------------------------------------------
library(groupr)
group_by2(mtcars, vs = 1) # sets the group vs==1 to inapplicable

## -----------------------------------------------------------------------------
as_tibble(iris)

## -----------------------------------------------------------------------------
iris2 <- group_by2(iris, Species) %>% 
  colgrp("value", "type")

pivot_grps(iris2, rows = "type")

## -----------------------------------------------------------------------------
df <- tibble(
  grp = c(1, 1, 1, 1, 2),
  subgrp = c(1, 2, 3, 4, NA),
  val = c(3.1, 2.8, 4.0, 3.8, 10.2)
)

df

## -----------------------------------------------------------------------------
regular_df <- group_by2(df, grp, subgrp)
pivot_grps(regular_df, cols = "grp")

## -----------------------------------------------------------------------------
igrp_df <- group_by2(df, grp, subgrp = NA)
pivot_grps(igrp_df, cols = "grp")

## ----eval=FALSE---------------------------------------------------------------
#  mtcars %>%
#    group_by2(vs = 0) %>%
#    mutate(hp_mean_vs1 = mean(hp))

