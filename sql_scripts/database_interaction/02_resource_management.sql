-- Resource Management Package
-- Run as cgms_owner

CREATE OR REPLACE PACKAGE resource_mgmt AS
    -- Resource Operations
    FUNCTION create_resource(
        p_resource_name IN VARCHAR2,
        p_category IN VARCHAR2,
        p_quantity IN NUMBER,
        p_unit_of_measure IN VARCHAR2,
        p_minimum_threshold IN NUMBER
    ) RETURN NUMBER;

    PROCEDURE update_resource_quantity(
        p_resource_id IN NUMBER,
        p_quantity_change IN NUMBER
    );

    PROCEDURE check_resource_thresholds;

    -- Resource Usage Operations
    PROCEDURE record_resource_usage(
        p_resource_id IN NUMBER,
        p_plot_id IN NUMBER,
        p_user_id IN NUMBER,
        p_quantity IN NUMBER,
        p_purpose IN VARCHAR2
    );

    -- Reporting Functions
    FUNCTION get_resource_availability(
        p_resource_id IN NUMBER
    ) RETURN NUMBER;

    FUNCTION get_resource_usage_history(
        p_resource_id IN NUMBER,
        p_start_date IN DATE,
        p_end_date IN DATE
    ) RETURN SYS_REFCURSOR;

    -- Validation Functions
    FUNCTION is_resource_available(
        p_resource_id IN NUMBER,
        p_quantity_needed IN NUMBER
    ) RETURN BOOLEAN;
END resource_mgmt;
/

CREATE OR REPLACE PACKAGE BODY resource_mgmt AS
    -- Create a new resource
    FUNCTION create_resource(
        p_resource_name IN VARCHAR2,
        p_category IN VARCHAR2,
        p_quantity IN NUMBER,
        p_unit_of_measure IN VARCHAR2,
        p_minimum_threshold IN NUMBER
    ) RETURN NUMBER IS
        v_resource_id NUMBER;
        v_status VARCHAR2(20);
    BEGIN
        -- Determine initial status
        v_status := CASE
            WHEN p_quantity = 0 THEN 'Depleted'
            WHEN p_quantity <= p_minimum_threshold THEN 'Low'
            ELSE 'Available'
        END;

        INSERT INTO RESOURCE (
            resource_id, resource_name, category,
            quantity_available, unit_of_measure,
            minimum_threshold, status,
            created_by, created_date
        ) VALUES (
            seq_resource_id.NEXTVAL, p_resource_name, p_category,
            p_quantity, p_unit_of_measure,
            p_minimum_threshold, v_status,
            SYS_CONTEXT('USERENV','SESSION_USER'), SYSDATE
        ) RETURNING resource_id INTO v_resource_id;

        COMMIT;
        RETURN v_resource_id;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20101, 'Error creating resource: ' || SQLERRM);
    END create_resource;

    -- Update resource quantity
    PROCEDURE update_resource_quantity(
        p_resource_id IN NUMBER,
        p_quantity_change IN NUMBER
    ) IS
        v_current_quantity NUMBER;
        v_minimum_threshold NUMBER;
        v_new_status VARCHAR2(20);
    BEGIN
        -- Get current quantity and threshold
        SELECT quantity_available, minimum_threshold
        INTO v_current_quantity, v_minimum_threshold
        FROM RESOURCE
        WHERE resource_id = p_resource_id
        FOR UPDATE;

        -- Calculate new quantity
        v_current_quantity := v_current_quantity + p_quantity_change;

        -- Validate new quantity
        IF v_current_quantity < 0 THEN
            RAISE_APPLICATION_ERROR(-20102, 'Insufficient resource quantity');
        END IF;

        -- Determine new status
        v_new_status := CASE
            WHEN v_current_quantity = 0 THEN 'Depleted'
            WHEN v_current_quantity <= v_minimum_threshold THEN 'Low'
            ELSE 'Available'
        END;

        -- Update resource
        UPDATE RESOURCE
        SET quantity_available = v_current_quantity,
            status = v_new_status,
            modified_by = SYS_CONTEXT('USERENV','SESSION_USER'),
            modified_date = SYSDATE
        WHERE resource_id = p_resource_id;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20103, 'Error updating resource quantity: ' || SQLERRM);
    END update_resource_quantity;

    -- Check resource thresholds
    PROCEDURE check_resource_thresholds IS
        CURSOR c_resources IS
            SELECT resource_id, quantity_available, minimum_threshold, status
            FROM RESOURCE
            FOR UPDATE;
    BEGIN
        FOR r IN c_resources LOOP
            IF r.quantity_available <= r.minimum_threshold AND r.status = 'Available' THEN
                UPDATE RESOURCE
                SET status = 'Low',
                    modified_by = SYS_CONTEXT('USERENV','SESSION_USER'),
                    modified_date = SYSDATE
                WHERE CURRENT OF c_resources;
            ELSIF r.quantity_available = 0 AND r.status != 'Depleted' THEN
                UPDATE RESOURCE
                SET status = 'Depleted',
                    modified_by = SYS_CONTEXT('USERENV','SESSION_USER'),
                    modified_date = SYSDATE
                WHERE CURRENT OF c_resources;
            END IF;
        END LOOP;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20104, 'Error checking resource thresholds: ' || SQLERRM);
    END check_resource_thresholds;

    -- Record resource usage
    PROCEDURE record_resource_usage(
        p_resource_id IN NUMBER,
        p_plot_id IN NUMBER,
        p_user_id IN NUMBER,
        p_quantity IN NUMBER,
        p_purpose IN VARCHAR2
    ) IS
    BEGIN
        -- Verify resource availability
        IF NOT is_resource_available(p_resource_id, p_quantity) THEN
            RAISE_APPLICATION_ERROR(-20105, 'Insufficient resource quantity available');
        END IF;

        -- Record usage
        INSERT INTO RESOURCE_USAGE (
            usage_id, resource_id, plot_id, user_id,
            quantity_used, usage_date, purpose,
            created_by, created_date
        ) VALUES (
            seq_usage_id.NEXTVAL, p_resource_id, p_plot_id, p_user_id,
            p_quantity, SYSDATE, p_purpose,
            SYS_CONTEXT('USERENV','SESSION_USER'), SYSDATE
        );

        -- Update resource quantity
        update_resource_quantity(p_resource_id, -p_quantity);

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20106, 'Error recording resource usage: ' || SQLERRM);
    END record_resource_usage;

    -- Get resource availability
    FUNCTION get_resource_availability(
        p_resource_id IN NUMBER
    ) RETURN NUMBER IS
        v_quantity NUMBER;
    BEGIN
        SELECT quantity_available INTO v_quantity
        FROM RESOURCE
        WHERE resource_id = p_resource_id;

        RETURN v_quantity;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END get_resource_availability;

    -- Get resource usage history
    FUNCTION get_resource_usage_history(
        p_resource_id IN NUMBER,
        p_start_date IN DATE,
        p_end_date IN DATE
    ) RETURN SYS_REFCURSOR IS
        v_result SYS_REFCURSOR;
    BEGIN
        OPEN v_result FOR
            SELECT ru.usage_id, ru.plot_id, ru.user_id,
                   ru.quantity_used, ru.usage_date, ru.purpose,
                   u.first_name || ' ' || u.last_name as user_name,
                   p.plot_number
            FROM RESOURCE_USAGE ru
            JOIN "USER" u ON ru.user_id = u.user_id
            JOIN PLOT p ON ru.plot_id = p.plot_id
            WHERE ru.resource_id = p_resource_id
            AND ru.usage_date BETWEEN p_start_date AND p_end_date
            ORDER BY ru.usage_date DESC;

        RETURN v_result;
    END get_resource_usage_history;

    -- Check resource availability
    FUNCTION is_resource_available(
        p_resource_id IN NUMBER,
        p_quantity_needed IN NUMBER
    ) RETURN BOOLEAN IS
        v_available_quantity NUMBER;
    BEGIN
        SELECT quantity_available INTO v_available_quantity
        FROM RESOURCE
        WHERE resource_id = p_resource_id;

        RETURN v_available_quantity >= p_quantity_needed;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END is_resource_available;
END resource_mgmt;
/

-- Exit
EXIT; 