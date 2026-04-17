# P73: Server-to-UI Data Flow Principle [ARCHIVED]

**NOTICE: This principle has been elevated and expanded into MP52 (Unidirectional Data Flow Meta-Principle). Please refer to MP52 for the current authoritative version.**

**Date Archived**: 2025-04-09
**Replaced By**: MP52_unidirectional_data_flow.md
**Reason for Archiving**: Elevated to meta-principle status to reflect its foundational importance

---

**Original Principle**: Data should flow unidirectionally from server to UI, with UI output IDs explicitly matching their server-side counterparts.

## Description

The Server-to-UI Data Flow Principle establishes that data in Shiny applications should flow from the server to the UI in a unidirectional manner. UI components should be designed to consume data provided by server functions, with consistent naming patterns ensuring proper connection between data sources and display components.

## Rationale

Unidirectional data flow from server to UI:

1. **Predictability**: Creates a clear path for data, making the application's state more predictable
2. **Debugging Efficiency**: Simplifies tracing the source of data issues
3. **Maintainability**: Reduces coupling between components
4. **Consistency**: Enforces a standardized approach to data handling
5. **Error Reduction**: Minimizes unintended side effects and race conditions

## Implementation

1. **Matching Output IDs**:
   - Every UI output element must have an ID that exactly matches its server-side counterpart
   - Example: A `textOutput("customer_name")` in the UI must have a corresponding `output$customer_name <- renderText({...})` in the server

2. **Namespace Consistency**:
   - When using modules, ensure proper namespace handling:
   ```r
   # UI function
   myModuleUI <- function(id) {
     ns <- NS(id)
     textOutput(ns("customer_name"))  # Properly namespaced
   }
   
   # Server function
   myModuleServer <- function(id) {
     moduleServer(id, function(input, output, session) {
       output$customer_name <- renderText({...})  # Automatically namespaced
     })
   }
   ```

3. **Database-Aligned Naming**:
   - Output identifiers should follow a naming pattern reflecting their data source
   - Pattern: `[section]_[datasource]_[field]`
   - Example: `customer_profile_email` for displaying the email field from customer_profile table

4. **Validation Before Rendering**:
   - Server code should validate data existence before sending to UI
   ```r
   output$customer_value <- renderText({
     # Validate data exists before trying to display it
     req(df_customer_profile_dna)
     req("m_value" %in% colnames(df_customer_profile_dna))
     
     format(df_customer_profile_dna$m_value[1], big.mark=",")
   })
   ```

## Validation Rule

**Column-Dependent Naming Rule**:
Variables displayed in the UI should have names that follow the `[section]_[datasource]_[field]` pattern where:
- `[section]` represents the functional area (e.g., customer, product, transaction)
- `[datasource]` represents the source table or object (e.g., profile, dna)
- `[field]` represents the exact column name in the data source

For example:
- `customer_dna_m_value` for displaying the m_value column from the customer DNA table
- `transaction_history_date` for displaying the date column from the transaction history

## Exceptions

1. **Aggregated Values**: When displaying derived values (aggregates, calculations), names should reflect the computation but still follow a consistent pattern
2. **Reactive UI**: Cases where UI must update based on user input (though the data flow is still server→UI)
3. **Static Content**: Elements that don't display dynamic data

## References

- Shiny Reactivity: https://shiny.posit.co/r/articles/build/understanding-reactivity/
- ModuleServer Documentation: https://shiny.posit.co/r/reference/shiny/1.7.0/moduleserver

## Related Principles

- P72: UI Package Consistency Principle
- SLN01: Type Safety in Logical Contexts