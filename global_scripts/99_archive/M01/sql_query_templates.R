# sql_query_templates.R
# SQL query templates for the M01 (External Raw Data Connection) module
#
# This file contains standardized SQL query templates that can be used
# across different platform implementations of the M01 module.

#' Get a SQL query template by name
#'
#' @param template_name Name of the template to retrieve
#' @param platform Platform identifier (e.g., "06" for eBay)
#' @param parameters Parameters to substitute in the template
#'
#' @return SQL query string with parameters substituted
#'
get_sql_template <- function(template_name, platform = NULL, parameters = list()) {
  # Get base template
  template <- get_base_template(template_name)
  
  # If platform is specified, get platform-specific template and merge
  if(!is.null(platform)) {
    platform_template <- get_platform_template(template_name, platform)
    if(!is.null(platform_template)) {
      template <- platform_template
    }
  }
  
  # Substitute parameters
  if(length(parameters) > 0) {
    template <- substitute_parameters(template, parameters)
  }
  
  return(template)
}

#' Get base SQL template by name
#'
#' @param template_name Name of the template to retrieve
#'
#' @return SQL query string or NULL if not found
#'
get_base_template <- function(template_name) {
  # Define standard SQL templates
  templates <- list(
    # Check connection template
    "connection_test" = "
      SELECT 1 AS connection_test;
    ",
    
    # Get version template
    "get_version" = "
      SELECT @@VERSION AS server_version;
    ",
    
    # List databases template
    "list_databases" = "
      SELECT name 
      FROM sys.databases 
      ORDER BY name;
    ",
    
    # List tables template
    "list_tables" = "
      SELECT 
        t.name AS table_name,
        s.name AS schema_name,
        t.create_date,
        t.modify_date
      FROM 
        sys.tables t
      JOIN 
        sys.schemas s ON t.schema_id = s.schema_id
      ORDER BY 
        s.name, t.name;
    ",
    
    # Table schema template
    "table_schema" = "
      SELECT 
        c.name AS column_name,
        t.name AS data_type,
        c.max_length,
        c.precision,
        c.scale,
        c.is_nullable,
        c.is_identity
      FROM 
        sys.columns c
      JOIN 
        sys.types t ON c.user_type_id = t.user_type_id
      JOIN 
        sys.tables tbl ON c.object_id = tbl.object_id
      JOIN 
        sys.schemas s ON tbl.schema_id = s.schema_id
      WHERE 
        tbl.name = '%table_name%'
        AND s.name = '%schema_name%'
      ORDER BY 
        c.column_id;
    ",
    
    # Recent orders template
    "recent_orders" = "
      SELECT 
        order_id,
        customer_id,
        order_date,
        total_amount,
        status
      FROM 
        %orders_table%
      WHERE 
        order_date >= DATEADD(day, -%days%, GETDATE())
      ORDER BY 
        order_date DESC;
    ",
    
    # Customer orders template
    "customer_orders" = "
      SELECT 
        o.order_id,
        o.order_date,
        o.total_amount,
        o.status,
        p.product_id,
        p.product_name,
        oi.quantity,
        oi.unit_price,
        oi.subtotal
      FROM 
        %orders_table% o
      JOIN 
        %order_products_table% oi ON o.order_id = oi.order_id
      JOIN 
        %products_table% p ON oi.product_id = p.product_id
      WHERE 
        o.customer_id = '%customer_id%'
      ORDER BY 
        o.order_date DESC;
    ",
    
    # Product sales template
    "product_sales" = "
      SELECT 
        p.product_id,
        p.product_name,
        SUM(oi.quantity) AS total_quantity,
        SUM(oi.subtotal) AS total_sales,
        COUNT(DISTINCT o.order_id) AS order_count,
        COUNT(DISTINCT o.customer_id) AS customer_count
      FROM 
        %products_table% p
      JOIN 
        %order_products_table% oi ON p.product_id = oi.product_id
      JOIN 
        %orders_table% o ON oi.order_id = o.order_id
      WHERE 
        o.order_date BETWEEN '%start_date%' AND '%end_date%'
      GROUP BY 
        p.product_id, p.product_name
      ORDER BY 
        total_sales DESC;
    "
  )
  
  # Return requested template or NULL if not found
  if(template_name %in% names(templates)) {
    return(templates[[template_name]])
  } else {
    warning("Template not found: ", template_name)
    return(NULL)
  }
}

#' Get platform-specific SQL template by name
#'
#' @param template_name Name of the template to retrieve
#' @param platform Platform identifier (e.g., "06" for eBay)
#'
#' @return SQL query string or NULL if not found
#'
get_platform_template <- function(template_name, platform) {
  # Define platform-specific templates
  if(platform == "06") {  # eBay
    ebay_templates <- list(
      # eBay-specific recent orders template
      "recent_orders" = "
        SELECT 
          OrderID AS order_id,
          CustomerID AS customer_id,
          OrderDate AS order_date,
          TotalAmount AS total_amount,
          OrderStatus AS status
        FROM 
          eBay_Sales.dbo.Orders
        WHERE 
          OrderDate >= DATEADD(day, -%days%, GETDATE())
        ORDER BY 
          OrderDate DESC;
      ",
      
      # eBay-specific customer orders template
      "customer_orders" = "
        SELECT 
          o.OrderID AS order_id,
          o.OrderDate AS order_date,
          o.TotalAmount AS total_amount,
          o.OrderStatus AS status,
          p.ProductID AS product_id,
          p.ProductName AS product_name,
          oi.Quantity AS quantity,
          oi.UnitPrice AS unit_price,
          oi.Quantity * oi.UnitPrice AS subtotal
        FROM 
          eBay_Sales.dbo.Orders o
        JOIN 
          eBay_Sales.dbo.Orderproducts oi ON o.OrderID = oi.OrderID
        JOIN 
          eBay_Sales.dbo.Products p ON oi.ProductID = p.ProductID
        WHERE 
          o.CustomerID = '%customer_id%'
        ORDER BY 
          o.OrderDate DESC;
      ",
      
      # eBay-specific product sales template
      "product_sales" = "
        SELECT 
          p.ProductID AS product_id,
          p.ProductName AS product_name,
          SUM(oi.Quantity) AS total_quantity,
          SUM(oi.Quantity * oi.UnitPrice) AS total_sales,
          COUNT(DISTINCT o.OrderID) AS order_count,
          COUNT(DISTINCT o.CustomerID) AS customer_count
        FROM 
          eBay_Sales.dbo.Products p
        JOIN 
          eBay_Sales.dbo.Orderproducts oi ON p.ProductID = oi.ProductID
        JOIN 
          eBay_Sales.dbo.Orders o ON oi.OrderID = o.OrderID
        WHERE 
          o.OrderDate BETWEEN '%start_date%' AND '%end_date%'
        GROUP BY 
          p.ProductID, p.ProductName
        ORDER BY 
          total_sales DESC;
      "
    )
    
    # Return requested template or NULL if not found
    if(template_name %in% names(ebay_templates)) {
      return(ebay_templates[[template_name]])
    } else {
      return(NULL)  # Fall back to base template
    }
  } else {
    # No platform-specific templates for other platforms
    return(NULL)
  }
}

#' Substitute parameters in SQL template
#'
#' @param template SQL template string with placeholders
#' @param parameters Named list of parameters to substitute
#'
#' @return SQL query string with parameters substituted
#'
substitute_parameters <- function(template, parameters) {
  # Check inputs
  if(is.null(template) || is.null(parameters)) {
    return(template)
  }
  
  # Substitute each parameter
  result <- template
  for(param_name in names(parameters)) {
    param_value <- parameters[[param_name]]
    placeholder <- paste0("%", param_name, "%")
    result <- gsub(placeholder, param_value, result, fixed = TRUE)
  }
  
  return(result)
}

#' Format SQL query for logging or display
#'
#' @param query SQL query string to format
#' @param max_length Maximum length for truncation
#' @param indent Indentation string
#'
#' @return Formatted SQL query string
#'
format_sql_query <- function(query, max_length = NULL, indent = "  ") {
  if(is.null(query)) {
    return("NULL")
  }
  
  # Remove extra whitespace and newlines
  formatted <- gsub("\\s+", " ", query)
  
  # Replace specific SQL keywords with newline + keyword
  keywords <- c("SELECT", "FROM", "WHERE", "GROUP BY", "ORDER BY", 
                "HAVING", "JOIN", "LEFT JOIN", "RIGHT JOIN", "INNER JOIN",
                "OUTER JOIN", "UNION", "EXCEPT", "INTERSECT")
  
  for(keyword in keywords) {
    formatted <- gsub(paste0("\\s", keyword, "\\s"), paste0("\n", indent, keyword, " "), 
                     formatted, ignore.case = TRUE)
  }
  
  # Replace commas with comma + newline in SELECT and GROUP BY clauses
  in_select <- FALSE
  in_group_by <- FALSE
  lines <- strsplit(formatted, "\n")[[1]]
  
  for(i in 1:length(lines)) {
    # Check if line contains SELECT or GROUP BY
    if(grepl("SELECT", lines[i], ignore.case = TRUE)) {
      in_select <- TRUE
      in_group_by <- FALSE
    } else if(grepl("GROUP BY", lines[i], ignore.case = TRUE)) {
      in_select <- FALSE
      in_group_by <- TRUE
    } else if(grepl("FROM|WHERE|ORDER BY|HAVING", lines[i], ignore.case = TRUE)) {
      in_select <- FALSE
      in_group_by <- FALSE
    }
    
    # Replace commas in SELECT and GROUP BY clauses
    if(in_select || in_group_by) {
      lines[i] <- gsub(",", ",\n  ", lines[i])
    }
  }
  
  formatted <- paste(lines, collapse = "\n")
  
  # Truncate if needed
  if(!is.null(max_length) && nchar(formatted) > max_length) {
    formatted <- paste0(substr(formatted, 1, max_length), "...")
  }
  
  return(formatted)
}