-- Security and Access Control for Community Garden Management System
-- Run as cgms_owner

-- Create Security Configuration Table
CREATE TABLE SECURITY_CONFIG (
    config_id NUMBER PRIMARY KEY,
    feature_name VARCHAR2(50) NOT NULL,
    min_role_level VARCHAR2(20) NOT NULL,
    weekend_access CHAR(1) DEFAULT 'N',
    holiday_access CHAR(1) DEFAULT 'N',
    created_date DATE DEFAULT SYSDATE,
    modified_date DATE,
    CONSTRAINT chk_role_level CHECK (min_role_level IN ('Member', 'Volunteer', 'Admin')),
    CONSTRAINT chk_weekend_access CHECK (weekend_access IN ('Y', 'N')),
    CONSTRAINT chk_holiday_access CHECK (holiday_access IN ('Y', 'N'))
);

CREATE SEQUENCE seq_security_config_id START WITH 1 INCREMENT BY 1;

-- Create Holiday Table
CREATE TABLE HOLIDAY (
    holiday_id NUMBER PRIMARY KEY,
    holiday_name VARCHAR2(100) NOT NULL,
    holiday_date DATE NOT NULL,
    recurring CHAR(1) DEFAULT 'Y',
    created_by VARCHAR2(30),
    created_date DATE DEFAULT SYSDATE,
    CONSTRAINT chk_recurring CHECK (recurring IN ('Y', 'N'))
);

CREATE SEQUENCE seq_holiday_id START WITH 1 INCREMENT BY 1;

-- Create Access Log Table
CREATE TABLE ACCESS_LOG (
    log_id NUMBER PRIMARY KEY,
    user_id NUMBER,
    action_type VARCHAR2(50),
    target_object VARCHAR2(50),
    access_date TIMESTAMP,
    status VARCHAR2(20),
    error_message VARCHAR2(4000),
    ip_address VARCHAR2(50),
    session_id VARCHAR2(50)
);

CREATE SEQUENCE seq_log_id START WITH 1 INCREMENT BY 1;

-- Create Security Management Package
CREATE OR REPLACE PACKAGE security_mgmt AS
    -- Configure feature security
    PROCEDURE configure_feature(
        p_feature_name IN VARCHAR2,
        p_min_role_level IN VARCHAR2,
        p_weekend_access IN CHAR DEFAULT 'N',
        p_holiday_access IN CHAR DEFAULT 'N'
    );

    -- Add holiday
    PROCEDURE add_holiday(
        p_holiday_name IN VARCHAR2,
        p_holiday_date IN DATE,
        p_recurring IN CHAR DEFAULT 'Y'
    );

    -- Check access permission
    FUNCTION check_access_permission(
        p_user_id IN NUMBER,
        p_feature_name IN VARCHAR2
    ) RETURN BOOLEAN;

    -- Log access attempt
    PROCEDURE log_access_attempt(
        p_user_id IN NUMBER,
        p_action_type IN VARCHAR2,
        p_target_object IN VARCHAR2,
        p_status IN VARCHAR2,
        p_error_message IN VARCHAR2 DEFAULT NULL
    );

    -- Get user permissions
    FUNCTION get_user_permissions(
        p_user_id IN NUMBER
    ) RETURN SYS_REFCURSOR;
END security_mgmt;
/

CREATE OR REPLACE PACKAGE BODY security_mgmt AS
    -- Configure feature security
    PROCEDURE configure_feature(
        p_feature_name IN VARCHAR2,
        p_min_role_level IN VARCHAR2,
        p_weekend_access IN CHAR DEFAULT 'N',
        p_holiday_access IN CHAR DEFAULT 'N'
    ) IS
    BEGIN
        MERGE INTO SECURITY_CONFIG sc
        USING DUAL
        ON (sc.feature_name = UPPER(p_feature_name))
        WHEN MATCHED THEN
            UPDATE SET
                min_role_level = p_min_role_level,
                weekend_access = UPPER(p_weekend_access),
                holiday_access = UPPER(p_holiday_access),
                modified_date = SYSDATE
        WHEN NOT MATCHED THEN
            INSERT (config_id, feature_name, min_role_level, 
                   weekend_access, holiday_access)
            VALUES (seq_security_config_id.NEXTVAL, UPPER(p_feature_name),
                   p_min_role_level, UPPER(p_weekend_access), 
                   UPPER(p_holiday_access));

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20501, 'Error configuring feature security: ' || SQLERRM);
    END configure_feature;

    -- Add holiday
    PROCEDURE add_holiday(
        p_holiday_name IN VARCHAR2,
        p_holiday_date IN DATE,
        p_recurring IN CHAR DEFAULT 'Y'
    ) IS
    BEGIN
        INSERT INTO HOLIDAY (
            holiday_id, holiday_name, holiday_date,
            recurring, created_by, created_date
        ) VALUES (
            seq_holiday_id.NEXTVAL, p_holiday_name, p_holiday_date,
            UPPER(p_recurring), SYS_CONTEXT('USERENV','SESSION_USER'), SYSDATE
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20502, 'Error adding holiday: ' || SQLERRM);
    END add_holiday;

    -- Check access permission
    FUNCTION check_access_permission(
        p_user_id IN NUMBER,
        p_feature_name IN VARCHAR2
    ) RETURN BOOLEAN IS
        v_user_role VARCHAR2(20);
        v_min_role_level VARCHAR2(20);
        v_weekend_access CHAR(1);
        v_holiday_access CHAR(1);
        v_is_weekend BOOLEAN;
        v_is_holiday BOOLEAN;
    BEGIN
        -- Get user role
        SELECT user_type INTO v_user_role
        FROM "USER"
        WHERE user_id = p_user_id;

        -- Get feature security settings
        SELECT min_role_level, weekend_access, holiday_access
        INTO v_min_role_level, v_weekend_access, v_holiday_access
        FROM SECURITY_CONFIG
        WHERE feature_name = UPPER(p_feature_name);

        -- Check if it's weekend
        v_is_weekend := TO_CHAR(SYSDATE, 'D') IN (1, 7);

        -- Check if it's holiday
        SELECT COUNT(*) > 0 INTO v_is_holiday
        FROM HOLIDAY
        WHERE (holiday_date = TRUNC(SYSDATE)
               OR (recurring = 'Y' 
                   AND TO_CHAR(holiday_date, 'MMDD') = TO_CHAR(SYSDATE, 'MMDD')));

        -- Admin always has access
        IF v_user_role = 'Admin' THEN
            RETURN TRUE;
        END IF;

        -- Check role level
        IF v_user_role = 'Member' AND v_min_role_level != 'Member' THEN
            RETURN FALSE;
        END IF;

        IF v_user_role = 'Volunteer' AND v_min_role_level = 'Admin' THEN
            RETURN FALSE;
        END IF;

        -- Check weekend access
        IF v_is_weekend AND v_weekend_access = 'N' THEN
            RETURN FALSE;
        END IF;

        -- Check holiday access
        IF v_is_holiday AND v_holiday_access = 'N' THEN
            RETURN FALSE;
        END IF;

        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END check_access_permission;

    -- Log access attempt
    PROCEDURE log_access_attempt(
        p_user_id IN NUMBER,
        p_action_type IN VARCHAR2,
        p_target_object IN VARCHAR2,
        p_status IN VARCHAR2,
        p_error_message IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        INSERT INTO ACCESS_LOG (
            log_id, user_id, action_type,
            target_object, access_date, status,
            error_message, ip_address, session_id
        ) VALUES (
            seq_log_id.NEXTVAL, p_user_id, p_action_type,
            p_target_object, SYSTIMESTAMP, p_status,
            p_error_message,
            SYS_CONTEXT('USERENV','IP_ADDRESS'),
            SYS_CONTEXT('USERENV','SESSIONID')
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20503, 'Error logging access attempt: ' || SQLERRM);
    END log_access_attempt;

    -- Get user permissions
    FUNCTION get_user_permissions(
        p_user_id IN NUMBER
    ) RETURN SYS_REFCURSOR IS
        v_result SYS_REFCURSOR;
    BEGIN
        OPEN v_result FOR
            SELECT sc.feature_name,
                   CASE 
                       WHEN u.user_type = 'Admin' THEN 'Y'
                       WHEN u.user_type = 'Volunteer' AND sc.min_role_level IN ('Member', 'Volunteer') THEN 'Y'
                       WHEN u.user_type = 'Member' AND sc.min_role_level = 'Member' THEN 'Y'
                       ELSE 'N'
                   END as has_access,
                   sc.weekend_access,
                   sc.holiday_access
            FROM SECURITY_CONFIG sc
            CROSS JOIN "USER" u
            WHERE u.user_id = p_user_id
            ORDER BY sc.feature_name;

        RETURN v_result;
    END get_user_permissions;
END security_mgmt;
/

-- Initialize Security Configuration
BEGIN
    -- Configure feature security
    security_mgmt.configure_feature('PLOT_ASSIGNMENT', 'Member', 'N', 'N');
    security_mgmt.configure_feature('RESOURCE_MANAGEMENT', 'Volunteer', 'Y', 'N');
    security_mgmt.configure_feature('EVENT_MANAGEMENT', 'Volunteer', 'Y', 'Y');
    security_mgmt.configure_feature('USER_MANAGEMENT', 'Admin', 'Y', 'Y');
    security_mgmt.configure_feature('GARDEN_MANAGEMENT', 'Admin', 'Y', 'Y');

    -- Add standard holidays
    security_mgmt.add_holiday('New Year''s Day', TO_DATE('01-01-2024', 'DD-MM-YYYY'), 'Y');
    security_mgmt.add_holiday('Christmas Day', TO_DATE('25-12-2024', 'DD-MM-YYYY'), 'Y');
    security_mgmt.add_holiday('Independence Day', TO_DATE('04-07-2024', 'DD-MM-YYYY'), 'Y');
    security_mgmt.add_holiday('Labor Day', TO_DATE('02-09-2024', 'DD-MM-YYYY'), 'Y');
    security_mgmt.add_holiday('Thanksgiving', TO_DATE('28-11-2024', 'DD-MM-YYYY'), 'Y');
END;
/

-- Create Security Views
CREATE OR REPLACE VIEW V_USER_PERMISSIONS AS
SELECT u.user_id,
       u.first_name || ' ' || u.last_name as user_name,
       u.user_type,
       sc.feature_name,
       CASE 
           WHEN u.user_type = 'Admin' THEN 'Y'
           WHEN u.user_type = 'Volunteer' AND sc.min_role_level IN ('Member', 'Volunteer') THEN 'Y'
           WHEN u.user_type = 'Member' AND sc.min_role_level = 'Member' THEN 'Y'
           ELSE 'N'
       END as has_access,
       sc.weekend_access,
       sc.holiday_access
FROM "USER" u
CROSS JOIN SECURITY_CONFIG sc;

CREATE OR REPLACE VIEW V_ACCESS_LOG_SUMMARY AS
SELECT u.user_id,
       u.first_name || ' ' || u.last_name as user_name,
       al.action_type,
       al.target_object,
       al.status,
       COUNT(*) as attempt_count,
       MAX(al.access_date) as last_attempt
FROM ACCESS_LOG al
JOIN "USER" u ON al.user_id = u.user_id
GROUP BY u.user_id, u.first_name, u.last_name,
         al.action_type, al.target_object, al.status;

-- Exit
EXIT; 