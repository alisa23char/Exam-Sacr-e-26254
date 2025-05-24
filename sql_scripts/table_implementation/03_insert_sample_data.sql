-- Insert Sample Data for Community Garden Management System
-- Run as cgms_owner

-- Insert initial admin user (required for audit columns)
INSERT INTO "USER" (
    user_id, first_name, last_name, email, phone,
    join_date, status, user_type, created_date
) VALUES (
    seq_user_id.NEXTVAL, 'System', 'Admin', 'admin@cgms.com', '000-000-0000',
    SYSDATE, 'Active', 'Admin', SYSDATE
);

-- Get the admin user ID for audit columns
DECLARE
    v_admin_id NUMBER;
BEGIN
    SELECT user_id INTO v_admin_id FROM "USER" WHERE email = 'admin@cgms.com';

    -- Insert sample users
    INSERT INTO "USER" (
        user_id, first_name, last_name, email, phone,
        join_date, status, user_type, created_by, created_date
    ) VALUES (
        seq_user_id.NEXTVAL, 'John', 'Doe', 'john.doe@email.com', '123-456-7890',
        SYSDATE, 'Active', 'Member', v_admin_id, SYSDATE
    );

    INSERT INTO "USER" (
        user_id, first_name, last_name, email, phone,
        join_date, status, user_type, created_by, created_date
    ) VALUES (
        seq_user_id.NEXTVAL, 'Jane', 'Smith', 'jane.smith@email.com', '234-567-8901',
        SYSDATE, 'Active', 'Member', v_admin_id, SYSDATE
    );

    -- Insert sample gardens
    INSERT INTO GARDEN (
        garden_id, garden_name, location, total_plots,
        status, created_by, created_date
    ) VALUES (
        seq_garden_id.NEXTVAL, 'Riverside Community Garden',
        '123 River Road', 50, 'Active', v_admin_id, SYSDATE
    );

    INSERT INTO GARDEN (
        garden_id, garden_name, location, total_plots,
        status, created_by, created_date
    ) VALUES (
        seq_garden_id.NEXTVAL, 'Hillside Garden',
        '456 Hill Street', 30, 'Active', v_admin_id, SYSDATE
    );

    -- Insert sample plots
    FOR i IN 1..5 LOOP
        INSERT INTO PLOT (
            plot_id, garden_id, plot_number, size,
            location, status, created_by, created_date
        ) VALUES (
            seq_plot_id.NEXTVAL, 1, 'A' || i, 100,
            'Section A, Plot ' || i, 'Available', v_admin_id, SYSDATE
        );
    END LOOP;

    -- Insert sample resources
    INSERT INTO RESOURCE (
        resource_id, resource_name, category, quantity_available,
        unit_of_measure, minimum_threshold, status, created_by, created_date
    ) VALUES (
        seq_resource_id.NEXTVAL, 'Garden Soil', 'Soil',
        1000, 'kg', 100, 'Available', v_admin_id, SYSDATE
    );

    INSERT INTO RESOURCE (
        resource_id, resource_name, category, quantity_available,
        unit_of_measure, minimum_threshold, status, created_by, created_date
    ) VALUES (
        seq_resource_id.NEXTVAL, 'Watering Can', 'Tools',
        20, 'units', 5, 'Available', v_admin_id, SYSDATE
    );

    -- Insert sample plants
    INSERT INTO PLANT (
        plant_id, plant_name, species, growing_season,
        days_to_harvest, spacing_requirements, sunlight_needs,
        created_by, created_date
    ) VALUES (
        seq_plant_id.NEXTVAL, 'Tomato', 'Solanum lycopersicum',
        'Summer', 80, '45-60cm', 'Full Sun', v_admin_id, SYSDATE
    );

    INSERT INTO PLANT (
        plant_id, plant_name, species, growing_season,
        days_to_harvest, spacing_requirements, sunlight_needs,
        created_by, created_date
    ) VALUES (
        seq_plant_id.NEXTVAL, 'Carrot', 'Daucus carota',
        'Spring-Fall', 70, '5-8cm', 'Full Sun', v_admin_id, SYSDATE
    );

    -- Insert sample events
    INSERT INTO EVENT (
        event_id, garden_id, event_name, event_type,
        event_date, max_participants, status, description,
        created_by, created_date
    ) VALUES (
        seq_event_id.NEXTVAL, 1, 'Spring Planting Workshop',
        'Workshop', SYSDATE + 30, 20, 'Planned',
        'Learn proper planting techniques for spring vegetables',
        v_admin_id, SYSDATE
    );

    -- Insert sample plot assignments
    INSERT INTO PLOT_ASSIGNMENT (
        assignment_id, plot_id, user_id, start_date,
        status, created_by, created_date
    ) VALUES (
        seq_assignment_id.NEXTVAL, 1, 2, SYSDATE,
        'Active', v_admin_id, SYSDATE
    );

    -- Insert sample plot plants
    INSERT INTO PLOT_PLANT (
        plot_plant_id, plot_id, plant_id, planting_date,
        expected_harvest_date, status, quantity,
        created_by, created_date
    ) VALUES (
        seq_plot_plant_id.NEXTVAL, 1, 1, SYSDATE,
        SYSDATE + 80, 'Planted', 3, v_admin_id, SYSDATE
    );

    -- Insert sample resource usage
    INSERT INTO RESOURCE_USAGE (
        usage_id, resource_id, plot_id, user_id,
        quantity_used, usage_date, purpose,
        created_by, created_date
    ) VALUES (
        seq_usage_id.NEXTVAL, 1, 1, 2,
        5, SYSDATE, 'Initial plot preparation',
        v_admin_id, SYSDATE
    );

    -- Insert sample event participants
    INSERT INTO EVENT_PARTICIPANT (
        participation_id, event_id, user_id,
        registration_date, status, role,
        created_by, created_date
    ) VALUES (
        seq_participation_id.NEXTVAL, 1, 2,
        SYSDATE, 'Registered', 'Attendee',
        v_admin_id, SYSDATE
    );

    -- Commit the transaction
    COMMIT;
END;
/

-- Exit 