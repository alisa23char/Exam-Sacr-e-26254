-- Create Pluggable Database for Community Garden Management System
-- Run as SYSDBA

-- Create PDB
CREATE PLUGGABLE DATABASE cgms_pdb 
  ADMIN USER cgms_admin IDENTIFIED BY "your_secure_password"
  ROLES = (DBA)
  DEFAULT TABLESPACE cgms_data
    DATAFILE '/u01/app/oracle/oradata/cgms/cgms_data01.dbf' 
    SIZE 500M AUTOEXTEND ON NEXT 100M MAXSIZE 10G
  FILE_NAME_CONVERT = ('/u01/app/oracle/oradata/orcl/pdbseed/',
                      '/u01/app/oracle/oradata/cgms/');

-- Open the PDB
ALTER PLUGGABLE DATABASE cgms_pdb OPEN;

-- Set the PDB to automatically start
ALTER PLUGGABLE DATABASE cgms_pdb SAVE STATE;

-- Create Tablespaces
CREATE TABLESPACE cgms_indexes
  DATAFILE '/u01/app/oracle/oradata/cgms/cgms_idx01.dbf'
  SIZE 250M AUTOEXTEND ON NEXT 50M MAXSIZE 5G;

CREATE TABLESPACE cgms_archive
  DATAFILE '/u01/app/oracle/oradata/cgms/cgms_arch01.dbf'
  SIZE 1G AUTOEXTEND ON NEXT 500M MAXSIZE 20G;

-- Comments
COMMENT ON PLUGGABLE DATABASE cgms_pdb IS 
  'Community Garden Management System Production Database';

-- Exit from SYSDBA session
EXIT; 