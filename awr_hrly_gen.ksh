### creating the awr report ###

ORACLE_SID=$1
export ORACLE_SID

export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=`grep -i ^"$ORACLE_SID" /etc/oratab | awk -F: '{print $2}'`
export PATH=$PATH:${ORACLE_HOME}/bin


$ORACLE_HOME/bin/sqlplus "/ as sysdba" << EOF
declare
i_begin_snap_id number;
i_end_snap_id number;
i_db_id number;
i_inst_num number; 
begin

--select the db_id and the instance_number of the instance,
select DBID, INSTANCE_NUMBER into i_db_id, i_inst_num from dba_hist_database_instance where rownum=1;
select SNAP_ID into i_end_snap_id from dba_hist_snapshot where trunc(end_interval_time,'HH24') = trunc(sysdate,'HH24') order by SNAP_ID desc;

--set the begin snap_id of the previous hour as we are generation hourly awr reports
i_begin_snap_id := i_end_snap_id - 1;

--generate and write the report to a table
insert into system.temp_awr_output select output from table (SYS.DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_HTML(i_db_id, i_inst_num, i_begin_snap_id, i_end_snap_id));
commit; 

end;
/
EOF

### creating report name ###
report_name=/common/db_script/reports/awr_${ORACLE_SID}_`date | awk '{print $3"_"$2"_"$6"_"$4}'`.html
export report_name

### spooling previously created report to the file specified ###
$ORACLE_HOME/bin/sqlplus -s "/ as sysdba" << EOF
set linesize 1500;
set echo off;
set heading off;
set termout on;

spool $report_name;
select s_output from system.temp_awr_output;
truncate table system.temp_awr_output;
spool off;
EOF

### delete the older reports ###
ctl=`ls -l /common/db_scripts/reports | grep .html | wc -l`
if [ $ctl -gt 110 ]
then
ls -l /common/db_scripts/reports | grep .html | head -10 | awk '{print "/common/db_scripts/reports/"$9}' | xargs rm
#else
#echo "dont delete anything"
fi
