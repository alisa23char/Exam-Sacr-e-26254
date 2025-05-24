# Community Garden Management System

A comprehensive PL/SQL-based system for managing community gardens, including plot assignments, resource management, and event coordination.

## Overview

The Community Garden Management System consists of three main packages:

1. Garden Management Package (`garden_mgmt`)
2. Resource Management Package (`resource_mgmt`)
3. Event Management Package (`event_mgmt`)

Each package is designed with comprehensive error handling, security integration, audit logging, and transaction management.

## Package Details

### 1. Garden Management Package (`garden_mgmt`)

Handles garden and plot operations with error codes ranging from -20601 to -20699.

#### Functions:
- `get_garden_stats(p_garden_id)`: Returns garden statistics including total plots, available plots, and active gardeners
- `get_available_plots(p_garden_id)`: Lists all available plots in a garden
- `get_user_plots(p_user_id)`: Returns plots assigned to a specific user

#### Procedures:
- `assign_plot(p_plot_id, p_user_id, p_start_date, p_end_date)`: Assigns a plot to a user
- `release_plot(p_plot_id, p_user_id)`: Releases a plot from a user

### 2. Resource Management Package (`resource_mgmt`)

Manages resources, inventory, and usage tracking with error codes ranging from -20701 to -20799.

#### Functions:
- `get_resource_status(p_garden_id)`: Returns status of all resources in a garden
- `get_resource_history(p_resource_id, p_start_date, p_end_date)`: Shows resource usage history
- `check_resource_availability(p_resource_id, p_quantity, p_start_date, p_end_date)`: Checks if requested quantity is available

#### Procedures:
- `reserve_resource(p_resource_id, p_user_id, p_quantity, p_start_date, p_end_date, p_purpose)`: Reserves resources
- `return_resource(p_reservation_id, p_return_quantity, p_condition_notes)`: Processes resource returns

### 3. Event Management Package (`event_mgmt`)

Handles event creation and management with error codes ranging from -20801 to -20899.

#### Functions:
- `get_upcoming_events(p_garden_id, p_days_ahead)`: Lists upcoming events
- `get_event_participants(p_event_id)`: Returns list of event participants
- `check_event_capacity(p_event_id)`: Checks if event has available capacity

#### Procedures:
- `create_event(p_garden_id, p_event_name, p_event_type, p_start_date, p_end_date, p_max_participants, p_description)`: Creates a new event
- `register_participant(p_event_id, p_user_id, p_notes)`: Registers a participant for an event
- `cancel_registration(p_event_id, p_user_id, p_reason)`: Cancels event registration

## Common Features

All packages include:

- Role-based access control
- Weekend/Holiday restrictions
- Audit trail maintenance
- Detailed logging
- Input validation
- Status tracking
- Transaction safety

## Error Code Ranges

- Garden Management: -20601 to -20699
- Resource Management: -20701 to -20799
- Event Management: -20801 to -20899

## Installation

1. Run the database creation scripts in the following order:
   - `sql_scripts/01_create_database.sql`
   - `sql_scripts/02_create_procedures.sql`
   - `sql_scripts/03_create_triggers.sql`
   - `sql_scripts/04_create_tables_and_data.sql`
   - `sql_scripts/05_insert_holidays.sql`
   - `sql_scripts/06_create_functions.sql`
   - `sql_scripts/07_create_materialized_views.sql`

2. Install the packages in the following order:
   - `sql_scripts/packages/garden_management_pkg.sql`
   - `sql_scripts/packages/resource_management_pkg.sql`
   - `sql_scripts/packages/event_management_pkg.sql`

## Usage Examples

### Garden Management
```sql
-- Get garden statistics
DECLARE
    v_result SYS_REFCURSOR;
BEGIN
    v_result := garden_mgmt.get_garden_stats(1);
    -- Process the cursor
END;

-- Assign a plot
BEGIN
    garden_mgmt.assign_plot(
        p_plot_id => 1,
        p_user_id => 1,
        p_start_date => SYSDATE,
        p_end_date => ADD_MONTHS(SYSDATE, 6)
    );
END;
```

### Resource Management
```sql
-- Reserve resources
BEGIN
    resource_mgmt.reserve_resource(
        p_resource_id => 1,
        p_user_id => 1,
        p_quantity => 2,
        p_start_date => SYSDATE,
        p_end_date => SYSDATE + 7,
        p_purpose => 'Garden maintenance'
    );
END;
```

### Event Management
```sql
-- Create an event
BEGIN
    event_mgmt.create_event(
        p_garden_id => 1,
        p_event_name => 'Spring Planting Workshop',
        p_event_type => 'Workshop',
        p_start_date => SYSDATE + 14,
        p_end_date => SYSDATE + 14 + 4/24, -- 4 hours duration
        p_max_participants => 20,
        p_description => 'Learn spring planting techniques'
    );
END;
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

Conclusion

This documentation represents a partially completed implementation of the required system components. Several critical tasks remain unfinished:

1. The Docker deployment with Traefik load balancing was not fully implemented
2. The TLS encryption with Let's Encrypt configuration remains incomplete
3. Screenshots and validation evidence for the completed tasks are missing
4. The security implementations need further configuration and testing

Additional work is needed to complete these remaining tasks and ensure all components are properly integrated and functioning as required. Future updates should focus on completing these missing elements and providing comprehensive documentation with validation evidence. 