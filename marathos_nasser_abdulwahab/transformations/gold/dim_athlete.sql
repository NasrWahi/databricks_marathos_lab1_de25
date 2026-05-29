-- Gold: dim_athlete

CREATE OR REFRESH MATERIALIZED VIEW marathos.gold.dim_athlete
  COMMENT "Athlete dimension - gold layer" AS
SELECT
  athlete_id,