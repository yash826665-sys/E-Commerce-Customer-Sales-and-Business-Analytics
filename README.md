# E-Commerce-Customer-Sales-and-Business-Analytics

## Business Problem

An e-commerce marketplace wants to understand its sales performance, customer behavior, product performance, seller performance, delivery operations, and customer satisfaction in order to identify concrete opportunities for growth and operational improvement.

## Objectives

- Quantify revenue, order volume, and customer growth over time
- Segment customers by value using RFM analysis
- Evaluate whether repeat-purchase retention is a realistic growth lever for this business
- Identify top- and bottom-performing product categories and sellers
- Measure delivery performance and its relationship to customer satisfaction
- Translate findings into specific, evidence-backed business recommendations

## Headline Findings

| Metric | Value |
|---|---|
| Total Revenue | R$ 15,419,773.75 |
| Total Delivered Orders | 96,478 |
| Unique Customers | 93,358 |
| Average Order Value | R$ 159.83 |
| Repeat Customer Rate | 3.0% |
| Top-10-Category Revenue Share | 62.4% |
| Top-10%-Seller Revenue Share | 67.1% |
| Late Delivery Rate | 6.77% |
| Avg. Review Score (On-Time vs. Late) | 4.29 vs. 2.27 |

**The single biggest actionable finding:** late deliveries are associated with a review score more than 2 points lower than on-time deliveries (2.27 vs. 4.29 out of 5), making delivery reliability the clearest lever for improving customer satisfaction marketplace-wide.

## Dataset

[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle) — real, anonymized commercial orders from September 2016 to October 2018, covering ~100K orders across customers, sellers, products, payments, and reviews.

## Data Model

```
customers (1) ──< orders (1) ──< order_items >── (many:1) products >── (many:1) category_translation
                     │                │
                     │                └──< (many:1) sellers
                     │
                     ├──< order_payments
                     └──< order_reviews
```

`customer_id` is a per-order key; `customer_unique_id` identifies the actual person across orders and is used for all customer-level (RFM, retention) analysis.

## Tools & Technologies

- **Python:** NumPy, Pandas, Matplotlib, Seaborn — data cleaning, transformation, EDA, RFM segmentation, cohort analysis
- **SQL:** SQLite — 20 business questions using beginner-friendly SQL (no CTEs, no window functions)
- **Tableau:** three dashboards (Executive Overview, Customer Analytics, Product & Operations)
- **Reporting:** a 23-page PDF business report built from the actual calculated results

## Repository Structure

```
ecommerce-data-analytics/
│
├── data/
│   ├── raw/                     # original Olist CSVs
│   └── processed/                # cleaned tables, master order-level fact table, RFM/cohort/etc. outputs
│
├── notebooks/
│   └── ecommerce_analysis.ipynb  # full Python EDA notebook
│
├── sql/
│   └── ecommerce_analysis.sql    # 20 documented business questions in SQL
│
├── dashboard_images/
│   ├── Executive.png
│   ├── Customer Analytics.png
│   └── Operations.png
│
├── charts/                       # 12 individual EDA charts (PNG)
│
├── report/
│   └── ecommerce_analytics_report.pdf
│
├── README.md
```

## Data Cleaning Summary

- Converted all order/review date columns to datetime
- Filled 610 missing product categories with `'unknown'` rather than dropping rows
- Merged English category translations, falling back to the Portuguese name where no translation existed
- Restricted revenue/delivery/review analysis to `order_status == 'delivered'` orders (96,478 of 99,441, ~97%) since these represent complete, realized transactions
- De-duplicated review records to one review per order (kept most recent)

Full documentation of every decision is in the notebook (Section 5) and the PDF report.

## Exploratory Analysis Highlights

- Monthly revenue trend (peaked November 2017, Black Friday seasonality)
- Revenue and order-volume concentration by product category and state
- Order value and delivery-time distributions
- Review score distribution and its relationship to delivery status

See `charts/` for all 12 individual visualizations, each tied to a specific business question.

## Customer Segmentation (RFM)

Customers were segmented using Recency, Frequency, and Monetary value with simple, explainable quantile/rule-based scoring (no machine learning). Because ~97% of customers have Frequency = 1, Frequency was scored with a straightforward rule (1 order → 1, 2 orders → 3, 3+ orders → 5) rather than quantiles, which would fail with so many tied values.

| Segment | % Customers | % Revenue |
|---|---|---|
| Big Spenders (New) | 15.5% | 28.3% |
| At Risk (High Value) | 14.7% | 27.4% |
| Potential Loyalists | 20.0% | 19.0% |
| Needs Attention | 15.8% | 10.4% |
| Lost / Hibernating | 16.4% | 5.5% |
| New / Low-Value | 15.4% | 5.1% |
| Champions | 1.1% | 2.4% |
| At Risk (Was Frequent) | 1.1% | 1.9% |

## Cohort / Retention Analysis — and Its Limitation

A full acquisition-cohort retention heatmap was built (see notebook and PDF report), but the result revealed an important limitation stated explicitly rather than glossed over: **fewer than 2% of customers make any repeat purchase at all**, so month-over-month retention is consistently under 1% for nearly every cohort. This is a genuine finding about Olist's business model — it behaves like a one-time-purchase marketplace, not a subscription/habitual-repurchase business — and RFM segmentation (not cohort retention) is used as the primary customer-value framework as a result.

## SQL Analysis
The sql analysis consist of 20 fully structured queries

## Tableau Dashboards

1. **Executive Overview** — KPI cards, monthly revenue trend, category/state revenue breakdown
2. **Customer Analytics** — RFM segment revenue/customer share, customer spend distribution, retention cohort heatmap
3. **Product & Operations Analytics** — late delivery rate by state, lowest-rated categories, seller concentration (Pareto), review score distribution


## Key Findings

See the [full PDF report](report/ecommerce_analytics_report.pdf) for all 10 key insights with evidence and business implications. Highlights:

1. Revenue is concentrated: top 10 of 74 categories drive 62.4% of revenue.
2. Only 3.0% of customers are repeat purchasers — this is fundamentally a new-customer-acquisition business.
3. Late delivery is strongly associated with lower reviews (2.27 vs. 4.29 average score).
4. Delivery performance varies sharply by region (AP/AM/AL/PA all 23+ days vs. 12.09-day average).
5. The top 10% of sellers generate 67.1% of marketplace revenue.

## Business Recommendations

1. Launch a targeted win-back campaign for high-value RFM segments (30.2% of customers, 55.7% of revenue)
2. Prioritize a delivery-reliability initiative in the worst-performing states
3. Open a direct seller/quality review for Office Furniture (lowest-rated high-volume category)
4. Build a dedicated account-management track for top-decile sellers
5. Reframe retention strategy around acquisition and first-purchase experience, not loyalty programs
6. Set more conservative estimated-delivery dates in slow-performing regions
7. Investigate the 1-star review segment specifically, not just the average score

Full detail for each recommendation (what, why, supporting analysis, expected benefit) is in the PDF report.

## Project Limitations

- Dataset covers Sep 2016 - Oct 2018 only; findings may not reflect current conditions
- No product cost/margin data exists — all figures are **revenue**, never **profit**
- Low repeat-purchase rate limits the reliability of traditional cohort retention analysis
- The delivery-satisfaction relationship is an association, not proven causation
- `customer_unique_id` may undercount some repeat customers if contact details changed across orders
- Findings reflect a multi-seller marketplace and may not generalize to a single-brand retailer

## Future Improvements

- Incorporate product cost data (if available) to move from revenue to true profitability analysis
- Extend the dataset with more recent order history to validate whether findings still hold
- A/B test the delivery-estimate and win-back-campaign recommendations directly rather than relying on observational analysis alone

## 📗 Excel Data Cleaning

After completing the main analysis using Python, SQL, and Tableau, I additionally cleaned and prepared the dataset using **Microsoft Excel** to demonstrate a practical spreadsheet-based data-cleaning workflow.

The Excel workflow included:

* **Power Query** for data import, transformation, and cleaning
* **XLOOKUP / VLOOKUP** for data enrichment across related datasets
* **SUMIFS / COUNTIFS** for aggregation and analysis
* **IF and date formulas** for calculated fields and delivery metrics
* Handling missing values and duplicates


This Excel workflow was added **later as an additional data-cleaning and business-analysis approach**, while the original project analysis was performed using Python, SQL, and Tableau.

**Link of cleaned dataset using excel**-https://www.kaggle.com/datasets/yashchaudhary000/cleaned-data-using-excel
