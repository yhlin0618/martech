# DNA Analysis Test Data

This directory contains sample datasets for testing the DNA (Customer Behavior) Analysis functionality in the Vital Signs app.

## Available Test Datasets

### 1. `dna_sample_minimal.csv`
**Purpose**: Basic testing with minimal required fields
- **Fields**: customer_id, payment_time, lineitem_price
- **Records**: 31 transactions from 10 customers
- **Description**: Simple format with only the three essential fields needed for DNA analysis
- **Use Case**: Testing basic functionality and field detection

### 2. `dna_sample_complete.csv`
**Purpose**: Complete testing with all optional fields
- **Fields**: customer_id, payment_time, lineitem_price, Variation, sku, ship_postal_code, product_line_id
- **Records**: 44 transactions from 15 customers
- **Description**: Comprehensive format including all supported optional fields
- **Use Case**: Testing advanced features like brand analysis, geographic segmentation, and product line insights

### 3. `dna_sample_email_format.csv`
**Purpose**: Testing email-based customer identification
- **Fields**: buyer_email, order_date, sales, Variation
- **Records**: 31 transactions from 10 customers
- **Description**: Uses email addresses instead of customer IDs to test the email-to-ID conversion functionality
- **Use Case**: Testing alternative customer identification methods and field name variations

### 4. `dna_sample_large_dataset.csv`
**Purpose**: Performance testing with larger dataset
- **Fields**: customer_id, time, amount, product_name, category
- **Records**: 62 transactions from 20 customers
- **Description**: Larger dataset with diverse product categories for testing scalability
- **Use Case**: Performance testing and validating DNA metrics with more diverse customer behaviors

## Data Characteristics

### Customer Profiles Included
- **High-Value Customers**: Multiple high-amount transactions (e.g., C005, C017)
- **Frequent Buyers**: Regular purchasing patterns (e.g., C004, C006)
- **Occasional Buyers**: Sporadic purchase behavior (e.g., C012, C014)
- **Single Purchase**: One-time buyers for testing edge cases

### Product Categories
- Electronics (most common)
- Beauty & Personal Care
- Sports & Fitness
- Home & Garden
- Luxury Items
- Books & Media
- Clothing
- Toys & Games

### Time Span
All datasets cover transactions from January 2024 to June 2024 (6 months) to provide meaningful temporal analysis for DNA metrics.

## Expected DNA Analysis Results

When processing these datasets, you should expect to see:

1. **Recency (R)**: Days since last purchase
2. **Frequency (F)**: Number of transactions per customer
3. **Monetary (M)**: Total spending per customer
4. **Inter-Purchase Time (IPT)**: Average days between purchases
5. **Customer Activity Index (CAI)**: Activity level metric
6. **Purchase Consistency Value (PCV)**: Purchase pattern consistency
7. **Customer Lifetime Value (CLV)**: Estimated customer value
8. **NES (Net Engagement Score)**: Overall customer engagement

## Usage Instructions

1. Upload any of these CSV files through the Vital Signs app's file upload interface
2. Navigate to the "客戶 DNA 分析" (Customer DNA Analysis) tab
3. The system will automatically detect the field mappings
4. Process the data to generate DNA metrics and visualizations
5. Explore different visualization options and statistical summaries

## File Format Notes

- All files use UTF-8 encoding
- Date formats: YYYY-MM-DD HH:MM:SS or YYYY-MM-DD
- Monetary values: Decimal format (e.g., 299.99)
- Customer identifiers: Text strings or email addresses
- Missing values: Leave cells empty (do not use "NA" or "NULL") 