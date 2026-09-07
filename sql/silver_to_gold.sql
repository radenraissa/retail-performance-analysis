-- ============================================================
-- Silver -> Gold Layer Build
-- Source: public.customer_data, public.order_data (silver, cleaned)
-- Output: gold schema — star schema for Power BI
-- ============================================================

-- ------------------------------------------------------------
-- 0. Schema setup
-- ------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS gold;

-- ------------------------------------------------------------
-- 1. dim_date
-- Derived from order_data.order_date
-- ------------------------------------------------------------
CREATE TABLE gold.dim_date AS
SELECT DISTINCT
    order_date::date AS date_key,
    EXTRACT(YEAR FROM order_date::date)::int AS year,
    EXTRACT(QUARTER FROM order_date::date)::int AS quarter,
    EXTRACT(MONTH FROM order_date::date)::int AS month,
    TO_CHAR(order_date::date, 'Month') AS month_name,
    TO_CHAR(order_date::date, 'YYYY-MM') AS year_month
FROM public.order_data;

ALTER TABLE gold.dim_date ADD PRIMARY KEY (date_key);

-- ------------------------------------------------------------
-- 2. dim_product
-- Derived from order_data (product_id, category, sub_category)
-- ------------------------------------------------------------
CREATE TABLE gold.dim_product AS
SELECT DISTINCT
    product_id,
    category,
    sub_category
FROM public.order_data;

ALTER TABLE gold.dim_product ADD PRIMARY KEY (product_id);

-- ------------------------------------------------------------
-- 3. dim_customer
-- Only customer_id + review_rating retained.
-- customer_data was found to have no meaningful behavioral
-- correlation with order_data (see notebook: previous_purchases
-- vs actual order count, corr = 0.0146). review_rating is kept
-- as a standalone attribute to test satisfaction vs revenue
-- correlation — not treated as a time-series or NPS metric.
-- ------------------------------------------------------------
CREATE TABLE gold.dim_customer AS
SELECT DISTINCT
    customer_id,
    review_rating
FROM public.customer_data;

ALTER TABLE gold.dim_customer ADD PRIMARY KEY (customer_id);

-- ------------------------------------------------------------
-- 4. fact_orders
-- Grain: one row per order_id.
-- Excludes 21 rows where cost_price and list_price are both 0
-- with no recoverable reference price elsewhere in the dataset
-- (486 of the original 507 zero-price rows were already
-- recovered via same-product median imputation at the silver
-- stage; see cleaning notebook for the investigation).
-- ship_mode intentionally excluded — not required by any of
-- the 3 analysis questions.
-- ------------------------------------------------------------
CREATE TABLE gold.fact_orders AS
SELECT
    order_id,
    order_date::date AS date_key,
    product_id,
    customer_id,
    segment,
    quantity,
    cost_price,
    list_price,
    discount_percent,
    (list_price * quantity * (1 - discount_percent / 100.0)) AS revenue,
    ((list_price - cost_price) * quantity * (1 - discount_percent / 100.0)) AS profit
FROM public.order_data
WHERE NOT (cost_price = 0 AND list_price = 0);

ALTER TABLE gold.fact_orders ADD PRIMARY KEY (order_id);
ALTER TABLE gold.fact_orders ADD FOREIGN KEY (date_key) REFERENCES gold.dim_date(date_key);
ALTER TABLE gold.fact_orders ADD FOREIGN KEY (product_id) REFERENCES gold.dim_product(product_id);
ALTER TABLE gold.fact_orders ADD FOREIGN KEY (customer_id) REFERENCES gold.dim_customer(customer_id);

