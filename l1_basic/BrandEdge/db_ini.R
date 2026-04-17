
############################################################
#  init_db.R                                               #
#  Run once (or whenever schema changes) to create /       #
#  migrate users.sqlite for authentication app             #
############################################################

library(DBI)
library(RSQLite)
library(bcrypt)
con <- dbConnect(RSQLite::SQLite(), "users.sqlite")
dbExecute(con, "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY,
                                                  username TEXT UNIQUE,
                                                  hash TEXT,
                                                  role TEXT DEFAULT 'user',
                                                  login_count INTEGER DEFAULT 0)")
dbExecute(con, "CREATE TABLE IF NOT EXISTS rawdata (id INTEGER PRIMARY KEY,
                                                     user_id INTEGER,
                                                     uploaded_at TEXT,
                                                     json TEXT)")
dbExecute(con, "CREATE TABLE IF NOT EXISTS processed_data (id INTEGER PRIMARY KEY,
                                                            user_id INTEGER,
                                                            processed_at TEXT,
                                                            json TEXT)")

# ---- Baseline table ----
dbExecute(con, "CREATE TABLE IF NOT EXISTS users (
               id INTEGER PRIMARY KEY,
               username    TEXT UNIQUE,
               hash        TEXT,
               role        TEXT DEFAULT 'user'
             )")

# ---- Incremental migrations ----
add_col <- function(def) dbExecute(con, paste0("ALTER TABLE users ADD COLUMN ", def))
cols <- dbListFields(con, "users")
if (!"email"        %in% cols) add_col("email TEXT")
if (!"fail_count"   %in% cols) add_col("fail_count INTEGER DEFAULT 0")
if (!"last_fail"    %in% cols) add_col("last_fail TEXT")
if (!"reset_token"  %in% cols) add_col("reset_token TEXT")
if (!"token_expiry" %in% cols) add_col("token_expiry TEXT")

# ---- Seed an admin account (optional) ----
if (nrow(dbGetQuery(con, "SELECT 1 FROM users WHERE username = 'admin'")) == 0) {
  dbExecute(con, "INSERT INTO users (username, hash, role, email) VALUES (?, ?, 'admin', ?)",
            params = list("admin", bcrypt::hashpw("12345"), "admin@example.com"))
  message("Seeded default admin / 12345")
}

message("Database initialised / migrated successfully ✅")

dbDisconnect(con)
