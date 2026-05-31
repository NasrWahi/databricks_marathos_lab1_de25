-- Gold view: per-country statistics for distance-based events (km/mi)

-- Fitting question for Dashboard: which countries dominate distance ultra-marathons?

USE CATALOG marathos;
USE SCHEMA gold;

CREATE OR REFRESH MATERIALIZED VIEW marathos.gold.view_distance_country_stats
  COMMENT "Per-country statistics for distance-based events" AS
SELECT
  a.athlete_country,
  COUNT(*)                                       AS n_finishes,
  COUNT(DISTINCT a.athlete_id)                   AS n_athletes,
  ROUND(AVG(f.recomputed_speed_kmh), 2)          AS avg_speed_kmh,
  ROUND(AVG(f.performance_seconds) / 3600.0, 2)  AS avg_time_hours,
  ROUND(AVG(f.age_at_event), 1)                  AS avg_age,
  MIN(f.performance_seconds)                     AS best_time_seconds
FROM
  fct_results f
  LEFT JOIN dim_event   e ON f.event_id   = e.event_id
  LEFT JOIN dim_athlete a ON f.athlete_id = a.athlete_id
WHERE
  e.event_type = 'distance'
GROUP BY
  a.athlete_country
ORDER BY
  n_finishes DESC;