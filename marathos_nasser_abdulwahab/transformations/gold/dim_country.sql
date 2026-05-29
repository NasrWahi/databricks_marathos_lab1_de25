-- Gold: dim_country

CREATE OR REFRESH MATERIALIZED VIEW marathos.gold.dim_country
  COMMENT "Country dimension BONUS - gold layer" AS
WITH codes_in_data AS (
  SELECT DISTINCT athlete_country AS country_code
  FROM marathos.silver.marathon_obt
  WHERE athlete_country IS NOT NULL
)
SELECT
  d.country_code,
  COALESCE(c.country_name, d.country_code) AS country_name,
  COALESCE(c.continent, 'Unknown')         AS continent
FROM
  codes_in_data d
  LEFT JOIN marathos.silver.countries c ON d.country_code = c.country_code
ORDER BY
  d.country_code;