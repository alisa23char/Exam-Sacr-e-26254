-- Resource Management Procedures
-- Run as cgms_owner

CREATE OR REPLACE PROCEDURE reserve_resource(
    p_resource_id IN NUMBER,
    p_user_id IN NUMBER,
    p_quantity IN NUMBER,
    p_start_date IN DATE,
    p_end_date IN DATE,
    p_purpose IN VARCHAR2
) IS
    v_available NUMBER;
BEGIN
    -- Check availability
    v_available := check_resource_availability(p_resource_id, p_quantity, p_start_date, p_end_date);
    
    IF v_available = 0 THEN
        RAISE_APPLICATION_ERROR(-20701, 'Requested resource quantity not available for the specified period');
    END IF;

    -- Create reservation
    INSERT INTO RESOURCE_RESERVATION (
        resource_id,
        user_id,
        quantity,
        start_date,
        end_date,
        purpose,
        status,
        created_date,
        created_by
    ) VALUES (
        p_resource_id,
        p_user_id,
        p_quantity,
        p_start_date,
        p_end_date,
        p_purpose,
        'Active',
        SYSDATE,
        USER
    );

    -- Update resource available quantity
    UPDATE RESOURCE
    SET available_quantity = available_quantity - p_quantity,
        last_updated_date = SYSDATE,
        last_updated_by = USER
    WHERE resource_id = p_resource_id;

    -- Log the action
    INSERT INTO AUDIT_LOG (
        action_type,
        table_name,
        record_id,
        action_date,
        action_by,
        action_details
    ) VALUES (
        'RESOURCE_RESERVATION',
        'RESOURCE',
        p_resource_id,
        SYSDATE,
        USER,
        'Resource reserved by user ' || p_user_id || ' - Quantity: ' || p_quantity
    );

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END reserve_resource;
/

CREATE OR REPLACE PROCEDURE return_resource(
    p_reservation_id IN NUMBER,
    p_return_quantity IN NUMBER,
    p_condition_notes IN VARCHAR2
) IS
    v_resource_id NUMBER;
    v_original_quantity NUMBER;
    v_returned_quantity NUMBER;
BEGIN
    -- Get reservation details
    SELECT resource_id, quantity, NVL(returned_quantity, 0)
    INTO v_resource_id, v_original_quantity, v_returned_quantity
    FROM RESOURCE_RESERVATION
    WHERE reservation_id = p_reservation_id
    AND status = 'Active'
    FOR UPDATE;

    -- Validate return quantity
    IF (v_returned_quantity + p_return_quantity) > v_original_quantity THEN
        RAISE_APPLICATION_ERROR(-20702, 'Return quantity exceeds original reservation quantity');
    END IF;

    -- Update reservation
    IF (v_returned_quantity + p_return_quantity) = v_original_quantity THEN
        UPDATE RESOURCE_RESERVATION
        SET status = 'Completed',
            returned_quantity = v_original_quantity,
            return_date = SYSDATE,
            condition_notes = p_condition_notes,
            last_updated_date = SYSDATE,
            last_updated_by = USER
        WHERE reservation_id = p_reservation_id;
    ELSE
        UPDATE RESOURCE_RESERVATION
        SET returned_quantity = v_returned_quantity + p_return_quantity,
            condition_notes = p_condition_notes,
            last_updated_date = SYSDATE,
            last_updated_by = USER
        WHERE reservation_id = p_reservation_id;
    END IF;

    -- Update resource quantity
    UPDATE RESOURCE
    SET available_quantity = available_quantity + p_return_quantity,
        last_updated_date = SYSDATE,
        last_updated_by = USER
    WHERE resource_id = v_resource_id;

    -- Log the action
    INSERT INTO AUDIT_LOG (
        action_type,
        table_name,
        record_id,
        action_date,
        action_by,
        action_details
    ) VALUES (
        'RESOURCE_RETURN',
        'RESOURCE',
        v_resource_id,
        SYSDATE,
        USER,
        'Resource returned - Quantity: ' || p_return_quantity || ' - Condition: ' || p_condition_notes
    );

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20703, 'Active reservation not found');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END return_resource;
/

-- Exit
EXIT; 