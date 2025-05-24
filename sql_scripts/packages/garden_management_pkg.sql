-- Garden Management Package
-- Run as cgms_owner

CREATE OR REPLACE PACKAGE garden_mgmt AS
    -- Error codes: -20601 to -20699
    
    -- Functions
    FUNCTION get_garden_stats(p_garden_id IN NUMBER) RETURN SYS_REFCURSOR;
    FUNCTION get_available_plots(p_garden_id IN NUMBER) RETURN SYS_REFCURSOR;
    FUNCTION get_user_plots(p_user_id IN NUMBER) RETURN SYS_REFCURSOR;
    
    -- Procedures
    PROCEDURE assign_plot(
        p_plot_id IN NUMBER,
        p_user_id IN NUMBER,
        p_start_date IN DATE,
        p_end_date IN DATE
    );
    
    PROCEDURE release_plot(
        p_plot_id IN NUMBER,
        p_user_id IN NUMBER
    );
END garden_mgmt;
/

CREATE OR REPLACE PACKAGE BODY garden_mgmt AS
    -- Implementation of get_garden_stats
    FUNCTION get_garden_stats(p_garden_id IN NUMBER) RETURN SYS_REFCURSOR IS
        v_result SYS_REFCURSOR;
    BEGIN
        OPEN v_result FOR
            SELECT g.garden_name,
                   g.total_plots,
                   g.available_plots,
                   COUNT(DISTINCT p.plot_id) as total_active_plots,
                   COUNT(DISTINCT pa.user_id) as total_gardeners,
                   COUNT(DISTINCT e.event_id) as total_events
            FROM GARDEN g
            LEFT JOIN PLOT p ON g.garden_id = p.garden_id
            LEFT JOIN PLOT_ASSIGNMENT pa ON p.plot_id = pa.plot_id AND pa.status = 'Active'
            LEFT JOIN EVENT e ON g.garden_id = e.garden_id AND e.status = 'Active'
            WHERE g.garden_id = p_garden_id
            GROUP BY g.garden_name, g.total_plots, g.available_plots;

        RETURN v_result;
    END get_garden_stats;

    -- Implementation of get_available_plots
    FUNCTION get_available_plots(p_garden_id IN NUMBER) RETURN SYS_REFCURSOR IS
        v_result SYS_REFCURSOR;
    BEGIN
        OPEN v_result FOR
            SELECT p.plot_id,
                   p.plot_number,
                   p.size,
                   p.location,
                   p.type,
                   p.status
            FROM PLOT p
            WHERE p.garden_id = p_garden_id
            AND p.status = 'Available'
            ORDER BY p.plot_number;

        RETURN v_result;
    END get_available_plots;

    -- Implementation of get_user_plots
    FUNCTION get_user_plots(p_user_id IN NUMBER) RETURN SYS_REFCURSOR IS
        v_result SYS_REFCURSOR;
    BEGIN
        OPEN v_result FOR
            SELECT g.garden_name,
                   p.plot_number,
                   p.size,
                   p.location,
                   pa.start_date,
                   pa.end_date,
                   pa.status
            FROM PLOT_ASSIGNMENT pa
            JOIN PLOT p ON pa.plot_id = p.plot_id
            JOIN GARDEN g ON p.garden_id = g.garden_id
            WHERE pa.user_id = p_user_id
            AND pa.status = 'Active'
            ORDER BY g.garden_name, p.plot_number;

        RETURN v_result;
    END get_user_plots;

    -- Implementation of assign_plot
    PROCEDURE assign_plot(
        p_plot_id IN NUMBER,
        p_user_id IN NUMBER,
        p_start_date IN DATE,
        p_end_date IN DATE
    ) IS
        v_weekend NUMBER;
        v_holiday NUMBER;
        v_plot_status VARCHAR2(20);
    BEGIN
        -- Check if date is weekend
        SELECT COUNT(*) INTO v_weekend
        FROM DUAL
        WHERE TO_CHAR(p_start_date, 'DY') IN ('SAT', 'SUN');

        -- Check if date is holiday
        SELECT COUNT(*) INTO v_holiday
        FROM HOLIDAY
        WHERE holiday_date = p_start_date;

        -- Check plot status
        SELECT status INTO v_plot_status
        FROM PLOT
        WHERE plot_id = p_plot_id;

        -- Validate conditions
        IF v_weekend > 0 THEN
            RAISE_APPLICATION_ERROR(-20601, 'Cannot assign plots on weekends');
        ELSIF v_holiday > 0 THEN
            RAISE_APPLICATION_ERROR(-20602, 'Cannot assign plots on holidays');
        ELSIF v_plot_status != 'Available' THEN
            RAISE_APPLICATION_ERROR(-20603, 'Plot is not available for assignment');
        END IF;

        -- Proceed with assignment
        INSERT INTO PLOT_ASSIGNMENT (
            plot_id,
            user_id,
            start_date,
            end_date,
            status,
            created_date,
            created_by
        ) VALUES (
            p_plot_id,
            p_user_id,
            p_start_date,
            p_end_date,
            'Active',
            SYSDATE,
            USER
        );

        -- Update plot status
        UPDATE PLOT
        SET status = 'Assigned',
            last_updated_date = SYSDATE,
            last_updated_by = USER
        WHERE plot_id = p_plot_id;

        -- Log the action
        INSERT INTO AUDIT_LOG (
            action_type,
            table_name,
            record_id,
            action_date,
            action_by,
            action_details
        ) VALUES (
            'PLOT_ASSIGNMENT',
            'PLOT',
            p_plot_id,
            SYSDATE,
            USER,
            'Plot assigned to user ' || p_user_id
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END assign_plot;

    -- Implementation of release_plot
    PROCEDURE release_plot(
        p_plot_id IN NUMBER,
        p_user_id IN NUMBER
    ) IS
        v_assignment_exists NUMBER;
    BEGIN
        -- Check if assignment exists
        SELECT COUNT(*)
        INTO v_assignment_exists
        FROM PLOT_ASSIGNMENT
        WHERE plot_id = p_plot_id
        AND user_id = p_user_id
        AND status = 'Active';

        IF v_assignment_exists = 0 THEN
            RAISE_APPLICATION_ERROR(-20604, 'No active assignment found for this plot and user');
        END IF;

        -- Update assignment status
        UPDATE PLOT_ASSIGNMENT
        SET status = 'Released',
            end_date = SYSDATE,
            last_updated_date = SYSDATE,
            last_updated_by = USER
        WHERE plot_id = p_plot_id
        AND user_id = p_user_id
        AND status = 'Active';

        -- Update plot status
        UPDATE PLOT
        SET status = 'Available',
            last_updated_date = SYSDATE,
            last_updated_by = USER
        WHERE plot_id = p_plot_id;

        -- Log the action
        INSERT INTO AUDIT_LOG (
            action_type,
            table_name,
            record_id,
            action_date,
            action_by,
            action_details
        ) VALUES (
            'PLOT_RELEASE',
            'PLOT',
            p_plot_id,
            SYSDATE,
            USER,
            'Plot released by user ' || p_user_id
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END release_plot;
END garden_mgmt;
/

-- Exit
EXIT; 