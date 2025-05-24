-- Oracle Enterprise Manager Setup for Community Garden Management System
-- Run as SYSDBA

-- Create EM Repository Tablespace
CREATE TABLESPACE em_repository
  DATAFILE '/u01/app/oracle/oradata/cgms/em_repository01.dbf'
  SIZE 2G
  AUTOEXTEND ON NEXT 100M MAXSIZE 10G;

-- Create EM Repository Owner
CREATE USER em_owner IDENTIFIED BY "your_secure_password"
  DEFAULT TABLESPACE em_repository
  TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON em_repository;

-- Grant necessary privileges to EM Repository Owner
GRANT CONNECT, RESOURCE TO em_owner;
GRANT CREATE VIEW, CREATE PROCEDURE, CREATE MATERIALIZED VIEW TO em_owner;
GRANT EXECUTE ON DBMS_LOCK TO em_owner;
GRANT SELECT ANY DICTIONARY TO em_owner;

-- Create Monitoring User for Enterprise Manager
CREATE USER em_monitor IDENTIFIED BY "your_secure_password"
  DEFAULT TABLESPACE cgms_data
  TEMPORARY TABLESPACE temp;

-- Grant Monitoring Privileges
GRANT CREATE SESSION TO em_monitor;
GRANT SELECT ANY DICTIONARY TO em_monitor;
GRANT ADVISOR TO em_monitor;
GRANT SELECT_CATALOG_ROLE TO em_monitor;

-- Create Custom Metrics
BEGIN
  -- Garden Usage Metric
  DBMS_SERVER_ALERT.SET_THRESHOLD(
    metrics_id => DBMS_SERVER_ALERT.OPERATOR_OBSERVATION,
    warning_operator => DBMS_SERVER_ALERT.OPERATOR_GE,
    warning_value => '80',
    critical_operator => DBMS_SERVER_ALERT.OPERATOR_GE,
    critical_value => '90',
    observation_period => 30,
    consecutive_occurrences => 3,
    instance_name => 'cgms_pdb',
    object_type => 'GARDEN_USAGE',
    object_name => 'TOTAL_PLOTS_OCCUPIED_PERCENTAGE'
  );

  -- Resource Depletion Alert
  DBMS_SERVER_ALERT.SET_THRESHOLD(
    metrics_id => DBMS_SERVER_ALERT.OPERATOR_OBSERVATION,
    warning_operator => DBMS_SERVER_ALERT.OPERATOR_LE,
    warning_value => '20',
    critical_operator => DBMS_SERVER_ALERT.OPERATOR_LE,
    critical_value => '10',
    observation_period => 60,
    consecutive_occurrences => 1,
    instance_name => 'cgms_pdb',
    object_type => 'RESOURCE_LEVEL',
    object_name => 'AVAILABLE_QUANTITY_PERCENTAGE'
  );
END;
/

-- Create Monitoring Package
CREATE OR REPLACE PACKAGE em_monitoring AS
  -- Monitor Database Space Usage
  PROCEDURE check_tablespace_usage;
  -- Monitor User Sessions
  PROCEDURE check_user_sessions;
  -- Monitor Long-Running Queries
  PROCEDURE check_long_running_queries;
  -- Monitor Resource Usage
  PROCEDURE check_resource_usage;
END em_monitoring;
/

CREATE OR REPLACE PACKAGE BODY em_monitoring AS
  PROCEDURE check_tablespace_usage IS
  BEGIN
    -- Implementation details
    NULL;
  END check_tablespace_usage;

  PROCEDURE check_user_sessions IS
  BEGIN
    -- Implementation details
    NULL;
  END check_user_sessions;

  PROCEDURE check_long_running_queries IS
  BEGIN
    -- Implementation details
    NULL;
  END check_long_running_queries;

  PROCEDURE check_resource_usage IS
  BEGIN
    -- Implementation details
    NULL;
  END check_resource_usage;
END em_monitoring;
/

-- Create Monitoring Jobs
BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'MONITOR_TABLESPACE_USAGE',
    job_type        => 'STORED_PROCEDURE',
    job_action      => 'em_monitoring.check_tablespace_usage',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=HOURLY',
    enabled         => TRUE
  );

  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'MONITOR_USER_SESSIONS',
    job_type        => 'STORED_PROCEDURE',
    job_action      => 'em_monitoring.check_user_sessions',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=MINUTELY;INTERVAL=15',
    enabled         => TRUE
  );

  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'MONITOR_LONG_RUNNING_QUERIES',
    job_type        => 'STORED_PROCEDURE',
    job_action      => 'em_monitoring.check_long_running_queries',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=MINUTELY;INTERVAL=5',
    enabled         => TRUE
  );

  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'MONITOR_RESOURCE_USAGE',
    job_type        => 'STORED_PROCEDURE',
    job_action      => 'em_monitoring.check_resource_usage',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=HOURLY',
    enabled         => TRUE
  );
END;
/

-- Exit
EXIT; 