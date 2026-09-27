# DataCo Smart Supply Chain Analysis

## Overview
This project analyzes end-to-end supply chain logistics, sales performance, fulfillment statuses, and late delivery risks for DataCo Global.

**Source:** Kaggle `shashwatwork/dataco-smart-supply-chain-for-big-data-analysis` (v1).

## Data Quality & Limitations
* **Format & Encoding:** 180,519 rows x 53 columns in raw CSV format (using `latin1` encoding).
* **Missing Fields:** `Product Description` is 100% null in the original raw source and was retained as null. `Order Zipcode` is also largely unpopulated.
* **Privacy & Compliance (PII):** Raw files contained sensitive customer PII fields (`Customer Email`, `Customer Password`, `Customer Fname`, `Customer Lname`, `Customer Street`, `Customer Zipcode`). In accordance with data governance standards, all PII fields were stripped from the curated analytics export while remaining untouched in `raw_unedited/`.

## Data Cleaning & Transformation
1. **Grain & Identity:** Verified `Order Item Id` as the unique candidate primary key across all 180,519 order items.
2. **Timestamp Parsing:** Standardized order and shipping timestamps into clean ISO datetime fields (`order date (DateOrders)` and `shipping date (DateOrders)`).
3. **Data Minimization:** Removed 6 PII columns from the downstream reporting table.

## Folder Contents
* [`raw_unedited/DataCoSupplyChainDataset.csv`](raw_unedited/DataCoSupplyChainDataset.csv) - The original source dataset.
* [`data/cleaned/`](data/cleaned/) - Cleaned analytics datasets (CSV and Excel formats).
* [`notebooks/DataCo_Supply_Chain_analysis.ipynb`](notebooks/DataCo_Supply_Chain_analysis.ipynb) - Jupyter notebook with data loading, cleaning, and profiling.
* [`sql/DataCo_Supply_Chain.sql`](sql/DataCo_Supply_Chain.sql) - SQL Server schema DDL, aggregate queries, and moving average CTEs.
* [`dashboard/`](dashboard/) - Power BI semantic model (`.pbip` format).
* [`visuals/dataco_sales_by_region.png`](visuals/dataco_sales_by_region.png) - Exported chart visual.

## Data Validation
Cross-verification between Python profiling scripts and SQL queries confirmed:
* **Order Item Count:** Exactly 180,519 order items.
* **Unique Orders:** 65,752 distinct order IDs.
* **Total Sales:** $36,783,702.66 across all order items.
* **Late Delivery Risk Rate:** 54.83% of items carry a late delivery risk flag.

## Key Finding

Regional analysis reveals that Western Europe and Central America represent the largest sales markets, while over 54% of total shipments carry a late delivery risk:

![Top 10 Order Regions by Total Sales](visuals/dataco_sales_by_region.png)
