# 100g_dbConnect_from_list

Source: `update_scripts/global_scripts/02_db_utils/100g_dbConnect_from_list.R`

## Functions

**Function List:**
- [dbConnect_from_list](#dbconnect-from-list)

### dbConnect_from_list

Database Connection Function

Establishes a connection to a specified DuckDB database from the predefined list
and stores the connection in the global environment.


## Parameters

- **dataset Character. The name of the database to connect to (must exist in path_list)**
- **path_list List. The list of database paths (defaults to db_path_list)**
- **read_only Logical. Whether to open the database in read-only mode**


## Return Value

Connection object. The established database connection


## Details


The function performs the following steps:
1. Validates that the requested dataset exists in the path list
2. Gets the database path from the list
3. Establishes a connection to the DuckDB database
4. Displays all tables in the connected database
5. Assigns the connection to a global variable with the same name as the dataset
6. Returns the connection object for chaining


## Note


- The connection is stored in the global environment with the same name as the dataset
- This allows other functions to access the connection without explicitly passing it
- Connections should be closed with dbDisconnect() when no longer needed
- For multiple connections, use dbDisconnect_all() to close all at once


## Example


# Connect to raw_data database in write mode
raw_data <- dbConnect_from_list("raw_data", read_only = FALSE)

# Connect to processed_data database in read-only mode
processed_data <- dbConnect_from_list("processed_data", read_only = TRUE)


---

