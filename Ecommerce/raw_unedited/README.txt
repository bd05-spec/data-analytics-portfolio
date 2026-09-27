DATASET: Kaggle - mkechinov/ecommerce-behavior-data-from-multi-category-store (version 8)
STATUS : NOT PROCESSED - raw files only.

WHY NOT PROCESSED
The download completed successfully, but the analysis was deliberately not started
because the instruction was to finish only the already-completed projects and not to
begin new ones.

FILES (raw, unedited, in raw_unedited\)
  2019-Oct.csv  ~5.67 GB
  2019-Nov.csv  ~9.01 GB

SCHEMA (verified by reading both files)
  event_time      (string) "YYYY-MM-DD HH:MM:SS UTC"
  event_type      (string) view | cart | purchase
  product_id      (int)
  category_id     (int, large values - read as string in tools to avoid precision loss)
  category_code   (string, many nulls)
  brand           (string, many nulls)
  price           (float, no nulls observed)
  user_id         (int)
  user_session    (string, UUID)

VERIFIED FACTS (row counts counted, not estimated)
  2019-Oct.csv  42,448,764 rows
  2019-Nov.csv  67,501,979 rows
  Total        109,950,743 rows

  Event type totals (2019-Oct): view 40,779,399 | cart 926,516 | purchase 742,849
  Event type totals (2019-Nov): view 63,556,110 | cart 3,028,930 | purchase 916,939

KNOWN CAVEATS IF YOU PROCEED LATER
  - Exceeds Excel's 1,048,576 row limit. Use CSV/Parquet or a database, not XLSX.
  - category_id exceeds 2^53; keep it as text in Power BI and SQL, or it will be rounded.
  - No revenue column exists. price is the unit price shown at event time, so any
    revenue figure would be an assumption, not a measured value.
  - Legitimate duplicate events exist (a user can view the same product repeatedly);
    do not de-duplicate without a documented business rule.
  - There is no customer identifier beyond user_id and no order/payment data, so
    per-customer LTV or true conversion-to-order analysis is not possible.

NOT PRODUCED FOR THIS DATASET (by design)
  cleaned data, data-quality report, SQL, DAX, dashboards, notebooks.
