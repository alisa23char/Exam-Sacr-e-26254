-- Garden Management Functions
-- Run as cgms_owner

CREATE OR REPLACE FUNCTION get_garden_stats(
    p_garden_id IN NUMBER
) RETURN SYS_REFCURSOR IS
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
/

CREATE OR REPLACE FUNCTION get_available_plots(
    p_garden_id IN NUMBER
) RETURN SYS_REFCURSOR IS
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
/

CREATE OR REPLACE FUNCTION get_user_plots(
    p_user_id IN NUMBER
) RETURN SYS_REFCURSOR IS
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
/

-- Exit
EXIT; 