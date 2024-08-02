WITH
  purchase_sessions AS(
  SELECT
    user_pseudo_id AS users,
    PARSE_DATE('%Y%m%d', event_date) AS session_date,
    MIN(CASE
        WHEN event_name='session_start' THEN TIMESTAMP_MICROS(event_timestamp)
    END
      ) AS session_begin,
    MIN(CASE
        WHEN event_name='purchase' THEN TIMESTAMP_MICROS(event_timestamp)
    END
      ) AS purchase_time,
    --For device split in purchase session duration analysis
    --category
  FROM
    tc-da-1.turing_data_analytics.raw_events AS events
  WHERE
    event_name IN ('session_start',
      'purchase')
  GROUP BY
    users,
    session_date 
    --category
  HAVING
  -- Ensure that there is at least one 'purchase' event in the session
    MIN(CASE WHEN event_name = 'purchase' THEN event_timestamp END ) IS NOT NULL 
  -- Ensure that there is at least one 'session_start' event in the session
    AND MIN(CASE WHEN event_name = 'session_start' THEN event_timestamp END ) IS NOT NULL
  -- Ensure that the 'session_start' and 'purchase' events occurred on the same day
    AND DATE(TIMESTAMP_MICROS(MIN(CASE WHEN event_name = 'session_start' THEN event_timestamp END ))) = DATE(TIMESTAMP_MICROS(MIN(CASE WHEN event_name = 'purchase' THEN event_timestamp END)))
  -- Ensure that the 'purchase' event occurred after the 'session_start' event
    AND MIN(CASE WHEN event_name = 'purchase' THEN event_timestamp END ) > MIN(CASE WHEN event_name = 'session_start' THEN event_timestamp END) 
    ),
  cust_purchase_duration AS(
  SELECT
    users,
    session_date,
    TIMESTAMP_DIFF(purchase_time, session_begin, SECOND) AS purchase_duration_seconds,
    TIMESTAMP_DIFF(purchase_time, session_begin, MINUTE) AS purchase_duration_minutes,
    --category
  FROM
    purchase_sessions ),
  daily_duration AS (
  SELECT
    session_date,
    COUNT(cust_purchase_duration.session_date) AS num_purchases,
    ROUND(AVG(cust_purchase_duration.purchase_duration_minutes)) AS avg_purchase_min,
    APPROX_QUANTILES(cust_purchase_duration.purchase_duration_minutes, 4)[
  OFFSET
    (2)] AS median_purchase_duration_min,
  FROM
    cust_purchase_duration
  GROUP BY
    session_date )
SELECT
  *
FROM
    daily_duration