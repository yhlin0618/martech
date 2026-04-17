# 103g_dbDisconnect_all

Source: `update_scripts/global_scripts/02_db_utils/103g_dbDisconnect_all.R`

## Functions

**Function List:**
- [dbDisconnect_all](#dbdisconnect-all)

### dbDisconnect_all

Close All Database Connections

Disconnects all active DuckDB connections.


## Return Value

Invisible NULL


## Details


This function searches the global environment for DuckDB connection objects
and disconnects them. It's useful for cleaning up at the end of a script.


## Example


# Close all open database connections
dbDisconnect_all()


---

