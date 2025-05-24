# Community Garden Management System - Database Setup

This directory contains the database setup scripts for the Community Garden Management System. These scripts should be executed in the specified order to create and configure the database environment.

## Prerequisites

- Oracle Database 19c or later
- SYSDBA privileges for initial setup
- Oracle Enterprise Manager (for monitoring setup)

## Script Execution Order

1. `01_create_pdb.sql`
   - Creates the Pluggable Database (PDB)
   - Sets up initial tablespaces
   - Configures basic PDB parameters

2. `02_create_users.sql`
   - Creates application users and roles
   - Implements access control
   - Sets up user profiles and quotas

3. `03_em_setup.sql`
   - Configures Oracle Enterprise Manager
   - Sets up monitoring metrics
   - Creates monitoring jobs and alerts

4. `04_progress_tracking.sql`
   - Implements deployment tracking
   - Creates version control tables
   - Sets up progress monitoring

## Security Notes

- Replace all occurrences of "your_secure_password" with actual secure passwords
- Store passwords in a secure password vault
- Follow the principle of least privilege for user grants
- Enable audit trails for sensitive operations

## Monitoring Setup

The Enterprise Manager configuration includes:
- Custom metrics for garden usage
- Resource depletion alerts
- Automated monitoring jobs
- Performance tracking

## Progress Tracking

The system includes:
- Deployment history tracking
- Schema version control
- Feature deployment monitoring
- Rollback script management

## Post-Installation Steps

1. Verify PDB creation and status
2. Confirm user privileges
3. Test Enterprise Manager connectivity
4. Validate progress tracking functionality

## Troubleshooting

If you encounter issues during setup:
1. Check the alert log for errors
2. Verify SYSDBA privileges
3. Ensure all prerequisites are met
4. Review the deployment history table

## Contact

For support or questions, contact the database administration team.

## Version History

- 1.0.0: Initial database setup
- Future versions will be tracked in the schema_version table 