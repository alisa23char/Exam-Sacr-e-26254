-- Event Management Package
-- Run as cgms_owner

CREATE OR REPLACE PACKAGE event_mgmt AS
    -- Error codes: -20801 to -20899
    
    -- Functions
    FUNCTION get_upcoming_events(
        p_garden_id IN NUMBER,
        p_days_ahead IN NUMBER DEFAULT 30
    ) RETURN SYS_REFCURSOR;
    
    FUNCTION get_event_participants(
        p_event_id IN NUMBER
    ) RETURN SYS_REFCURSOR;
    
    FUNCTION check_event_capacity(
        p_event_id IN NUMBER
    ) RETURN NUMBER;
    
    -- Procedures
    PROCEDURE create_event(
        p_garden_id IN NUMBER,
        p_event_name IN VARCHAR2,
        p_event_type IN VARCHAR2,
        p_start_date IN DATE,
        p_end_date IN DATE,
        p_max_participants IN NUMBER,
        p_description IN VARCHAR2
    );
    
    PROCEDURE register_participant(
        p_event_id IN NUMBER,
        p_user_id IN NUMBER,
        p_notes IN VARCHAR2 DEFAULT NULL
    );
    
    PROCEDURE cancel_registration(
        p_event_id IN NUMBER,
        p_user_id IN NUMBER,
        p_reason IN VARCHAR2
    );
END event_mgmt;
/

CREATE OR REPLACE PACKAGE BODY event_mgmt AS
    -- Implementation of get_upcoming_events
    FUNCTION get_upcoming_events(
        p_garden_id IN NUMBER,
        p_days_ahead IN NUMBER DEFAULT 30
    ) RETURN SYS_REFCURSOR IS
        v_result SYS_REFCURSOR;
    BEGIN
        OPEN v_result FOR
            SELECT e.event_id,
                   e.event_name,
                   e.event_type,
                   e.start_date,
                   e.end_date,
                   e.max_participants,
                   COUNT(ep.participant_id) as current_participants,
                   e.status,
                   e.description
            FROM EVENT e
            LEFT JOIN EVENT_PARTICIPANT ep ON e.event_id = ep.event_id AND ep.status = 'Confirmed'
            WHERE e.garden_id = p_garden_id
            AND e.start_date BETWEEN SYSDATE AND SYSDATE + p_days_ahead
            AND e.status = 'Active'
            GROUP BY e.event_id, e.event_name, e.event_type, e.start_date, e.end_date,
                     e.max_participants, e.status, e.description
            ORDER BY e.start_date;

        RETURN v_result;
    END get_upcoming_events;

    -- Implementation of get_event_participants
    FUNCTION get_event_participants(
        p_event_id IN NUMBER
    ) RETURN SYS_REFCURSOR IS
        v_result SYS_REFCURSOR;
    BEGIN
        OPEN v_result FOR
            SELECT u.user_id,
                   u.user_name,
                   u.email,
                   ep.registration_date,
                   ep.status,
                   ep.notes
            FROM EVENT_PARTICIPANT ep
            JOIN USERS u ON ep.user_id = u.user_id
            WHERE ep.event_id = p_event_id
            ORDER BY ep.registration_date;

        RETURN v_result;
    END get_event_participants;

    -- Implementation of check_event_capacity
    FUNCTION check_event_capacity(
        p_event_id IN NUMBER
    ) RETURN NUMBER IS
        v_max_participants NUMBER;
        v_current_participants NUMBER;
        v_result NUMBER;
    BEGIN
        -- Get event capacity details
        SELECT max_participants,
               (SELECT COUNT(*)
                FROM EVENT_PARTICIPANT
                WHERE event_id = e.event_id
                AND status = 'Confirmed')
        INTO v_max_participants, v_current_participants
        FROM EVENT e
        WHERE event_id = p_event_id;

        -- Check if space is available
        v_result := CASE
            WHEN v_current_participants < v_max_participants THEN 1
            ELSE 0
        END;

        RETURN v_result;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END check_event_capacity;

    -- Implementation of create_event
    PROCEDURE create_event(
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

    -- Implementation of register_participant
    PROCEDURE register_participant(
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

    -- Implementation of cancel_registration
    PROCEDURE cancel_registration(
        p_event_id IN NUMBER,
        p_user_id IN NUMBER,
        p_reason IN VARCHAR2
    ) IS
        v_participant_id NUMBER;
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
END event_mgmt;
/

-- Exit
EXIT; 