-- Garden Management Package
-- Run as cgms_owner

CREATE OR REPLACE PACKAGE garden_mgmt AS
    -- Garden Operations
    FUNCTION create_garden(
        p_garden_name IN VARCHAR2,
        p_location IN VARCHAR2,
        p_total_plots IN NUMBER
    ) RETURN NUMBER;

    PROCEDURE update_garden_status(
        p_garden_id IN NUMBER,
        p_status IN VARCHAR2
    );

    -- Plot Operations
    FUNCTION create_plot(
        p_garden_id IN NUMBER,
        p_plot_number IN VARCHAR2,
        p_size IN NUMBER,
        p_location IN VARCHAR2
    ) RETURN NUMBER;

    PROCEDURE assign_plot(
        p_plot_id IN NUMBER,
        p_user_id IN NUMBER,
        p_start_date IN DATE DEFAULT SYSDATE,
        p_end_date IN DATE DEFAULT NULL
    );

    PROCEDURE update_plot_status(
        p_plot_id IN NUMBER,
        p_status IN VARCHAR2
    );

    -- Validation Functions
    FUNCTION is_plot_available(
        p_plot_id IN NUMBER
    ) RETURN BOOLEAN;

    FUNCTION get_plot_assignment_status(
        p_plot_id IN NUMBER
    ) RETURN VARCHAR2;

    -- Reporting Functions
    FUNCTION get_garden_utilization(
        p_garden_id IN NUMBER
    ) RETURN NUMBER;

    FUNCTION get_user_plot_count(
        p_user_id IN NUMBER
    ) RETURN NUMBER;
END garden_mgmt;
/

CREATE OR REPLACE PACKAGE BODY garden_mgmt AS
    -- Create a new garden
    FUNCTION create_garden(
        p_garden_name IN VARCHAR2,
        p_location IN VARCHAR2,
        p_total_plots IN NUMBER
    ) RETURN NUMBER IS
        v_garden_id NUMBER;
    BEGIN
        INSERT INTO GARDEN (
            garden_id, garden_name, location, total_plots,
            status, created_by, created_date
        ) VALUES (
            seq_garden_id.NEXTVAL, p_garden_name, p_location, p_total_plots,
            'Active', SYS_CONTEXT('USERENV','SESSION_USER'), SYSDATE
        ) RETURNING garden_id INTO v_garden_id;

        COMMIT;
        RETURN v_garden_id;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20001, 'Error creating garden: ' || SQLERRM);
    END create_garden;

    -- Update garden status
    PROCEDURE update_garden_status(
        p_garden_id IN NUMBER,
        p_status IN VARCHAR2
    ) IS
    BEGIN
        UPDATE GARDEN
        SET status = p_status,
            modified_by = SYS_CONTEXT('USERENV','SESSION_USER'),
            modified_date = SYSDATE
        WHERE garden_id = p_garden_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Garden not found');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20003, 'Error updating garden status: ' || SQLERRM);
    END update_garden_status;

    -- Create a new plot
    FUNCTION create_plot(
        p_garden_id IN NUMBER,
        p_plot_number IN VARCHAR2,
        p_size IN NUMBER,
        p_location IN VARCHAR2
    ) RETURN NUMBER IS
        v_plot_id NUMBER;
        v_total_plots NUMBER;
        v_current_plots NUMBER;
    BEGIN
        -- Check garden capacity
        SELECT total_plots, (SELECT COUNT(*) FROM PLOT WHERE garden_id = p_garden_id)
        INTO v_total_plots, v_current_plots
        FROM GARDEN
        WHERE garden_id = p_garden_id;

        IF v_current_plots >= v_total_plots THEN
            RAISE_APPLICATION_ERROR(-20004, 'Garden has reached maximum plot capacity');
        END IF;

        INSERT INTO PLOT (
            plot_id, garden_id, plot_number, size,
            location, status, created_by, created_date
        ) VALUES (
            seq_plot_id.NEXTVAL, p_garden_id, p_plot_number, p_size,
            p_location, 'Available', SYS_CONTEXT('USERENV','SESSION_USER'), SYSDATE
        ) RETURNING plot_id INTO v_plot_id;

        COMMIT;
        RETURN v_plot_id;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20005, 'Error creating plot: ' || SQLERRM);
    END create_plot;

    -- Assign plot to user
    PROCEDURE assign_plot(
        p_plot_id IN NUMBER,
        p_user_id IN NUMBER,
        p_start_date IN DATE DEFAULT SYSDATE,
        p_end_date IN DATE DEFAULT NULL
    ) IS
        v_plot_status VARCHAR2(20);
        v_user_plot_count NUMBER;
    BEGIN
        -- Check plot availability
        SELECT status INTO v_plot_status
        FROM PLOT
        WHERE plot_id = p_plot_id;

        IF v_plot_status != 'Available' THEN
            RAISE_APPLICATION_ERROR(-20006, 'Plot is not available for assignment');
        END IF;

        -- Check user's plot limit
        SELECT COUNT(*)
        INTO v_user_plot_count
        FROM PLOT_ASSIGNMENT
        WHERE user_id = p_user_id
        AND status = 'Active';

        IF v_user_plot_count >= 3 THEN
            RAISE_APPLICATION_ERROR(-20007, 'User has reached maximum plot limit');
        END IF;

        -- Create assignment
        INSERT INTO PLOT_ASSIGNMENT (
            assignment_id, plot_id, user_id, start_date, end_date,
            status, created_by, created_date
        ) VALUES (
            seq_assignment_id.NEXTVAL, p_plot_id, p_user_id, p_start_date, p_end_date,
            'Active', SYS_CONTEXT('USERENV','SESSION_USER'), SYSDATE
        );

        -- Update plot status
        UPDATE PLOT
        SET status = 'Assigned',
            modified_by = SYS_CONTEXT('USERENV','SESSION_USER'),
            modified_date = SYSDATE
        WHERE plot_id = p_plot_id;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20008, 'Error assigning plot: ' || SQLERRM);
    END assign_plot;

    -- Update plot status
    PROCEDURE update_plot_status(
        p_plot_id IN NUMBER,
        p_status IN VARCHAR2
    ) IS
    BEGIN
        UPDATE PLOT
        SET status = p_status,
            modified_by = SYS_CONTEXT('USERENV','SESSION_USER'),
            modified_date = SYSDATE
        WHERE plot_id = p_plot_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20009, 'Plot not found');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20010, 'Error updating plot status: ' || SQLERRM);
    END update_plot_status;

    -- Check if plot is available
    FUNCTION is_plot_available(
        p_plot_id IN NUMBER
    ) RETURN BOOLEAN IS
        v_status VARCHAR2(20);
    BEGIN
        SELECT status INTO v_status
        FROM PLOT
        WHERE plot_id = p_plot_id;

        RETURN v_status = 'Available';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END is_plot_available;

    -- Get plot assignment status
    FUNCTION get_plot_assignment_status(
        p_plot_id IN NUMBER
    ) RETURN VARCHAR2 IS
        v_status VARCHAR2(20);
    BEGIN
        SELECT status INTO v_status
        FROM PLOT_ASSIGNMENT
        WHERE plot_id = p_plot_id
        AND status = 'Active';

        RETURN v_status;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_plot_assignment_status;

    -- Calculate garden utilization percentage
    FUNCTION get_garden_utilization(
        p_garden_id IN NUMBER
    ) RETURN NUMBER IS
        v_total_plots NUMBER;
        v_assigned_plots NUMBER;
    BEGIN
        SELECT total_plots INTO v_total_plots
        FROM GARDEN
        WHERE garden_id = p_garden_id;

        SELECT COUNT(*) INTO v_assigned_plots
        FROM PLOT
        WHERE garden_id = p_garden_id
        AND status = 'Assigned';

        RETURN ROUND((v_assigned_plots / v_total_plots) * 100, 2);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END get_garden_utilization;

    -- Get user's plot count
    FUNCTION get_user_plot_count(
        p_user_id IN NUMBER
    ) RETURN NUMBER IS
        v_plot_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_plot_count
        FROM PLOT_ASSIGNMENT
        WHERE user_id = p_user_id
        AND status = 'Active';

        RETURN v_plot_count;
    END get_user_plot_count;
END garden_mgmt;
/

-- Exit
EXIT; 