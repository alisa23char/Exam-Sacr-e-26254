# Community Garden Management System - Advanced Programming

This directory contains advanced programming features including triggers, auditing system, security restrictions, and access control for the Community Garden Management System.

## Components Overview

### 1. Triggers (`01_triggers.sql`)
Implements database triggers for:
- Audit trail maintenance
- Business rule enforcement
- Resource monitoring
- Event capacity control
- Security enforcement

Key Features:
- Automatic audit trail generation
- Data integrity validation
- Status updates
- Capacity management

### 2. Auditing System (`02_auditing.sql`)
Comprehensive auditing framework including:
- Audit trail configuration
- Detailed change tracking
- Archive management
- Reporting capabilities

Key Components:
- Audit configuration tables
- Archive management
- Retention policies
- Automated maintenance jobs

### 3. Security System (`03_security.sql`)
Advanced security implementation with:
- Role-based access control
- Weekend/Holiday restrictions
- Access logging
- Security monitoring

Key Features:
- Feature-level security
- Time-based access control
- Comprehensive logging
- Permission management

## Usage Examples

### Trigger Implementation
```sql
-- Example of audit trigger usage
INSERT INTO GARDEN (garden_id, garden_name, location)
VALUES (seq_garden_id.NEXTVAL, 'New Garden', 'Location');
-- Automatically creates audit trail entry

-- Example of capacity control
INSERT INTO EVENT_PARTICIPANT (event_id, user_id)
VALUES (1, 1);
-- Automatically checks capacity limits
```

### Auditing System
```sql
-- Configure auditing for a table
BEGIN
    audit_mgmt.configure_auditing(
        p_table_name => 'GARDEN',
        p_audit_level => 'FULL',
        p_retention_days => 90
    );
END;

-- View audit history
SELECT * FROM TABLE(
    audit_mgmt.get_record_history('GARDEN', 1)
);
```

### Security System
```sql
-- Configure feature security
BEGIN
    security_mgmt.configure_feature(
        p_feature_name => 'PLOT_ASSIGNMENT',
        p_min_role_level => 'Member',
        p_weekend_access => 'N',
        p_holiday_access => 'N'
    );
END;

-- Check access permission
IF security_mgmt.check_access_permission(1, 'PLOT_ASSIGNMENT') THEN
    -- Proceed with operation
END IF;
```

## Error Handling

Error code ranges for advanced features:
- Triggers: -20301 to -20399
- Auditing: -20401 to -20499
- Security: -20501 to -20599

## Maintenance

### Daily Tasks
1. Monitor audit trail size
2. Review access logs
3. Check error logs
4. Verify trigger performance

### Weekly Tasks
1. Review security violations
2. Check audit archives
3. Update holiday calendar
4. Analyze access patterns

### Monthly Tasks
1. Review security configurations
2. Clean up old audit records
3. Update access policies
4. Performance optimization

## Security Considerations

1. Access Control
   - Role-based permissions
   - Time-based restrictions
   - Feature-level security
   - Audit trail protection

2. Data Protection
   - Audit trail encryption
   - Access log security
   - Sensitive data handling
   - Archive security

3. Monitoring
   - Security violation alerts
   - Access pattern analysis
   - Audit trail monitoring
   - Performance impact tracking

## Dependencies

These features depend on:
- Base tables and sequences
- User authentication system
- Oracle security framework
- Database job scheduler

## Best Practices

1. Trigger Management
   - Minimize trigger complexity
   - Avoid trigger chains
   - Handle exceptions properly
   - Monitor performance impact

2. Audit Trail
   - Regular archiving
   - Proper retention policies
   - Performance optimization
   - Space management

3. Security Implementation
   - Regular policy reviews
   - Access monitoring
   - Holiday calendar updates
   - Permission audits 