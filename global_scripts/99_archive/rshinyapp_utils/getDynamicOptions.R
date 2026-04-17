  dta %>%
    dplyr::filter({{invariable}} %in% list) %>%
    dplyr::pull({{outvariable}}) %>%
    unique() %>%
    sort()
}
