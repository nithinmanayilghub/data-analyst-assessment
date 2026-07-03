-- ===================================================================================================================
-- SCRIPT: Funnel Conversion and Drop-off Analysis
-- AUTHOR: Senior Data Analyst (Google Coach)
-- DESCRIPTION: Evaluates customer progression through the standard SaaS funnel stages:
--              Signup -> Trial -> Activated -> Paid -> Churned
--              Analyzes overall lifetime performance, monthly cohorts, and breakdowns by marketing source.
-- TARGET DATABASE: MySQL 8.0+
-- DEPENDENCIES: cleaned_master_table (Cleaned and normalized customer-subscription lifecycle table)
-- ===================================================================================================================

USE emergent;

-- ===================================================================================================================
-- SECTION 1: Overall Cumulative Funnel Conversion
-- Purpose: Measure the total conversion rates and drop-off points across the entire customer history.
-- ===================================================================================================================

WITH funnel_counts AS (
    SELECT
        COUNT(true_signup_date) AS total_signup,
        COUNT(trial_start) AS total_trial,
        COUNT(activated) AS total_activated,
        COUNT(subscription_start_date) AS total_paid,
        COUNT(churned) AS total_churned
    FROM cleaned_master_table
)
SELECT
    total_signup,
    total_trial,
    total_activated,
    total_paid,
    total_churned,
    
    -- Conversion rates from stage to stage
    ROUND(total_trial * 100.0 / NULLIF(total_signup, 0), 2) AS signup_to_trial_pct,
    ROUND(total_activated * 100.0 / NULLIF(total_trial, 0), 2) AS trial_to_activated_pct,
    ROUND(total_paid * 100.0 / NULLIF(total_activated, 0), 2) AS activated_to_paid_pct,
    ROUND(total_churned * 100.0 / NULLIF(total_paid, 0), 2) AS paid_to_churn_pct,
    
    -- Drop-off rates from stage to stage
    ROUND((total_signup - total_trial) * 100.0 / NULLIF(total_signup, 0), 2) AS signup_to_trial_dropoff_pct,
    ROUND((total_trial - total_activated) * 100.0 / NULLIF(total_trial, 0), 2) AS trial_to_activated_dropoff_pct,
    ROUND((total_activated - total_paid) * 100.0 / NULLIF(total_activated, 0), 2) AS activated_to_paid_dropoff_pct
FROM funnel_counts;


-- ===================================================================================================================
-- SECTION 2: Month-over-Month Cohort Funnel Conversion
-- Purpose: Track how conversion metrics evolve based on the month the customer signed up.
-- ===================================================================================================================

WITH cohort_counts AS (
    SELECT
        DATE_FORMAT(true_signup_date, '%Y-%m') AS cohort_month,
        COUNT(true_signup_date) AS signup_count,
        COUNT(trial_start) AS trial_count,
        COUNT(activated) AS activated_count,
        COUNT(subscription_start_date) AS paid_count,
        COUNT(churned) AS churned_count
    FROM cleaned_master_table
    WHERE true_signup_date IS NOT NULL
    GROUP BY cohort_month
)
SELECT
    cohort_month,
    signup_count,
    trial_count,
    activated_count,
    paid_count,
    churned_count,
    
    -- Stage-to-Stage conversion rates per cohort
    ROUND(trial_count * 100.0 / NULLIF(signup_count, 0), 2) AS signup_to_trial_pct,
    ROUND(activated_count * 100.0 / NULLIF(trial_count, 0), 2) AS trial_to_activated_pct,
    ROUND(paid_count * 100.0 / NULLIF(activated_count, 0), 2) AS activated_to_paid_pct,
    ROUND(churned_count * 100.0 / NULLIF(paid_count, 0), 2) AS paid_to_churn_pct
FROM cohort_counts
ORDER BY cohort_month;


-- ===================================================================================================================
-- SECTION 3: Funnel Performance by Acquisition Source (Marketing Channel)
-- Purpose: Uncover which marketing channels bring the highest converting and longest retaining users.
-- ===================================================================================================================

WITH source_counts AS (
    SELECT
        COALESCE(acquisition_source, 'Unknown') AS channel,
        COUNT(true_signup_date) AS signup_count,
        COUNT(trial_start) AS trial_count,
        COUNT(activated) AS activated_count,
        COUNT(subscription_start_date) AS paid_count,
        COUNT(churned) AS churned_count
    FROM cleaned_master_table
    GROUP BY channel
)
SELECT
    channel,
    signup_count,
    trial_count,
    activated_count,
    paid_count,
    churned_count,
    
    -- Funnel conversion rates per acquisition channel
    ROUND(trial_count * 100.0 / NULLIF(signup_count, 0), 2) AS signup_to_trial_pct,
    ROUND(activated_count * 100.0 / NULLIF(trial_count, 0), 2) AS trial_to_activated_pct,
    ROUND(paid_count * 100.0 / NULLIF(activated_count, 0), 2) AS activated_to_paid_pct,
    ROUND(churned_count * 100.0 / NULLIF(paid_count, 0), 2) AS paid_to_churn_pct
FROM source_counts
ORDER BY paid_count DESC;


-- ===================================================================================================================
-- SECTION 4: Funnel Performance by Customer Segment
-- Purpose: Identify friction points unique to SMB, Mid-Market, and Enterprise customers.
-- ===================================================================================================================

WITH segment_counts AS (
    SELECT
        segment,
        COUNT(true_signup_date) AS signup_count,
        COUNT(trial_start) AS trial_count,
        COUNT(activated) AS activated_count,
        COUNT(subscription_start_date) AS paid_count,
        COUNT(churned) AS churned_count
    FROM cleaned_master_table
    GROUP BY segment
)
SELECT
    segment,
    signup_count,
    trial_count,
    activated_count,
    paid_count,
    churned_count,
    
    -- Funnel conversion rates per segment
    ROUND(trial_count * 100.0 / NULLIF(signup_count, 0), 2) AS signup_to_trial_pct,
    ROUND(activated_count * 100.0 / NULLIF(trial_count, 0), 2) AS trial_to_activated_pct,
    ROUND(paid_count * 100.0 / NULLIF(activated_count, 0), 2) AS activated_to_paid_pct,
    ROUND(churned_count * 100.0 / NULLIF(paid_count, 0), 2) AS paid_to_churn_pct
FROM segment_counts
ORDER BY paid_count DESC;
