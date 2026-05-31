-- Gold view: top performers per distance-based event (km/mi)

-- Joins fact -> dimensions and ranks athletes by finishing time.

USE CATALOG marathos;
USE SCHEMA gold;

CREATE OR REFRESH MATERIALIZED VIEW marathos.gold.view_distance_top_performers
  COMMENT "Top performers per distance-based event (km/mi races)" AS
SELECT
  e.event_name,
  e.event_distance_value,
  e.event_distance_unit,
  a.athlete_country,
  a.athlete_gender,
  f.age_at_event,
  f.performance_seconds,
  -- Format seconds back to HH:MM:SS for readability
  CONCAT(
    LPAD(CAST(f.performance_seconds / 3600 AS INT), 2, '0'), ':',
    LPAD(CAST((f.performance_seconds % 3600) / 60 AS INT), 2, '0'), ':',
    LPAD(CAST(f.performance_seconds % 60 AS INT), 2, '0')
  )                                     AS performance_time,
  f.recomputed_speed_kmh,
  RANK() OVER (
    PARTITION BY e.event_id
    ORDER BY f.performance_seconds ASC
  )                                     AS rank_in_event
FROM
  fct_results f
  LEFT JOIN dim_event   e ON f.event_id   = e.event_id
  LEFT JOIN dim_athlete a ON f.athlete_id = a.athlete_id
WHERE
  e.event_type = 'distance'
  AND f.performance_seconds IS NOT NULL;