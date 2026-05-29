-- Gold: dim_event

CREATE OR REFRESH MATERIALIZED VIEW marathos.gold.dim_event
    COMMENT "Event dimension - gold layer" AS
WITH ranked_events AS (
    SELECT
      event_name,
      DENSE_RANK() OVER (ORDER BY event_name) AS event_id
    FROM (SELECT DISTINCT event_name FROM marathos.silver.marathon_obt)
)