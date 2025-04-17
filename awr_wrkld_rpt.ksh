#!/usr/bin/ksh
############################################################
## This shell script utilizes a SQL Report base by Karl Arao, Oracle ACE
## http://karlarao.wordpress.com
## Slight redesign and encased in shell script by Kellyn Pot'Vin to load to a repository database and store by dbname.
## Usage: ./awr_wrkld.ksh <ORACLE_SID> <REP_SID>  
## REP_SID=Repository DB, ORACLE_SID=DB report to be gathered from
############################################################

#----------------------------------------------------------------------------
# Verify that the ORACLE_SID has been specified on the UNIX command-line...
#----------------------------------------------------------------------------
if (( $# != 2 ))
then
    echo "usage: $0 ORACLE_SID REP_SID"
        exit 1
fi
#
#----------------------------------------------------------------------------
# Set up Oracle environment...
#----------------------------------------------------------------------------
. /home/oracle/.kprofile
export ORACLE_SID=$1
export REP_SID=$2

echo "Oracle SID: "${ORACLE_SID}
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=`grep -i ^"$ORACLE_SID" /etc/oratab | awk -F: '{print $2}'`
export PATH=$PATH:${ORACLE_HOME}/bin


export EXEC_DIR=/common/db_scripts/admin
export SQL_DIR=/common/db_scripts/sql
export LOG_DIR=/common/db_scripts/logs
export OUT_FL=${LOG_DIR}/awr_wrkld_${ORACLE_SID}.log

export USR_NM=dba_mgmnt
export pass=`grep "${USR_NM}" ${EXEC_DIR}/.p_fl | awk '{print $2}'`


sqlplus  << EOF > ${OUT_FL}
${USR_NM}/${pass}@${REP_SID}
set echo off verify off head off 
set pagesize 500000
set linesize 350

COLUMN blocksize NEW_VALUE _blocksize NOPRINT
select distinct block_size blocksize from v\$datafile@${ORACLE_SID};

COLUMN dbid NEW_VALUE _dbid NOPRINT
select dbid from v\$database@${ORACLE_SID};

COLUMN instancenumber NEW_VALUE _instancenumber NOPRINT
select instance_number instancenumber from v\$instance@${ORACLE_SID};

INSERT INTO DBA_MGMNT.AWR_WRKLD_RPT  
SELECT s0.snap_id snap_id,
  vd.name sid,
  TO_CHAR(s0.END_INTERVAL_TIME,'YY/MM/DD HH24:MI') timestamp,
  s0.instance_number instance,
  round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2) duration,
  s3t1.value AS cpu,
  (round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2)*60)*s3t1.value TM_Amount,
  (s5t1.value - s5t0.value) / 1000000 as db_time,
  (s6t1.value - s6t0.value) / 1000000 as db_cpu,
  (s7t1.value - s7t0.value) / 1000000 as bg_cpu,
  round(DECODE(s8t1.value,null,'null',(s8t1.value - s8t0.value) / 1000000),2) as rman,
  ((s5t1.value - s5t0.value) / 1000000)/60 /  round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2) aas,
  round(((s6t1.value - s6t0.value) / 1000000) + ((s7t1.value - s7t0.value) / 1000000),2) Total_Oracle,
  -- s1t1.value - s1t0.value AS OS_Busy,  -- this is osstat BUSY_TIME
  round(s2t1.value,2) AS load,
  (s1t1.value - s1t0.value)/100 AS Total_OS,
  s4t1.value/1024/1024 AS memory, 
   ((s15t1.value - s15t0.value)  / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
    ) as IO_Reads, 
   ((s16t1.value - s16t0.value)  / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
    ) as IO_Writes, 
   ((s13t1.value - s13t0.value)  / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
    ) as IO_Redo, 
   (((s11t1.value - s11t0.value)* &_blocksize)/1024/1024)  / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60) 
      as IO_R_mbs, 
   (((s12t1.value - s12t0.value)* &_blocksize)/1024/1024)  / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60) 
      as IO_W_mbs, 
   ((s14t1.value - s14t0.value)/1024/1024)  / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
     as redo_size_sec, 
     s9t0.value logons, 
   ((s10t1.value - s10t0.value)  / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
    ) as exs, 
  ((round(((s6t1.value - s6t0.value) / 1000000) + ((s7t1.value - s7t0.value) / 1000000),2)) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                                                              + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                                                              + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                                                              + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2)*60)*s3t1.value))*100 as oracpupct,
  ((round(DECODE(s8t1.value,null,'null',(s8t1.value - s8t0.value) / 1000000),2)) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                                                              + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                                                              + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                                                              + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2)*60)*s3t1.value))*100 as rmancpupct,
  (((s1t1.value - s1t0.value)/100) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                                                              + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                                                              + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                                                              + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2)*60)*s3t1.value))*100 as oscpupct,
  (((s17t1.value - s17t0.value)/100) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                                                              + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                                                              + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                                                              + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2)*60)*s3t1.value))*100 as oscpuusr,
  (((s18t1.value - s18t0.value)/100) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                                                              + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                                                              + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                                                              + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2)*60)*s3t1.value))*100 as oscpusys,
  (((s19t1.value - s19t0.value)/100) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                                                              + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                                                              + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                                                              + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2)*60)*s3t1.value))*100 as oscpuio
FROM dba_hist_snapshot@${ORACLE_SID} s0,
  v\$database@${ORACLE_SID} vd,
  dba_hist_snapshot@${ORACLE_SID} s1,
  dba_hist_osstat@${ORACLE_SID}  s1t0,         
  dba_hist_osstat@${ORACLE_SID} s1t1,
  dba_hist_osstat@${ORACLE_SID} s17t0,        
  dba_hist_osstat@${ORACLE_SID} s17t1,
  dba_hist_osstat@${ORACLE_SID} s18t0,        
  dba_hist_osstat@${ORACLE_SID} s18t1,
  dba_hist_osstat@${ORACLE_SID} s19t0,        
  dba_hist_osstat@${ORACLE_SID} s19t1,
  dba_hist_osstat@${ORACLE_SID} s2t1,         
  dba_hist_osstat@${ORACLE_SID} s3t1,         
  dba_hist_osstat@${ORACLE_SID} s4t1,          
  dba_hist_sys_time_model@${ORACLE_SID} s5t0,
  dba_hist_sys_time_model@${ORACLE_SID} s5t1,
  dba_hist_sys_time_model@${ORACLE_SID} s6t0,
  dba_hist_sys_time_model@${ORACLE_SID} s6t1,
  dba_hist_sys_time_model@${ORACLE_SID} s7t0,
  dba_hist_sys_time_model@${ORACLE_SID} s7t1,
  dba_hist_sys_time_model@${ORACLE_SID} s8t0,
  dba_hist_sys_time_model@${ORACLE_SID} s8t1,
  dba_hist_sysstat@${ORACLE_SID} s9t0,        
  dba_hist_sysstat@${ORACLE_SID} s9t1,        
  dba_hist_sysstat@${ORACLE_SID} s10t0,       
  dba_hist_sysstat@${ORACLE_SID} s10t1,
  dba_hist_sysstat@${ORACLE_SID} s11t0,       
  dba_hist_sysstat@${ORACLE_SID} s11t1,
  dba_hist_sysstat@${ORACLE_SID} s12t0,       
  dba_hist_sysstat@${ORACLE_SID} s12t1,
  dba_hist_sysstat@${ORACLE_SID} s13t0,       
  dba_hist_sysstat@${ORACLE_SID} s13t1,
  dba_hist_sysstat@${ORACLE_SID} s14t0,      
  dba_hist_sysstat@${ORACLE_SID} s14t1,
  dba_hist_sysstat@${ORACLE_SID} s15t0,       
  dba_hist_sysstat@${ORACLE_SID} s15t1,
  dba_hist_sysstat@${ORACLE_SID} s16t0,       
  dba_hist_sysstat@${ORACLE_SID} s16t1
WHERE s0.dbid            = &_dbid    
AND s1.dbid              = s0.dbid
AND vd.dbid		 = s0.dbid
AND s1t0.dbid            = s0.dbid
AND s1t1.dbid            = s0.dbid
AND s2t1.dbid            = s0.dbid
AND s3t1.dbid            = s0.dbid
AND s4t1.dbid            = s0.dbid
AND s5t0.dbid            = s0.dbid
AND s5t1.dbid            = s0.dbid
AND s6t0.dbid            = s0.dbid
AND s6t1.dbid            = s0.dbid
AND s7t0.dbid            = s0.dbid
AND s7t1.dbid            = s0.dbid
AND s8t0.dbid            = s0.dbid
AND s8t1.dbid            = s0.dbid
AND s9t0.dbid            = s0.dbid
AND s9t1.dbid            = s0.dbid
AND s10t0.dbid            = s0.dbid
AND s10t1.dbid            = s0.dbid
AND s11t0.dbid            = s0.dbid
AND s11t1.dbid            = s0.dbid
AND s12t0.dbid            = s0.dbid
AND s12t1.dbid            = s0.dbid
AND s13t0.dbid            = s0.dbid
AND s13t1.dbid            = s0.dbid
AND s14t0.dbid            = s0.dbid
AND s14t1.dbid            = s0.dbid
AND s15t0.dbid            = s0.dbid
AND s15t1.dbid            = s0.dbid
AND s16t0.dbid            = s0.dbid
AND s16t1.dbid            = s0.dbid
AND s17t0.dbid            = s0.dbid
AND s17t1.dbid            = s0.dbid
AND s18t0.dbid            = s0.dbid
AND s18t1.dbid            = s0.dbid
AND s19t0.dbid            = s0.dbid
AND s19t1.dbid            = s0.dbid
AND s0.instance_number   = &_instancenumber   
AND s1.instance_number   = s0.instance_number
AND s1t0.instance_number = s0.instance_number
AND s1t1.instance_number = s0.instance_number
AND s2t1.instance_number = s0.instance_number
AND s3t1.instance_number = s0.instance_number
AND s4t1.instance_number = s0.instance_number
AND s5t0.instance_number = s0.instance_number
AND s5t1.instance_number = s0.instance_number
AND s6t0.instance_number = s0.instance_number
AND s6t1.instance_number = s0.instance_number
AND s7t0.instance_number = s0.instance_number
AND s7t1.instance_number = s0.instance_number
AND s8t0.instance_number = s0.instance_number
AND s8t1.instance_number = s0.instance_number
AND s9t0.instance_number = s0.instance_number
AND s9t1.instance_number = s0.instance_number
AND s10t0.instance_number = s0.instance_number
AND s10t1.instance_number = s0.instance_number
AND s11t0.instance_number = s0.instance_number
AND s11t1.instance_number = s0.instance_number
AND s12t0.instance_number = s0.instance_number
AND s12t1.instance_number = s0.instance_number
AND s13t0.instance_number = s0.instance_number
AND s13t1.instance_number = s0.instance_number
AND s14t0.instance_number = s0.instance_number
AND s14t1.instance_number = s0.instance_number
AND s15t0.instance_number = s0.instance_number
AND s15t1.instance_number = s0.instance_number
AND s16t0.instance_number = s0.instance_number
AND s16t1.instance_number = s0.instance_number
AND s17t0.instance_number = s0.instance_number
AND s17t1.instance_number = s0.instance_number
AND s18t0.instance_number = s0.instance_number
AND s18t1.instance_number = s0.instance_number
AND s19t0.instance_number = s0.instance_number
AND s19t1.instance_number = s0.instance_number
AND s1.snap_id           = s0.snap_id + 1
AND s1t0.snap_id         = s0.snap_id
AND s1t1.snap_id         = s0.snap_id + 1
AND s2t1.snap_id         = s0.snap_id + 1
AND s3t1.snap_id         = s0.snap_id + 1
AND s4t1.snap_id         = s0.snap_id + 1
AND s5t0.snap_id         = s0.snap_id
AND s5t1.snap_id         = s0.snap_id + 1
AND s6t0.snap_id         = s0.snap_id
AND s6t1.snap_id         = s0.snap_id + 1
AND s7t0.snap_id         = s0.snap_id
AND s7t1.snap_id         = s0.snap_id + 1
AND s8t0.snap_id         = s0.snap_id
AND s8t1.snap_id         = s0.snap_id + 1
AND s9t0.snap_id         = s0.snap_id
AND s9t1.snap_id         = s0.snap_id + 1
AND s10t0.snap_id         = s0.snap_id
AND s10t1.snap_id         = s0.snap_id + 1
AND s11t0.snap_id         = s0.snap_id
AND s11t1.snap_id         = s0.snap_id + 1
AND s12t0.snap_id         = s0.snap_id
AND s12t1.snap_id         = s0.snap_id + 1
AND s13t0.snap_id         = s0.snap_id
AND s13t1.snap_id         = s0.snap_id + 1
AND s14t0.snap_id         = s0.snap_id
AND s14t1.snap_id         = s0.snap_id + 1
AND s15t0.snap_id         = s0.snap_id
AND s15t1.snap_id         = s0.snap_id + 1
AND s16t0.snap_id         = s0.snap_id
AND s16t1.snap_id         = s0.snap_id + 1
AND s17t0.snap_id         = s0.snap_id
AND s17t1.snap_id         = s0.snap_id + 1
AND s18t0.snap_id         = s0.snap_id
AND s18t1.snap_id         = s0.snap_id + 1
AND s19t0.snap_id         = s0.snap_id
AND s19t1.snap_id         = s0.snap_id + 1
AND s1t0.stat_name       = 'BUSY_TIME'
AND s1t1.stat_name       = s1t0.stat_name
AND s17t0.stat_name       = 'USER_TIME'
AND s17t1.stat_name       = s17t0.stat_name
AND s18t0.stat_name       = 'SYS_TIME'
AND s18t1.stat_name       = s18t0.stat_name
AND s19t0.stat_name       = 'IOWAIT_TIME'
AND s19t1.stat_name       = s19t0.stat_name
AND s2t1.stat_name       = 'LOAD'
AND s3t1.stat_name       = 'NUM_CPUS'
AND s4t1.stat_name       = 'PHYSICAL_MEMORY_BYTES'
AND s5t0.stat_name       = 'DB time'
AND s5t1.stat_name       = s5t0.stat_name
AND s6t0.stat_name       = 'DB CPU'
AND s6t1.stat_name       = s6t0.stat_name
AND s7t0.stat_name       = 'background cpu time'
AND s7t1.stat_name       = s7t0.stat_name
AND s8t0.stat_name       = 'RMAN cpu time (backup/restore)'
AND s8t1.stat_name       = s8t0.stat_name
AND s9t0.stat_name       = 'logons current'
AND s9t1.stat_name       = s9t0.stat_name
AND s10t0.stat_name       = 'execute count'
AND s10t1.stat_name       = s10t0.stat_name
AND s11t0.stat_name       = 'physical reads'
AND s11t1.stat_name       = s11t0.stat_name
AND s12t0.stat_name       = 'physical writes'
AND s12t1.stat_name       = s12t0.stat_name
AND s13t0.stat_name       = 'redo writes'
AND s13t1.stat_name       = s13t0.stat_name
AND s14t0.stat_name       = 'redo size'
AND s14t1.stat_name       = s14t0.stat_name
AND s15t0.stat_name       = 'physical read IO requests'
AND s15t1.stat_name       = s15t0.stat_name
AND s16t0.stat_name       = 'physical write IO requests'
AND s16t1.stat_name       = s16t0.stat_name
AND TO_CHAR(s0.END_INTERVAL_TIME,'D') >= 1     
AND TO_CHAR(s0.END_INTERVAL_TIME,'D') <= 7; 
COMMIT;
EOF
