-- Garden Management Procedures
-- Run as cgms_owner

CREATE OR REPLACE PROCEDURE assign_plot(
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
/

CREATE OR REPLACE PROCEDURE release_plot(
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
/

-- Exit 