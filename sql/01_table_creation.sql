-- ===================================================================================================================
-- SCRIPT: 01_table_creation.sql
-- AUTHOR: Senior Data Analyst (Google Coach)
-- DESCRIPTION: Sets up the MySQL database and defines schemas for the raw tables (customers, subscriptions, events)
--              and the unified cleaned_master_table.
-- TARGET DATABASE: MySQL 8.0+
-- ===================================================================================================================

-- Create the database
CREATE DATABASE IF NOT EXISTS emergent;
USE emergent;

-- 1. Schema for Raw Customers Table
DROP TABLE IF EXISTS raw_customers;
CREATE TABLE raw_customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    signup_date VARCHAR(50),      -- Loaded as string for formatting flexibility
    segment VARCHAR(50),
    country VARCHAR(50),
    is_enterprise VARCHAR(10)     -- Loaded as string to handle text values
);

-- 2. Schema for Raw Subscriptions Table
DROP TABLE IF EXISTS raw_subscriptions;
CREATE TABLE raw_subscriptions (
    subscription_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    start_date VARCHAR(50),       -- Loaded as string
    end_date VARCHAR(50),         -- Loaded as string
    monthly_price INT,            -- Kept as INT for exact currency precision
    status VARCHAR(50)
);

-- 3. Schema for Raw Events Table
DROP TABLE IF EXISTS raw_events;
CREATE TABLE raw_events (
    event_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    event_type VARCHAR(50),
    event_date VARCHAR(50),       -- Loaded as string
    source VARCHAR(50)
);

-- 4. Schema for the Final Cleaned Master Customer Lifecycle Table
-- This matches the output structure of our Python/Pandas data cleaning pipeline
DROP TABLE IF EXISTS cleaned_master_table;
CREATE TABLE cleaned_master_table (
    customer_id VARCHAR(50) PRIMARY KEY,
    segment VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL,
    is_enterprise VARCHAR(10) NOT NULL,
    acquisition_source VARCHAR(50) NOT NULL,
    true_signup_date DATE NOT NULL,
    subscription_id VARCHAR(50),
    subscription_start_date DATE,
    subscription_end_date DATE,
    monthly_price INT,
    subscription_status VARCHAR(50),
    activated DATE,
    churned DATE,
    trial_start DATE,
    life_cycle_stage VARCHAR(50) NOT NULL
);
