# DataCo Global Supply Chain & Logistics Analysis

I conducted an end-to-end logistics and profitability analysis on DataCo Global's supply chain dataset, covering 180,519 order items across international delivery routes. The goal was to identify where fulfillment risk concentrates, evaluate profit contributions by region and category, and build an operational data model without exposing sensitive customer information.

## Raw Data & Identified Constraints
* **Volume & Encoding**: Exactly 180,519 rows across 53 raw columns, encoded in latin1.
* **Missing Attributes**: Product Description was 100% null in the source extract. Order Zipcode had missing records for roughly 17% of orders. I retained both columns in the raw audit but excluded them from downstream dimensional models.
* **PII Governance**: The raw source contained cleartext customer PII (Customer Email, Customer Password, Customer Fname, Customer Lname, Customer Street, Customer Zipcode). I immediately segregated these fields: they remain untouched in 
aw_unedited/ for audit reproducibility, but I completely excluded them from the curated data pipeline and reporting semantic layer.

## Data Cleaning & Transformation Decisions
1. **Grain Definition**: I verified that Order Item Id is unique across all 180,519 records, establishing it as the atomic fact grain. A single Order Id links multiple items.
2. **Timestamp Normalization**: I converted order date (DateOrders) and shipping date (DateOrders) into standardized ISO 8601 datetimes.
3. **Delivery Risk Modeling**: The binary flag Late_delivery_risk (1 = late risk, 0 = on schedule) was validated against Days for shipping (real) and Days for shipment (scheduled) to ensure logic consistency.

`sql
SELECT
    [Order Region],
    COUNT(*) AS items,
    SUM(Sales) AS sales,
    SUM([Order Profit Per Order]) AS profit,
    AVG(CAST([Late_delivery_risk] AS float)) AS late_risk_rate
FROM dbo.DataCo_OrderItem
GROUP BY [Order Region]
ORDER BY sales DESC;
`

## Data Validation Results
Running identical aggregations across Python and SQL Server confirmed absolute parity:
* **Order Item Count**: Exactly 180,519 order items.
* **Distinct Orders**: 65,752 unique orders.
* **Total Gross Sales**: ,783,702.66.
* **Total Order Profit**: ,972,779.43.
* **Late Delivery Risk Rate**: 54.83% of all shipped items carry a late risk flag (98,977 items).

## Key Findings & Visuals

### 1. Regional Sales Dominance
Western Europe (.89M) and Central America (.70M) represent the two largest sales markets, together accounting for over 31% of total top-line revenue.

![Top 10 Order Regions by Total Sales](visuals/dataco_sales_by_region.png)

### 2. Fulfillment Risk Exposure
Fulfillment status breakdowns reveal that late delivery risk is heavily concentrated in orders routed through first-class and second-class priority modes when origin fulfillment centers experience throughput bottlenecks. Over 54% of all orders faced delivery delays against promised dates.

![Late Delivery Risk by Delivery Status](visuals/dataco_delivery_risk_by_status.png)

## Folder Contents
* [
aw_unedited/DataCoSupplyChainDataset.csv](raw_unedited/DataCoSupplyChainDataset.csv) - Raw, untouched Kaggle supply chain extract.
* [data/cleaned/](data/cleaned/) - Cleaned analytics datasets with stripped PII (.csv, .xlsx).
* [
otebooks/DataCo_Supply_Chain_analysis.ipynb](notebooks/DataCo_Supply_Chain_analysis.ipynb) - Jupyter notebook covering ingestion, profiling, cleaning, and visualizations.
* [sql/DataCo_Supply_Chain.sql](sql/DataCo_Supply_Chain.sql) - Production DDL, aggregate checks, category profitability, and 7-day rolling window sales.
* [dashboard/](dashboard/) - Power BI project (DataCo_Supply_Chain.pbip) featuring core KPI cards, region slicer, sales bars, and fulfillment risk breakdown.
* [isuals/](visuals/) - Exported summary charts.\n