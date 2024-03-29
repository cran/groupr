#' Pivot with Inapplicable Groups
#'
#' Pivot a dataset by defining the way the current grouping
#' will be transformed into a new one. A pivot to wider consumes
#' a row grouping (created by group_by2) and produces a new
#' set of columns. A pivot to longer consumes a column grouping
#' and produces a new row grouping.
#' 
#' To pivot a column grouping to a row grouping, pass the specification of the
#' new row grouping using the \code{cols} argument. The format is \code{list(values_col =
#' "oldcol_1", "oldcol_2", ...)}. This will take all the data from the old columns,
#' combine them into a new column \code{values_col}, and automatically provide
#' a grouping variable, which will be called \code{name}. The values of \code{name}
#' will be the corresponding names of the old columns.
#'
#' To pivot a row grouping to a column grouping, pass a grouped
#' dataset (using group_by2) and specify which grouping variable should
#' be consumed to produce a set of new columns.
#'
#' Both arguments can be passed in one call, in which case \code{rows} will be handled
#' first, followed by \code{cols}.
#'
#' See the introduction vignette for more details and examples.
#' 
#' @param x A data frame
#' @param rows A list of character vectors, defining the new row grouping
#' @param cols A character vector, defining the new columns
#' @return A pivoted data frame with the new grouping
#' 
#' @export
pivot_grps <- function (x, rows = NULL, cols = NULL) {
  if(is.null(rows) & is.null(cols)) { return(x) }
  if(is.null(rows)) {
    return(pivot_gc(x, cols))
  }
  if (is.null(cols)) {
    return(pivot_cg(x, rows))
  }
  pivot_gc(pivot_cg(x, rows), cols)
}
  

col_grps <- function (x, col) {
  cgrps <- attr(x, "colgroups")
  
  cbind(
    x[group_cols(data = x)],
    make_cols(x, cgrps$.index, col)
  )
}

make_cols <- function (x, col, nm) {
  map(names(x[-group_cols(data = x)]),
      ~ make_col(x, col, nm, .)) %>% 
    reduce(~ vec_cbind(.x, .y[-1]))
}

make_col <- function (x, col, nm, datacol) {
  out <- map(col, ~ tibble::tibble(
    !!nm := rep_along(x[[datacol]][[.]], .),
    !!datacol := x[[datacol]][[.]]
  )) %>%
    reduce(vctrs::vec_rbind)
}

pivot_cg <- function (x, rows) {
  old_igrps <- igroup_vars(x)
  if (length(rows) != 1) {
    abort("pivot_grps: argument `rows` must be a single string")
  }
  if (!rows %in% col_index_name(x)) { 
    abort(paste0("pivot_grps: column grouping `", rows, "` does not exist"), class = "error_miss_col")
  }
  out <- dplyr::group_modify(
    x, ~ col_grps(., rows)
  )
  group_by2(out, !!!old_igrps, !!rlang::sym(rows))
}
            
grp_cols <- function (x, colgrps) {
  grps <- attr(x, "groups")
  gnames <- names(grps[-length(grps)])
  dnames <- setdiff(names(x), gnames)
  grows <- grps[[".rows"]]

  sliced <- map(grows, ~ vec_slice(dplyr::ungroup(x[dnames]), .x)) %>% 
    transpose()

  newnames <- intersect(grps[[gnames]], colgrps)
  
  as_tibble(
    map(sliced, ~ as_tibble(setNames(., newnames)))
  )
}

pivot_gc <- function (x, col) {
  if (length(col) > 1 | !is.null(colgrp_vars(x))) { abort(
    "pivot_grps: cannot make more than one column index",
    class = "error_bad_arg"
  )}
  old_igrps <- igroup_vars(x)
  not_found <- col[!col %in% names(old_igrps)]
  if (length(not_found) != 0) {
    abort(paste0("pivot_grps: couldn't find the grouping variable requested by argument `col`.",
                 "\nMissing grouping variable: ",
                 paste0(not_found, collapse = ", ")),
          class = "error_bad_arg")
  }
  
  grp_rows <- group_data(x)$.rows
  not_uniq <- any(map_lgl(grp_rows, ~ length(.) > 1))
  if (not_uniq) {
    abort(paste0("pivot_grps: could not pivot from groups to columns.",
                 "\nThe grouping for `x` must uniquely identify rows.",
                 "\nCurrent grouping: ",
                 paste0(names(old_igrps), collapse = ", ")),
          class = "error_bad_pivot")
  }

  grps <- old_igrps[names(old_igrps) != col]
  exp <- expand_igrps(group_by2(x, !!!grps))
  
  # dplyr::group_by avoids polymiss vectors
  grp_dat <- group_data(dplyr::group_by(exp, !!!syms(col)))
  attr(grp_dat, ".drop") <- NULL
  
  colgrps <- grp_dat[-length(grp_dat)][[1]]

  out <-
    exp %>%
    group_by(!!!syms(group_vars(exp))) %>%
    dplyr::group_modify(~ grp_cols(dplyr::group_by(., !!!syms(col)),
                                   colgrps)) %>%
    group_by2(!!!syms(names(grps)))

  infer_colgrps(out, index_name = col)
}
