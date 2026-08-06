# Retail Performance Analytics

End-to-end data pipeline (bronze → silver → gold) with star-schema and Power BI dashboard analyzing retail order data, built to evaluate profitability and revenue health for a finance/executive audience.

## Problem Statement

Management has visibility into total revenue, but not into where and whether that revenue is actually profitable, whether growth reflects healthy demand, or whether customer satisfaction is a reliable early-warning signal. This project evaluates profitability across product categories, tracks whether revenue growth is accompanied by rising or falling average order value, and tests whether customer satisfaction and retention correlate with revenue to give finance a clearer, evidence-based view of business health beyond top-line numbers.

## Questions

1. Which product categories/sub-categories generate the highest profit margin, and which contribute the most/least in absolute profit?
2. Is monthly revenue trending up or down, and does AOV move with it — or does revenue growth mask a shift toward cheaper orders?
3. Does customer satisfaction (review rating) or repeat-purchase behavior (retention) correlate with revenue — can either be used as an early-warning indicator?

## Data

- `order_data.csv` — 9,994 order-level transactions (2022–2023): category, sub-category, product, cost/list price, discount, quantity, customer_id.
- `customer_data.csv` — 5,050 customer records: demographics, review_rating, subscription/purchase behavior fields.
- Verified: `customer_id` overlaps between both files, but customer_data's self-reported purchase history has ~0 correlation with actual order_data behavior (r = 0.0146) — the two tables are not truly relationally linked. Only `customer_id` and `review_rating` are carried into the gold layer from customer_data.

## Pipeline

**Bronze → Silver** (`notebooks/data-cleaning.ipynb`, Python/pandas)
- Standardized column names, deduplicated rows, normalized inconsistent category labels
- Median-imputed skewed numeric nulls, flagged categorical nulls as "Unknown"
- Identified 507 order rows with $0 cost/list price; recovered 486 via same-product price lookup, excluded 21 unresolved rows
- Validity checks (logical bounds, not statistical outlier removal — this is a descriptive, not predictive, project)

**Silver → Gold** (`sql/silver_to_gold.sql`, PostgreSQL)
- Star schema: `fact_orders`, `dim_date`, `dim_product`, `dim_customer`
- `fact_orders` excludes the 21 unresolved zero-price rows
- Derived `revenue` and `profit` fields per order

**Gold → Dashboard** (`dashboard/retail_dashboard.pbix`, Power BI)
- Imported from Postgres `gold` schema, relationships modeled in star schema
- DAX measures: Total Revenue, Total Profit, Profit Margin, Order Count, AOV, Avg Review Rating

## Key Findings

- Profit margin is consistent (~10–13.5%) across all sub-categories — no category is meaningfully more/less efficient on margin. However, ~44% of all transactions have zero margin (cost = list price), concentrated most heavily in Office Supplies (57% of its rows).
- Office Supplies drives high order volume but contributes less total profit than Technology or Furniture.
- Revenue and AOV move together month over month — growth is not diluted by a shift toward cheaper orders.
- Customer review rating shows no correlation with customer revenue — not a reliable early-warning signal.

## Repo Structure

```
data/           raw CSVs
sql/            schema.sql (silver DDL), silver_to_gold.sql (gold build)
notebooks/      bronze-to-silver cleaning notebook
dashboard/      retail_dashboard.pbix
```

## How to Use

**View only:** open `dashboard/retail_dashboard.pbix` in Power BI Desktop (free). Data is cached in the file — no database connection needed.

**Reproduce the pipeline:**
1. Set up a local PostgreSQL instance
2. Run `sql/schema.sql` to create the silver-layer tables
3. Import `data/customer_data.csv` and `data/order_data.csv`
4. Run `notebooks/data-cleaning.ipynb` to clean bronze → silver
5. Run `sql/silver_to_gold.sql` to build the gold star schema
6. Open the `.pbix`, update the Postgres connection under Transform Data → Data Source Settings, refresh
