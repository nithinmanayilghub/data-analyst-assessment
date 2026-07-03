-- ===================================================================================================================
-- SCRIPT: Core SaaS Metrics Analysis
-- AUTHOR: Senior Data Analyst (Google Coach)
-- DESCRIPTION: Computes core B2B SaaS growth and retention metrics over time using a dynamic monthly calendar.
--              Includes MRR, ARR, Logo Churn, Revenue Churn, ARPC, and Segmented performance.
-- TARGET DATABASE: MySQL 8.0+
-- DEPENDENCIES: cleaned_master_table (Cleaned and normalized customer-subscription lifecycle table)
-- ===================================================================================================================

USE emergent;

-- ===================================================================================================================
-- METRIC 1: Monthly Recurring Revenue (MRR)
-- Formula: Sum of monthly prices of all customers with active subscriptions during each calendar month.
-- ===================================================================================================================

-- Generating a dynamic list of months to serve as our calendar baseline
WITH RECURSIVE months AS (
    SELECT 
        DATE_FORMAT(MIN(COALESCE(subscription_start_date, true_signup_date)), '%Y-%m-01') AS month_start,
        LAST_DAY(MIN(COALESCE(subscription_start_date, true_signup_date))) AS month_end
    FROM cleaned_master_table
    
    UNION ALL
    
    SELECT 
        DATE_ADD(month_start, INTERVAL 1 MONTH), 
        LAST_DAY(DATE_ADD(month_start, INTERVAL 1 MONTH))
    FROM months
    WHERE month_start < (SELECT MAX(COALESCE(subscription_end_date, CURRENT_DATE())) FROM cleaned_master_table)
)
SELECT
    DATE_FORMAT(m.month_start, '%Y-%m') AS billing_month,
    ROUND(SUM(COALESCE(c.monthly_price, 0)), 2) AS mrr
FROM months m
LEFT JOIN cleaned_master_table c
  ON COALESCE(c.subscription_start_date, c.true_signup_date) <= m.month_end
  AND (c.subscription_end_date IS NULL OR c.subscription_end_date >= m.month_start)
  AND c.subscription_id IS NOT NULL
GROUP BY m.month_start
ORDER BY billing_month;


-- ===================================================================================================================
-- METRIC 2: Annual Recurring Revenue (ARR)
-- Formula: Latest Month's MRR * 12 (SaaS Annual Run-Rate)
-- ===================================================================================================================

WITH RECURSIVE months AS (
    SELECT 
        DATE_FORMAT(MIN(COALESCE(subscription_start_date, true_signup_date)), '%Y-%m-01') AS month_start,
        LAST_DAY(MIN(COALESCE(subscription_start_date, true_signup_date))) AS month_end
    FROM cleaned_master_table
    UNION ALL
    SELECT 
        DATE_ADD(month_start, INTERVAL 1 MONTH), 
        LAST_DAY(DATE_ADD(month_start, INTERVAL 1 MONTH))
    FROM months
    WHERE month_start < (SELECT MAX(COALESCE(subscription_end_date, CURRENT_DATE())) FROM cleaned_master_table)
),
monthly_mrr AS (
    SELECT
        DATE_FORMAT(m.month_start, '%Y-%m') AS billing_month,
        ROUND(SUM(COALESCE(c.monthly_price, 0)), 2) AS mrr
    FROM months m
    LEFT JOIN cleaned_master_table c
      ON COALESCE(c.subscription_start_date, c.true_signup_date) <= m.month_end
      AND (c.subscription_end_date IS NULL OR c.subscription_end_date >= m.month_start)
      AND c.subscription_id IS NOT NULL
    GROUP BY m.month_start
)
SELECT 
    billing_month AS run_rate_month,
    mrr AS current_mrr,
    ROUND(mrr * 12, 2) AS ARR
FROM monthly_mrr
ORDER BY billing_month DESC
LIMIT 1;


-- ===================================================================================================================
-- METRIC 3: Customer (Logo) Churn Rate
-- Formula: (Customers canceled during Month M / Active customers at the start of Month M) * 100
-- ===================================================================================================================

WITH RECURSIVE months AS (
    SELECT 
        DATE_FORMAT(MIN(COALESCE(subscription_start_date, true_signup_date)), '%Y-%m-01') AS month_start,
        LAST_DAY(MIN(COALESCE(subscription_start_date, true_signup_date))) AS month_end
    FROM cleaned_master_table
    UNION ALL
    SELECT 
        DATE_ADD(month_start, INTERVAL 1 MONTH), 
        LAST_DAY(DATE_ADD(month_start, INTERVAL 1 MONTH))
    FROM months
    WHERE month_start < (SELECT MAX(COALESCE(subscription_end_date, CURRENT_DATE())) FROM cleaned_master_table)
),
monthly_active_at_start AS (
    SELECT
        m.month_start,
        COUNT(DISTINCT c.customer_id) AS active_customers
    FROM months m
    LEFT JOIN cleaned_master_table c
      ON COALESCE(c.subscription_start_date, c.true_signup_date) < m.month_start
      AND (c.subscription_end_date IS NULL OR c.subscription_end_date >= m.month_start)
      AND c.subscription_id IS NOT NULL
    GROUP BY m.month_start
),
monthly_churns AS (
    SELECT
        m.month_start,
        COUNT(DISTINCT c.customer_id) AS churned_customers
    FROM months m
    LEFT JOIN cleaned_master_table c
      ON c.subscription_end_date >= m.month_start
      AND c.subscription_end_date <= m.month_end
      AND c.subscription_id IS NOT NULL
    GROUP BY m.month_start
)
SELECT
    DATE_FORMAT(a.month_start, '%Y-%m') AS billing_month,
    a.active_customers AS active_logos_at_start,
    COALESCE(c.churned_customers, 0) AS churned_logos_during_month,
    ROUND(
        COALESCE(c.churned_customers, 0) * 100.0 / NULLIF(a.active_customers, 0),
        2
    ) AS logo_churn_rate
FROM monthly_active_at_start a
LEFT JOIN monthly_churns c ON a.month_start = c.month_start
ORDER BY billing_month;


-- ===================================================================================================================
-- METRIC 4: Revenue Churn Rate
-- Formula: (MRR canceled during Month M / Active MRR at the start of Month M) * 100
-- ===================================================================================================================

WITH RECURSIVE months AS (
    SELECT 
        DATE_FORMAT(MIN(COALESCE(subscription_start_date, true_signup_date)), '%Y-%m-01') AS month_start,
        LAST_DAY(MIN(COALESCE(subscription_start_date, true_signup_date))) AS month_end
    FROM cleaned_master_table
    UNION ALL
    SELECT 
        DATE_ADD(month_start, INTERVAL 1 MONTH), 
        LAST_DAY(DATE_ADD(month_start, INTERVAL 1 MONTH))
    FROM months
    WHERE month_start < (SELECT MAX(COALESCE(subscription_end_date, CURRENT_DATE())) FROM cleaned_master_table)
),
monthly_revenue_at_start AS (
    SELECT
        m.month_start,
        SUM(COALESCE(c.monthly_price, 0)) AS active_mrr_at_start
    FROM months m
    LEFT JOIN cleaned_master_table c
      ON COALESCE(c.subscription_start_date, c.true_signup_date) < m.month_start
      AND (c.subscription_end_date IS NULL OR c.subscription_end_date >= m.month_start)
      AND c.subscription_id IS NOT NULL
    GROUP BY m.month_start
),
monthly_revenue_churns AS (
    SELECT
        m.month_start,
        SUM(COALESCE(c.monthly_price, 0)) AS churned_mrr_during_month
    FROM months m
    LEFT JOIN cleaned_master_table c
      ON c.subscription_end_date >= m.month_start
      AND c.subscription_end_date <= m.month_end
      AND c.subscription_id IS NOT NULL
    GROUP BY m.month_start
)
SELECT
    DATE_FORMAT(a.month_start, '%Y-%m') AS billing_month,
    a.active_mrr_at_start,
    COALESCE(c.churned_mrr_during_month, 0) AS churned_mrr_during_month,
    ROUND(
        COALESCE(c.churned_mrr_during_month, 0) * 100.0 / NULLIF(a.active_mrr_at_start, 0),
        2
    ) AS revenue_churn_rate
FROM monthly_revenue_at_start a
LEFT JOIN monthly_revenue_churns c ON a.month_start = c.month_start
ORDER BY billing_month;


-- ===================================================================================================================
-- METRIC 5: Average Revenue per Customer (ARPC)
-- Formula: Total Active MRR in Month M / Total Active Customers in Month M
-- ===================================================================================================================

WITH RECURSIVE months AS (
    SELECT 
        DATE_FORMAT(MIN(COALESCE(subscription_start_date, true_signup_date)), '%Y-%m-01') AS month_start,
        LAST_DAY(MIN(COALESCE(subscription_start_date, true_signup_date))) AS month_end
    FROM cleaned_master_table
    UNION ALL
    SELECT 
        DATE_ADD(month_start, INTERVAL 1 MONTH), 
        LAST_DAY(DATE_ADD(month_start, INTERVAL 1 MONTH))
    FROM months
    WHERE month_start < (SELECT MAX(COALESCE(subscription_end_date, CURRENT_DATE())) FROM cleaned_master_table)
)
SELECT
    DATE_FORMAT(m.month_start, '%Y-%m') AS billing_month,
    ROUND(SUM(COALESCE(c.monthly_price, 0)), 2) AS active_mrr,
    COUNT(DISTINCT c.customer_id) AS active_customers,
    ROUND(
        SUM(COALESCE(c.monthly_price, 0)) / NULLIF(COUNT(DISTINCT c.customer_id), 0),
        2
    ) AS arpc
FROM months m
LEFT JOIN cleaned_master_table c
  ON COALESCE(c.subscription_start_date, c.true_signup_date) <= m.month_end
  AND (c.subscription_end_date IS NULL OR c.subscription_end_date >= m.month_start)
  AND c.subscription_id IS NOT NULL
GROUP BY m.month_start
ORDER BY billing_month;


-- ===================================================================================================================
-- METRIC 6 (ADVANCED deep-dive): Segmented MRR and Logo Churn Rate
-- Purpose: Breaking down business health by size tier (Enterprise, Mid-Market, SMB, Unknown)
-- ===================================================================================================================

WITH RECURSIVE months AS (
    SELECT 
        DATE_FORMAT(MIN(COALESCE(subscription_start_date, true_signup_date)), '%Y-%m-01') AS month_start,
        LAST_DAY(MIN(COALESCE(subscription_start_date, true_signup_date))) AS month_end
    FROM cleaned_master_table
    UNION ALL
    SELECT 
        DATE_ADD(month_start, INTERVAL 1 MONTH), 
        LAST_DAY(DATE_ADD(month_start, INTERVAL 1 MONTH))
    FROM months
    WHERE month_start < (SELECT MAX(COALESCE(subscription_end_date, CURRENT_DATE())) FROM cleaned_master_table)
),
segmented_metrics AS (
    SELECT
        m.month_start,
        c.segment,
        ROUND(SUM(COALESCE(c.monthly_price, 0)), 2) AS mrr,
        COUNT(DISTINCT c.customer_id) AS active_customers,
        COUNT(DISTINCT CASE 
            WHEN c.subscription_end_date >= m.month_start 
             AND c.subscription_end_date <= m.month_end 
            THEN c.customer_id 
        END) AS monthly_churned_customers
    FROM months m
    LEFT JOIN cleaned_master_table c
      ON COALESCE(c.subscription_start_date, c.true_signup_date) <= m.month_end
      AND (c.subscription_end_date IS NULL OR c.subscription_end_date >= m.month_start)
      AND c.subscription_id IS NOT NULL
    GROUP BY m.month_start, c.segment
)
SELECT
    DATE_FORMAT(s.month_start, '%Y-%m') AS billing_month,
    COALESCE(s.segment, 'Grand Total') AS customer_segment,
    s.mrr AS active_mrr,
    s.active_customers AS active_logos,
    s.monthly_churned_customers AS churned_logos,
    ROUND(
        s.monthly_churned_customers * 100.0 / NULLIF(s.active_customers, 0),
        2
    ) AS segment_logo_churn_rate
FROM segmented_metrics s
WHERE s.segment IS NOT NULL
ORDER BY billing_month, active_mrr DESC;
