CREATE TABLE skystep_data (
    master_id UUID PRIMARY KEY,
    order_channel VARCHAR(50),
    last_order_channel VARCHAR(50),
    first_order_date DATE,
    last_order_date DATE,
    last_order_date_online DATE,
    last_order_date_offline DATE,
    order_num_total_ever_online FLOAT,
    order_num_total_ever_offline FLOAT,
    customer_value_total_ever_offline FLOAT,
    customer_value_total_ever_online FLOAT,
    interested_in_categories_12 VARCHAR(255)
);

CREATE VIEW rfm_vw AS
SELECT 
    master_id,
    last_order_date,
    -- Combining Online + Offline behavior
    (order_num_total_ever_online + order_num_total_ever_offline) AS total_frequency,
    (customer_value_total_ever_online + customer_value_total_ever_offline) AS total_monetary
FROM skystep_data;

SELECT (MAX(last_order_date) + INTERVAL '2 days') as analysis_date FROM skystep_data;

CREATE OR REPLACE VIEW rfm_metrics_vw AS
SELECT 
    master_id,
    -- Calculated days from the above step as analysis_date' (June 1, 2021)
    ('2021-06-01'::DATE - last_order_date::DATE) AS recency,
    total_frequency AS frequency,
    total_monetary AS monetary
FROM rfm_vw;

CREATE OR REPLACE VIEW rfm_scores_vw AS
SELECT 
    *,
    -- Lower recency is better (Score 5)
    NTILE(5) OVER (ORDER BY recency ASC) AS r_score,
    -- Higher frequency is better (Score 5)
    NTILE(5) OVER (ORDER BY frequency DESC) AS f_score,
    -- Higher monetary is better (Score 5)
    NTILE(5) OVER (ORDER BY monetary DESC) AS m_score
FROM rfm_metrics_vw;

SELECT 
    master_id,
    (r_score::TEXT || f_score::TEXT) AS rf_score,
    CASE 
        WHEN (r_score = 5 AND f_score = 5) THEN 'Champions'
        WHEN (r_score >= 4 AND f_score >= 4) THEN 'Loyal Customers'
        WHEN (r_score <= 2 AND f_score >= 3) THEN 'At Risk'
        WHEN (r_score <= 2 AND f_score <= 2) THEN 'Hibernating'
        ELSE 'Potential Loyalist'
    END AS segment
FROM rfm_scores_vw;



