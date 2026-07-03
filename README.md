# SaaS Growth & GTM Analytics (MySQL - Python - Power BI)
### *Emergence Data Analyst Take-Home Assessment*

---

## 1. Executive Summary

This repository contains the end-to-end data cleaning, SQL modeling, and growth analytics for a B2B SaaS company. By auditing and merging messy CRM profiles, billing databases, and event logs, we reconstructed the true customer lifecycle funnel and computed core SaaS metrics (MRR, ARR, Churn, and ARPC) with 100% mathematical integrity.

### **Key Performance Indicators (July 2023 Run-Rate):**
*   **Annual Recurring Revenue (ARR):** $1,654,620 ($137,885 MRR * 12)
*   **Active Paying Customers (Logos):** 515
*   **Average Revenue Per Customer (ARPC):** $267.74 / month
*   **Monthly Logo Churn Rate:** 4.48% (Lowest in 2023)
*   **Monthly Revenue Churn Rate:** 3.59% (Net Positive Revenue Retention)

---

## 2. Core Business Insights & GTM Recommendations

### **Insight 1: The "Zombie User" Crisis (Product Adoption Friction)**
Out of 906 paying customers in our master database, **only 404 (44.6%) have ever activated the software**. 
*   **The Friction:** **502 paying customers (55.4%) are "Zombie Users"**—they are currently paying for our service but have never activated their accounts. 
*   **The Risk:** These accounts are extremely high-risk churn liabilities. The moment they audit their software expenditures, they will cancel. 

> [!IMPORTANT]
> **Actionable Recommendation 1:** Implement an **Automated Post-Purchase Onboarding Playbook**. 
> Trigger targeted email sequences and customer success outreach to any customer who has paid but has not activated their account within 7 days. Focus GTM energy on *adoption*, not just acquisition.

---

### **Insight 2: The Non-Linear Funnel (Direct Purchase Flow)**
Our GTM funnel is non-linear. Out of 906 paying customers, **230 completely bypassed the free trial stage** and bought the product directly.
*   **Channel Drivers:** Direct purchases are heavily driven by the **Outbound** sales channel and **Ads** conversion paths. 
*   **The Breakdown:** 
    *   **Outbound:** Converts signups to paid at a massive **91.44%** yield, with a 70.8% trial-start rate. 
    *   **Referral:** Converts signups to paid at **92.64%** yield, but only 64.5% start a trial.

> [!TIP]
> **Actionable Recommendation 2:** Reallocate GTM budget from Ads to **Outbound Sales** and **Organic Content**. 
> Outbound delivers the highest contract values and conversions, while **Organic** traffic yields our most loyal customers (lowest cohort churn rate at **23.2%** vs. Ads churn at **28.7%**).

---

## 3. Product Funnel Visualization

```mermaid
funnel
    title Customer Journey Funnel (2023)
    Signup (100% Base): 1000
    Trial Started (67.6% Yield): 676
    Activated (40.4% Yield): 404
    Paid Subscriber (90.6% Combined Yield): 906
    Canceled/Churned (26.2% of Paid Base): 237
```
*Note: The Paid stage includes direct buyers who bypassed trial/activation, resulting in a non-linear funnel expansion from the Activation stage.*

---

## 4. Raw Data Quality Audit & Cleaning Assumptions

During the initial Python/Pandas profiling phase, we identified several logical contradictions and applied the following cleaning rules:

| Data Issue Identified | Impact on Business Metrics | Cleaning Rule & Logic Applied |
| :--- | :--- | :--- |
| **Chronology Mismatch** (401 records) | Subscriptions starting before CRM signup date, breaking funnel chronology. | **True Signup Date Rule:** Defined `true_signup_date` as the minimum of the CRM `signup_date`, subscription `start_date`, and the first `signup` event date. |
| **Mismatched Event Dates** (990 records) | Mismatches between event-log signup dates and CRM profiles. | **Unified Date Dimension:** Resolved CRM profile and event log signup discrepancies using the True Signup Date rule. |
| **Subscription Duplication** (35 records) | Customers having multiple active subscriptions starting on the same day with identical prices. | **De-duplication Key:** Grouped by `['customer_id', 'start_date']` and kept the first record. Handled as system double-ingestion errors rather than multi-product purchases. |
| **Missing Customer Segments** (243 records) | Distorts segment performance analysis. | **Imputation:** Imputed missing values as `'Unknown'` and optimized columns to `category` type to save memory. |

---

## 5. Metric Definitions (SQL Specification)

To calculate metrics with 100% precision, we avoided the standard "cohort grouping bug" (which only counts revenue in the signup month) and implemented **interval-overlapping dynamic queries**:

*   **Active Monthly Recurring Revenue (MRR):** Sum of the `monthly_price` of all customers where:
    $$\text{True Signup Date} \le \text{Month End}$$
    $$\text{Subscription End Date IS NULL OR } \ge \text{Month Start}$$
    $$\text{Subscription ID IS NOT NULL}$$
*   **Logo Churn Rate:** Monthly cancellations divided by active customers at the start of that month:
    $$\text{Logo Churn Rate}_M = \frac{\text{Cancellations in Month M}}{\text{Active customers at start of Month M}} \times 100$$
*   **Revenue Churn Rate:** The value of MRR canceled in a month divided by the active MRR at the start of that month:
    $$\text{Revenue Churn Rate}_M = \frac{\text{MRR Canceled in Month M}}{\text{Active MRR at start of Month M}} \times 100$$
*   **Average Revenue Per Customer (ARPC):** Active MRR in Month M divided by unique active customer count in Month M.

---

## 6. How to Reproduce Results

### **1. Prerequisites**
*   Python 3.11+
*   MySQL 8.0+
*   `uv` (fast package manager)

### **2. Setup and Data Cleaning (Python/Pandas)**
Initialize the environment and run the data validation script:
```powershell
# Create virtual environment and install dependencies
uv venv
.venv\Scripts\Activate.ps1
uv sync

# Run data cleaning to generate cleaned_master_table.csv
uv run python python/data_validation.py
```

### **3. Database Schema & Metric Calculation (MySQL)**
1.  Connect to your MySQL database.
2.  Run the SQL scripts in order:
    *   `sql/01_table_creation.sql`: Creates database and schema.
    *   `sql/02_data_cleaning.sql`: Cleans string formats and standardizes dates to `YYYY-MM-DD`.
    *   `sql/03_core_metrics.sql`: Calculates dynamic MRR, ARR, Churn, and Segmented metrics.
    *   `sql/04_funnel_analysis.sql`: Computes funnel conversions and marketing source performance.

### **4. BI Dashboard Integration**
Pre-calculated aggregated datasets are exported in the `dashboard/` folder as lightweight CSV files (`mrr_trend.csv`, `overall_funnel.csv`, etc.). Import these CSVs directly into Power BI/Tableau for instant visual rendering with **zero DAX overhead**.
