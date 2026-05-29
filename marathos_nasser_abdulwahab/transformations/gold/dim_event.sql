-- Gold: dim_event

CREATE OR REFRESH MATERIALIZED VIEW marathos.gold.dim_event
    COMMENT "Event dimension - gold layer" AS
WITH ranked_events AS (
    SELECT
      event_name,
      DENSE_RANK() OVER (ORDER BY event_name) AS event_id
    FROM (SELECT DISTINCT event_name FROM marathos.silver.marathon_obt)
)
SELECT
  r.event_id,
  r.event_name,
  MAX_BY(s.event_distance_value, s.event_start_date)      AS event_distance_value,
  MAX_BY(s.event_distance_unit, s.event_start_date)       AS event_distance_unit,
  MAX_BY(s.event_type, s.event_start_date)                AS event_type,
  MAX_BY(s.event_number_of_finishers, s.event_start_date) AS event_number_of_finishers
FROM
  marathos.silver.marathon_obt s
  INNER JOIN ranked_events r ON s.event_name = r.event_name
GROUP BY
  r.event_id, r.event_name
ORDER BY
  r.event_id;