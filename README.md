# Product Analytics: Customer Purchase Behavior Analysis Based on Dynamic Daily Duration Insights

## Overview
The project aims to understand how much time it takes for users to make a purchase on a merchandise store's website, from their first arrival until their first purchase on the same day. The project focuses on analyzing the dynamic daily purchase duration to derive actionable insights into user behavior. 

## Project Structure
The dynamic daily duration analysis was conducted by following these steps:
+ Extract and Calculate:
  * Queried session data to get timestamps for first arrival and first purchase.
  * Calculated purchase durations in minutes for each session.
+ Aggregate and Analyze:
  * Aggregated data to compute daily median purchase durations.
  * Conducted device-specific analysis to compare user behavior across desktop, mobile, and tablet.
+ Distribution and Visualization:
  * Analyzed distribution of session durations across different time ranges.
  * Created visualizations to represent daily median durations, purchase volume vs. session duration, and device-specific behaviors.
+ Insights and Recommendations:
  * Derived actionable insights to improve user experience.
  * Provided device-specific recommendations for optimizing purchase processes.

## Tools used
Big Query, Google Spreadsheets & Google Slides

## Data Source
A single table <kbd> data_analytics.raw_events </kbd> containing information about users’ activity on a merchandise store's webpage from Nov 1, 2020 to Jan 31, 2021. The dataset used includes user session data with timestamps for events such as <kbd>session_start</kbd> and <kbd>purchase</kbd> along with <kbd>user_pseudo_id</kbd> and <kbd>category</kbd> (type of device) .


## Data Processing
Full Code in file : ![ProductAnalytics.sql](https://github.com/ammu993/Product-Analytics-Customer-Behavior/blob/1bf90dc2c2624734603cdb209126acb9d6d1746f/ProductAnalytics.sql)

SQL code snippet  identifies the start of each session and the corresponding purchase event, ensuring both events occur on the same day and the purchase happens after the session start. The query also allows for device-specific analysis by including a device category
```sql
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
    --For device split in purchase duration analysis
    --category
  FROM
    data_analytics.raw_events AS events
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
```
CTE that calculates daily metrics for purchase duration, including the number of purchases, the average purchase duration, and the median purchase duration in minutes
```sql
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
    session_date
```
## [Analysis and Insights](https://github.com/user-attachments/files/16495020/CUSTOMER.PURCHASE.BEHAVIOR.ANALYSIS.pdf)

Following are the analyses performed and key insights gained:
+ Daily Median Purchase Duration: Identified significant fluctuations with peaks around key shopping events.
+ Purchase Volume vs. Session Duration: Found correlation between higher purchase volumes and longer session durations.
+ Distribution of Purchase Durations: Discovered that most sessions are under 30 minutes, with some notable outliers.
+ Device-Specific Analysis: Noted differences in user behavior across desktop, mobile, and tablet.

## Visualizations
![Daily median purchase duration over time](https://github.com/user-attachments/assets/07537723-1444-400e-87da-13ccb550d78d)

![Daily Purchase Volume vs. Average Session Duration](https://github.com/user-attachments/assets/e97d868e-73f6-4ccd-b0e1-a85f1fa7bade)

![Daily purchase duration dynamic by device category](https://github.com/user-attachments/assets/c196fb2f-fb88-4011-a555-29eb6fcbc493)

![Distribution of Purchase Durations by Category](https://github.com/user-attachments/assets/fd94392a-f99c-4c7a-8b53-2bd4afd7d257)


## Limitations and Drawbacks
+ Analysis focused solely on purchase duration.
+ Exclusion of sessions that began around midnight and continued with purchase early next day.

