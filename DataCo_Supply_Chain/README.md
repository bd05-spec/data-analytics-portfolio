# DataCo Global — where the money is, and where the delays are

180,519 order-line rows. Each one is an item inside an order. My job: figure out which regions and categories actually drive revenue, and why more than half of all order items arrived late. I also had to keep customer PII out of the analytic files entirely.

## The dashboard

Five pages answering "why does delivery run late?":

* **Shipping** - late rate by shipping class (First Class 95.3%, Standard 38.1%), scheduled vs actual days, flat late rate by market, items by class and outcome.
* **Trend** - quarterly sales and profit with the last two quarters flagged: from 2017 Q4 orders shrink to about one item each, and 2018 Q1 covers January only.
* **Status and category** - order status vs delivery outcome, and profit and late rate by category.
* **Arrival vs promise** - how many days early or late items arrive, by class, plus all 23 regions (48.8-58.0%) and department margins.
* **Action plan** - an "extra promise days" slider. One extra day cuts the shipped late rate from 57.3% to 23.7% (57,957 items on time), with a recommended promise for each class.

![Shipping](visuals/dashboard_shipping.png)
![Action plan](visuals/dashboard_action_plan.png)

## The raw file, honestly

53 columns, latin1-encoded, one big Kaggle export. Two columns were dead on arrival: Product Description is empty in every single row, and Order Zipcode is missing for about 17% of orders. I left both in `raw_unedited/` for the audit trail and excluded them downstream — no point modeling a column with no values.

The PII situation needed care. The raw file has customer names, emails, passwords, street addresses. Those stay in `raw_unedited/` and nowhere else. The cleaned fact table carries only IDs and order attributes.

## What I did to it

`Order Item Id` is unique across all 180,519 rows, so that's the fact grain; `Order Id` ties items to orders (65,752 of them). I normalized the two DateOrders timestamps to ISO datetimes, and kept `Late_delivery_risk` as the binary flag it is — 1 means the item was at risk of missing its committed date, validated against the real-vs-scheduled shipping day counts.

```sql
SELECT
    [Order Region],
    COUNT(*) AS items,
    SUM(Sales) AS sales,
    SUM([Order Profit Per Order]) AS profit,
    AVG(CAST([Late_delivery_risk] AS float)) AS late_risk_rate
FROM dbo.DataCo_OrderItem
GROUP BY [Order Region]
ORDER BY sales DESC;
```

That region rollup is the query I kept coming back to. It answers both questions at once — revenue and risk.

## The numbers matched, so I moved on

Python and SQL agree: 180,519 items, 65,752 orders. Sales total $36,784,735.01, profit $3,966,902.97 (an earlier version of this README quoted $36,783,702.66 and $3,972,779.43; the cleaned and raw files both give the figures above). The late flag is on 98,977 items: 54.83% of all items, or 57.3% once the 7,754 canceled shipments are left out.

## What the data actually says

Western Europe ($5.89M) and Central America ($5.67M) are the two biggest regions — together just over 31% of all revenue. South America sits at exactly half of Western Europe. The dashboard's bar chart makes the drop-off obvious.

![Top regions by total sales](visuals/dataco_sales_by_region.png)

On risk: the "Late delivery" status maps 1:1 to the risk flag (100% by definition), while advance shipping, canceled, and on-time shipments carry zero flagged risk. That sounds trivial, but it confirms the flag is derived cleanly from status rather than being a noisy separate signal — and with 54.83% of all items late, the operational problem is real regardless of how you slice it. It is not regional: every market sits between 54.4% and 55.2%. It is the promise. First Class always takes 2 days against a 1-day promise, and Second Class averages 4.0 actual days, the same as Standard, while promising 2.

![Late-delivery risk by shipment status](visuals/dataco_delivery_risk_by_status.png)

## What's in the folder

* [`raw_unedited/DataCoSupplyChainDataset.csv`](raw_unedited/DataCoSupplyChainDataset.csv) — original Kaggle extract, PII intact, untouched.
* [`data/cleaned/`](data/cleaned/) — de-identified analytic tables (CSV, XLSX).
* [`notebooks/DataCo_Supply_Chain_analysis.ipynb`](notebooks/DataCo_Supply_Chain_analysis.ipynb) — profiling, cleaning, charts.
* [`sql/DataCo_Supply_Chain.sql`](sql/DataCo_Supply_Chain.sql) — DDL, aggregates, category profit, 7-day rolling sales.
* [`dashboard/DataCo_Supply_Chain.pbip`](dashboard/DataCo_Supply_Chain.pbip) — Power BI project (PBIR report + TMDL star schema: Date, Shipping Mode, Category -> Order Items) reading the de-identified CSV through a `DataRoot` parameter. Five pages: Shipping, Trend, Status and category, Arrival vs promise, Action plan.
* [`dashboard/DataCo_Supply_Chain.pbix`](dashboard/DataCo_Supply_Chain.pbix) — standalone copy for download.
* [`visuals/`](visuals/) — the two charts above.