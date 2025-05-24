# Process Relationships Documentation

## Overview
This document describes the relationships between different business processes in the Community Garden Management System. The relationships are visualized in `process_relationships.puml`.

## Process Interactions

### 1. Plot Management Relationships
- **With Resource Management**
  - Requires resources for plot maintenance
  - Tracks resource allocation per plot
  - Monitors resource usage efficiency
  
- **With User Management**
  - Plot assignment to users
  - User permissions for plot access
  - Plot maintenance responsibility tracking
  
- **With Event Management**
  - Plots can host events
  - Plot-specific workshops or training
  - Harvest celebrations

### 2. Resource Management Relationships
- **With Plot Management**
  - Allocates resources to plots
  - Monitors plot-specific resource usage
  - Manages resource thresholds per plot
  
- **With User Management**
  - Tracks user resource usage
  - Manages user resource quotas
  - Resource access permissions
  
- **With Event Management**
  - Resource allocation for events
  - Event-specific resource tracking
  - Resource usage reporting

### 3. Event Management Relationships
- **With Plot Management**
  - Events linked to specific plots
  - Plot-based activity scheduling
  - Maintenance event coordination
  
- **With Resource Management**
  - Event resource requirements
  - Resource reservation for events
  - Post-event resource accounting
  
- **With User Management**
  - Event participation tracking
  - Organizer assignments
  - Attendance management

### 4. User Management Relationships
- **With All Processes**
  - Authentication and authorization
  - Activity tracking
  - Performance monitoring
  - Role-based access control

## Entity Relationships

### 1. Plot Entity
- **With User Entity**: One-to-many (One user can manage multiple plots)
- **With Resource Entity**: Many-to-many (Plots use multiple resources)
- **With Event Entity**: One-to-many (Plots can host multiple events)

### 2. Resource Entity
- **With User Entity**: Many-to-many (Resources used by multiple users)
- **With Plot Entity**: Many-to-many (Resources allocated to multiple plots)
- **With Event Entity**: Many-to-many (Resources used in multiple events)

### 3. Event Entity
- **With User Entity**: Many-to-many (Events have multiple participants)
- **With Plot Entity**: Many-to-one (Events associated with specific plots)
- **With Resource Entity**: Many-to-many (Events use multiple resources)

### 4. User Entity
- **With Plot Entity**: One-to-many (Users assigned to multiple plots)
- **With Resource Entity**: Many-to-many (Users access multiple resources)
- **With Event Entity**: Many-to-many (Users participate in multiple events)

## Process Dependencies

### Critical Dependencies
1. User Management is a prerequisite for all other processes
2. Resource Management affects all resource-consuming processes
3. Plot Management depends on both User and Resource Management
4. Event Management depends on all other processes

### Data Flow Dependencies
1. User → Plot → Resource
2. User → Event → Resource
3. Plot → Event
4. Resource → Plot/Event

## Integration Points

### System Integration
1. Authentication system integrates with all processes
2. Resource tracking system connects all resource usage
3. Event system coordinates with all other modules
4. Reporting system aggregates data across processes

### External Integration
1. Weather service integration affects multiple processes
2. Payment processing spans across processes
3. Notification system connects all processes
4. External reporting integrates across processes 