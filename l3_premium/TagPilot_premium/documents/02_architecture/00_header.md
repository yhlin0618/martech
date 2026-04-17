# TagPilot Premium - Complete Technical Documentation

**Document Version**: v1.0 (2025-11-06)
**Application Version**: v18 (bs4Dash)
**Project**: TagPilot Premium - 精準行銷平台
**Purpose**: Comprehensive documentation of all application logic, data flow, algorithms, modules, and UI components

---

## 📖 Document Overview

This document provides **complete technical documentation** for the TagPilot Premium application, including:

- ✅ Complete system architecture and data flow
- ✅ All core algorithms with formulas and examples
- ✅ Detailed documentation of all 9 modules
- ✅ UI component logic and display calculations
- ✅ Customer segmentation and clustering methods
- ✅ All 38+ customer tags with calculation logic
- ✅ Example code snippets with line number references
- ✅ Real-world calculation examples

**Target Audience**: Developers, data scientists, product managers, and stakeholders who need to understand the complete application logic.

---

## 📋 Table of Contents

### Part 1: System Architecture & Data Flow

1. **Application Structure Overview**
   - 1.1 Main Application File: app.R
   - 1.2 UI Structure (bs4Dash Framework)

2. **Complete Data Flow**
   - 2.1 High-Level Data Pipeline
   - 2.2 Server-Side Data Flow
   - 2.3 Data Dependencies Between Modules
   - 2.4 Reactive Data Passing Pattern

3. **File Structure**

4. **Key Data Structures**
   - 4.1 Transaction Data (Input from CSV)
   - 4.2 Customer Summary Data (After DNA Analysis)
   - 4.3 Tagged Customer Data (After Tags Calculation)

5. **Critical Configuration Files**
   - 5.1 customer_dynamics_config.R
   - 5.2 packages.R

6. **External Dependencies**
   - 6.1 Database (PostgreSQL)
   - 6.2 Global Scripts (Submodule)

### Part 2: Core Algorithms & Calculations

1. **Z-Score Customer Dynamics Algorithm**
   - 1.1 Algorithm Overview
   - 1.2 Step-by-Step Calculation
     - Step 1: Calculate CAP (Observation Window)
     - Step 2: Calculate μ_ind (Industry Median IPT)
     - Step 3: Calculate W (Recent Activity Window)
     - Step 4: Calculate F_i,w (Purchase Frequency)
     - Step 5: Calculate Customer Summary Metrics
     - Step 6: Calculate λ_w and σ_w (Benchmarks)
     - Step 7: Calculate Z-Score (z_i)
     - Step 8: Classify customer_dynamics

2. **Value Level Calculation (P20/P80 with Edge Cases)**
   - 2.1 Standard P20/P80 Method
   - 2.2 Edge Case Handling
     - Edge Case 1: All Values Same
     - Edge Case 2: P20 Equals Minimum
     - Edge Case 3: P80 Equals Maximum
   - 2.3 Validation

3. **Activity Level Calculation**
   - 3.1 Two-Tier Strategy
     - Tier 1: ni ≥ 4 (Use CAI)
     - Tier 2: ni < 4 (Set to NA)
   - 3.2 CAI Calculation Logic

4. **Grid Position Calculation**
   - 4.1 Nine-Grid Matrix (3×3)

### Part 3: Module Details

- **Module 0: Upload Module**
- **Module 1: DNA Analysis Module (Core)** ⭐
  - 1.1 Module Purpose
  - 1.2 Processing Steps (Steps 1-18)
  - 1.3 Module Output
  - 1.4 UI Components
- **Module 2: Customer Base Value**
  - 2.1 Purpose
  - 2.2 Input
  - 2.3 Calculations
  - 2.4 UI Output
- **Module 3: RFM Value Analysis**
  - 3.1 Purpose
  - 3.2 Processing
  - 3.3 RFM Score Calculation
  - 3.4 UI Output
- **Module 4: Customer Activity (CAI)**
  - 4.1 Purpose
  - 4.2 Key Metrics
  - 4.3 Calculations
  - 4.4 UI Output
- **Module 5: Customer Status**
  - 5.1 Purpose
  - 5.2 Key Tags Calculated
  - 5.3 UI Output
- **Module 6: RSV Matrix**
  - 6.1 Purpose
  - 6.2 Dimensions
  - 6.3 27-Cell Matrix
  - 6.4 UI Output
- **Module 7: Lifecycle Prediction**
  - 7.1 Purpose
  - 7.2 Prediction Logic
  - 7.3 UI Output
- **Module 8: Advanced Analytics**
  - 8.1 Purpose
  - 8.2 Features
  - 8.3 Requirements

### Part 4: UI Components & Display Logic

1. **Common UI Patterns**
   - 1.1 ValueBox Pattern
   - 1.2 Plotly Chart Pattern
   - 1.3 DataTable Pattern

2. **Module-Specific UI Logic**
   - 2.1 DNA Module: Nine-Grid Display
     - Grid Card Generation Function
     - Strategy Database (45 Strategies)
     - Dynamic Grid Layout
   - 2.2 Customer Status Module: Churn Distribution
     - Lifecycle Distribution Bar Chart
     - Churn Risk Pie Chart
     - Days to Churn Histogram

3. **Number Formatting & Display**
   - 3.1 Currency Formatting
   - 3.2 Percentage Formatting
   - 3.3 Large Number Abbreviation
   - 3.4 Date Formatting

4. **Conditional Display Logic**
   - 4.1 ConditionalPanel Pattern
   - 4.2 Dynamic UI Generation

5. **Download Handlers**
   - 5.1 CSV Download

---

## 🔑 Key Concepts Quick Reference

| Concept | Definition | File Location |
|---------|-----------|---------------|
| **Z-Score Method** | Statistical customer dynamics classification | `utils/analyze_customer_dynamics_new.R` |
| **P20/P80 Segmentation** | Percentile-based value classification | `utils/analyze_customer_dynamics_new.R:419-532` |
| **CAI (Customer Activity Index)** | Purchase interval change indicator | `scripts/global_scripts/04_utils/fn_analysis_dna.R` |
| **Nine-Grid Matrix** | Value × Activity segmentation (A1-C3) | `modules/module_dna_multi_premium_v2.R:563-585` |
| **45 Strategies** | Marketing strategies for each grid×lifecycle | `modules/module_dna_multi_premium_v2.R:1031+` |
| **38+ Customer Tags** | Comprehensive customer attributes | `utils/calculate_customer_tags.R` |

---

## 🚀 Quick Start

To understand a specific aspect:
- **Data flow**: See Part 1, Section 2
- **Segmentation logic**: See Part 2, Sections 2-4
- **Module functionality**: See Part 3 (find your module)
- **UI calculations**: See Part 4

---

## 📝 Document Conventions

- **⭐** = Critical/Core component
- **✅** = Recently fixed/updated (2025-11-06)
- `code blocks` = Actual code from files
- **Examples** = Real calculation demonstrations
- [file.R:123] = Line number reference

---

