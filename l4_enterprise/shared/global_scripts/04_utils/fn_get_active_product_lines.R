#' Get Active Product Lines from app_config.yaml
#'
#' Returns the subset of df_product_line that are active, excluding 'all'.
#' Source of truth for which product lines are active is app_config.yaml's
#' product_lines.active field, NOT the csv file.
#'
#' @param product_line_df Data frame of product lines (default: global df_product_line)
#' @param config App configuration list (default: global app_configs)
#' @return Data frame of active product lines (product_line_id != "all")
#'
#' @details
#' app_config.yaml setting:
#'   product_lines:
#'     active: all           # all product lines are active
#'     active: [hsg, blb]    # only these are active
#'
#' Replaces the old pattern of filtering by df_product_line$included == TRUE.
#' The 'included' column no longer exists in df_product_line.csv (#363).
#'
#' @examples
#' active_pl <- get_active_product_lines()
#' nrow(active_pl)
#'
#' @export
get_active_product_lines <- function(product_line_df = df_product_line,
                                     config = app_configs) {
  pl <- product_line_df[product_line_df$product_line_id != "all", , drop = FALSE]

  active_setting <- tryCatch(
    config$product_lines$active,
    error = function(e) "all"
  )

  if (is.null(active_setting) || identical(active_setting, "all")) {
    return(pl)
  }

  active_ids <- as.character(active_setting)
  result <- pl[pl$product_line_id %in% active_ids, , drop = FALSE]

  if (nrow(result) == 0) {
    stop("get_active_product_lines(): no active product lines found. ",
         "Check app_config.yaml > product_lines > active. ",
         "Current setting: ", paste(active_ids, collapse = ", "), ". ",
         "Available ids: ", paste(pl$product_line_id, collapse = ", "))
  }

  result
}
