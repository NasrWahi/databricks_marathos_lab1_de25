-- Data quality and verification checks for the Marthos pipeline 
-- From SQL Editor, old and new

-- These were used to validate the pipeline outputs.
-- Confirming the streamed LLM data arrived.
-- Checking nulls, inspecting distributions etc.
-- Multiple pipeline refreshes for confirmations.


-- Streaming verification (LLM-generated marathon)

-- Confirm the streamed LLM events
-- 3 Marathos SWEDISH events (Stockholm 12, Goteborg 8, Malmo 5) = 25 rows
SELECT event_name, event_type, COUNT(*) AS n
FROM marathos.silver.marathon_obt
WHERE event_name LIKE 'Marathos%'
GROUP BY event_name, event_type
ORDER BY event_name;

-- Delta history showing each streaming -> the bronze table
DESCRIBE HISTORY marathos.bronze.raw_marathon;

-- Null handling (should return 0 after dim fixes)

-- Silver: athlete_gender is now coalesced to 'unknown', so no nulls remain
SELECT COUNT(*) AS null_gender_silver
FROM marathos.silver.marathon_obt
WHERE athlete_gender IS NULL;

-- Mart: event_type and gender through the dimensions
-- COALESCE(MAX_BY(...), MAX(...)) = nulls should not appear
SELECT COUNT(*) AS null_event_type_mart
FROM marathos.gold.mart_sweden
WHERE event_type IS NULL;

SELECT COUNT(*) AS null_gender_mart
FROM marathos.gold.mart_sweden
WHERE athlete_gender IS NULL;


-- Scoping verification (mart is Swedish events only)


-- Every event name should end in '(SWE)' - confirms the mart filter works
SELECT DISTINCT event_name
FROM marathos.gold.mart_sweden
ORDER BY event_name;


-- Distributions: sanity-checks, dashboard figures

-- Gender split for the dashboard donut/pie
-- Note: Following queries, were later updated in the dashboard's dataset
SELECT athlete_gender, COUNT(*) AS n
FROM marathos.gold.mart_sweden
GROUP BY athlete_gender
ORDER BY n DESC;

-- Top Swedish events by number of finishes.
SELECT event_name, COUNT(*) AS 
FROM marathos.gold.mart_sweden
GROUP BY event_name
ORDER BY n DESC;