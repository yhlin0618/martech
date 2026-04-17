  dta %>%
    dplyr::select({{ variable }}) %>%
    dplyr::pull() %>%
    unique() %>% 
    sort()
}
