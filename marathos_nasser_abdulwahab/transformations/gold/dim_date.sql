-- Gold: dim_date

CREATE OR REFRESH MATERIALIZED VIEW marathos.gold.dim_date
  COMMENT "Date dimension BONUS - gold layer" AS
SELECT DISTINCT
  DENSE_RANK() OVER (ORDER BY event_start_date)  AS date_id,
  event_start_date                               AS full_date,
  YEAR(event_start_date)                         AS year,
  MONTH(event_start_date)                        AS month,
  DAY(event_start_date)                          AS day,
  DATE_FORMAT(event_start_date, 'EEEE')          AS weekday,
  QUARTER(event_start_date)                      AS quarter
FROM
  marathos.silver.marathon_obt
WHERE
  event_start_date IS NOT NULL
ORDER BY
  date_id;