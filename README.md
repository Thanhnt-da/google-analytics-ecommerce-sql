# Google Analytics eCommerce — SQL Analysis

Exploratory analysis of the **Google Analytics Sample** eCommerce dataset using **BigQuery Standard SQL**. The project answers ten business questions covering traffic, engagement, conversion, revenue, the purchase funnel, and cross-sell behaviour for the Google Merchandise Store (2017 data).

## Dataset

- **Source:** `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
- Publicly available GA360 export of the Google Merchandise Store.
- Nested/repeated fields (`hits`, `hits.product`) are flattened with `UNNEST`.

## How to run

1. Open the [BigQuery console](https://console.cloud.google.com/bigquery).
2. The dataset is public — no setup needed beyond a Google Cloud project.
3. Copy any query from [`queries.sql`](./queries.sql) and run it.

## Questions answered & key findings

| # | Question | Key finding |
|---|----------|-------------|
| 1 | Total visits, pageviews, transactions for Jan–Mar 2017 | Activity dipped in February then rebounded; March was strongest with 993 transactions vs 713 in January. |
| 2 | Bounce rate per traffic source, July 2017 | Direct traffic had the lowest bounce rate (~43%) of the major sources, while YouTube was the highest (~67%) — direct visitors are far more engaged. |
| 3 | Revenue by traffic source, by week and month, June 2017 | Direct traffic drove the overwhelming majority of June revenue (~$97k for the month vs ~$19k from google). |
| 4 | Conversion rate by traffic source, 2017 | `dfa` (2.64%) and direct (2.48%) converted roughly **2.7× better** than google (0.92%), even though google brought far more visits. |
| 5 | Avg pageviews: purchasers vs non-purchasers, Jun–Jul 2017 | Non-purchasers actually viewed **more** pages (~317–334) than purchasers (~94–124) — high browsing does not equal high buying intent. |
| 6 | Avg transactions per purchasing user, July 2017 | Customers who bought averaged ~4.16 transactions each. |
| 7 | Revenue contribution by device, 2017 | Desktop dominated at **96.4%** of revenue; mobile 3.2%, tablet 0.4%. |
| 8 | Cross-sell for buyers of "YouTube Men's Vintage Henley", July 2017 | Top co-purchased item was Google Sunglasses (20 units), followed by Google Women's Vintage Hero Tee. |
| 9 | View → add-to-cart → purchase funnel, Jan–Mar 2017 | Add-to-cart rate rose from ~28% to ~37% and purchase rate from ~8% to ~13% over the quarter — funnel efficiency improved. |
| 10 | Weekly revenue + cumulative revenue, May–Jul 2017 | Steady weekly revenue accumulating to ~$210k+ by week 24, useful for trend tracking. |

## Key takeaways

- **Quality beats volume in acquisition.** Google sends the most traffic but converts worst; direct and `dfa` are the efficient channels.
- **Desktop is the revenue engine** — mobile is heavily under-monetised relative to its likely traffic share, a clear optimisation target.
- **The funnel improved quarter-on-quarter**, suggesting product or UX changes in early 2017 were working.

## Skills demonstrated

Aggregation & filtering · `UNNEST` of nested/repeated fields · CTEs · `UNION ALL` · window functions (running totals, share-of-total) · funnel/cohort logic · subqueries for cross-sell · date parsing and wildcard table suffixes.

## Files

- `README.md` — this overview and findings
- `queries.sql` — all ten queries, runnable
- `report.pdf` — formatted report with result screenshots *(optional)*
