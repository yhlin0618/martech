# macro_overview

Source: `99_archive/rshinyapp_modules/macro/macro_overview.R`

## Functions

**Function List:**
- [createKpiBox](#createkpibox)
- [macroOverviewUI](#macrooverviewui)
- [macroOverviewServer](#macrooverviewserver)

### createKpiBox

Create a KPI value box


## Parameters

- **ns The namespace function**
- **title The title of the value box**
- **value_id The output ID for the value**
- **diff_id The output ID for the difference indicator**
- **perc_id The output ID for the percentage change**


## Return Value

A value_box object


---


### macroOverviewUI

Macro Overview UI Function


## Parameters

- **id The module ID**


## Return Value

A UI component


---


### macroOverviewServer

Macro Overview Server Function


## Parameters

- **id The module ID**
- **data_source The data source reactive list**


## Return Value

None


---

