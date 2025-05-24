-- Event Management Functions
-- Run as cgms_owner

CREATE OR REPLACE FUNCTION get_upcoming_events(
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
/

CREATE OR REPLACE FUNCTION get_event_participants(
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
/

CREATE OR REPLACE FUNCTION check_event_capacity(
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
/

-- Exit 
EXIT; 