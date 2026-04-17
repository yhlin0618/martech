# Amazon Product Scraping and Feature Analysis Setup Guide

This guide will help you set up and run the Amazon product scraping script that extracts product information and analyzes features using GPT.

## 📋 Prerequisites

### 1. Install R
- Download R from [https://cran.r-project.org/](https://cran.r-project.org/)
- Install R for Windows
- Make sure R is added to your system PATH

### 2. Install RStudio (Recommended)
- Download RStudio from [https://posit.co/download/rstudio-desktop/](https://posit.co/download/rstudio-desktop/)
- Install RStudio Desktop

### 3. Get OpenAI API Key
- Sign up at [https://platform.openai.com/](https://platform.openai.com/)
- Create an API key
- Note down your API key (you'll need it later)

## 🚀 Quick Setup

### Step 1: Run Setup Script
Open R or RStudio and run the setup script:

```r
source("setup_scraping_environment.R")
```

This will:
- Install all required R packages
- Create a `.env` file for configuration
- Test basic functionality

### Step 2: Configure API Key
Edit the `.env` file and replace `your_openai_api_key_here` with your actual OpenAI API key:

```
OPENAI_API_KEY_LIN=sk-your-actual-api-key-here
```

### Step 3: Run the Scraping Script
```r
source("scrapping_understanding_fixed.R")
```

## 📁 File Structure

```
latex_test/
├── scrapping_understanding.R          # Original script (has issues)
├── scrapping_understanding_fixed.R    # Fixed version with error handling
├── setup_scraping_environment.R       # Setup script
├── .env                               # Configuration file (created by setup)
└── README_scraping_setup.md          # This file
```

## 🔧 What the Script Does

### 1. Web Scraping
- Scrapes Amazon product pages using the ASIN (Amazon Standard Identification Number)
- Extracts product title, features, description, and images
- Uses enhanced headers to avoid detection
- Includes retry logic for failed requests

### 2. Feature Analysis
- Sends product information to GPT-4 API
- Analyzes product features for specific characteristics:
  - Waterproof capability
  - Bluetooth functionality
  - Built-in battery
  - Smart device features
- Returns results in JSON format

### 3. Error Handling
- Comprehensive error handling for network issues
- Graceful handling of missing product information
- API error handling and retry logic

## ⚠️ Important Notes

### Amazon Anti-Scraping Measures
Amazon has sophisticated anti-bot protection:
- **Rate Limiting**: Don't make too many requests too quickly
- **IP Blocking**: Your IP might get blocked if detected
- **CAPTCHA**: Pages might show CAPTCHA challenges
- **Dynamic Content**: Some content is loaded via JavaScript

### Solutions for Production Use
1. **Use Proxies**: Rotate IP addresses
2. **Respect Rate Limits**: Add delays between requests
3. **Use Selenium**: For JavaScript-heavy pages
4. **Consider APIs**: Amazon offers official APIs for some data

## 🛠️ Troubleshooting

### Common Issues

#### 1. R Not Found
```
Error: R not found in PATH
```
**Solution**: Install R and add it to your system PATH

#### 2. Package Installation Failed
```
Error: Failed to install package
```
**Solution**: 
- Check internet connection
- Try installing packages manually:
```r
install.packages(c("httr", "rvest", "jsonlite", "stringr", "dplyr", "DT", "readr", "dotenv"))
```

#### 3. API Key Error
```
Error: OpenAI API key not configured
```
**Solution**: 
- Check that `.env` file exists
- Verify API key is correctly set in `.env` file
- Make sure there are no extra spaces or quotes

#### 4. Amazon Blocking Requests
```
Error: Failed to retrieve page
```
**Solutions**:
- Try different ASINs
- Add delays between requests
- Use a VPN or proxy
- Check if Amazon is blocking your IP

#### 5. JSON Parsing Error
```
Error: Could not parse JSON result
```
**Solution**: 
- Check GPT API response format
- Verify API key has sufficient credits
- Check internet connection

### Debug Mode
To run with more detailed output, modify the script to add:
```r
options(verbose = TRUE)
```

## 🔄 Customization

### Change Product ASIN
Edit the `asin` variable in the script:
```r
asin <- "B07FVQLBL3"  # Change to your desired ASIN
```

### Modify Features to Analyze
Edit the GPT prompt in the `analyze_features_with_gpt` function:
```r
gpt_prompt <- paste0("
根據以下 Amazon 商品敘述與特色，請根據這些特徵進行 dummy coding，輸出為 JSON 格式，值為 0 或 1：

特徵：
1. 是否防水 (waterproof)
2. 是否具備藍牙 (bluetooth)
3. 是否內建電池 (battery included)
4. 是否為智慧裝置 (smart device)
# Add more features here
```

### Add Proxy Support
To use a proxy, add to your `.env` file:
```
PROXY_URL=http://your-proxy-server:port
PROXY_USERNAME=your_username
PROXY_PASSWORD=your_password
```

Then modify the scraping function to use the proxy.

## 📊 Expected Output

When successful, you should see output like:
```
🚀 Starting Amazon Product Scraping and Analysis
==================================================
🔍 Scraping Amazon product: B07FVQLBL3
   Attempt 1 of 3...
   ✅ Successfully retrieved page
✅ All required packages loaded successfully
✅ Environment variables loaded

📋 Product Information:
Title: [Product Title]
Features: [Product Features]...
Description: [Product Description]...
Images found: [Number of images]

🤖 Analyzing features with GPT...
✅ Feature analysis completed

🔍 Feature Analysis Results:
{"waterproof": 0, "bluetooth": 1, "battery_included": 1, "smart_device": 0}

📊 Parsed Features:
$waterproof
[1] 0

$bluetooth
[1] 1

$battery_included
[1] 1

$smart_device
[1] 0

✅ Script execution completed
```

## 🚨 Legal and Ethical Considerations

1. **Respect robots.txt**: Check Amazon's robots.txt file
2. **Rate Limiting**: Don't overwhelm Amazon's servers
3. **Terms of Service**: Review Amazon's terms of service
4. **Data Usage**: Only use data for legitimate purposes
5. **Attribution**: Give credit when using scraped data

## 📞 Support

If you encounter issues:
1. Check this README for troubleshooting steps
2. Verify all prerequisites are installed
3. Check your internet connection
4. Ensure your OpenAI API key is valid and has credits
5. Try with different ASINs to isolate issues

## 🔄 Updates

The script includes:
- ✅ Automatic package installation
- ✅ Environment configuration
- ✅ Error handling and retry logic
- ✅ Enhanced headers for anti-detection
- ✅ JSON parsing and validation
- ✅ Comprehensive logging

For production use, consider implementing:
- Proxy rotation
- Rate limiting
- Data storage
- Monitoring and alerting
- Legal compliance measures 