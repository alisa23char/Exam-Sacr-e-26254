-- Validation Tests for Community Garden Management System
-- Run as cgms_owner

-- Test Package Declaration
CREATE OR REPLACE PACKAGE validation_tests AS
    -- Test data integrity
    PROCEDURE test_data_integrity;
    -- Test business rules
    PROCEDURE test_business_rules;
    -- Test relationships
    PROCEDURE test_relationships;
    -- Test constraints
    PROCEDURE test_constraints;
END validation_tests;
/

-- Test Package Body
CREATE OR REPLACE PACKAGE BODY validation_tests AS
    -- Helper procedure to log test results
    PROCEDURE log_test_result(
        p_test_name IN VARCHAR2,
        p_status IN VARCHAR2,
        p_message IN VARCHAR2
    ) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(
            'Test: ' || p_test_name || 
            ' - Status: ' || p_status || 
            ' - Message: ' || p_message
        );
    END log_test_result;

    -- Test data integrity
    PROCEDURE test_data_integrity IS
        v_count NUMBER;
        v_test_name VARCHAR2(100);
    BEGIN
        -- Test 1: Check for orphaned records in PLOT_ASSIGNMENT
        v_test_name := 'Check Orphaned Plot Assignments';
        SELECT COUNT(*) INTO v_count
        FROM PLOT_ASSIGNMENT pa
        WHERE NOT EXISTS (
            SELECT 1 FROM PLOT p WHERE p.plot_id = pa.plot_id
        ) OR NOT EXISTS (
            SELECT 1 FROM "USER" u WHERE u.user_id = pa.user_id
        );
        
        IF v_count = 0 THEN
            log_test_result(v_test_name, 'PASS', 'No orphaned records found');
        ELSE
            log_test_result(v_test_name, 'FAIL', v_count || ' orphaned records found');
        END IF;

        -- Test 2: Check for duplicate active plot assignments
        v_test_name := 'Check Duplicate Active Plot Assignments';
        SELECT COUNT(*) INTO v_count
        FROM (
            SELECT plot_id, COUNT(*)
            FROM PLOT_ASSIGNMENT
            WHERE status = 'Active'
            GROUP BY plot_id
            HAVING COUNT(*) > 1
        );
        
        IF v_count = 0 THEN
            log_test_result(v_test_name, 'PASS', 'No duplicate active assignments found');
        ELSE
            log_test_result(v_test_name, 'FAIL', v_count || ' plots with multiple active assignments');
        END IF;
    END test_data_integrity;

    -- Test business rules
    PROCEDURE test_business_rules IS
        v_count NUMBER;
        v_test_name VARCHAR2(100);
    BEGIN
        -- Test 1: Check plot capacity rules
        v_test_name := 'Check Plot Capacity Rules';
        SELECT COUNT(*) INTO v_count
        FROM GARDEN g
        WHERE g.total_plots < (
            SELECT COUNT(*) FROM PLOT p WHERE p.garden_id = g.garden_id
        );
        
        IF v_count = 0 THEN
            log_test_result(v_test_name, 'PASS', 'All gardens within plot capacity');
        ELSE
            log_test_result(v_test_name, 'FAIL', v_count || ' gardens exceed plot capacity');
        END IF;

        -- Test 2: Check resource minimum threshold alerts
        v_test_name := 'Check Resource Threshold Rules';
        SELECT COUNT(*) INTO v_count
        FROM RESOURCE
        WHERE quantity_available < minimum_threshold
        AND status != 'Low';
        
        IF v_count = 0 THEN
            log_test_result(v_test_name, 'PASS', 'Resource status correctly reflects threshold');
        ELSE
            log_test_result(v_test_name, 'FAIL', v_count || ' resources need status update');
        END IF;
    END test_business_rules;

    -- Test relationships
    PROCEDURE test_relationships IS
        v_count NUMBER;
        v_test_name VARCHAR2(100);
    BEGIN
        -- Test 1: Check referential integrity
        v_test_name := 'Check Referential Integrity';
        SELECT COUNT(*) INTO v_count
        FROM (
            SELECT plot_id FROM PLOT_PLANT
            MINUS
            SELECT plot_id FROM PLOT
        );
        
        IF v_count = 0 THEN
            log_test_result(v_test_name, 'PASS', 'All relationships maintain referential integrity');
        ELSE
            log_test_result(v_test_name, 'FAIL', v_count || ' integrity violations found');
        END IF;

        -- Test 2: Check event participant limits
        v_test_name := 'Check Event Participant Limits';
        SELECT COUNT(*) INTO v_count
        FROM EVENT e
        WHERE e.max_participants < (
            SELECT COUNT(*) 
            FROM EVENT_PARTICIPANT ep 
            WHERE ep.event_id = e.event_id
            AND ep.status = 'Registered'
        );
        
        IF v_count = 0 THEN
            log_test_result(v_test_name, 'PASS', 'All events within participant limits');
        ELSE
            log_test_result(v_test_name, 'FAIL', v_count || ' events exceed participant limits');
        END IF;
    END test_relationships;

    -- Test constraints
    PROCEDURE test_constraints IS
        v_test_name VARCHAR2(100);
        v_error_caught BOOLEAN;
    BEGIN
        -- Test 1: Check negative quantity constraint
        v_test_name := 'Check Negative Quantity Constraint';
        v_error_caught := FALSE;
        BEGIN
            INSERT INTO RESOURCE (
                resource_id, resource_name, category, quantity_available,
                unit_of_measure, minimum_threshold, status
            ) VALUES (
                seq_resource_id.NEXTVAL, 'Test Resource', 'Test',
                -1, 'units', 0, 'Available'
            );
        EXCEPTION
            WHEN OTHERS THEN
                v_error_caught := TRUE;
        END;
        
        IF v_error_caught THEN
            log_test_result(v_test_name, 'PASS', 'Negative quantity correctly rejected');
        ELSE
            log_test_result(v_test_name, 'FAIL', 'Negative quantity incorrectly accepted');
            ROLLBACK;
        END IF;

        -- Test 2: Check date range constraint
        v_test_name := 'Check Date Range Constraint';
        v_error_caught := FALSE;
        BEGIN
            INSERT INTO PLOT_ASSIGNMENT (
                assignment_id, plot_id, user_id, start_date, end_date,
                status
            ) VALUES (
                seq_assignment_id.NEXTVAL, 1, 1, SYSDATE, SYSDATE-1,
                'Active'
            );
        EXCEPTION
            WHEN OTHERS THEN
                v_error_caught := TRUE;
        END;
        
        IF v_error_caught THEN
            log_test_result(v_test_name, 'PASS', 'Invalid date range correctly rejected');
        ELSE
            log_test_result(v_test_name, 'FAIL', 'Invalid date range incorrectly accepted');
            ROLLBACK;
        END IF;
    END test_constraints;
END validation_tests;
/

-- Run all tests
BEGIN
    DBMS_OUTPUT.PUT_LINE('Starting Validation Tests...');
    DBMS_OUTPUT.PUT_LINE('================================');
    
    DBMS_OUTPUT.PUT_LINE('Data Integrity Tests:');
    validation_tests.test_data_integrity;
    DBMS_OUTPUT.PUT_LINE('--------------------------------');
    
    DBMS_OUTPUT.PUT_LINE('Business Rules Tests:');
    validation_tests.test_business_rules;
    DBMS_OUTPUT.PUT_LINE('--------------------------------');
    
    DBMS_OUTPUT.PUT_LINE('Relationship Tests:');
    validation_tests.test_relationships;
    DBMS_OUTPUT.PUT_LINE('--------------------------------');
    
    DBMS_OUTPUT.PUT_LINE('Constraint Tests:');
    validation_tests.test_constraints;
    DBMS_OUTPUT.PUT_LINE('================================');
    DBMS_OUTPUT.PUT_LINE('Validation Tests Complete.');
END;
/

-- Exit
EXIT; 