-- Gold: dim_athlete

CREATE OR REFRESH MATERIALIZED VIEW marathos.gold.dim_athlete
  COMMENT "Athlete dimension - gold layer" AS
SELECT
  -- Reminder: MAX fallback via COALESCE so an attribute is never null in dashboard
  athlete_id,
  COALESCE(MAX_BY(athlete_gender, event_start_date), MAX(athlete_gender))               AS athlete_gender,
  COALESCE(MAX_BY(athlete_country, event_start_date), MAX(athlete_country))             AS athlete_country,
  COALESCE(MAX_BY(athlete_age_category, event_start_date), MAX(athlete_age_category))   AS athlete_age_category,
  COALESCE(MAX_BY(athlete_club, event_start_date), MAX(athlete_club))                   AS athlete_club,
  COALESCE(MAX_BY(athlete_year_of_birth, event_start_date), MAX(athlete_year_of_birth)) AS athlete_year_of_birth
FROM
  marathos.silver.marathon_obt
GROUP BY
  athlete_id
ORDER BY
  athlete_id;