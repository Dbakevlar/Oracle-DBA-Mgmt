select * from (
select sql_id,  inst_id,
   sum(decode(vash.session_state,'ON CPU',1,0)) as  "ON CPU",
   sum(decode(vash.session_state,'WAITING',1,0))  as "WAITING FOR CPU",
   event , count(distinct(session_id||session_serial#)) as "SESSION COUNT"
from  gv$active_session_history vash
where sample_time > sysdate - 5 /( 60*24)
group by event ,inst_id, sql_id , event
order by 4 desc
) where rownum <11;