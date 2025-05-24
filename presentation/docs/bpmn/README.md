# Business Process Model and Notation (BPMN) Documentation

This folder contains the business process models for the Community Garden Management System.

## Files Structure

1. `business_processes.md`
   - Comprehensive documentation of all business processes
   - Includes actors, flows, rules, and requirements
   - Serves as the main reference document

2. BPMN Diagrams (PlantUML format)
   - `plot_management.puml`: Plot allocation and maintenance processes
   - `resource_management.puml`: Resource tracking and distribution
   - `event_management.puml`: Event planning and execution
   - `user_management.puml`: User registration and activity tracking

## How to View the Diagrams

These BPMN diagrams are written in PlantUML format and can be rendered using:
1. Online PlantUML server
2. Local PlantUML installation
3. IDE plugins that support PlantUML
4. Converting to other formats using draw.io or Lucidchart

## Process Overview

### Plot Management
- Plot application and approval
- Maintenance tracking
- Compliance monitoring
- Status updates

### Resource Management
- Inventory tracking
- Resource allocation
- Usage monitoring
- Threshold alerts

### Event Management
- Event proposal and approval
- Registration handling
- Attendance tracking
- Feedback collection

### User Management
- Registration process
- Role assignment
- Activity tracking
- Performance monitoring

## Implementation Notes

1. Each diagram follows standard BPMN notation
2. Processes are aligned with database schema
3. Integration points are clearly marked
4. System automated tasks are distinguished from manual tasks

## Maintenance

When updating these processes:
1. Modify the relevant PUML file
2. Update the business_processes.md documentation
3. Ensure changes align with database schema
4. Test process flows for consistency 