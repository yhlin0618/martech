
############################################################
#  init_db.R                                               #
#  Run once (or whenever schema changes) to create /       #
#  migrate users.sqlite for authentication app             #
############################################################

library(DBI)
library(RPostgres)
library(bcrypt)


dotenv::load_dot_env(file = ".env")


# ── DB helpers ----------------------------------------------------------------

get_con <- function() {
  # ➊ 建立連線
  con <- dbConnect(
    Postgres(),
    host     = Sys.getenv("PGHOST"),
    port     = as.integer(Sys.getenv("PGPORT", 5432)),
    user     = Sys.getenv("PGUSER"),
    password = Sys.getenv("PGPASSWORD"),
    dbname   = Sys.getenv("PGDATABASE"),
    sslmode  = Sys.getenv("PGSSLMODE", "require") # DO 版一定要 require
  )
  
  # ➋ 建表（若不存在）
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS users (
      id           SERIAL PRIMARY KEY,
      username     TEXT UNIQUE,
      hash         TEXT,
      role         TEXT DEFAULT 'user',
      login_count  INTEGER DEFAULT 0
    );
  ")
  
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS rawdata (
      id           SERIAL PRIMARY KEY,
      user_id      INTEGER REFERENCES users(id),
      uploaded_at  TIMESTAMPTZ DEFAULT now(),
      json         JSONB
    );
  ")
  
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS processed_data (
      id            SERIAL PRIMARY KEY,
      user_id       INTEGER REFERENCES users(id),
      processed_at  TIMESTAMPTZ DEFAULT now(),
      json          JSONB
    );
  ")
  
  con
}



con <- get_con()



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
  dbExecute(con, "INSERT INTO users (username, hash, role, email) VALUES ($1, $2, 'admin', $3)",
            params = list("admin", bcrypt::hashpw("12345"), "admin@example.com"))
  message("Seeded default admin / 12345")
}

message("Database initialised / migrated successfully ✅")

dbDisconnect(con)
