-- Event Management Procedures
-- Run as cgms_owner

CREATE OR REPLACE PROCEDURE create_event(
    p_garden_id IN NUMBER,
    p_event_name IN VARCHAR2,
    p_event_type IN VARCHAR2,
    p_start_date IN DATE,
    p_end_date IN DATE,
    p_max_participants IN NUMBER,
    p_description IN VARCHAR2
) IS
    v_weekend NUMBER;
    v_holiday NUMBER;
BEGIN
    -- Check if date is weekend
    SELECT COUNT(*) INTO v_weekend
    FROM DUAL
    WHERE TO_CHAR(p_start_date, 'DY') IN ('SAT', 'SUN');

    -- Check if date is holiday
    SELECT COUNT(*) INTO v_holiday
    FROM HOLIDAY
    WHERE holiday_date = p_start_date;

    -- Validate conditions
    IF v_weekend > 0 THEN
        RAISE_APPLICATION_ERROR(-20801, 'Cannot schedule events on weekends');
    ELSIF v_holiday > 0 THEN
        RAISE_APPLICATION_ERROR(-20802, 'Cannot schedule events on holidays');
    END IF;

    -- Create event
    INSERT INTO EVENT (
        garden_id,
        event_name,
        event_type,
        start_date,
        end_date,
        max_participants,
        description,
        status,
        created_date,
        created_by
    ) VALUES (
        p_garden_id,
        p_event_name,
        p_event_type,
        p_start_date,
        p_end_date,
        p_max_participants,
        p_description,
        'Active',
        SYSDATE,
        USER
    );

    -- Log the action
    INSERT INTO AUDIT_LOG (
        action_type,
        table_name,
        record_id,
        action_date,
        action_by,
        action_details
    ) VALUES (
        'EVENT_CREATION',
        'EVENT',
        event_seq.CURRVAL,
        SYSDATE,
        USER,
        'New event created: ' || p_event_name
    );

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END create_event;
/

CREATE OR REPLACE PROCEDURE register_participant(
    p_event_id IN NUMBER,
    p_user_id IN NUMBER,
    p_notes IN VARCHAR2 DEFAULT NULL
) IS
    v_capacity_available NUMBER;
    v_existing_registration NUMBER;
BEGIN
    -- Check if already registered
    SELECT COUNT(*)
    INTO v_existing_registration
    FROM EVENT_PARTICIPANT
    WHERE event_id = p_event_id
    AND user_id = p_user_id
    AND status IN ('Confirmed', 'Pending');

    IF v_existing_registration > 0 THEN
        RAISE_APPLICATION_ERROR(-20803, 'User already registered for this event');
    END IF;

    -- Check capacity
    v_capacity_available := check_event_capacity(p_event_id);
    
    IF v_capacity_available = 0 THEN
        RAISE_APPLICATION_ERROR(-20804, 'Event has reached maximum capacity');
    END IF;

    -- Register participant
    INSERT INTO EVENT_PARTICIPANT (
        event_id,
        user_id,
        registration_date,
        status,
        notes,
        created_date,
        created_by
    ) VALUES (
        p_event_id,
        p_user_id,
        SYSDATE,
        'Confirmed',
        p_notes,
        SYSDATE,
        USER
    );

    -- Log the action
    INSERT INTO AUDIT_LOG (
        action_type,
        table_name,
        record_id,
        action_date,
        action_by,
        action_details
    ) VALUES (
        'EVENT_REGISTRATION',
        'EVENT_PARTICIPANT',
        event_participant_seq.CURRVAL,
        SYSDATE,
        USER,
        'User ' || p_user_id || ' registered for event ' || p_event_id
    );

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END register_participant;
/

CREATE OR REPLACE PROCEDURE cancel_registration(
    p_event_id IN NUMBER,
    p_user_id IN NUMBER,
    p_reason IN VARCHAR2
) IS
BEGIN
    -- Update participant status
    UPDATE EVENT_PARTICIPANT
    SET status = 'Cancelled',
        cancellation_reason = p_reason,
        cancellation_date = SYSDATE,
        last_updated_date = SYSDATE,
        last_updated_by = USER
    WHERE event_id = p_event_id
    AND user_id = p_user_id
    AND status = 'Confirmed'
    RETURNING participant_id INTO v_participant_id;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20805, 'Active registration not found for this event');
    END IF;

    -- Log the action
    INSERT INTO AUDIT_LOG (
        action_type,
        table_name,
        record_id,
        action_date,
        action_by,
        action_details
    ) VALUES (
        'EVENT_CANCELLATION',
        'EVENT_PARTICIPANT',
        v_participant_id,
        SYSDATE,
        USER,
        'User ' || p_user_id || ' cancelled registration for event ' || p_event_id || ' - Reason: ' || p_reason
    );

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END cancel_registration;
/

-- Exit
EXIT; 