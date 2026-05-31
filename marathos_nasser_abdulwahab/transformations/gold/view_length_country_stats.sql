-- Gold view: per-country statistics for length-based (in this case: time) events

USE CATALOG marathos;
USE SCHEMA gold;

CREATE OR REFRESH MATERIALIZED VIEW marathos.gold.view_length_country_stats
  COMMENT "Per-country statistics for length-based (time) events" AS
SELECT
  a.athlete_country,
  COUNT(*)                               AS n_finishes,
  COUNT(DISTINCT a.athlete_id)           AS n_athletes,
  ROUND(AVG(f.performance_km), 2)        AS avg_distance_km,
  MAX(f.performance_km)                  AS best_distance_km,
  ROUND(AVG(f.recomputed_speed_kmh), 2)  AS avg_speed_kmh,
  ROUND(AVG(f.age_at_event), 1)          AS avg_age
FROM
  fct_results f
  LEFT JOIN dim_event   e ON f.event_id   = e.event_id
  LEFT JOIN dim_athlete a ON f.athlete_id = a.athlete_id
WHERE
  e.event_type = 'length'
GROUP BY
  a.athlete_country
ORDER BY
  n_finishes DESC;