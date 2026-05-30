-- Gold: fct_results

-- One row per athlete-race-finish. 
-- Joins silver to dim_event and dim_date to attach IDs like event_id, date_id etc etc. 
-- Athlete_id, key in silver.
-- Materialized view, not streaming, dim_event uses dense_rank, streaming and dense_rank don't mix.

CREATE OR REFRESH MATERIALIZED VIEW marathos.gold.fct_results
  COMMENT "Race results fact table - gold layer" AS
SELECT
  ROW_NUMBER() OVER (ORDER BY s.athlete_id, e.event_id, d.date_id) AS result_id,
  e.event_id,
  s.athlete_id,
  d.date_id,
  s.performance_seconds,
  s.performance_km,
  s.recomputed_speed_kmh,
  s.age_at_event
FROM
  marathos.silver.marathon_obt s
  LEFT JOIN marathos.gold.dim_event e ON s.event_name = e.event_name
  LEFT JOIN marathos.gold.dim_date  d ON s.event_start_date = d.full_date;