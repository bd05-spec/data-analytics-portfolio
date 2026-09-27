/* ============================================================================
   Ecommerce Multi-Category Store - SQL Pipeline & Analysis Queries (T-SQL)
   Target: SQL Server / Azure SQL
   Purpose: Full ETL pipeline, model specs, data quality validation, and 
            business analysis queries for 109.95M store interaction events.
   ============================================================================ */

/* ============================================================================
   Ecommerce Multi-Category Store - SQL cleaning / modelling script (T-SQL)
   Target: SQL Server / Azure SQL (run in SSMS or sqlcmd)
   Purpose: reproduce the same cleaned-data steps as the Python pipeline
            (scripts/01_clean_and_profile.py) so Power BI can also be fed
            straight from a database.
   Source : 2019-Oct.csv + 2019-Nov.csv = 109,950,743 rows
   Grain  : one row = one event (view | cart | purchase)
   ============================================================================ */

/* ---------------------------------------------------------------------------
   0. STAGING - import the raw CSVs untouched.
      category_id is VARCHAR on purpose: values exceed 2^53, casting to BIGINT
      silently rounds them.
--------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.stg_events', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.stg_events (
        event_time    VARCHAR(50)  NULL,
        event_type    VARCHAR(20)  NULL,
        product_id    VARCHAR(50)  NULL,   -- raw text, validated on cleaning
        category_id   VARCHAR(50)  NULL,
        category_code VARCHAR(200) NULL,
        brand         VARCHAR(200) NULL,
        price         VARCHAR(50)  NULL,   -- raw text, validated on cleaning
        user_id       VARCHAR(50)  NULL,
        user_session  VARCHAR(100) NULL
    );
END;
GO

-- Load raw month files (adjust paths; repeat per month)
-- BULK INSERT dbo.stg_events
-- FROM 'C:\data\2019-Oct.csv'
-- WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', TABLOCK, MAXERRORS = 0);

/* ---------------------------------------------------------------------------
   1. HARD REJECTS - only rows whose event_time cannot be parsed (typed at all).
      Everything else is KEPT and cleaned in step 2, exactly like the Python
      pipeline: soft problems (12 rows with null user_session -> data/bad_rows.csv,
      256,761 rows with price <= 0 -> data_quality_report.csv) are REPORTED but
      no row is dropped, so the cleaned table keeps all 109,950,743 rows.
      Expected reject count on this dataset: 0.
--------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.clean_events_rejects', 'U') IS NOT NULL DROP TABLE dbo.clean_events_rejects;
CREATE TABLE dbo.clean_events_rejects (
    reject_reason VARCHAR(100) NULL,
    event_time    VARCHAR(50)  NULL,
    event_type    VARCHAR(20)  NULL,
    product_id    VARCHAR(50)  NULL,
    price         VARCHAR(50)  NULL,
    user_id       VARCHAR(50)  NULL,
    user_session  VARCHAR(100) NULL
);
GO

INSERT INTO dbo.clean_events_rejects
SELECT reject_reason, event_time, event_type, product_id, price, user_id, user_session
FROM (
    SELECT
        t.*,
        CASE
            WHEN t.event_time_parsed IS NULL THEN 'unparseable_event_time'
            ELSE NULL
        END AS reject_reason
    FROM (
        SELECT
            TRY_CONVERT(datetime2(0), REPLACE(event_time, ' UTC', '')) AS event_time_parsed,
            LOWER(LTRIM(RTRIM(event_type)))                            AS event_type,
            TRY_CONVERT(bigint, product_id)                            AS product_id,
            category_id,
            NULLIF(LTRIM(RTRIM(category_code)), '')                    AS category_code,
            NULLIF(LTRIM(RTRIM(brand)), '')                            AS brand,
            TRY_CONVERT(float, price)                                  AS price,
            TRY_CONVERT(bigint, user_id)                               AS user_id,
            NULLIF(LTRIM(RTRIM(user_session)), '')                     AS user_session
        FROM dbo.stg_events
    ) AS t
) AS x
WHERE x.reject_reason IS NOT NULL;
GO

/* ---------------------------------------------------------------------------
   2. CLEANING - typed table, null strategy, derived price features.
      Null strategy (identical to the Python pipeline):
        * brand / category_code -> unknown-flag column + fill 'unknown'
        * category hierarchy    -> split category_code on '.'
        * PurchasePrice         -> price on purchase events, 0 otherwise
        * PriceBand             -> half-open bins [0,10) [10,25) [25,50)
                                   [50,100) [100,250) [250,500) [500, inf)
      Legitimate duplicate events are intentionally KEPT.
--------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.clean_events', 'U') IS NOT NULL DROP TABLE dbo.clean_events;
CREATE TABLE dbo.clean_events (
    event_time_parsed        datetime2(0) NOT NULL,
    event_type               varchar(20)  NOT NULL,
    product_id               bigint       NOT NULL,
    category_id              varchar(50)  NULL,
    category_code            varchar(200) NOT NULL,
    brand                    varchar(200) NOT NULL,
    price                    float        NOT NULL,
    user_id                  bigint       NOT NULL,
    user_session             varchar(100) NULL,   -- 12 rows are NULL (logged, kept)
    brand_is_unknown         tinyint      NOT NULL,
    category_code_is_unknown tinyint      NOT NULL,
    category_main            varchar(50)  NULL,
    category_sub             varchar(50)  NULL,
    category_detail          varchar(50)  NULL,
    PurchasePrice            float        NOT NULL,
    PriceBand                varchar(20)  NOT NULL
);
GO

INSERT INTO dbo.clean_events (
    event_time_parsed, event_type, product_id, category_id, category_code, brand,
    price, user_id, user_session, brand_is_unknown, category_code_is_unknown,
    category_main, category_sub, category_detail, PurchasePrice, PriceBand
)
SELECT
    t.event_time_parsed,
    t.event_type,
    t.product_id,
    t.category_id,
    COALESCE(t.category_code, 'unknown')                        AS category_code,
    COALESCE(t.brand, 'unknown')                                AS brand,
    COALESCE(t.price, 0.0)                                      AS price,
    t.user_id,
    t.user_session,
    CASE WHEN t.brand IS NULL THEN 1 ELSE 0 END                 AS brand_is_unknown,
    CASE WHEN t.category_code IS NULL THEN 1 ELSE 0 END         AS category_code_is_unknown,
    -- Hierarchy matches pandas str.split('.').str[n]: dot-less values yield
    -- 'unknown' for part 1 and NULL for parts 2-3. PARSENAME assumes <= 4 parts,
    -- which holds here (max observed depth = 3).
    PARSENAME(REPLACE(COALESCE(t.category_code, 'unknown'), '.', '.'), 1) AS category_main,
    PARSENAME(REPLACE(COALESCE(t.category_code, 'unknown'), '.', '.'), 2) AS category_sub,
    PARSENAME(REPLACE(COALESCE(t.category_code, 'unknown'), '.', '.'), 3) AS category_detail,
    CASE WHEN t.event_type = 'purchase' THEN t.price ELSE 0.0 END AS PurchasePrice,
    CASE
        WHEN t.price <  10 THEN '$0-10'
        WHEN t.price <  25 THEN '$10-25'
        WHEN t.price <  50 THEN '$25-50'
        WHEN t.price < 100 THEN '$50-100'
        WHEN t.price < 250 THEN '$100-250'
        WHEN t.price < 500 THEN '$250-500'
        ELSE '$500+'
    END                                                         AS PriceBand
FROM (
    SELECT
        TRY_CONVERT(datetime2(0), REPLACE(event_time, ' UTC', '')) AS event_time_parsed,
        LOWER(LTRIM(RTRIM(event_type)))                            AS event_type,
        TRY_CONVERT(bigint, product_id)                            AS product_id,
        category_id,
        NULLIF(LTRIM(RTRIM(category_code)), '')                    AS category_code,
        NULLIF(LTRIM(RTRIM(brand)), '')                            AS brand,
        TRY_CONVERT(float, price)                                  AS price,
        TRY_CONVERT(bigint, user_id)                               AS user_id,
        NULLIF(LTRIM(RTRIM(user_session)), '')                     AS user_session
    FROM dbo.stg_events
) AS t
WHERE t.event_time_parsed IS NOT NULL;
GO

/* ---------------------------------------------------------------------------
   3. MODELLING for Power BI - small dimensions + aggregate facts.
      110M rows are heavy for Import mode; these aggregates keep the report
      snappy while the event table stays available for drill-through.
--------------------------------------------------------------------------- */
-- Sorted price-band dimension (so bands don't sort alphabetically)
CREATE TABLE dbo.dim_price_band (PriceBand varchar(20) NOT NULL PRIMARY KEY, SortOrder int NOT NULL);
INSERT INTO dbo.dim_price_band (PriceBand, SortOrder) VALUES
 ('$0-10', 1), ('$10-25', 2), ('$25-50', 3), ('$50-100', 4),
 ('$100-250', 5), ('$250-500', 6), ('$500+', 7), ('unknown', 8);
GO

-- Category dimension (hierarchy already parsed in clean_events)
SELECT DISTINCT category_code, category_main, category_sub, category_detail
INTO dbo.dim_category
FROM dbo.clean_events
WHERE category_code <> 'unknown';
GO

-- Brand dimension
SELECT DISTINCT brand INTO dbo.dim_brand
FROM dbo.clean_events
WHERE brand <> 'unknown';
GO

-- Date dimension
SELECT DISTINCT CAST(event_time_parsed AS date) AS [Date],
       DATEPART(year, event_time_parsed) AS [Year],
       DATEPART(month, event_time_parsed) AS [Month],
       DATENAME(month, event_time_parsed) AS MonthName,
       DATEPART(day, event_time_parsed) AS [Day],
       DATEPART(weekday, event_time_parsed) AS DayOfWeek
INTO dbo.dim_date
FROM dbo.clean_events;
GO

-- Aggregate facts (the grain Power BI visuals actually need)
SELECT CAST(event_time_parsed AS date) AS event_date, event_type,
       COUNT(*) AS events, SUM(PurchasePrice) AS purchase_price
INTO dbo.agg_daily_event_type
FROM dbo.clean_events
GROUP BY CAST(event_time_parsed AS date), event_type;
GO

SELECT PriceBand, event_type, COUNT(*) AS events, SUM(PurchasePrice) AS purchase_price
INTO dbo.agg_price_band_event_type
FROM dbo.clean_events
GROUP BY PriceBand, event_type;
GO

SELECT category_main, event_type, COUNT(*) AS events, SUM(PurchasePrice) AS purchase_price
INTO dbo.agg_category_main_event_type
FROM dbo.clean_events
WHERE category_code <> 'unknown'
GROUP BY category_main, event_type;
GO

SELECT brand, event_type, COUNT(*) AS events, SUM(PurchasePrice) AS purchase_price
INTO dbo.agg_brand_event_type
FROM dbo.clean_events
WHERE brand <> 'unknown'
GROUP BY brand, event_type;
GO

/* ---------------------------------------------------------------------------
   4. VALIDATION - expected results on the full Oct+Nov dataset
--------------------------------------------------------------------------- */
SELECT COUNT(*) AS staged_rows   FROM dbo.stg_events;          -- 109,950,743
SELECT COUNT(*) AS rejected_rows FROM dbo.clean_events_rejects; -- 0 (nothing unparseable)
SELECT COUNT(*) AS cleaned_rows  FROM dbo.clean_events;         -- 109,950,743 (no row dropped)
-- soft data-quality issues that are KEPT (mirror of data/bad_rows.csv + report)
SELECT COUNT(*) AS rows_null_session FROM dbo.clean_events WHERE user_session IS NULL; -- 12
SELECT COUNT(*) AS rows_zero_price   FROM dbo.clean_events WHERE price <= 0;           -- 256,761
SELECT COUNT(*) AS rows_unknown_brand    FROM dbo.clean_events WHERE brand = 'unknown';         -- 15,341,158 (13.95%)
SELECT COUNT(*) AS rows_unknown_category FROM dbo.clean_events WHERE category_code = 'unknown'; -- 35,413,780 (32.21%)
SELECT event_type, COUNT(*) AS events FROM dbo.clean_events GROUP BY event_type;
-- view 104,335,509 | cart 3,955,446 | purchase 1,659,788
SELECT PriceBand, SUM(events) AS events, SUM(purchase_price) AS purchase_price
FROM dbo.agg_price_band_event_type GROUP BY PriceBand ORDER BY PriceBand;


/* ============================================================================
   ANALYTICAL QUERIES & REPORTING DATASETS
   ============================================================================ */

-- ============================================================================
-- Ecommerce Multi-Category Store - analysis queries (T-SQL)
-- Target : SQL Server / Azure SQL, table dbo.clean_events (+ dbo.agg_* built by
--          scripts/sql_pipeline.sql). 109,950,743 rows, Oct-Nov 2019.
-- Grain  : one row = one event (view | cart | purchase); NO quantity column.
-- Value  : PurchasePrice (= price on purchase rows, 0 elsewhere) is the only
--          meaningful value column. Never SUM(price) across all events.
-- Run    : SSMS, or: sqlcmd -S .\SQLEXPRESS -d Ecommerce -i scripts\queries.sql
-- ============================================================================

-- Q1: Sanity - row count, distinct users/sessions/products, date range
SELECT 'Q1_sanity' AS query,
       COUNT(*)                     AS total_events,
       COUNT(DISTINCT user_id)      AS distinct_users,
       COUNT(DISTINCT product_id)   AS distinct_products,
       COUNT(DISTINCT user_session) AS distinct_sessions,
       MIN(event_time_parsed)       AS min_time,
       MAX(event_time_parsed)       AS max_time
FROM dbo.clean_events;
-- expected: 109,950,743 rows | 2019-10-01 00:00:00 .. 2019-11-30 23:59:59

-- Q2: Event type totals and share (funnel base)
SELECT 'Q2_event_type' AS query,
       event_type,
       COUNT(*) AS events,
       CAST(100.0 * COUNT(*) / (SELECT COUNT(*) FROM dbo.clean_events) AS decimal(10,2)) AS pct
FROM dbo.clean_events
GROUP BY event_type
ORDER BY events DESC;
-- expected: view 104,335,509 (94.89%) | cart 3,955,446 (3.60%) | purchase 1,659,788 (1.51%)

-- Q3: Daily trend Oct 1 - Nov 30
SELECT 'Q3_daily_trend' AS query,
       CAST(event_time_parsed AS date) AS event_date,
       SUM(CASE WHEN event_type = 'view'     THEN 1 ELSE 0 END) AS views,
       SUM(CASE WHEN event_type = 'cart'     THEN 1 ELSE 0 END) AS carts,
       SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchases,
       COUNT(*) AS total
FROM dbo.clean_events
GROUP BY CAST(event_time_parsed AS date)
ORDER BY event_date;

-- Q4: Hourly distribution (UTC) - peak shopping hours
SELECT 'Q4_hourly' AS query,
       DATEPART(hour, event_time_parsed) AS hour_utc,
       COUNT(*) AS events,
       SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchases
FROM dbo.clean_events
GROUP BY DATEPART(hour, event_time_parsed)
ORDER BY hour_utc;

-- Q5: Top 15 category_code by views (unknown category excluded)
SELECT TOP (15) 'Q5_top_categories_views' AS query,
       category_code,
       COUNT(*) AS views
FROM dbo.clean_events
WHERE event_type = 'view' AND category_code <> 'unknown'
GROUP BY category_code
ORDER BY views DESC;

-- Q5b: Size of the imputed buckets (null strategy transparency)
SELECT 'Q5b_unknown_share' AS query,
       SUM(category_code_is_unknown) AS rows_unknown_category,
       SUM(brand_is_unknown)         AS rows_unknown_brand,
       CAST(100.0 * SUM(category_code_is_unknown) / COUNT(*) AS decimal(6,2)) AS pct_unknown_category,
       CAST(100.0 * SUM(brand_is_unknown) / COUNT(*) AS decimal(6,2))         AS pct_unknown_brand
FROM dbo.clean_events;

-- Q6: Top 15 brands by purchase count + view->purchase conversion
SELECT TOP (15) 'Q6_brand_purchase' AS query,
       brand,
       SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchases,
       SUM(CASE WHEN event_type = 'view'     THEN 1 ELSE 0 END) AS views,
       CAST(100.0 * SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END)
                  / NULLIF(SUM(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END), 0)
            AS decimal(10,4)) AS view_to_purchase_pct
FROM dbo.clean_events
WHERE brand <> 'unknown'
GROUP BY brand
HAVING SUM(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) >= 10000
ORDER BY purchases DESC;

-- Q7: Funnel conversion rates (view -> cart -> purchase)
WITH totals AS (
    SELECT SUM(CASE WHEN event_type = 'view'     THEN 1 ELSE 0 END) AS views,
           SUM(CASE WHEN event_type = 'cart'     THEN 1 ELSE 0 END) AS carts,
           SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchases
    FROM dbo.clean_events
)
SELECT 'Q7_funnel' AS query,
       views, carts, purchases,
       CAST(100.0 * carts / views AS decimal(10,4))         AS view_to_cart_pct,
       CAST(100.0 * purchases / carts AS decimal(10,4))     AS cart_to_purchase_pct,
       CAST(100.0 * purchases / views AS decimal(10,4))     AS view_to_purchase_pct
FROM totals;
-- expected: view->cart 3.79% | cart->purchase 41.96% | view->purchase 1.59%
-- caveat: cart events are under-recorded (a purchase does not require a logged
-- cart event), so cart->purchase can exceed 100% on some slices (e.g. early Oct).

-- Q8: Average / min / max price by event type (price bias per event)
SELECT 'Q8_avg_price_by_event' AS query,
       event_type,
       COUNT(*) AS events,
       CAST(AVG(price) AS decimal(12,2)) AS avg_price,
       CAST(MIN(price) AS decimal(12,2)) AS min_price,
       CAST(MAX(price) AS decimal(12,2)) AS max_price
FROM dbo.clean_events
GROUP BY event_type
ORDER BY avg_price DESC;

-- Q9: Purchase rate by price band (uses the PriceBand column derived at cleaning)
SELECT 'Q9_price_band_conversion' AS query,
       PriceBand,
       COUNT(*) AS events,
       SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchases,
       CAST(100.0 * SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) / COUNT(*) AS decimal(10,4)) AS purchase_rate_pct
FROM dbo.clean_events
GROUP BY PriceBand
ORDER BY PriceBand;

-- Q9b: Purchase VALUE by price band - the money view
SELECT 'Q9b_purchase_value_band' AS query,
       PriceBand,
       SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchases,
       CAST(SUM(PurchasePrice) AS decimal(18,2)) AS total_purchase_price,
       CAST(SUM(PurchasePrice) / NULLIF(SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END), 0) AS decimal(12,2)) AS avg_purchase_price,
       CAST(100.0 * SUM(PurchasePrice) / (SELECT SUM(PurchasePrice) FROM dbo.clean_events) AS decimal(6,2)) AS value_share_pct
FROM dbo.clean_events
GROUP BY PriceBand
ORDER BY PriceBand;

-- Q10: Category hierarchy - top category_main by purchases (parsed during cleaning)
SELECT TOP (15) 'Q10_category_main' AS query,
       category_main,
       SUM(CASE WHEN event_type = 'view'     THEN 1 ELSE 0 END) AS views,
       SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchases,
       CAST(SUM(PurchasePrice) AS decimal(18,2)) AS purchase_value,
       CAST(100.0 * SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END)
                  / NULLIF(SUM(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END), 0)
            AS decimal(10,4)) AS view_to_purchase_pct
FROM dbo.clean_events
WHERE category_main IS NOT NULL AND category_main <> 'unknown'
GROUP BY category_main
ORDER BY purchases DESC;

-- Q11: Session-level funnel - how many sessions actually convert
SELECT 'Q11_session_funnel' AS query,
       has_view, has_cart, has_purchase,
       COUNT(*) AS sessions,
       CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS decimal(6,2)) AS pct_of_sessions
FROM (
    SELECT user_session,
           MAX(CASE WHEN event_type = 'view'     THEN 1 ELSE 0 END) AS has_view,
           MAX(CASE WHEN event_type = 'cart'     THEN 1 ELSE 0 END) AS has_cart,
           MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS has_purchase
    FROM dbo.clean_events
    GROUP BY user_session
) AS s
GROUP BY has_view, has_cart, has_purchase
ORDER BY sessions DESC;

-- Q12: Retention proxy - share of users active in both months
SELECT 'Q12_monthly_active_users' AS query,
       DATEPART(month, event_time_parsed) AS month_num,
       COUNT(DISTINCT user_id) AS mau,
       COUNT(*) AS events,
       CAST(SUM(PurchasePrice) AS decimal(18,2)) AS purchase_value
FROM dbo.clean_events
GROUP BY DATEPART(month, event_time_parsed)
ORDER BY month_num;
-- Oct 2019 vs Nov 2019, then repeat for returning users:
SELECT 'Q12b_cross_month_users' AS query,
       COUNT(*) AS users_in_both_months
FROM (
    SELECT user_id
    FROM dbo.clean_events
    GROUP BY user_id
    HAVING COUNT(DISTINCT DATEPART(month, event_time_parsed)) = 2
) AS u;

-- Q13: Value concentration - Pareto check on purchase value by product
SELECT 'Q13_top_product_value_share' AS query,
       CAST(SUM(CASE WHEN rnk <= 100 THEN purchase_value ELSE 0 END)
            / SUM(purchase_value) * 100 AS decimal(6,2)) AS top100_products_value_pct
FROM (
    SELECT product_id,
           SUM(PurchasePrice) AS purchase_value,
           ROW_NUMBER() OVER (ORDER BY SUM(PurchasePrice) DESC) AS rnk
    FROM dbo.clean_events
    GROUP BY product_id
) AS p;

-- Q14: Quality gate - staged rows must equal rejects + cleaned rows
SELECT 'Q14_reconciliation' AS query,
       (SELECT COUNT(*) FROM dbo.stg_events)           AS staged_rows,
       (SELECT COUNT(*) FROM dbo.clean_events_rejects) AS rejected_rows,
       (SELECT COUNT(*) FROM dbo.clean_events)         AS cleaned_rows,
       CASE WHEN (SELECT COUNT(*) FROM dbo.stg_events)
                 = (SELECT COUNT(*) FROM dbo.clean_events_rejects)
                 + (SELECT COUNT(*) FROM dbo.clean_events)
            THEN 'OK' ELSE 'MISMATCH' END AS reconciliation;
-- expected: staged 109,950,743 | rejected 0 | cleaned 109,950,743 | OK

