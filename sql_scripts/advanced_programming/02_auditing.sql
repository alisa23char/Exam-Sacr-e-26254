-- Auditing System Setup for Community Garden Management System
-- Run as cgms_owner

-- Create Audit Configuration Table
CREATE TABLE AUDIT_CONFIG (
    config_id NUMBER PRIMARY KEY,
    table_name VARCHAR2(30) NOT NULL,
    audit_level VARCHAR2(20) NOT NULL,
    retention_days NUMBER DEFAULT 90,
    enabled CHAR(1) DEFAULT 'Y',
    created_date DATE DEFAULT SYSDATE,
    modified_date DATE,
    CONSTRAINT chk_audit_level CHECK (audit_level IN ('NONE', 'MINIMAL', 'FULL')),
    CONSTRAINT chk_enabled CHECK (enabled IN ('Y', 'N'))
);

CREATE SEQUENCE seq_config_id START WITH 1 INCREMENT BY 1;

-- Create Audit Detail Table
CREATE TABLE AUDIT_DETAIL (
    detail_id NUMBER PRIMARY KEY,
    audit_id NUMBER NOT NULL,
    column_name VARCHAR2(30) NOT NULL,
    old_value VARCHAR2(4000),
    new_value VARCHAR2(4000),
    CONSTRAINT fk_audit_detail FOREIGN KEY (audit_id) REFERENCES AUDIT_TRAIL(audit_id)
);

CREATE SEQUENCE seq_detail_id START WITH 1 INCREMENT BY 1;

-- Create Audit Archive Table
CREATE TABLE AUDIT_ARCHIVE (
    archive_id NUMBER PRIMARY KEY,
    audit_id NUMBER NOT NULL,
    table_name VARCHAR2(30) NOT NULL,
    operation VARCHAR2(10) NOT NULL,
    old_values CLOB,
    new_values CLOB,
    changed_by VARCHAR2(30) NOT NULL,
    change_date TIMESTAMP NOT NULL,
    archive_date TIMESTAMP DEFAULT SYSTIMESTAMP
);

CREATE SEQUENCE seq_archive_id START WITH 1 INCREMENT BY 1;

-- Create Audit Management Package
CREATE OR REPLACE PACKAGE audit_mgmt AS
    -- Configure auditing for a table
    PROCEDURE configure_auditing(
        p_table_name IN VARCHAR2,
        p_audit_level IN VARCHAR2,
        p_retention_days IN NUMBER DEFAULT 90
    );

    -- Enable/Disable auditing
    PROCEDURE toggle_auditing(
        p_table_name IN VARCHAR2,
        p_enabled IN CHAR
    );

    -- Archive old audit records
    PROCEDURE archive_audit_records(
        p_days_old IN NUMBER DEFAULT 90
    );

    -- Purge archived records
    PROCEDURE purge_archived_records(
        p_days_old IN NUMBER DEFAULT 365
    );

    -- Get audit trail for a record
    FUNCTION get_record_history(
        p_table_name IN VARCHAR2,
        p_record_id IN NUMBER
    ) RETURN SYS_REFCURSOR;
END audit_mgmt;
/

CREATE OR REPLACE PACKAGE BODY audit_mgmt AS
    -- Configure auditing for a table
    PROCEDURE configure_auditing(
        p_table_name IN VARCHAR2,
        p_audit_level IN VARCHAR2,
        p_retention_days IN NUMBER DEFAULT 90
    ) IS
    BEGIN
        MERGE INTO AUDIT_CONFIG ac
        USING DUAL
        ON (ac.table_name = UPPER(p_table_name))
        WHEN MATCHED THEN
            UPDATE SET
                audit_level = UPPER(p_audit_level),
                retention_days = p_retention_days,
                modified_date = SYSDATE
        WHEN NOT MATCHED THEN
            INSERT (config_id, table_name, audit_level, retention_days)
            VALUES (seq_config_id.NEXTVAL, UPPER(p_table_name), 
                   UPPER(p_audit_level), p_retention_days);
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20401, 'Error configuring audit: ' || SQLERRM);
    END configure_auditing;

    -- Enable/Disable auditing
    PROCEDURE toggle_auditing(
        p_table_name IN VARCHAR2,
        p_enabled IN CHAR
    ) IS
    BEGIN
        UPDATE AUDIT_CONFIG
        SET enabled = UPPER(p_enabled),
            modified_date = SYSDATE
        WHERE table_name = UPPER(p_table_name);

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20402, 'Table not configured for auditing');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20403, 'Error toggling audit: ' || SQLERRM);
    END toggle_auditing;

    -- Archive old audit records
    PROCEDURE archive_audit_records(
        p_days_old IN NUMBER DEFAULT 90
    ) IS
        v_cutoff_date TIMESTAMP;
    BEGIN
        v_cutoff_date := SYSTIMESTAMP - p_days_old;

        INSERT INTO AUDIT_ARCHIVE (
            archive_id, audit_id, table_name,
            operation, old_values, new_values,
            changed_by, change_date
        )
        SELECT 
            seq_archive_id.NEXTVAL, audit_id, table_name,
            operation, old_values, new_values,
            changed_by, change_date
        FROM AUDIT_TRAIL
        WHERE change_date < v_cutoff_date;

        DELETE FROM AUDIT_DETAIL
        WHERE audit_id IN (
            SELECT audit_id
            FROM AUDIT_TRAIL
            WHERE change_date < v_cutoff_date
        );

        DELETE FROM AUDIT_TRAIL
        WHERE change_date < v_cutoff_date;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20404, 'Error archiving audit records: ' || SQLERRM);
    END archive_audit_records;

    -- Purge archived records
    PROCEDURE purge_archived_records(
        p_days_old IN NUMBER DEFAULT 365
    ) IS
        v_cutoff_date TIMESTAMP;
    BEGIN
        v_cutoff_date := SYSTIMESTAMP - p_days_old;

        DELETE FROM AUDIT_ARCHIVE
        WHERE archive_date < v_cutoff_date;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20405, 'Error purging archived records: ' || SQLERRM);
    END purge_archived_records;

    -- Get audit trail for a record
    FUNCTION get_record_history(
        p_table_name IN VARCHAR2,
        p_record_id IN NUMBER
    ) RETURN SYS_REFCURSOR IS
        v_result SYS_REFCURSOR;
    BEGIN
        OPEN v_result FOR
            SELECT at.operation, at.old_values, at.new_values,
                   at.changed_by, at.change_date,
                   ad.column_name, ad.old_value, ad.new_value
            FROM AUDIT_TRAIL at
            LEFT JOIN AUDIT_DETAIL ad ON at.audit_id = ad.audit_id
            WHERE at.table_name = UPPER(p_table_name)
            AND (at.old_values LIKE '%ID: ' || p_record_id || '%'
                 OR at.new_values LIKE '%ID: ' || p_record_id || '%')
            UNION ALL
            SELECT aa.operation, aa.old_values, aa.new_values,
                   aa.changed_by, aa.change_date,
                   NULL, NULL, NULL
            FROM AUDIT_ARCHIVE aa
            WHERE aa.table_name = UPPER(p_table_name)
            AND (aa.old_values LIKE '%ID: ' || p_record_id || '%'
                 OR aa.new_values LIKE '%ID: ' || p_record_id || '%')
            ORDER BY change_date DESC;

        RETURN v_result;
    END get_record_history;
END audit_mgmt;
/

-- Initialize Audit Configuration
BEGIN
    -- Configure auditing for main tables
    audit_mgmt.configure_auditing('GARDEN', 'FULL', 90);
    audit_mgmt.configure_auditing('PLOT', 'FULL', 90);
    audit_mgmt.configure_auditing('RESOURCE', 'FULL', 90);
    audit_mgmt.configure_auditing('USER', 'FULL', 90);
    audit_mgmt.configure_auditing('EVENT', 'FULL', 90);
    
    -- Configure auditing for junction tables
    audit_mgmt.configure_auditing('PLOT_ASSIGNMENT', 'MINIMAL', 90);
    audit_mgmt.configure_auditing('RESOURCE_USAGE', 'MINIMAL', 90);
    audit_mgmt.configure_auditing('EVENT_PARTICIPANT', 'MINIMAL', 90);
END;
/

-- Create Scheduled Job for Audit Maintenance
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
        job_name        => 'AUDIT_MAINTENANCE_JOB',
        job_type        => 'STORED_PROCEDURE',
        job_action      => 'audit_mgmt.archive_audit_records',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; BYHOUR=1',
        enabled         => TRUE,
        comments        => 'Daily job to archive old audit records'
    );

    DBMS_SCHEDULER.CREATE_JOB (
        job_name        => 'AUDIT_PURGE_JOB',
        job_type        => 'STORED_PROCEDURE',
        job_action      => 'audit_mgmt.purge_archived_records',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=MONTHLY; BYMONTHDAY=1; BYHOUR=2',
        enabled         => TRUE,
        comments        => 'Monthly job to purge old archived records'
    );
END;
/

-- Exit
EXIT; 