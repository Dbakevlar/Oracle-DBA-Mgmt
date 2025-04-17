REPHEADER PAGE LEFT '~~BEGIN-MAIN-METRICS~~'
REPFOOTER PAGE LEFT '~~END-MAIN-METRICS~~'
--Tyler Muth's ASH Mining, subsection of his full set of code

 select snap_id "snap",num_interval "dur_m", end_time "end",inst "inst",
  max(decode(metric_name,'Host CPU Utilization (%)',					average,null)) "os_cpu",
  max(decode(metric_name,'Host CPU Utilization (%)',					maxval,null)) "os_cpu_max",
  max(decode(metric_name,'Database Wait Time Ratio',                   round(average,1),null)) "db_wait_ratio",
max(decode(metric_name,'Database CPU Time Ratio',                   round(average,1),null)) "db_cpu_ratio",
max(decode(metric_name,'SQL Service Response Time',                   average,null)) "sql_res_t_cs",
max(decode(metric_name,'Executions Per Sec',                        average,null)) "exec_s",
max(decode(metric_name,'Logical Reads Per Sec',                     average,null)) "l_reads_s",
max(decode(metric_name,'User Commits Per Sec',                      average,null)) "commits_s",
max(decode(metric_name,'Physical Read Total Bytes Per Sec',         round((maxval)/1024/1024,1),null)) "read_mb_s_max"
  from(
  select  snap_id,num_interval,to_char(end_time,'YY/MM/DD HH24:MI') end_time,instance_number inst,metric_name,round(average,1) average,
  round(maxval,1) maxval
 from dba_hist_sysmetric_summary
where 
snap_id between &SNAP_ID_MIN and &SNAP_ID_MAX
 and metric_name in ('Host CPU Utilization (%)','Average Active Sessions','Executions Per Sec','Hard Parse Count Per Sec','Logical Reads Per Sec','Logons Per Sec',
 'Physical Read Total Bytes Per Sec','Physical Read Total IO Requests Per Sec','Physical Write Total Bytes Per Sec','Physical Write Total IO Requests Per Sec',
 'Redo Generated Per Sec','User Commits Per Sec','Current Logons Count','DB Block Gets Per Sec','DB Block Changes Per Sec',
 'Database Wait Time Ratio','Database CPU Time Ratio','SQL Service Response Time','Background Time Per Sec'))
 group by snap_id,num_interval, end_time,inst
 order by snap_id, end_time,inst;