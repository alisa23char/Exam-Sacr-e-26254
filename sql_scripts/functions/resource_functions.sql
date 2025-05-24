-- Resource Management Functions
-- Run as cgms_owner

CREATE OR REPLACE FUNCTION get_resource_status(
    p_garden_id IN NUMBER
) RETURN SYS_REFCURSOR IS
    v_result SYS_REFCURSOR;
BEGIN
    OPEN v_result FOR
        SELECT r.resource_id,
               r.resource_name,
               r.category,
               r.total_quantity,
               r.available_quantity,
               r.status,
               r.last_maintenance_date,
               r.next_maintenance_date
        FROM RESOURCE r
        WHERE r.garden_id = p_garden_id
        ORDER BY r.category, r.resource_name;

    RETURN v_result;
END get_resource_status;
/

CREATE OR REPLACE FUNCTION get_resource_history(
    p_resource_id IN NUMBER,
    p_start_date IN DATE,
    p_end_date IN DATE
) RETURN SYS_REFCURSOR IS
    v_result SYS_REFCURSOR;
BEGIN
    OPEN v_result FOR
        SELECT rh.action_date,
               rh.action_type,
               rh.quantity,
               rh.status,
               u.user_name as performed_by,
               rh.notes
        FROM RESOURCE_HISTORY rh
        JOIN USERS u ON rh.user_id = u.user_id
        WHERE rh.resource_id = p_resource_id
        AND rh.action_date BETWEEN p_start_date AND p_end_date
        ORDER BY rh.action_date DESC;

    RETURN v_result;
END get_resource_history;
/

CREATE OR REPLACE FUNCTION check_resource_availability(
    p_resource_id IN NUMBER,
    p_quantity IN NUMBER,
    p_start_date IN DATE,
    p_end_date IN DATE
) RETURN NUMBER IS
    v_available NUMBER;
    v_reserved NUMBER;
    v_result NUMBER;
BEGIN
    -- Get current available quantity
    SELECT available_quantity INTO v_available
    FROM RESOURCE
    WHERE resource_id = p_resource_id;

    -- Get total reserved quantity for the period
    SELECT NVL(SUM(quantity), 0) INTO v_reserved
    FROM RESOURCE_RESERVATION
    WHERE resource_id = p_resource_id
    AND status = 'Active'
    AND (
        (start_date BETWEEN p_start_date AND p_end_date)
        OR (end_date BETWEEN p_start_date AND p_end_date)
        OR (start_date <= p_start_date AND end_date >= p_end_date)
    );

    -- Calculate if requested quantity is available
    v_result := CASE
        WHEN (v_available - v_reserved) >= p_quantity THEN 1
        ELSE 0
    END;

    RETURN v_result;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END check_resource_availability;
/

-- Exit 
EXIT; 