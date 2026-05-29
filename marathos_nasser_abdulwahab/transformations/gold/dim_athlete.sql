-- Gold: dim_athlete

CREATE OR REFRESH MATERIALIZED VIEW marathos.gold.dim_athlete
  COMMENT "Athlete dimension - gold layer" AS
SELECT
  athlete_id,
  MAX_BY(athlete_gender, event_start_date)        AS athlete_gender,
  MAX_BY(athlete_country, event_start_date)       AS athlete_country,
  MAX_BY(athlete_age_category, event_start_date)  AS athlete_age_category,
  MAX_BY(athlete_club, event_start_date)          AS athlete_club,
  MAX_BY(athlete_year_of_birth, event_start_date) AS athlete_year_of_birth
FROM
  marathos.silver.marathon_obt
GROUP BY
  athlete_id
ORDER BY
  athlete_id;