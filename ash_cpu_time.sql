SELECT ash.sql_id,ash.sql_child_number,s.sql_text,
ash.sql_exec_start,ash.sql_exec_id, TO_CHAR(MIN(ash.sample_time),'hh24:mi:ss') AS min_sample_time, TO_CHAR(MAX(ash.sample_time),'hh24:mi:ss') AS max_sample_time
FROM   v$active_session_history ash,  v$sql s
WHERE  ash.sql_id           = s.sql_id (+)
AND    ash.sql_child_number = s.child_number (+)
GROUP  BY ash.sql_id,
ash.sql_child_number, 
s.sql_text,
ash.sql_exec_start,
ash.sql_exec_id
ORDER BY MIN(ash.sample_time);