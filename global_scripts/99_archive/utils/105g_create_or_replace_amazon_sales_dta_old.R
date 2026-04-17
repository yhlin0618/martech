create_or_replace_amazon_sales_dta <- function(con) {
  # 定義表格名稱
  table_name <- "amazon_sales_dta"
  
  # 定義建立表格的 SQL 語句
  create_table_sql <- "
    CREATE OR REPLACE TABLE amazon_sales_dta (
      amazon_order_id VARCHAR,
      merchant_order_id VARCHAR,
      shipment_id VARCHAR,
      shipment_product_id VARCHAR,
      amazon_order_product_id VARCHAR,
      merchant_order_product_id VARCHAR,
      purchase_date TIMESTAMPTZ,
      payments_date TIMESTAMPTZ,
      shipment_date TIMESTAMPTZ,
      reporting_date TIMESTAMPTZ,
      buyer_email VARCHAR,
      buyer_name VARCHAR,
      buyer_phone_number VARCHAR,
      sku VARCHAR,
      title VARCHAR,
      shipped_quantity BIGINT,
      currency CHAR(3),
      product_price DOUBLE,
      product_tax DOUBLE,
      shipping_price DOUBLE,
      shipping_tax DOUBLE,
      gift_wrap_price DOUBLE,
      gift_wrap_tax DOUBLE,
      ship_service_level VARCHAR,
      recipient_name VARCHAR,
      shipping_address_1 VARCHAR,
      shipping_address_2 VARCHAR,
      shipping_address_3 VARCHAR,
      shipping_city VARCHAR,
      shipping_state VARCHAR,
      shipping_postal_code VARCHAR,
      shipping_country_code VARCHAR,
      shipping_phone_number VARCHAR,
      billing_address_1 VARCHAR,
      billing_address_2 VARCHAR,
      billing_address_3 VARCHAR,
      billing_city VARCHAR,
      billing_state VARCHAR,
      bill_postal_code VARCHAR,
      bill_country VARCHAR,
      product_promo_discount DOUBLE,
      shipment_promo_discount DOUBLE,
      carrier VARCHAR,
      tracking_number VARCHAR,
      estimated_arrival_date TIMESTAMPTZ,
      fc VARCHAR,
      fulfillment_channel VARCHAR,
      sales_channel VARCHAR,
      PRIMARY KEY (amazon_order_id, shipment_id, shipment_product_id, amazon_order_product_id)
    );
  "
  
  # 定義索引語句
  indexes <- c(
    "CREATE INDEX idx_purchase_date ON amazon_sales_dta (purchase_date);",
    "CREATE INDEX idx_sku ON amazon_sales_dta (sku);"
  )
  
  # 調用之前定義好的 setup_table 函數執行建立表格與索引的操作
  setup_table(con, table_name, create_table_sql, indexes)
  
  # 印出表格結構資訊
  print(dbGetQuery(con, "PRAGMA table_info('amazon_sales_dta')"))
}
