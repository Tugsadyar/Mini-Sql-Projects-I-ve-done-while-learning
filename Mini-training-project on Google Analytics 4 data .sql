-- How many sessions per user ? 
SELECT 
  event_date,
  user_pseudo_id,
  p.key,
  p.value.int_value,
  COUNT(distinct p.value.int_value) OVER (partition by user_pseudo_id)as sessions_per_user
FROM
`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`, UNNEST(event_params) p
WHERE event_name = "session_start"
GROUP By 1,2,3,4
ORDER BY sessions_per_user DESC ;

-- For some date, what is the most common landing page ? How many UNIQUE users land on it & how many sessions ? 
-- Which source & medium are they from ? 

SELECT 
  traffic_source.source || " / " || traffic_source.medium as Source_Medium ,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = "page_location") as landing_page,
  COUNT(*) as nmbr_of_sessions,
  count(distinct user_pseudo_id) as unique_users
FROM
`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`, UNNEST(event_params) p
WHERE event_name = "session_start"
GROUP BY 1,2
ORDER BY unique_users DESC
limit 10;

-- How many transactions from sessions that started from that landing page and source-medium ?
-- Last-click attribution model ? () using source-medium)
SELECT Source_Medium , count(*) as purchases, sum(revenue) as sales FROM( 
SELECT 
  user_pseudo_id,
  (SELECT value.int_value FROM UNNEST(event_params) WHERE key = "ga_session_id") as session_id,
  (SELECT COALESCE(value.int_value,value.float_value,value.double_value) FROM UNNEST(event_params) WHERE key = "value") as revenue,
 traffic_source.source || " / " || traffic_source.medium as Source_Medium ,
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE event_name = "purchase"
  AND _TABLE_SUFFIX BETWEEN "20210125" AND "20210131"
ORDER BY RAND()
)
GROUP BY 1
ORDER BY 2 DESC;


-- First-click attribution model ?  
-- (For users that have only 1 purchase)
with user_first_sessions as(
SELECT 
  user_pseudo_id,
  event_timestamp,
  ROW_NUMBER() OVER(partition by user_pseudo_id ORDER BY event_timestamp ASC) as user_session_rank,
  (SELECT value.int_value FROM UNNEST(event_params) WHERE key = "ga_session_id") as session_id,
  (SELECT COALESCE(value.int_value,value.float_value,value.double_value) FROM UNNEST(event_params) WHERE key = "value") as revenue,
 traffic_source.source || " / " || traffic_source.medium as Source_Medium ,
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE event_name = "session_start"
AND _TABLE_SUFFIX BETWEEN "20210125" AND "20210131"
ORDER BY 1,3
), user_revenue_summary as (
SELECT 
  user_pseudo_id,
  SUM((SELECT COALESCE(value.int_value,value.float_value,value.double_value) FROM UNNEST(event_params) WHERE key = "value")) as revenue,
  count(*) as purchases
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE event_name = "purchase"
AND _TABLE_SUFFIX BETWEEN "20210125" AND "20210131"
GROUP BY 1
ORDER BY 1
)
SELECT
  f.Source_Medium,
  r.revenue,
  r.purchases
FROM user_first_sessions f
  JOIN user_revenue_summary r ON f.user_pseudo_id = r.user_pseudo_id
WHERE f.user_session_rank = 1








