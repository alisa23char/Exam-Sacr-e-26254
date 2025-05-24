-- Triggers for Community Garden Management System
-- Run as cgms_owner

-- Audit Trail Table
CREATE TABLE AUDIT_TRAIL (
    audit_id NUMBER PRIMARY KEY,
    table_name VARCHAR2(30) NOT NULL,
    operation VARCHAR2(10) NOT NULL,
    old_values CLOB,
    new_values CLOB,
    changed_by VARCHAR2(30) NOT NULL,
    change_date TIMESTAMP NOT NULL
);

CREATE SEQUENCE seq_audit_id START WITH 1 INCREMENT BY 1;

-- Generic Audit Trigger Function
CREATE OR REPLACE FUNCTION get_changed_values(
    p_old IN OUT NOCOPY SYS.ANYDATA,
    p_new IN OUT NOCOPY SYS.ANYDATA
) RETURN CLOB IS
    v_old_str CLOB;
    v_new_str CLOB;
BEGIN
    IF p_old IS NOT NULL THEN
        v_old_str := p_old.GetTypeName() || ': ' || p_old.AccessTimestamp();
    END IF;
    IF p_new IS NOT NULL THEN
        v_new_str := p_new.GetTypeName() || ': ' || p_new.AccessTimestamp();
    END IF;
    RETURN 'Old: ' || v_old_str || CHR(10) || 'New: ' || v_new_str;
END;
/

-- Audit Trigger for GARDEN Table
CREATE OR REPLACE TRIGGER trg_audit_garden
AFTER INSERT OR UPDATE OR DELETE ON GARDEN
FOR EACH ROW
DECLARE
    v_old_values CLOB;
    v_new_values CLOB;
    v_operation VARCHAR2(10);
BEGIN
    -- Determine operation type
    IF INSERTING THEN
        v_operation := 'INSERT';
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
    ELSE
        v_operation := 'DELETE';
    END IF;

    -- Capture old values
    IF UPDATING OR DELETING THEN
        v_old_values := 'Garden ID: ' || :OLD.garden_id ||
                       ', Name: ' || :OLD.garden_name ||
                       ', Status: ' || :OLD.status;
    END IF;

    -- Capture new values
    IF INSERTING OR UPDATING THEN
        v_new_values := 'Garden ID: ' || :NEW.garden_id ||
                       ', Name: ' || :NEW.garden_name ||
                       ', Status: ' || :NEW.status;
    END IF;

    -- Insert audit record
    INSERT INTO AUDIT_TRAIL (
        audit_id, table_name, operation,
        old_values, new_values,
        changed_by, change_date
    ) VALUES (
        seq_audit_id.NEXTVAL, 'GARDEN', v_operation,
        v_old_values, v_new_values,
        SYS_CONTEXT('USERENV','SESSION_USER'),
        SYSTIMESTAMP
    );
END;
/

-- Business Rule Trigger for PLOT_ASSIGNMENT
CREATE OR REPLACE TRIGGER trg_plot_assignment_rules
BEFORE INSERT OR UPDATE ON PLOT_ASSIGNMENT
FOR EACH ROW
DECLARE
    v_weekend_access BOOLEAN;
    v_is_holiday BOOLEAN;
    v_user_type VARCHAR2(20);
BEGIN
    -- Check if it's weekend
    v_weekend_access := TO_CHAR(SYSDATE, 'D') IN (1, 7);
    
    -- Check if it's a holiday (simplified example)
    SELECT COUNT(*) > 0 INTO v_is_holiday
    FROM HOLIDAY
    WHERE holiday_date = TRUNC(SYSDATE);

    -- Get user type
    SELECT user_type INTO v_user_type
    FROM "USER"
    WHERE user_id = :NEW.user_id;

    -- Enforce weekend/holiday restrictions
    IF v_weekend_access OR v_is_holiday THEN
        IF v_user_type != 'Admin' THEN
            RAISE_APPLICATION_ERROR(-20301, 
                'Plot assignments not allowed on weekends/holidays except for administrators');
        END IF;
    END IF;

    -- Set audit columns
    IF INSERTING THEN
        :NEW.created_date := SYSDATE;
        :NEW.created_by := SYS_CONTEXT('USERENV','SESSION_USER');
    END IF;
    :NEW.modified_date := SYSDATE;
    :NEW.modified_by := SYS_CONTEXT('USERENV','SESSION_USER');
END;
/

-- Resource Usage Monitoring Trigger
CREATE OR REPLACE TRIGGER trg_resource_usage_monitor
AFTER INSERT ON RESOURCE_USAGE
FOR EACH ROW
DECLARE
    v_current_quantity NUMBER;
    v_threshold NUMBER;
BEGIN
    -- Get current quantity and threshold
    SELECT quantity_available, minimum_threshold
    INTO v_current_quantity, v_threshold
    FROM RESOURCE
    WHERE resource_id = :NEW.resource_id;

    -- Check if quantity is below threshold
    IF v_current_quantity <= v_threshold THEN
        -- Log alert
        INSERT INTO RESOURCE_ALERT (
            alert_id,
            resource_id,
            alert_type,
            alert_message,
            created_date
        ) VALUES (
            seq_alert_id.NEXTVAL,
            :NEW.resource_id,
            'LOW_STOCK',
            'Resource quantity below threshold. Current: ' || 
            v_current_quantity || ', Threshold: ' || v_threshold,
            SYSDATE
        );
    END IF;
END;
/

-- Event Capacity Control Trigger
CREATE OR REPLACE TRIGGER trg_event_capacity
BEFORE INSERT ON EVENT_PARTICIPANT
FOR EACH ROW
DECLARE
    v_current_count NUMBER;
    v_max_participants NUMBER;
BEGIN
    -- Get current participant count and maximum limit
    SELECT COUNT(*), e.max_participants
    INTO v_current_count, v_max_participants
    FROM EVENT_PARTICIPANT ep
    JOIN EVENT e ON ep.event_id = e.event_id
    WHERE ep.event_id = :NEW.event_id
    AND ep.status = 'Registered'
    GROUP BY e.max_participants;

    -- Check capacity
    IF v_current_count >= v_max_participants THEN
        RAISE_APPLICATION_ERROR(-20302, 'Event has reached maximum capacity');
    END IF;
END;
/

-- Security Trigger for User Operations
CREATE OR REPLACE TRIGGER trg_user_security
BEFORE INSERT OR UPDATE OR DELETE ON "USER"
FOR EACH ROW
DECLARE
    v_user_role VARCHAR2(20);
BEGIN
    -- Get current user's role
    SELECT user_type INTO v_user_role
    FROM "USER"
    WHERE user_id = SYS_CONTEXT('USERENV','SESSION_USER');

    -- Enforce security rules
    IF v_user_role != 'Admin' THEN
        IF DELETING THEN
            RAISE_APPLICATION_ERROR(-20303, 'Only administrators can delete users');
        ELSIF INSERTING AND :NEW.user_type = 'Admin' THEN
            RAISE_APPLICATION_ERROR(-20304, 'Only administrators can create admin users');
        ELSIF UPDATING AND 
              (:OLD.user_type != :NEW.user_type OR 
               :OLD.status != :NEW.status) THEN
            RAISE_APPLICATION_ERROR(-20305, 'Only administrators can modify user type or status');
        END IF;
    END IF;
END;
/

-- Exit
EXIT; 