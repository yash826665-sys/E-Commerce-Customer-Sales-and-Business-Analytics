/* ==========================================================================
   OLIST E-COMMERCE BUSINESS ANALYSIS
   Beginner-friendly SQL: SELECT, JOIN, WHERE, GROUP BY, HAVING, ORDER BY,
   CASE WHEN, aggregate functions, basic subqueries only.
   No CTEs, no window functions, no stored procedures.

   Tables used:
     customers(customer_id, customer_unique_id, customer_zip_code_prefix,
               customer_city, customer_state)
     orders(order_id, customer_id, order_status, order_purchase_timestamp,
            order_approved_at, order_delivered_carrier_date,
            order_delivered_customer_date, order_estimated_delivery_date)
     order_items(order_id, order_item_id, product_id, seller_id,
                 shipping_limit_date, price, freight_value)
     order_payments(order_id, payment_sequential, payment_type,
                    payment_installments, payment_value)
     order_reviews(review_id, order_id, review_score, review_comment_title,
                   review_comment_message, review_creation_date,
                   review_answer_timestamp)
     products(product_id, product_category_name, ...)
     sellers(seller_id, seller_zip_code_prefix, seller_city, seller_state)

   All revenue analysis is restricted to order_status = 'delivered' orders,
   since these are the only orders that represent completed, realized sales.
   ========================================================================== */


/* ==========================================================================
   SECTION 1: SALES ANALYSIS
   ========================================================================== */

-- Q1. Business Question: What is the company's total revenue from completed orders?
-- Revenue is defined as item price + freight (shipping) value, summed across
-- every item in every delivered order.
SELECT ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM order_items oi
INNER JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered';
-- Result: R$ 15,419,773.75
-- What it tells us: This is the realized revenue base the business can report
-- on and grow from.
-- Business implication: Establishes the top-line baseline for all further
-- growth targets and forecasts.


-- Q2. Business Question: How did monthly order volume and revenue change over time?
SELECT SUBSTR(o.order_purchase_timestamp, 1, 7) AS order_month,
       COUNT(DISTINCT o.order_id) AS total_orders,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS revenue
FROM orders o
INNER JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY order_month
ORDER BY order_month;
-- What it tells us: Revenue grew steadily through 2017 and peaked in
-- November 2017 (R$1.15M), consistent with Black Friday seasonality.
-- Business implication: The business should plan inventory, staffing, and
-- marketing spend around this seasonal peak.


-- Q3. Business Question: Which product categories generate the most revenue?
SELECT p.product_category_name,
       COUNT(DISTINCT oi.order_id) AS orders,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS revenue
FROM order_items oi
INNER JOIN orders o ON oi.order_id = o.order_id
INNER JOIN products p ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY revenue DESC
LIMIT 10;
-- What it tells us: beleza_saude (health & beauty), relogios_presentes
-- (watches & gifts) and cama_mesa_banho (bed/bath/table) are the top 3
-- revenue-generating categories.
-- Business implication: These categories should be prioritized for
-- inventory investment, supplier negotiation, and featured marketing.


-- Q4. Business Question: How does average order value differ by payment method?
SELECT op.payment_type,
       COUNT(DISTINCT op.order_id) AS num_orders,
       ROUND(AVG(op.payment_value), 2) AS avg_payment_value
FROM order_payments op
INNER JOIN orders o ON op.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY op.payment_type
ORDER BY num_orders DESC;
-- What it tells us: Credit card is by far the dominant payment method
-- (~74,300 orders) and also has the highest average order value (R$162.24).
-- Business implication: Credit card checkout experience and installment
-- options should be a top priority for conversion optimization.


-- Q5. Business Question: How do customers use installment payments?
SELECT payment_installments,
       COUNT(*) AS num_payments
FROM order_payments
WHERE payment_installments > 0
GROUP BY payment_installments
ORDER BY payment_installments
LIMIT 12;
-- What it tells us: Single-installment (upfront) payments are most common,
-- but a large share of customers use 2-6 installments.
-- Business implication: Flexible installment options are clearly valued and
-- should be preserved/promoted, especially for higher-value categories.


/* ==========================================================================
   SECTION 2: CUSTOMER ANALYSIS
   ========================================================================== */

-- Q6. Business Question: Which customers place the most repeat orders?
SELECT c.customer_unique_id,
       COUNT(DISTINCT o.order_id) AS num_orders
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
HAVING COUNT(DISTINCT o.order_id) > 1
ORDER BY num_orders DESC
LIMIT 10;
-- What it tells us: A very small number of customers place more than one
-- order; the top repeat customer placed 15 orders.
-- Business implication: These customers are extremely valuable, but repeat
-- purchasing overall is rare on this marketplace (see RFM/cohort analysis).


-- Q7. Business Question: Which states have the most customers?
SELECT c.customer_state,
       COUNT(DISTINCT c.customer_unique_id) AS num_customers
FROM customers c
GROUP BY c.customer_state
ORDER BY num_customers DESC
LIMIT 10;
-- What it tells us: Sao Paulo (SP) has by far the most customers (~40,300),
-- followed by Rio de Janeiro (RJ) and Minas Gerais (MG).
-- Business implication: SP is the core market; marketing and logistics
-- investment should reflect this concentration.


-- Q8. Business Question: Which states generate the most revenue?
SELECT c.customer_state,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS revenue
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY revenue DESC
LIMIT 10;
-- What it tells us: Revenue by state closely mirrors customer count by
-- state, with SP alone generating over R$5.7M (about 37% of all revenue).
-- Business implication: Any disruption to SP logistics/operations carries
-- outsized revenue risk; expansion in RJ/MG has the next-largest headroom.


-- Q9. Business Question: Who are the company's highest-spending customers?
SELECT c.customer_unique_id,
       c.customer_state,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS total_spent
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id, c.customer_state
ORDER BY total_spent DESC
LIMIT 10;
-- What it tells us: The single highest-spending customer contributed
-- R$13,664.08 in one large order.
-- Business implication: High-value single-purchase customers should be
-- flagged for personalized re-engagement (see RFM "Big Spenders" segment).


/* ==========================================================================
   SECTION 3: PRODUCT ANALYSIS
   ========================================================================== */

-- Q10. Business Question: Which categories sell the highest volume of items?
SELECT p.product_category_name,
       COUNT(oi.order_item_id) AS items_sold
FROM order_items oi
INNER JOIN orders o ON oi.order_id = o.order_id
INNER JOIN products p ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY items_sold DESC
LIMIT 10;
-- What it tells us: cama_mesa_banho (bed/bath/table) sells the highest
-- volume of individual items (~10,950), even though beleza_saude generates
-- more total revenue.
-- Business implication: High-volume, lower-margin categories like this one
-- depend on efficient fulfillment to stay profitable at scale.


-- Q11. Business Question: Which categories have the highest average item price?
SELECT p.product_category_name,
       ROUND(AVG(oi.price), 2) AS avg_item_price,
       COUNT(*) AS items_sold
FROM order_items oi
INNER JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name
HAVING COUNT(*) >= 30
ORDER BY avg_item_price DESC
LIMIT 10;
-- What it tells us: pcs (computers), home appliances, and large kitchen
-- items carry the highest average price per item.
-- Business implication: These premium/high-ticket categories deserve extra
-- care around delivery quality, since a bad experience here is costlier.


-- Q12. Business Question: Which categories have the worst customer satisfaction?
SELECT p.product_category_name,
       ROUND(AVG(r.review_score), 2) AS avg_review_score,
       COUNT(DISTINCT oi.order_id) AS num_orders
FROM order_items oi
INNER JOIN orders o ON oi.order_id = o.order_id
INNER JOIN products p ON oi.product_id = p.product_id
INNER JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
HAVING COUNT(DISTINCT oi.order_id) >= 100
ORDER BY avg_review_score ASC
LIMIT 10;
-- What it tells us: moveis_escritorio (office furniture) has the lowest
-- average review score (3.52) among categories with meaningful order volume.
-- Business implication: Office furniture likely has quality, damage-in-transit,
-- or delivery issues worth investigating directly with sellers.


-- Q13. Business Question: Which high-volume categories also have below-average
-- satisfaction (a red flag combination)?
SELECT p.product_category_name,
       COUNT(DISTINCT oi.order_id) AS num_orders,
       ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM order_items oi
INNER JOIN orders o ON oi.order_id = o.order_id
INNER JOIN products p ON oi.product_id = p.product_id
INNER JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
HAVING COUNT(DISTINCT oi.order_id) >= 100 AND AVG(r.review_score) < 4.0
ORDER BY num_orders DESC;
-- What it tells us: cama_mesa_banho, informatica_acessorios, and
-- moveis_decoracao are all high-volume categories sitting just below a 4.0
-- average score.
-- Business implication: Because of their volume, even a small satisfaction
-- improvement here would affect a large number of customers.


/* ==========================================================================
   SECTION 4: SELLER ANALYSIS
   ========================================================================== */

-- Q14. Business Question: Which sellers generate the most revenue?
SELECT s.seller_id,
       s.seller_state,
       COUNT(DISTINCT oi.order_id) AS num_orders,
       ROUND(SUM(oi.price + oi.freight_value), 2) AS revenue
FROM order_items oi
INNER JOIN orders o ON oi.order_id = o.order_id
INNER JOIN sellers s ON oi.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id, s.seller_state
ORDER BY revenue DESC
LIMIT 10;
-- What it tells us: The top seller generated roughly R$247,000 in revenue
-- from about 1,124 orders; nearly all top sellers are based in SP.
-- Business implication: These top sellers are strategic partners worth
-- retaining with preferential support or account management.


-- Q15. Business Question: How are sellers distributed geographically?
SELECT seller_state,
       COUNT(DISTINCT seller_id) AS num_sellers
FROM sellers
GROUP BY seller_state
ORDER BY num_sellers DESC
LIMIT 10;
-- What it tells us: The large majority of sellers (1,849 of 3,095) are
-- based in Sao Paulo state.
-- Business implication: Seller concentration in SP likely helps explain
-- shorter delivery times for SP customers versus more remote states.


-- Q16. Business Question: Which sellers (with meaningful order volume) have
-- the worst average review scores?
SELECT s.seller_id,
       COUNT(DISTINCT oi.order_id) AS num_orders,
       ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM order_items oi
INNER JOIN orders o ON oi.order_id = o.order_id
INNER JOIN sellers s ON oi.seller_id = s.seller_id
INNER JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id
HAVING COUNT(DISTINCT oi.order_id) >= 50
ORDER BY avg_review_score ASC
LIMIT 10;
-- What it tells us: A handful of sellers with 50+ orders have average
-- review scores below 3.1, well under the marketplace-wide 4.16 average.
-- Business implication: These sellers should be reviewed for quality or
-- fulfillment issues, since they are dragging down overall marketplace
-- reputation despite meaningful order volume.


/* ==========================================================================
   SECTION 5: DELIVERY & REVIEWS ANALYSIS
   ========================================================================== */

-- Q17. Business Question: Which states have the slowest average delivery time?
SELECT c.customer_state,
       ROUND(AVG(JULIANDAY(o.order_delivered_customer_date)
                 - JULIANDAY(o.order_purchase_timestamp)), 1) AS avg_delivery_days,
       COUNT(*) AS num_orders
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(*) >= 50
ORDER BY avg_delivery_days DESC
LIMIT 10;
-- What it tells us: Northern/northeastern states (AP, AM, AL, PA) have the
-- slowest average delivery times, all above 23 days, versus a ~12-day
-- marketplace-wide average.
-- Business implication: These regions are strong candidates for a regional
-- fulfillment hub or a shipping-partner review.


-- Q18. Business Question: What percentage of orders are delivered late?
SELECT
  COUNT(*) AS total_delivered_orders,
  SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date
           THEN 1 ELSE 0 END) AS late_orders,
  ROUND(100.0 * SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date
                         THEN 1 ELSE 0 END) / COUNT(*), 2) AS late_rate_pct
FROM orders
WHERE order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL;
-- Result: 8.11% of delivered orders arrived after the estimated delivery date.
-- Business implication: While most orders arrive on time, roughly 1 in 12
-- orders is late enough to likely disappoint the customer.


-- Q19. Business Question: Is late delivery associated with lower review scores?
SELECT
  CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
       THEN 'Late' ELSE 'On-Time' END AS delivery_status,
  ROUND(AVG(r.review_score), 2) AS avg_review_score,
  COUNT(*) AS num_orders
FROM orders o
INNER JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;
-- Result: On-time orders average a 4.29 review score; late orders average
-- only 2.57.
-- IMPORTANT: This is a strong association, not proof of causation -- other
-- factors (e.g. product issues, communication) may also differ between the
-- two groups. Worded carefully: "Late deliveries are associated with
-- substantially lower review scores."
-- Business implication: Reducing late deliveries is very likely one of the
-- highest-leverage levers available for improving customer satisfaction.


-- Q20. Business Question: What is the overall distribution of review scores?
SELECT review_score,
       COUNT(*) AS num_reviews,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM order_reviews), 2) AS pct_of_total
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;
-- What it tells us: 57.8% of reviews are 5-star, but 11.5% are 1-star,
-- a meaningful unhappy minority.
-- Business implication: The 1-star segment (largely driven by late
-- deliveries, per Q19) is the clearest target for satisfaction improvement
-- initiatives.
