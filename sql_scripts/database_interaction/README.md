# Community Garden Management System - Database Interaction

This directory contains the PL/SQL packages that implement the business logic and data manipulation operations for the Community Garden Management System.

## Package Overview

### 1. Garden Management (`01_garden_management.sql`)
Handles operations related to gardens and plots:
- Garden creation and status updates
- Plot creation and assignment
- Plot status management
- Utilization reporting

Key Features:
- Automatic plot availability tracking
- User plot assignment limits
- Garden utilization calculations
- Plot assignment validation

### 2. Resource Management (`02_resource_management.sql`)
Manages shared gardening resources:
- Resource inventory tracking
- Usage recording
- Threshold monitoring
- Usage history reporting

Key Features:
- Automatic status updates based on quantity
- Resource usage validation
- Low stock alerts
- Usage history tracking

### 3. Event Management (`03_event_management.sql`)
Handles community events and participation:
- Event creation and scheduling
- Participant registration
- Status management
- Attendance tracking

Key Features:
- Event capacity management
- Registration validation
- Status transition rules
- Participant reporting

## Usage Examples

### Garden Management
```sql
-- Create a new garden
DECLARE
    v_garden_id NUMBER;
BEGIN
    v_garden_id := garden_mgmt.create_garden(
        p_garden_name => 'Riverside Garden',
        p_location => '123 River Road',
        p_total_plots => 50
    );
END;

-- Assign a plot
BEGIN
    garden_mgmt.assign_plot(
        p_plot_id => 1,
        p_user_id => 1,
        p_start_date => SYSDATE
    );
END;
```

### Resource Management
```sql
-- Create a new resource
DECLARE
    v_resource_id NUMBER;
BEGIN
    v_resource_id := resource_mgmt.create_resource(
        p_resource_name => 'Garden Soil',
        p_category => 'Soil',
        p_quantity => 1000,
        p_unit_of_measure => 'kg',
        p_minimum_threshold => 100
    );
END;

-- Record resource usage
BEGIN
    resource_mgmt.record_resource_usage(
        p_resource_id => 1,
        p_plot_id => 1,
        p_user_id => 1,
        p_quantity => 5,
        p_purpose => 'Initial plot preparation'
    );
END;
```

### Event Management
```sql
-- Create a new event
DECLARE
    v_event_id NUMBER;
BEGIN
    v_event_id := event_mgmt.create_event(
        p_garden_id => 1,
        p_event_name => 'Spring Planting Workshop',
        p_event_type => 'Workshop',
        p_event_date => SYSDATE + 30,
        p_max_participants => 20,
        p_description => 'Learn proper planting techniques'
    );
END;

-- Register a participant
BEGIN
    event_mgmt.register_participant(
        p_event_id => 1,
        p_user_id => 1,
        p_role => 'Attendee'
    );
END;
```

## Error Handling

All packages implement comprehensive error handling:
- Input validation
- Business rule enforcement
- Transaction management
- Custom error codes and messages

Error Code Ranges:
- Garden Management: -20001 to -20099
- Resource Management: -20100 to -20199
- Event Management: -20200 to -20299

## Best Practices

1. Transaction Management
   - All operations are atomic
   - Automatic rollback on errors
   - Proper COMMIT/ROLLBACK handling

2. Audit Trail
   - All operations track created_by/modified_by
   - Timestamp tracking for all changes
   - Status history maintenance

3. Data Validation
   - Input parameter validation
   - Business rule enforcement
   - Status transition rules
   - Capacity and limit checks

4. Performance Considerations
   - Cursor usage for bulk operations
   - Index-aware queries
   - Proper transaction boundaries
   - Status-based filtering

## Maintenance

Regular maintenance tasks:
1. Review error logs
2. Monitor performance
3. Update business rules
4. Adjust thresholds and limits

## Dependencies

These packages depend on:
- Base tables and sequences
- User authentication system
- Oracle built-in packages
- Custom error handling framework 