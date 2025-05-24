-- Event Management Package
-- Run as cgms_owner

CREATE OR REPLACE PACKAGE event_mgmt AS
    -- Event Operations
    FUNCTION create_event(
        p_garden_id IN NUMBER,
        p_event_name IN VARCHAR2,
        p_event_type IN VARCHAR2,
        p_event_date IN DATE,
        p_max_participants IN NUMBER,
        p_description IN VARCHAR2
    ) RETURN NUMBER;

    PROCEDURE update_event_status(
        p_event_id IN NUMBER,
        p_status IN VARCHAR2
    );

    -- Participant Operations
    PROCEDURE register_participant(
        p_event_id IN NUMBER,
        p_user_id IN NUMBER,
        p_role IN VARCHAR2
    );

    PROCEDURE update_participant_status(
        p_event_id IN NUMBER,
        p_user_id IN NUMBER,
        p_status IN VARCHAR2
    );

    -- Validation Functions
    FUNCTION is_event_full(
        p_event_id IN NUMBER
    ) RETURN BOOLEAN;

    FUNCTION can_register(
        p_event_id IN NUMBER,
        p_user_id IN NUMBER
    ) RETURN BOOLEAN;

    -- Reporting Functions
    FUNCTION get_event_participants(
        p_event_id IN NUMBER
    ) RETURN SYS_REFCURSOR;

    FUNCTION get_user_events(
        p_user_id IN NUMBER,
        p_start_date IN DATE DEFAULT SYSDATE,
        p_end_date IN DATE DEFAULT SYSDATE + 30
    ) RETURN SYS_REFCURSOR;
END event_mgmt;
/

CREATE OR REPLACE PACKAGE BODY event_mgmt AS
    -- Create a new event
    FUNCTION create_event(
        p_garden_id IN NUMBER,
        p_event_name IN VARCHAR2,
        p_event_type IN VARCHAR2,
        p_event_date IN DATE,
        p_max_participants IN NUMBER,
        p_description IN VARCHAR2
    ) RETURN NUMBER IS
        v_event_id NUMBER;
    BEGIN
        -- Validate event date
        IF p_event_date <= SYSDATE THEN
            RAISE_APPLICATION_ERROR(-20201, 'Event date must be in the future');
        END IF;

        INSERT INTO EVENT (
            event_id, garden_id, event_name, event_type,
            event_date, max_participants, status, description,
            created_by, created_date
        ) VALUES (
            seq_event_id.NEXTVAL, p_garden_id, p_event_name, p_event_type,
            p_event_date, p_max_participants, 'Planned', p_description,
            SYS_CONTEXT('USERENV','SESSION_USER'), SYSDATE
        ) RETURNING event_id INTO v_event_id;

        COMMIT;
        RETURN v_event_id;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20202, 'Error creating event: ' || SQLERRM);
    END create_event;

    -- Update event status
    PROCEDURE update_event_status(
        p_event_id IN NUMBER,
        p_status IN VARCHAR2
    ) IS
        v_current_status VARCHAR2(20);
        v_event_date DATE;
    BEGIN
        -- Get current status and event date
        SELECT status, event_date INTO v_current_status, v_event_date
        FROM EVENT
        WHERE event_id = p_event_id
        FOR UPDATE;

        -- Validate status transition
        CASE p_status
            WHEN 'Active' THEN
                IF v_current_status != 'Planned' THEN
                    RAISE_APPLICATION_ERROR(-20203, 'Event must be in Planned status to activate');
                END IF;
            WHEN 'Completed' THEN
                IF v_current_status != 'Active' OR v_event_date > SYSDATE THEN
                    RAISE_APPLICATION_ERROR(-20204, 'Event must be Active and past event date to complete');
                END IF;
            WHEN 'Cancelled' THEN
                IF v_current_status IN ('Completed', 'Cancelled') THEN
                    RAISE_APPLICATION_ERROR(-20205, 'Cannot cancel completed or cancelled event');
                END IF;
            ELSE
                RAISE_APPLICATION_ERROR(-20206, 'Invalid status');
        END CASE;

        -- Update event status
        UPDATE EVENT
        SET status = p_status,
            modified_by = SYS_CONTEXT('USERENV','SESSION_USER'),
            modified_date = SYSDATE
        WHERE event_id = p_event_id;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20207, 'Error updating event status: ' || SQLERRM);
    END update_event_status;

    -- Register participant
    PROCEDURE register_participant(
        p_event_id IN NUMBER,
        p_user_id IN NUMBER,
        p_role IN VARCHAR2
    ) IS
    BEGIN
        -- Check if registration is possible
        IF NOT can_register(p_event_id, p_user_id) THEN
            RAISE_APPLICATION_ERROR(-20208, 'Cannot register for this event');
        END IF;

        -- Register participant
        INSERT INTO EVENT_PARTICIPANT (
            participation_id, event_id, user_id,
            registration_date, status, role,
            created_by, created_date
        ) VALUES (
            seq_participation_id.NEXTVAL, p_event_id, p_user_id,
            SYSDATE, 'Registered', p_role,
            SYS_CONTEXT('USERENV','SESSION_USER'), SYSDATE
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20209, 'Error registering participant: ' || SQLERRM);
    END register_participant;

    -- Update participant status
    PROCEDURE update_participant_status(
        p_event_id IN NUMBER,
        p_user_id IN NUMBER,
        p_status IN VARCHAR2
    ) IS
    BEGIN
        UPDATE EVENT_PARTICIPANT
        SET status = p_status,
            modified_by = SYS_CONTEXT('USERENV','SESSION_USER'),
            modified_date = SYSDATE
        WHERE event_id = p_event_id
        AND user_id = p_user_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20210, 'Participant not found');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20211, 'Error updating participant status: ' || SQLERRM);
    END update_participant_status;

    -- Check if event is full
    FUNCTION is_event_full(
        p_event_id IN NUMBER
    ) RETURN BOOLEAN IS
        v_current_count NUMBER;
        v_max_participants NUMBER;
    BEGIN
        SELECT COUNT(*), e.max_participants
        INTO v_current_count, v_max_participants
        FROM EVENT_PARTICIPANT ep
        JOIN EVENT e ON ep.event_id = e.event_id
        WHERE ep.event_id = p_event_id
        AND ep.status = 'Registered'
        GROUP BY e.max_participants;

        RETURN v_current_count >= v_max_participants;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END is_event_full;

    -- Check if user can register
    FUNCTION can_register(
        p_event_id IN NUMBER,
        p_user_id IN NUMBER
    ) RETURN BOOLEAN IS
        v_event_status VARCHAR2(20);
        v_event_date DATE;
        v_already_registered NUMBER;
    BEGIN
        -- Get event details
        SELECT status, event_date INTO v_event_status, v_event_date
        FROM EVENT
        WHERE event_id = p_event_id;

        -- Check if already registered
        SELECT COUNT(*) INTO v_already_registered
        FROM EVENT_PARTICIPANT
        WHERE event_id = p_event_id
        AND user_id = p_user_id;

        RETURN v_event_status = 'Planned'
           AND v_event_date > SYSDATE
           AND v_already_registered = 0
           AND NOT is_event_full(p_event_id);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END can_register;

    -- Get event participants
    FUNCTION get_event_participants(
        p_event_id IN NUMBER
    ) RETURN SYS_REFCURSOR IS
        v_result SYS_REFCURSOR;
    BEGIN
        OPEN v_result FOR
            SELECT ep.participation_id, ep.user_id,
                   u.first_name || ' ' || u.last_name as participant_name,
                   ep.registration_date, ep.status, ep.role
            FROM EVENT_PARTICIPANT ep
            JOIN "USER" u ON ep.user_id = u.user_id
            WHERE ep.event_id = p_event_id
            ORDER BY ep.registration_date;

        RETURN v_result;
    END get_event_participants;

    -- Get user events
    FUNCTION get_user_events(
        p_user_id IN NUMBER,
        p_start_date IN DATE DEFAULT SYSDATE,
        p_end_date IN DATE DEFAULT SYSDATE + 30
    ) RETURN SYS_REFCURSOR IS
        v_result SYS_REFCURSOR;
    BEGIN
        OPEN v_result FOR
            SELECT e.event_id, e.event_name, e.event_type,
                   e.event_date, e.status as event_status,
                   ep.status as participation_status,
                   ep.role, g.garden_name
            FROM EVENT e
            JOIN EVENT_PARTICIPANT ep ON e.event_id = ep.event_id
            JOIN GARDEN g ON e.garden_id = g.garden_id
            WHERE ep.user_id = p_user_id
            AND e.event_date BETWEEN p_start_date AND p_end_date
            ORDER BY e.event_date;

        RETURN v_result;
    END get_user_events;
END event_mgmt;
/

-- Exit
EXIT; 