select
   to_char(round(sub1.sample_time, 'MI'), 'YYYY-MM-DD HH24:MI') as sample_minute,
   round(avg(sub1.on_cpu),1) as cpu_avg,
   round(avg(sub1.waiting),1) as wait_avg,
   round(avg(sub1.active_sessions),1) as act_avg,
   round( (variance(sub1.active_sessions)/avg(sub1.active_sessions)),1) as act_var_mean
from
   (    select
        sample_id,
        sample_time,
        sum(decode(session_state, 'ON CPU', 1, 0))  as on_cpu,
        sum(decode(session_state, 'WAITING', 1, 0)) as waiting,
        count(*) as active_sessions
     from
        dba_hist_active_sess_history
     where
        sample_time > sysdate - (&minutes/1440)
     group by
        sample_id,
        sample_time
   ) sub1
group by
   round(sub1.sample_time, 'MI')
order by
   round(sub1.sample_time, 'MI')
;