-- Gold: mart_sweden (dashboard)

-- Join fact to dimensions, filter to Sweden
-- Swedish Marathos events + LLM-generated data
-- Events based in Sweden

CREATE OR REFRESH MATERIALIZED VIEW marathos.gold.mart_sweden
  COMMENT "Mart for Swedish ultra-marathon events - gold layer" AS
SELECT
  e.event_name,
  e.event_type,
  e.event_distance_value,
  e.event_distance_unit,
  a.athlete_id,
  a.athlete_gender,
  a.athlete_age_category,
  c.country_name,
  d.full_date,
  d.year,
  f.age_at_event,
  f.performance_seconds,
  f.performance_km,
  f.recomputed_speed_kmh
FROM
  marathos.gold.fct_results f
  LEFT JOIN marathos.gold.dim_event   e ON f.event_id   = e.event_id
  LEFT JOIN marathos.gold.dim_athlete a ON f.athlete_id = a.athlete_id
  LEFT JOIN marathos.gold.dim_date    d ON f.date_id    = d.date_id
  LEFT JOIN marathos.gold.dim_country c ON a.athlete_country = c.country_code
WHERE
  -- Changed specifically so it focuses on Sweden
  e.event_name LIKE '%(SWE)%';