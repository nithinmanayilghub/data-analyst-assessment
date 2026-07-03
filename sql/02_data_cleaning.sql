-- ===================================================================================================================
-- SCRIPT: 02_data_cleaning.sql
-- AUTHOR: Senior Data Analyst (Google Coach)
-- DESCRIPTION: Documents the database cleaning steps to convert raw string values to proper dates/NULLs.
--              Includes date format normalization (DD-MM-YYYY to YYYY-MM-DD), Null imputation, and Lifecycle Stage logic.
-- TARGET DATABASE: MySQL 8.0+
-- ===================================================================================================================

USE emergent;

-- ===================================================================================================================
-- STEP 1: Normalize Pseudo-Nulls and Standardize Date Formats
-- Handles true NULLs, empty strings '', 'NaN' and 'null' text values, and European format ('DD-MM-YYYY') dates.
-- ===================================================================================================================

UPDATE cleaned_master_table 
SET 
    -- 1. Standardize True Signup Date
    true_signup_date = CASE 
        WHEN true_signup_date IS NULL OR true_signup_date = '' OR true_signup_date = 'NaN' OR true_signup_date = 'null' THEN NULL
        WHEN true_signup_date LIKE '__-__-____' THEN DATE_FORMAT(STR_TO_DATE(true_signup_date, '%d-%m-%Y'), '%Y-%m-%d')
        ELSE true_signup_date
    END,
    
    -- 2. Standardize Subscription Start Date
    subscription_start_date = CASE 
        WHEN subscription_start_date IS NULL OR subscription_start_date = '' OR subscription_start_date = 'NaN' OR subscription_start_date = 'null' THEN NULL
        WHEN subscription_start_date LIKE '__-__-____' THEN DATE_FORMAT(STR_TO_DATE(subscription_start_date, '%d-%m-%Y'), '%Y-%m-%d')
        ELSE subscription_start_date
    END,
    
    -- 3. Standardize Subscription End Date
    subscription_end_date = CASE 
        WHEN subscription_end_date IS NULL OR subscription_end_date = '' OR subscription_end_date = 'NaN' OR subscription_end_date = 'null' THEN NULL
        WHEN subscription_end_date LIKE '__-__-____' THEN DATE_FORMAT(STR_TO_DATE(subscription_end_date, '%d-%m-%Y'), '%Y-%m-%d')
        ELSE subscription_end_date
    END,
    
    -- 4. Standardize Trial Start Date
    trial_start = CASE 
        WHEN trial_start IS NULL OR trial_start = '' OR trial_start = 'NaN' OR trial_start = 'null' THEN NULL
        WHEN trial_start LIKE '__-__-____' THEN DATE_FORMAT(STR_TO_DATE(trial_start, '%d-%m-%Y'), '%Y-%m-%d')
        ELSE trial_start
    END,
    
    -- 5. Standardize Activation Date
    activated = CASE 
        WHEN activated IS NULL OR activated = '' OR activated = 'NaN' OR activated = 'null' THEN NULL
        WHEN activated LIKE '__-__-____' THEN DATE_FORMAT(STR_TO_DATE(activated, '%d-%m-%Y'), '%Y-%m-%d')
        ELSE activated
    END,
    
    -- 6. Standardize Churned Event Date
    churned = CASE 
        WHEN churned IS NULL OR churned = '' OR churned = 'NaN' OR churned = 'null' THEN NULL
        WHEN churned LIKE '__-__-____' THEN DATE_FORMAT(STR_TO_DATE(churned, '%d-%m-%Y'), '%Y-%m-%d')
        ELSE churned
    END;

-- ===================================================================================================================
-- STEP 2: Alter Column Data Types to Proper DATE Format
-- ===================================================================================================================

ALTER TABLE cleaned_master_table 
MODIFY COLUMN true_signup_date DATE,
MODIFY COLUMN subscription_start_date DATE,
MODIFY COLUMN subscription_end_date DATE,
MODIFY COLUMN trial_start DATE,
MODIFY COLUMN activated DATE,
MODIFY COLUMN churned DATE;

-- ===================================================================================================================
-- STEP 3: Compute Cumulative Customer Lifecycle Stages
-- Translates mutually exclusive final states into clean business stages.
-- ===================================================================================================================

-- (Reference only: This was computed instantly in Pandas using vectorized np.select and saved to the CSV)
/*
SELECT 
    customer_id,
    CASE 
        -- Churned: Subscription is canceled OR a churn event is recorded
        WHEN subscription_status = 'canceled' OR churned IS NOT NULL THEN 'Churned'
        
        -- Paid: Subscription is active and not canceled
        WHEN subscription_id IS NOT NULL AND subscription_status = 'active' THEN 'Paid'
        
        -- Activated: No subscription, but has activation date
        WHEN subscription_id IS NULL AND activated IS NOT NULL THEN 'Activated'
        
        -- Trial: No subscription, no activation, but has started a trial
        WHEN subscription_id IS NULL AND trial_start IS NOT NULL THEN 'Trial'
        
        -- Signup: Joined the platform but has not performed other actions
        ELSE 'Signup'
    END AS life_cycle_stage
FROM cleaned_master_table;
*/
