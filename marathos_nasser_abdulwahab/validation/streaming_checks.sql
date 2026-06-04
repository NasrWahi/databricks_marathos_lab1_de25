-- From SQL Editor

-- Total rows in bronze
SELECT COUNT(*) AS total_rader FROM marathos.bronze.raw_marathon;
-- Before LLM-data: 7 461 195
-- After: 7 461 220 (+25)

-- Confirming the 'LLM-rader' specifically (25 rows)
SELECT COUNT(*) AS llm_rader
FROM marathos.bronze.raw_marathon
WHERE CAST(`Athlete ID` AS BIGINT) >= 9000001;

-- History
DESCRIBE HISTORY marathos.bronze.raw_marathon;

-- This time with silver
-- Cleaner and more readable
-- Check for the LLM-events
SELECT event_name, event_type, COUNT(*) AS n
FROM marathos.silver.marathon_obt
WHERE event_name LIKE 'Marathos%'
GROUP BY event_name, event_type
ORDER BY event_name;