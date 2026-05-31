-- Gold view: top performers per length-based event

-- The focus for these races performance is the distance covered, ranked by km descending.

USE CATALOG marathos;
USE SCHEMA gold;

CREATE OR REFRESH MATERIALIZED VIEW marathos.gold.view_length_top_performers
  COMMENT "Top performers per length-based event (h races)" AS
SELECT
  e.event_name,
  e.event_distance_value                AS event_duration_hours,
  a.athlete_country,
  a.athlete_gender,
  f.age_at_event,
  f.performance_km,
  f.recomputed_speed_kmh,
  RANK() OVER (
    PARTITION BY e.event_id
    ORDER BY f.performance_km DESC
  )                                     AS rank_in_event
FROM
  fct_results f
  LEFT JOIN dim_event   e ON f.event_id   = e.event_id
  LEFT JOIN dim_athlete a ON f.athlete_id = a.athlete_id
WHERE
  e.event_type = 'length'
  AND f.performance_km IS NOT NULL;