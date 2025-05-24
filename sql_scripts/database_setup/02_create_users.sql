-- Create Users and Implement Access Control
-- Run as SYSDBA in cgms_pdb

-- Create Application Schema Owner
CREATE USER cgms_owner IDENTIFIED BY "your_secure_password"
  DEFAULT TABLESPACE cgms_data
  TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON cgms_data
  QUOTA UNLIMITED ON cgms_indexes
  QUOTA UNLIMITED ON cgms_archive;

-- Create Read-Only User for Reporting
CREATE USER cgms_reader IDENTIFIED BY "your_secure_password"
  DEFAULT TABLESPACE cgms_data
  TEMPORARY TABLESPACE temp
  QUOTA 0M ON cgms_data;

-- Create Application User
CREATE USER cgms_app IDENTIFIED BY "your_secure_password"
  DEFAULT TABLESPACE cgms_data
  TEMPORARY TABLESPACE temp
  QUOTA 50M ON cgms_data;

-- Create Roles
CREATE ROLE cgms_admin_role;
CREATE ROLE cgms_user_role;
CREATE ROLE cgms_reader_role;

-- Grant System Privileges to Schema Owner
GRANT CREATE SESSION TO cgms_owner;
GRANT CREATE TABLE TO cgms_owner;
GRANT CREATE VIEW TO cgms_owner;
GRANT CREATE PROCEDURE TO cgms_owner;
GRANT CREATE TRIGGER TO cgms_owner;
GRANT CREATE SEQUENCE TO cgms_owner;
GRANT CREATE MATERIALIZED VIEW TO cgms_owner;
GRANT CREATE SYNONYM TO cgms_owner;
GRANT CREATE TYPE TO cgms_owner;
GRANT CREATE JOB TO cgms_owner;

-- Grant Admin Role Privileges
GRANT CREATE SESSION TO cgms_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON cgms_owner.* TO cgms_admin_role;
GRANT EXECUTE ON cgms_owner.* TO cgms_admin_role;

-- Grant User Role Privileges
GRANT CREATE SESSION TO cgms_user_role;
GRANT SELECT, INSERT, UPDATE ON cgms_owner.GARDEN TO cgms_user_role;
GRANT SELECT, INSERT, UPDATE ON cgms_owner.PLOT TO cgms_user_role;
GRANT SELECT, INSERT ON cgms_owner.RESOURCE_USAGE TO cgms_user_role;
GRANT SELECT ON cgms_owner.PLANT TO cgms_user_role;
GRANT SELECT, INSERT ON cgms_owner.EVENT_PARTICIPANT TO cgms_user_role;

-- Grant Reader Role Privileges
GRANT CREATE SESSION TO cgms_reader_role;
GRANT SELECT ON cgms_owner.* TO cgms_reader_role;

-- Assign Roles
GRANT cgms_admin_role TO cgms_app;
GRANT cgms_reader_role TO cgms_reader;

-- Create Profiles
CREATE PROFILE cgms_app_profile LIMIT
  SESSIONS_PER_USER 50
  CPU_PER_SESSION UNLIMITED
  CPU_PER_CALL 3000
  CONNECT_TIME 240
  IDLE_TIME 30
  LOGICAL_READS_PER_SESSION DEFAULT
  LOGICAL_READS_PER_CALL 1000
  PRIVATE_SGA 15K
  COMPOSITE_LIMIT 5000000;

CREATE PROFILE cgms_user_profile LIMIT
  SESSIONS_PER_USER 3
  CPU_PER_SESSION UNLIMITED
  CPU_PER_CALL 1000
  CONNECT_TIME 120
  IDLE_TIME 15
  LOGICAL_READS_PER_SESSION DEFAULT
  LOGICAL_READS_PER_CALL 500
  PRIVATE_SGA 10K
  COMPOSITE_LIMIT 1000000;

-- Assign Profiles
ALTER USER cgms_app PROFILE cgms_app_profile;
ALTER USER cgms_reader PROFILE cgms_user_profile;

-- Enable Account Monitoring
ALTER SYSTEM SET audit_trail = DB,EXTENDED SCOPE = SPFILE;
ALTER SYSTEM SET audit_sys_operations = TRUE SCOPE = SPFILE;

-- Create Audit Policies
CREATE AUDIT POLICY cgms_dml_policy
  ACTIONS DELETE ON cgms_owner.GARDEN,
          DELETE ON cgms_owner.PLOT,
          DELETE ON cgms_owner.RESOURCE,
          UPDATE ON cgms_owner.USER;

CREATE AUDIT POLICY cgms_security_policy
  ACTIONS CREATE USER, ALTER USER, DROP USER,
          CREATE ROLE, ALTER ROLE, DROP ROLE,
          GRANT, REVOKE;

-- Enable Audit Policies
AUDIT POLICY cgms_dml_policy;
AUDIT POLICY cgms_security_policy;

-- Exit
EXIT; 