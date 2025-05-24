# Community Garden Management System - Table Implementation

This directory contains the scripts for implementing the physical database structure for the Community Garden Management System.

## Script Overview

1. `01_create_tables.sql`
   - Creates all database tables with proper constraints
   - Implements referential integrity
   - Sets up audit columns
   - Creates sequences for primary keys

2. `02_create_indexes.sql`
   - Creates indexes for performance optimization
   - Includes indexes for foreign keys
   - Implements indexes for frequently queried columns
   - Sets up composite indexes where appropriate

3. `03_insert_sample_data.sql`
   - Inserts initial system administrator
   - Provides sample data for testing
   - Demonstrates proper data relationships
   - Includes examples for all tables

4. `04_validation_tests.sql`
   - Tests data integrity
   - Validates business rules
   - Checks relationships
   - Verifies constraints

## Table Structure

### Primary Tables
- USER: System users and their roles
- GARDEN: Community garden locations
- PLOT: Individual garden plots
- RESOURCE: Shared gardening resources
- PLANT: Plant species information
- EVENT: Community events and workshops

### Junction Tables
- PLOT_ASSIGNMENT: Links plots to users
- PLOT_PLANT: Tracks plants in plots
- RESOURCE_USAGE: Records resource utilization
- EVENT_PARTICIPANT: Manages event attendance

## Implementation Details

### Constraints
- Primary and foreign key constraints
- Check constraints for valid values
- Unique constraints for business rules
- Date range validations

### Indexes
- Primary key indexes (automatic)
- Foreign key indexes
- Performance optimization indexes
- Composite indexes for complex queries

### Audit Columns
All tables include:
- created_by
- created_date
- modified_by
- modified_date

## Testing

The validation tests check:
1. Data Integrity
   - Orphaned records
   - Duplicate entries
   - Referential integrity

2. Business Rules
   - Plot capacity limits
   - Resource thresholds
   - Event participant limits

3. Constraints
   - Valid date ranges
   - Quantity restrictions
   - Status values

## Usage

Execute the scripts in order:
```sql
SQL> @01_create_tables.sql
SQL> @02_create_indexes.sql
SQL> @03_insert_sample_data.sql
SQL> @04_validation_tests.sql
```

## Performance Considerations

- Appropriate index selection
- Partitioning for large tables
- Optimized data types
- Strategic denormalization

## Maintenance

Regular maintenance tasks:
1. Rebuild indexes
2. Update statistics
3. Monitor space usage
4. Review performance metrics

## Troubleshooting

Common issues and solutions:
1. Constraint violations
   - Check data integrity
   - Verify foreign key relationships
   - Review business rules

2. Performance issues
   - Review execution plans
   - Check index usage
   - Analyze query patterns

3. Space management
   - Monitor tablespace usage
   - Check segment growth
   - Review partition statistics 