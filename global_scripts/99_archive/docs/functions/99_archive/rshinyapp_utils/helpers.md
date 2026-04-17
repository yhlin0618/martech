# helpers

Source: `99_archive/rshinyapp_utils/helpers.R`

## Functions

**Function List:**
- [safe_get](#safe-get)
- [formattime](#formattime)
- [make_names](#make-names)
- [clean_column_names_remove_english](#clean-column-names-remove-english)
- [getDynamicOptions](#getdynamicoptions)
- [CreateChoices](#createchoices)
- [remove_elements](#remove-elements)
- [Recode_time_TraceBack](#recode-time-traceback)
- [process_sales_data](#process-sales-data)

### safe_get

Safe Get Function

Safely loads an RDS file, returning NULL if the file doesn't exist


## Parameters

- **name The name of the RDS file (without extension)**
- **path The path to the RDS files directory**


## Return Value

The loaded object or NULL


---


### formattime

Format Time Function

Formats a date object based on the specified time scale


## Parameters

- **time_scale The date to format**
- **case The time scale to use (year, quarter, month)**


## Return Value

A formatted string


---


### make_names

Make Names Function

Cleans column names to ensure they're valid R variable names


## Parameters

- **x A character vector of column names**


## Return Value

A cleaned character vector


---


### clean_column_names_remove_english

Clean Column Names Function

Removes English text from Chinese column names


## Parameters

- **column_names A character vector of column names**


## Return Value

A cleaned character vector


---


### getDynamicOptions

Get Dynamic Options Function

Gets unique values from a data frame based on a filter


## Parameters

- **list Filter values**
- **dta Data frame**
- **invariable Variable to filter on**
- **outvariable Variable to extract values from**


## Return Value

A sorted vector of unique values


---


### CreateChoices

Create Choices Function

Creates a list of unique values from a data frame column


## Parameters

- **dta Data frame**
- **variable Variable to extract values from**


## Return Value

A sorted vector of unique values


---


### remove_elements

Remove Elements Function

Removes specified elements from a vector, ignoring case


## Parameters

- **vector The input vector**
- **elements Elements to remove**


## Return Value

The filtered vector


---


### Recode_time_TraceBack

Recode Time TraceBack Function

Converts a time scale to the corresponding historical time scale


## Parameters

- **profile The time scale to convert**


## Return Value

The corresponding historical time scale


---


### process_sales_data

Process Sales Data Function

Process and summarize sales data by time interval


## Parameters

- **SalesPattern Sales data frame**
- **time_scale_profile Time scale to use (year, quarter, month)**


## Return Value

Processed sales data frame


---

