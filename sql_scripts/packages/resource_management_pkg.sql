-- Resource Management Package
-- Run as cgms_owner

CREATE OR REPLACE PACKAGE resource_mgmt AS
    -- Resource Operations
    PROCEDURE add_resource(
        p_resource_name IN VARCHAR2,
        p_description IN VARCHAR2,
        p_quantity IN NUMBER,
        p_unit IN VARCHAR2,
        p_minimum_threshold IN NUMBER DEFAULT 0
    );

    PROCEDURE update_resource(
        p_resource_id IN NUMBER,
        p_resource_name IN VARCHAR2 DEFAULT NULL,
        p_description IN VARCHAR2 DEFAULT NULL,
        p_quantity IN NUMBER DEFAULT NULL,
        p_unit IN VARCHAR2 DEFAULT NULL,
        p_minimum_threshold IN NUMBER DEFAULT NULL
    );

    PROCEDURE delete_resource(
        p_resource_id IN NUMBER
    );

    -- Resource Usage Operations
    PROCEDURE record_usage(
        p_resource_id IN NUMBER,
        p_user_id IN NUMBER,
        p_plot_id IN NUMBER,
        p_quantity IN NUMBER,
        p_usage_date IN DATE DEFAULT SYSDATE,
        p_notes IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE return_resource(
        p_resource_id IN NUMBER,
        p_quantity IN NUMBER,
        p_notes IN VARCHAR2 DEFAULT NULL
    );

    -- Inventory Management
    PROCEDURE restock_resource(
        p_resource_id IN NUMBER,
        p_quantity IN NUMBER,
        p_supplier IN VARCHAR2 DEFAULT NULL,
        p_notes IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE adjust_inventory(
        p_resource_id IN NUMBER,
        p_adjustment_quantity IN NUMBER,
        p_reason IN VARCHAR2
    );

    -- Reporting Functions
    FUNCTION get_resource_status(
        p_resource_id IN NUMBER
    ) RETURN SYS_REFCURSOR;

    FUNCTION get_usage_history(
        p_resource_id IN NUMBER,
        p_start_date IN DATE DEFAULT TRUNC(SYSDATE) - 30,
        p_end_date IN DATE DEFAULT TRUNC(SYSDATE)
    ) RETURN SYS_REFCURSOR;

    FUNCTION get_low_stock_resources
    RETURN SYS_REFCURSOR;

    -- Error codes: -20701 to -20799
    
    -- Functions
    FUNCTION get_resource_status(p_garden_id IN NUMBER) RETURN SYS_REFCURSOR;
    FUNCTION get_resource_history(
        p_resource_id IN NUMBER,
        p_start_date IN DATE,
        p_end_date IN DATE
    ) RETURN SYS_REFCURSOR;
    FUNCTION check_resource_availability(
        p_resource_id IN NUMBER,
        p_quantity IN NUMBER,
        p_start_date IN DATE,
        p_end_date IN DATE
    ) RETURN NUMBER;
    
    -- Procedures
    PROCEDURE reserve_resource(
        p_resource_id IN NUMBER,
        p_user_id IN NUMBER,
        p_quantity IN NUMBER,
        p_start_date IN DATE,
        p_end_date IN DATE,
        p_purpose IN VARCHAR2
    );
    
    PROCEDURE return_resource(
        p_reservation_id IN NUMBER,
        p_return_quantity IN NUMBER,
        p_condition_notes IN VARCHAR2
    );
END resource_mgmt;
/

CREATE OR REPLACE PACKAGE BODY resource_mgmt AS
    -- Resource Operations
    PROCEDURE add_resource(
        p_resource_name IN VARCHAR2,
        p_description IN VARCHAR2,
        p_quantity IN NUMBER,
        p_unit IN VARCHAR2,
        p_minimum_threshold IN NUMBER DEFAULT 0
    ) IS
    BEGIN
        -- Check access permission
        IF NOT security_mgmt.check_access_permission(
            SYS_CONTEXT('USERENV','SESSION_USER'), 
            'RESOURCE_MANAGEMENT'
        ) THEN
            RAISE_APPLICATION_ERROR(-20701, 'Insufficient privileges to add resource');
        END IF;

        INSERT INTO RESOURCE (
            resource_id,
            resource_name,
            description,
            quantity_available,
            unit,
            minimum_threshold,
            status,
            created_by,
            created_date
        ) VALUES (
            seq_resource_id.NEXTVAL,
            p_resource_name,
            p_description,
            p_quantity,
            p_unit,
            p_minimum_threshold,
            'Active',
            SYS_CONTEXT('USERENV','SESSION_USER'),
            SYSDATE
        );

        -- Log the action
        security_mgmt.log_access_attempt(
            SYS_CONTEXT('USERENV','SESSION_USER'),
            'ADD_RESOURCE',
            p_resource_name,
            'SUCCESS'
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            security_mgmt.log_access_attempt(
                SYS_CONTEXT('USERENV','SESSION_USER'),
                'ADD_RESOURCE',
                p_resource_name,
                'FAILED',
                SQLERRM
            );
            RAISE_APPLICATION_ERROR(-20702, 'Error adding resource: ' || SQLERRM);
    END add_resource;

    PROCEDURE update_resource(
        p_resource_id IN NUMBER,
        p_resource_name IN VARCHAR2 DEFAULT NULL,
        p_description IN VARCHAR2 DEFAULT NULL,
        p_quantity IN NUMBER DEFAULT NULL,
        p_unit IN VARCHAR2 DEFAULT NULL,
        p_minimum_threshold IN NUMBER DEFAULT NULL
    ) IS
        v_resource RESOURCE%ROWTYPE;
    BEGIN
        -- Check access permission
        IF NOT security_mgmt.check_access_permission(
            SYS_CONTEXT('USERENV','SESSION_USER'), 
            'RESOURCE_MANAGEMENT'
        ) THEN
            RAISE_APPLICATION_ERROR(-20703, 'Insufficient privileges to update resource');
        END IF;

        -- Get current resource data
        SELECT * INTO v_resource
        FROM RESOURCE
        WHERE resource_id = p_resource_id
        FOR UPDATE;

        -- Update only provided fields
        UPDATE RESOURCE
        SET resource_name = NVL(p_resource_name, resource_name),
            description = NVL(p_description, description),
            quantity_available = NVL(p_quantity, quantity_available),
            unit = NVL(p_unit, unit),
            minimum_threshold = NVL(p_minimum_threshold, minimum_threshold),
            modified_by = SYS_CONTEXT('USERENV','SESSION_USER'),
            modified_date = SYSDATE
        WHERE resource_id = p_resource_id;

        -- Log the action
        security_mgmt.log_access_attempt(
            SYS_CONTEXT('USERENV','SESSION_USER'),
            'UPDATE_RESOURCE',
            TO_CHAR(p_resource_id),
            'SUCCESS'
        );

        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20704, 'Resource not found');
        WHEN OTHERS THEN
            ROLLBACK;
            security_mgmt.log_access_attempt(
                SYS_CONTEXT('USERENV','SESSION_USER'),
                'UPDATE_RESOURCE',
                TO_CHAR(p_resource_id),
                'FAILED',
                SQLERRM
            );
            RAISE_APPLICATION_ERROR(-20705, 'Error updating resource: ' || SQLERRM);
    END update_resource;

    PROCEDURE delete_resource(
        p_resource_id IN NUMBER
    ) IS
    BEGIN
        -- Check access permission
        IF NOT security_mgmt.check_access_permission(
            SYS_CONTEXT('USERENV','SESSION_USER'), 
            'RESOURCE_MANAGEMENT'
        ) THEN
            RAISE_APPLICATION_ERROR(-20706, 'Insufficient privileges to delete resource');
        END IF;

        -- Check for active usage
        IF EXISTS (
            SELECT 1 FROM RESOURCE_USAGE
            WHERE resource_id = p_resource_id
            AND return_date IS NULL
        ) THEN
            RAISE_APPLICATION_ERROR(-20707, 'Cannot delete resource with active usage');
        END IF;

        -- Soft delete by updating status
        UPDATE RESOURCE
        SET status = 'Inactive',
            modified_by = SYS_CONTEXT('USERENV','SESSION_USER'),
            modified_date = SYSDATE
        WHERE resource_id = p_resource_id;

        -- Log the action
        security_mgmt.log_access_attempt(
            SYS_CONTEXT('USERENV','SESSION_USER'),
            'DELETE_RESOURCE',
            TO_CHAR(p_resource_id),
            'SUCCESS'
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            security_mgmt.log_access_attempt(
                SYS_CONTEXT('USERENV','SESSION_USER'),
                'DELETE_RESOURCE',
                TO_CHAR(p_resource_id),
                'FAILED',
                SQLERRM
            );
            RAISE_APPLICATION_ERROR(-20708, 'Error deleting resource: ' || SQLERRM);
    END delete_resource;

    -- Resource Usage Operations
    PROCEDURE record_usage(
        p_resource_id IN NUMBER,
        p_user_id IN NUMBER,
        p_plot_id IN NUMBER,
        p_quantity IN NUMBER,
        p_usage_date IN DATE DEFAULT SYSDATE,
        p_notes IN VARCHAR2 DEFAULT NULL
    ) IS
        v_available_quantity NUMBER;
    BEGIN
        -- Check access permission
        IF NOT security_mgmt.check_access_permission(
            SYS_CONTEXT('USERENV','SESSION_USER'), 
            'RESOURCE_MANAGEMENT'
        ) THEN
            RAISE_APPLICATION_ERROR(-20709, 'Insufficient privileges to record resource usage');
        END IF;

        -- Check resource availability
        SELECT quantity_available INTO v_available_quantity
        FROM RESOURCE
        WHERE resource_id = p_resource_id
        FOR UPDATE;

        IF v_available_quantity < p_quantity THEN
            RAISE_APPLICATION_ERROR(-20710, 'Insufficient resource quantity available');
        END IF;

        -- Record usage
        INSERT INTO RESOURCE_USAGE (
            usage_id,
            resource_id,
            user_id,
            plot_id,
            quantity,
            usage_date,
            notes,
            created_by,
            created_date
        ) VALUES (
            seq_usage_id.NEXTVAL,
            p_resource_id,
            p_user_id,
            p_plot_id,
            p_quantity,
            p_usage_date,
            p_notes,
            SYS_CONTEXT('USERENV','SESSION_USER'),
            SYSDATE
        );

        -- Update resource quantity
        UPDATE RESOURCE
        SET quantity_available = quantity_available - p_quantity,
            modified_by = SYS_CONTEXT('USERENV','SESSION_USER'),
            modified_date = SYSDATE
        WHERE resource_id = p_resource_id;

        -- Log the action
        security_mgmt.log_access_attempt(
            SYS_CONTEXT('USERENV','SESSION_USER'),
            'RECORD_USAGE',
            TO_CHAR(p_resource_id),
            'SUCCESS'
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            security_mgmt.log_access_attempt(
                SYS_CONTEXT('USERENV','SESSION_USER'),
                'RECORD_USAGE',
                TO_CHAR(p_resource_id),
                'FAILED',
                SQLERRM
            );
            RAISE_APPLICATION_ERROR(-20711, 'Error recording resource usage: ' || SQLERRM);
    END record_usage;

    PROCEDURE return_resource(
        p_resource_id IN NUMBER,
        p_quantity IN NUMBER,
        p_notes IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        -- Check access permission
        IF NOT security_mgmt.check_access_permission(
            SYS_CONTEXT('USERENV','SESSION_USER'), 
            'RESOURCE_MANAGEMENT'
        ) THEN
            RAISE_APPLICATION_ERROR(-20712, 'Insufficient privileges to return resource');
        END IF;

        -- Update resource quantity
        UPDATE RESOURCE
        SET quantity_available = quantity_available + p_quantity,
            modified_by = SYS_CONTEXT('USERENV','SESSION_USER'),
            modified_date = SYSDATE
        WHERE resource_id = p_resource_id;

        -- Log return
        INSERT INTO RESOURCE_RETURN (
            return_id,
            resource_id,
            quantity,
            return_date,
            notes,
            created_by,
            created_date
        ) VALUES (
            seq_return_id.NEXTVAL,
            p_resource_id,
            p_quantity,
            SYSDATE,
            p_notes,
            SYS_CONTEXT('USERENV','SESSION_USER'),
            SYSDATE
        );

        -- Log the action
        security_mgmt.log_access_attempt(
            SYS_CONTEXT('USERENV','SESSION_USER'),
            'RETURN_RESOURCE',
            TO_CHAR(p_resource_id),
            'SUCCESS'
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            security_mgmt.log_access_attempt(
                SYS_CONTEXT('USERENV','SESSION_USER'),
                'RETURN_RESOURCE',
                TO_CHAR(p_resource_id),
                'FAILED',
                SQLERRM
            );
            RAISE_APPLICATION_ERROR(-20713, 'Error returning resource: ' || SQLERRM);
    END return_resource;

    -- Inventory Management
    PROCEDURE restock_resource(
        p_resource_id IN NUMBER,
        p_quantity IN NUMBER,
        p_supplier IN VARCHAR2 DEFAULT NULL,
        p_notes IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        -- Check access permission
        IF NOT security_mgmt.check_access_permission(
            SYS_CONTEXT('USERENV','SESSION_USER'), 
            'RESOURCE_MANAGEMENT'
        ) THEN
            RAISE_APPLICATION_ERROR(-20714, 'Insufficient privileges to restock resource');
        END IF;

        -- Update resource quantity
        UPDATE RESOURCE
        SET quantity_available = quantity_available + p_quantity,
            modified_by = SYS_CONTEXT('USERENV','SESSION_USER'),
            modified_date = SYSDATE
        WHERE resource_id = p_resource_id;

        -- Log restock
        INSERT INTO RESOURCE_RESTOCK (
            restock_id,
            resource_id,
            quantity,
            supplier,
            restock_date,
            notes,
            created_by,
            created_date
        ) VALUES (
            seq_restock_id.NEXTVAL,
            p_resource_id,
            p_quantity,
            p_supplier,
            SYSDATE,
            p_notes,
            SYS_CONTEXT('USERENV','SESSION_USER'),
            SYSDATE
        );

        -- Log the action
        security_mgmt.log_access_attempt(
            SYS_CONTEXT('USERENV','SESSION_USER'),
            'RESTOCK_RESOURCE',
            TO_CHAR(p_resource_id),
            'SUCCESS'
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            security_mgmt.log_access_attempt(
                SYS_CONTEXT('USERENV','SESSION_USER'),
                'RESTOCK_RESOURCE',
                TO_CHAR(p_resource_id),
                'FAILED',
                SQLERRM
            );
            RAISE_APPLICATION_ERROR(-20715, 'Error restocking resource: ' || SQLERRM);
    END restock_resource;

    PROCEDURE adjust_inventory(
        p_resource_id IN NUMBER,
        p_adjustment_quantity IN NUMBER,
        p_reason IN VARCHAR2
    ) IS
    BEGIN
        -- Check access permission
        IF NOT security_mgmt.check_access_permission(
            SYS_CONTEXT('USERENV','SESSION_USER'), 
            'RESOURCE_MANAGEMENT'
        ) THEN
            RAISE_APPLICATION_ERROR(-20716, 'Insufficient privileges to adjust inventory');
        END IF;

        -- Update resource quantity
        UPDATE RESOURCE
        SET quantity_available = quantity_available + p_adjustment_quantity,
            modified_by = SYS_CONTEXT('USERENV','SESSION_USER'),
            modified_date = SYSDATE
        WHERE resource_id = p_resource_id;

        -- Log adjustment
        INSERT INTO RESOURCE_ADJUSTMENT (
            adjustment_id,
            resource_id,
            adjustment_quantity,
            reason,
            adjustment_date,
            created_by,
            created_date
        ) VALUES (
            seq_adjustment_id.NEXTVAL,
            p_resource_id,
            p_adjustment_quantity,
            p_reason,
            SYSDATE,
            SYS_CONTEXT('USERENV','SESSION_USER'),
            SYSDATE
        );

        -- Log the action
        security_mgmt.log_access_attempt(
            SYS_CONTEXT('USERENV','SESSION_USER'),
            'ADJUST_INVENTORY',
            TO_CHAR(p_resource_id),
            'SUCCESS'
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            security_mgmt.log_access_attempt(
                SYS_CONTEXT('USERENV','SESSION_USER'),
                'ADJUST_INVENTORY',
                TO_CHAR(p_resource_id),
                'FAILED',
                SQLERRM
            );
            RAISE_APPLICATION_ERROR(-20717, 'Error adjusting inventory: ' || SQLERRM);
    END adjust_inventory;

    -- Reporting Functions
    FUNCTION get_resource_status(
        p_resource_id IN NUMBER
    ) RETURN SYS_REFCURSOR IS
        v_result SYS_REFCURSOR;
    BEGIN
        OPEN v_result FOR
            SELECT r.resource_name,
                   r.quantity_available,
                   r.unit,
                   r.minimum_threshold,
                   r.status,
                   COUNT(ru.usage_id) as active_usage_count,
                   SUM(ru.quantity) as total_quantity_used
            FROM RESOURCE r
            LEFT JOIN RESOURCE_USAGE ru ON r.resource_id = ru.resource_id
            WHERE r.resource_id = p_resource_id
            GROUP BY r.resource_name, r.quantity_available, r.unit,
                     r.minimum_threshold, r.status;

        RETURN v_result;
    END get_resource_status;

    FUNCTION get_usage_history(
        p_resource_id IN NUMBER,
        p_start_date IN DATE DEFAULT TRUNC(SYSDATE) - 30,
        p_end_date IN DATE DEFAULT TRUNC(SYSDATE)
    ) RETURN SYS_REFCURSOR IS
        v_result SYS_REFCURSOR;
    BEGIN
        OPEN v_result FOR
            SELECT ru.usage_date,
                   u.first_name || ' ' || u.last_name as user_name,
                   p.plot_number,
                   ru.quantity,
                   ru.notes
            FROM RESOURCE_USAGE ru
            JOIN "USER" u ON ru.user_id = u.user_id
            JOIN PLOT p ON ru.plot_id = p.plot_id
            WHERE ru.resource_id = p_resource_id
            AND ru.usage_date BETWEEN p_start_date AND p_end_date
            ORDER BY ru.usage_date DESC;

        RETURN v_result;
    END get_usage_history;

    FUNCTION get_low_stock_resources
    RETURN SYS_REFCURSOR IS
        v_result SYS_REFCURSOR;
    BEGIN
        OPEN v_result FOR
            SELECT resource_name,
                   quantity_available,
                   unit,
                   minimum_threshold,
                   ROUND((quantity_available / NULLIF(minimum_threshold, 0)) * 100, 2) as stock_level_percentage
            FROM RESOURCE
            WHERE quantity_available <= minimum_threshold
            AND status = 'Active'
            ORDER BY stock_level_percentage;

        RETURN v_result;
    END get_low_stock_resources;

    -- Implementation of get_resource_status
    FUNCTION get_resource_status(p_garden_id IN NUMBER) RETURN SYS_REFCURSOR IS
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

    -- Implementation of get_resource_history
    FUNCTION get_resource_history(
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

    -- Implementation of check_resource_availability
    FUNCTION check_resource_availability(
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

    -- Implementation of reserve_resource
    PROCEDURE reserve_resource(
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

    -- Implementation of return_resource
    PROCEDURE return_resource(
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
END resource_mgmt;
/

-- Exit
EXIT; 