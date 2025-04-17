SELECT MIN(SAMPLE_TIME) AS "Earliest Sample",
MAX(SAMPLE_TIME) as "Most Recent Sample"
FROM  v$active_session_history