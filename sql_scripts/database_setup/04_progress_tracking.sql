-- Progress Tracking Setup for Community Garden Management System
-- Run as cgms_owner

-- Create Progress Tracking Tables
CREATE TABLE deployment_history (
    deployment_id NUMBER PRIMARY KEY,
    script_name VARCHAR2(100) NOT NULL,
    execution_date TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    executed_by VARCHAR2(30) NOT NULL,
    status VARCHAR2(20) CHECK (status IN ('Success','Failed','In Progress')),
    error_message VARCHAR2(4000),
    execution_time NUMBER,
    script_checksum VARCHAR2(64)
);

CREATE TABLE schema_version (
    version_id NUMBER PRIMARY KEY,
    version_number VARCHAR2(20) NOT NULL,
    description VARCHAR2(200),
    deployed_date TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    deployed_by VARCHAR2(30) NOT NULL,
    status VARCHAR2(20) CHECK (status IN ('Current','Previous','Failed')),
    script_reference VARCHAR2(100)
);

CREATE TABLE feature_deployment (
    feature_id NUMBER PRIMARY KEY,
    feature_name VARCHAR2(100) NOT NULL,
    deployment_date TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    deployed_by VARCHAR2(30) NOT NULL,
    status VARCHAR2(20) CHECK (status IN ('Planned','In Progress','Completed','Failed')),
    dependencies VARCHAR2(500),
    rollback_script VARCHAR2(100)
);

-- Create Sequences
CREATE SEQUENCE seq_deployment_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_version_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_feature_id START WITH 1 INCREMENT BY 1;

-- Create Progress Tracking Package
CREATE OR REPLACE PACKAGE progress_tracking AS
    -- Log deployment execution
    PROCEDURE log_deployment(
        p_script_name IN VARCHAR2,
        p_status IN VARCHAR2,
        p_error_message IN VARCHAR2 DEFAULT NULL
    );
    
    -- Update schema version
    PROCEDURE update_schema_version(
        p_version_number IN VARCHAR2,
        p_description IN VARCHAR2
    );
    
    -- Track feature deployment
    PROCEDURE track_feature(
        p_feature_name IN VARCHAR2,
        p_status IN VARCHAR2,
        p_dependencies IN VARCHAR2 DEFAULT NULL,
        p_rollback_script IN VARCHAR2 DEFAULT NULL
    );
    
    -- Get current schema version
    FUNCTION get_current_version RETURN VARCHAR2;
    
    -- Check deployment status
    FUNCTION check_deployment_status(
        p_script_name IN VARCHAR2
    ) RETURN VARCHAR2;
END progress_tracking;
/

CREATE OR REPLACE PACKAGE BODY progress_tracking AS
    PROCEDURE log_deployment(
        p_script_name IN VARCHAR2,
        p_status IN VARCHAR2,
        p_error_message IN VARCHAR2 DEFAULT NULL
    ) IS
        v_checksum VARCHAR2(64);
        v_start_time TIMESTAMP;
        v_execution_time NUMBER;
    BEGIN
        -- Calculate script checksum
        SELECT STANDARD_HASH(p_script_name, 'SHA256') INTO v_checksum FROM DUAL;
        
        v_start_time := SYSTIMESTAMP;
        
        -- Log deployment
        INSERT INTO deployment_history (
            deployment_id,
            script_name,
            executed_by,
            status,
            error_message,
            execution_time,
            script_checksum
        ) VALUES (
            seq_deployment_id.NEXTVAL,
            p_script_name,
            SYS_CONTEXT('USERENV','SESSION_USER'),
            p_status,
            p_error_message,
            EXTRACT(SECOND FROM (SYSTIMESTAMP - v_start_time)),
            v_checksum
        );
        COMMIT;
    END log_deployment;

    PROCEDURE update_schema_version(
        p_version_number IN VARCHAR2,
        p_description IN VARCHAR2
    ) IS
    BEGIN
        -- Update previous version status
        UPDATE schema_version
        SET status = 'Previous'
        WHERE status = 'Current';
        
        -- Insert new version
        INSERT INTO schema_version (
            version_id,
            version_number,
            description,
            deployed_by,
            status,
            script_reference
        ) VALUES (
            seq_version_id.NEXTVAL,
            p_version_number,
            p_description,
            SYS_CONTEXT('USERENV','SESSION_USER'),
            'Current',
            NULL
        );
        COMMIT;
    END update_schema_version;

    PROCEDURE track_feature(
        p_feature_name IN VARCHAR2,
        p_status IN VARCHAR2,
        p_dependencies IN VARCHAR2 DEFAULT NULL,
        p_rollback_script IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        INSERT INTO feature_deployment (
            feature_id,
            feature_name,
            deployed_by,
            status,
            dependencies,
            rollback_script
        ) VALUES (
            seq_feature_id.NEXTVAL,
            p_feature_name,
            SYS_CONTEXT('USERENV','SESSION_USER'),
            p_status,
            p_dependencies,
            p_rollback_script
        );
        COMMIT;
    END track_feature;

    FUNCTION get_current_version RETURN VARCHAR2 IS
        v_version VARCHAR2(20);
    BEGIN
        SELECT version_number INTO v_version
        FROM schema_version
        WHERE status = 'Current';
        
        RETURN v_version;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_current_version;

    FUNCTION check_deployment_status(
        p_script_name IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_status VARCHAR2(20);
    BEGIN
        SELECT status INTO v_status
        FROM deployment_history
        WHERE script_name = p_script_name
        AND execution_date = (
            SELECT MAX(execution_date)
            FROM deployment_history
            WHERE script_name = p_script_name
        );
        
        RETURN v_status;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END check_deployment_status;
END progress_tracking;
/

-- Create Initial Version Record
BEGIN
    progress_tracking.update_schema_version(
        p_version_number => '1.0.0',
        p_description => 'Initial database setup'
    );
END;
/

-- Exit
EXIT; 