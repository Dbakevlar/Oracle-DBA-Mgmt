-- Create table
create table AWR_WRKLD_RPT
(
  DB_ID        NUMBER not null,
  DB_NAME      VARCHAR2(9),
  TIMESTMP     VARCHAR2(14),
  INSTANCE     NUMBER not null,
  DURATION     NUMBER,
  CPU          NUMBER,
  TM_AMT       NUMBER,
  DB_TIME      NUMBER,
  DB_CPU       NUMBER,
  BG_CPU       NUMBER,
  RMAN         NUMBER,
  AAS          NUMBER,
  TOTAL_ORACLE NUMBER,
  LOAD         NUMBER,
  TOTAL_OS     NUMBER,
  MEMORY       NUMBER,
  IO_READS     NUMBER,
  IO_WRITES    NUMBER,
  IO_REDO      NUMBER,
  IO_R_MB      NUMBER,
  IO_W_MB      NUMBER,
  REDO_SZ_SEC  NUMBER,
  LOGONS       NUMBER,
  EXECUTIONS   NUMBER,
  ORA_CPU_PCT  NUMBER,
  RMAN_CPU_PCT NUMBER,
  OS_CPU_PCT   NUMBER,
  OS_CPU_USR   NUMBER,
  OS_CPU_SYS   NUMBER,
  OS_CPU_IO    NUMBER
)
tablespace DBA_MGMNT_DATA1
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );