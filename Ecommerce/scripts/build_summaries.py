"""Build small Power BI summary files from the raw Ecommerce event logs.

The raw files (2019-Oct.csv, 2019-Nov.csv, ~14.7 GB together) are too big for
Git and for a Power BI import, so this script streams them through DuckDB and
writes compact CSVs to Ecommerce/data/summary/.

Usage:
    python build_summaries.py [--raw-dir PATH]

--raw-dir defaults to Ecommerce/raw_unedited next to this script. Raw files are
never committed (see .gitignore). Times are UTC, as in the source.

Notes on the metrics:
- "purchase value" is the sum of `price` on purchase events. The data has no
  quantity or order-total field, so this is not revenue.
- Distinct users and sessions are counted per grain (day, month, whole period).
  They are not additive across days, so they live in their own files.
"""
import argparse
import time
from pathlib import Path

import duckdb

HERE = Path(__file__).resolve().parent
OUT = HERE.parent / "data" / "summary"
WORK = HERE.parent / "data" / "_work"  # gitignored: parquet cache lives here

PRICE_BANDS = """
    CASE
        WHEN price < 10 THEN '01|Under $10'
        WHEN price < 25 THEN '02|$10-25'
        WHEN price < 50 THEN '03|$25-50'
        WHEN price < 100 THEN '04|$50-100'
        WHEN price < 250 THEN '05|$100-250'
        WHEN price < 500 THEN '06|$250-500'
        WHEN price < 1000 THEN '07|$500-1,000'
        ELSE '08|$1,000+'
    END
"""

FUNNEL_COLS = """
    count(*) FILTER (WHERE event_type = 'view')     AS views,
    count(*) FILTER (WHERE event_type = 'cart')     AS carts,
    count(*) FILTER (WHERE event_type = 'purchase') AS purchases,
    round(sum(price) FILTER (WHERE event_type = 'purchase'), 2) AS purchase_value
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw-dir", type=Path, default=HERE.parent / "raw_unedited")
    args = ap.parse_args()
    files = [args.raw_dir / "2019-Oct.csv", args.raw_dir / "2019-Nov.csv"]
    for f in files:
        if not f.exists():
            raise SystemExit(f"missing raw file: {f}")

    OUT.mkdir(parents=True, exist_ok=True)
    WORK.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect()
    con.execute(f"SET temp_directory = '{(WORK / 'tmp').as_posix()}'")
    con.execute("SET preserve_insertion_order = false")

    events = WORK / "events.parquet"
    if not events.exists():
        t = time.time()
        src = ", ".join(f"'{f.as_posix()}'" for f in files)
        con.execute(f"""
            COPY (
                SELECT
                    strptime(event_time, '%Y-%m-%d %H:%M:%S UTC') AS ts,
                    event_type, product_id, category_id,
                    coalesce(category_code, '') AS category_code,
                    coalesce(brand, '') AS brand,
                    price, user_id, user_session
                FROM read_csv([{src}], header = true, columns = {{
                    'event_time': 'VARCHAR', 'event_type': 'VARCHAR',
                    'product_id': 'BIGINT', 'category_id': 'BIGINT',
                    'category_code': 'VARCHAR', 'brand': 'VARCHAR',
                    'price': 'DOUBLE', 'user_id': 'BIGINT',
                    'user_session': 'VARCHAR'}})
            ) TO '{events.as_posix()}' (FORMAT parquet, COMPRESSION zstd)
        """)
        print(f"parquet cache built in {time.time() - t:.0f}s")

    con.execute(f"""
        CREATE VIEW e AS
        SELECT *,
               CAST(ts AS DATE) AS date,
               strftime(ts, '%Y-%m') AS month,
               CASE WHEN category_code = '' THEN 'Unspecified'
                    ELSE split_part(category_code, '.', 1) END AS category
        FROM '{events.as_posix()}'
    """)

    def write(name, sql):
        t = time.time()
        path = OUT / f"{name}.csv"
        con.execute(f"COPY ({sql}) TO '{path.as_posix()}' (HEADER)")
        print(f"{name}.csv  {path.stat().st_size / 1024:.0f} KB  {time.time() - t:.0f}s")

    write("event_types", """
        SELECT event_type, month, count(*) AS events FROM e GROUP BY ALL ORDER BY ALL""")

    write("monthly_funnel", f"""
        SELECT month, {FUNNEL_COLS},
               count(DISTINCT user_id) AS users,
               count(DISTINCT user_session) AS sessions,
               count(DISTINCT user_session) FILTER (WHERE event_type = 'view') AS view_sessions,
               count(DISTINCT user_session) FILTER (WHERE event_type = 'cart') AS cart_sessions,
               count(DISTINCT user_session) FILTER (WHERE event_type = 'purchase') AS purchase_sessions
        FROM e GROUP BY month
        UNION ALL
        SELECT 'All', {FUNNEL_COLS},
               count(DISTINCT user_id), count(DISTINCT user_session),
               count(DISTINCT user_session) FILTER (WHERE event_type = 'view'),
               count(DISTINCT user_session) FILTER (WHERE event_type = 'cart'),
               count(DISTINCT user_session) FILTER (WHERE event_type = 'purchase')
        FROM e ORDER BY month""")

    write("daily_category", f"""
        SELECT date, category, {FUNNEL_COLS}
        FROM e GROUP BY ALL ORDER BY ALL""")

    write("daily_users", """
        SELECT date,
               count(DISTINCT user_id) AS users,
               count(DISTINCT user_session) AS sessions,
               count(DISTINCT user_id) FILTER (WHERE event_type = 'purchase') AS buyers
        FROM e GROUP BY date ORDER BY date""")

    write("hour_weekday", f"""
        SELECT isodow(ts) AS weekday_num, strftime(ts, '%a') AS weekday,
               hour(ts) AS hour_utc, {FUNNEL_COLS}
        FROM e GROUP BY ALL ORDER BY weekday_num, hour_utc""")

    write("top_brands", f"""
        SELECT CASE WHEN brand = '' THEN 'Unbranded' ELSE brand END AS brand, {FUNNEL_COLS}
        FROM e GROUP BY 1 ORDER BY purchase_value DESC NULLS LAST LIMIT 30""")

    write("top_categories", f"""
        SELECT CASE WHEN category_code = '' THEN 'Unspecified' ELSE category_code END AS category_code,
               {FUNNEL_COLS}
        FROM e GROUP BY 1 ORDER BY purchase_value DESC NULLS LAST LIMIT 30""")

    write("price_bands", f"""
        SELECT split_part(band, '|', 1)::INT AS band_order, split_part(band, '|', 2) AS price_band,
               {FUNNEL_COLS}
        FROM (SELECT *, {PRICE_BANDS} AS band FROM e) GROUP BY ALL ORDER BY band_order""")

    # Data-quality check used to judge the October cart drop-off: how many
    # sessions that purchased logged no cart event at all.
    write("cart_tracking_check", """
        WITH s AS (
            SELECT month, user_session,
                   bool_or(event_type = 'cart') AS has_cart,
                   bool_or(event_type = 'purchase') AS has_purchase
            FROM e GROUP BY ALL)
        SELECT month,
               count(*) FILTER (WHERE has_purchase) AS purchase_sessions,
               count(*) FILTER (WHERE has_purchase AND NOT has_cart) AS purchase_sessions_without_cart
        FROM s GROUP BY month ORDER BY month""")


if __name__ == "__main__":
    main()
