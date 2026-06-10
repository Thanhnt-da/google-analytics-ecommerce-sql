-- =====================================================================
-- Google Analytics eCommerce — SQL Analysis
-- Dataset: bigquery-public-data.google_analytics_sample.ga_sessions_2017*
-- Dialect: BigQuery Standard SQL
-- =====================================================================


-- ---------------------------------------------------------------------
-- Query 01: Total visits, pageviews and transactions for Jan, Feb, Mar 2017
-- ---------------------------------------------------------------------
SELECT
  LEFT(date, 6) AS month,
  SUM(totals.visits) AS visits,
  SUM(totals.pageviews) AS pageviews,
  SUM(totals.transactions) AS transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _table_suffix BETWEEN '0101' AND '0331'
GROUP BY month
ORDER BY month;


-- ---------------------------------------------------------------------
-- Query 02: Bounce rate per traffic source, July 2017
-- bounce_rate = total_bounces / total_visits
-- ---------------------------------------------------------------------
SELECT
  trafficSource.source AS source,
  SUM(totals.visits) AS total_visits,
  SUM(totals.bounces) AS total_no_of_bounces,
  ROUND(SUM(totals.bounces) / SUM(totals.visits) * 100.0, 3) AS bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _table_suffix BETWEEN '0701' AND '0731'
GROUP BY source
ORDER BY total_visits DESC;


-- ---------------------------------------------------------------------
-- Query 03: Revenue by traffic source, by week and by month, June 2017
-- ---------------------------------------------------------------------
WITH month_data AS (
  SELECT
    'Month' AS time_type,
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS time,
    trafficSource.source AS source,
    SUM(product.productRevenue) / 1000000 AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE _table_suffix BETWEEN '0601' AND '0630'
    AND product.productRevenue IS NOT NULL
  GROUP BY 1, 2, 3
),
week_data AS (
  SELECT
    'Week' AS time_type,
    FORMAT_DATE('%Y%W', PARSE_DATE('%Y%m%d', date)) AS time,
    trafficSource.source AS source,
    SUM(product.productRevenue) / 1000000 AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE _table_suffix BETWEEN '0601' AND '0630'
    AND product.productRevenue IS NOT NULL
  GROUP BY 1, 2, 3
)
SELECT * FROM month_data
UNION ALL
SELECT * FROM week_data
ORDER BY revenue DESC;


-- ---------------------------------------------------------------------
-- Query 04: Conversion rate by traffic source, 2017
-- (only sources with >= 50 transactions)
-- ---------------------------------------------------------------------
SELECT
  trafficSource.source AS source,
  SUM(totals.visits) AS total_visits,
  SUM(totals.transactions) AS total_transactions,
  ROUND(SUM(totals.transactions) / SUM(totals.visits) * 100.0, 3) AS conversion_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _table_suffix BETWEEN '0101' AND '1231'
GROUP BY source
HAVING total_transactions >= 50
ORDER BY conversion_rate DESC;


-- ---------------------------------------------------------------------
-- Query 05: Avg pageviews by purchaser type (purchasers vs non), Jun–Jul 2017
-- ---------------------------------------------------------------------
WITH purchaser_data AS (
  SELECT
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    SUM(totals.pageviews) / COUNT(DISTINCT fullVisitorId) AS avg_pageviews_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE _table_suffix BETWEEN '0601' AND '0731'
    AND totals.transactions >= 1
    AND product.productRevenue IS NOT NULL
  GROUP BY month
),
non_purchaser_data AS (
  SELECT
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    SUM(totals.pageviews) / COUNT(DISTINCT fullVisitorId) AS avg_pageviews_non_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE _table_suffix BETWEEN '0601' AND '0731'
    AND totals.transactions IS NULL
    AND product.productRevenue IS NULL
  GROUP BY month
)
SELECT
  pd.month,
  pd.avg_pageviews_purchase,
  npd.avg_pageviews_non_purchase
FROM purchaser_data pd
FULL JOIN non_purchaser_data npd USING (month)
ORDER BY month;


-- ---------------------------------------------------------------------
-- Query 06: Avg transactions per purchasing user, July 2017
-- ---------------------------------------------------------------------
SELECT
  FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
  SUM(totals.transactions) / COUNT(DISTINCT fullVisitorId) AS avg_total_transactions_per_user
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
  UNNEST(hits) AS hits,
  UNNEST(hits.product) AS product
WHERE _table_suffix BETWEEN '0701' AND '0731'
  AND totals.transactions >= 1
  AND product.productRevenue IS NOT NULL
GROUP BY month;


-- ---------------------------------------------------------------------
-- Query 07: Revenue contribution by device category, 2017
-- ---------------------------------------------------------------------
SELECT
  device.deviceCategory AS device,
  SUM(product.productRevenue) / 1000000 AS revenue,
  ROUND(
    SUM(product.productRevenue) / SUM(SUM(product.productRevenue)) OVER () * 100.0, 2
  ) AS ratio
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
  UNNEST(hits) AS hits,
  UNNEST(hits.product) AS product
WHERE _table_suffix BETWEEN '0101' AND '1231'
  AND totals.transactions IS NOT NULL
  AND product.productRevenue IS NOT NULL
GROUP BY device
ORDER BY ratio DESC;


-- ---------------------------------------------------------------------
-- Query 08: Other products purchased by buyers of
-- "YouTube Men's Vintage Henley", July 2017
-- ---------------------------------------------------------------------
SELECT
  product.v2ProductName AS other_purchased_products,
  SUM(product.productQuantity) AS quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
  UNNEST(hits) AS hits,
  UNNEST(hits.product) AS product
WHERE _table_suffix BETWEEN '0701' AND '0731'
  AND totals.transactions >= 1
  AND product.productRevenue IS NOT NULL
  AND product.v2ProductName != "YouTube Men's Vintage Henley"
  AND fullVisitorId IN (
    SELECT DISTINCT fullVisitorId
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
      UNNEST(hits) AS hits,
      UNNEST(hits.product) AS product
    WHERE _table_suffix BETWEEN '0701' AND '0731'
      AND totals.transactions >= 1
      AND product.productRevenue IS NOT NULL
      AND product.v2ProductName = "YouTube Men's Vintage Henley"
  )
GROUP BY other_purchased_products
ORDER BY quantity DESC;


-- ---------------------------------------------------------------------
-- Query 09: Funnel cohort (product view -> add-to-cart -> purchase), Jan–Mar 2017
-- add_to_cart_rate = add_to_cart / product_view
-- purchase_rate    = purchase / product_view
-- ---------------------------------------------------------------------
WITH product_data AS (
  SELECT
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    COUNT(CASE WHEN hits.eCommerceAction.action_type = '2'
               THEN product.v2ProductName END) AS num_product_view,
    COUNT(CASE WHEN hits.eCommerceAction.action_type = '3'
               THEN product.v2ProductName END) AS num_addtocart,
    COUNT(CASE WHEN hits.eCommerceAction.action_type = '6'
               AND product.productRevenue IS NOT NULL
               THEN product.v2ProductName END) AS num_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE _table_suffix BETWEEN '0101' AND '0331'
  GROUP BY month
)
SELECT
  *,
  ROUND(num_addtocart / num_product_view * 100, 2) AS add_to_cart_rate,
  ROUND(num_purchase / num_product_view * 100, 2) AS purchase_rate
FROM product_data
ORDER BY month;


-- ---------------------------------------------------------------------
-- Query 10: Weekly revenue and cumulative revenue, May–Jul 2017
-- ---------------------------------------------------------------------
WITH weekly_revenue AS (
  SELECT
    FORMAT_DATE('%Y-%W', PARSE_DATE('%Y%m%d', date)) AS week,
    ROUND(SUM(product.productRevenue) / 1000000, 2) AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE _table_suffix BETWEEN '0501' AND '0731'
    AND product.productRevenue IS NOT NULL
  GROUP BY week
)
SELECT
  week,
  revenue,
  ROUND(SUM(revenue) OVER (ORDER BY week), 2) AS cumulative_revenue
FROM weekly_revenue
ORDER BY week;
