select * from (
select sql_id,  inst_id,
      sum(decode(vash.session_state,'ON CPU',1,0))  as "Number on CPU",
      sum(decode(vash.session_state,'WAITING',1,0)) as "Number Waiting on CPU"
from  gv$active_session_history vash
where sample_time > sysdate - 5 /( 60*24)
group by sql_id, inst_id
order by 3 desc
) where rownum < 11
/