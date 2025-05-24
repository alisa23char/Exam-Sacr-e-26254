# Logical Database Model
## Community Garden Management System

### Entity-Relationship Model

#### 1. Gardens
```sql
CREATE TABLE Gardens (
    garden_id NUMBER PRIMARY KEY,
    garden_name VARCHAR2(100) NOT NULL,
    location VARCHAR2(200) NOT NULL,
    total_plots NUMBER NOT NULL,
    created_date DATE DEFAULT SYSDATE,
    status VARCHAR2(20) CHECK (status IN ('Active', 'Inactive', 'Maintenance'))
);
```

#### 2. Plots
```sql
CREATE TABLE Plots (
    plot_id NUMBER PRIMARY KEY,
    garden_id NUMBER REFERENCES Gardens(garden_id),
    plot_number VARCHAR2(20) NOT NULL,
    size_sqft NUMBER NOT NULL,
    status VARCHAR2(20) CHECK (status IN ('Available', 'Assigned', 'Maintenance')),
    UNIQUE (garden_id, plot_number)
);
```

#### 3. Users
```sql
CREATE TABLE Users (
    user_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) UNIQUE NOT NULL,
    phone VARCHAR2(20),
    user_type VARCHAR2(20) CHECK (user_type IN ('Admin', 'Volunteer', 'Gardener')),
    created_date DATE DEFAULT SYSDATE
);
```

#### 4. Plot_Assignments
```sql
CREATE TABLE Plot_Assignments (
    assignment_id NUMBER PRIMARY KEY,
    plot_id NUMBER REFERENCES Plots(plot_id),
    user_id NUMBER REFERENCES Users(user_id),
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR2(20) CHECK (status IN ('Active', 'Expired', 'Terminated')),
    UNIQUE (plot_id, user_id, start_date)
);
```

#### 5. Plants
```sql
CREATE TABLE Plants (
    plant_id NUMBER PRIMARY KEY,
    plant_name VARCHAR2(100) NOT NULL,
    plant_type VARCHAR2(50) NOT NULL,
    growing_season VARCHAR2(50),
    days_to_harvest NUMBER,
    planting_instructions CLOB
);
```

#### 6. Plot_Plants
```sql
CREATE TABLE Plot_Plants (
    plot_plant_id NUMBER PRIMARY KEY,
    plot_id NUMBER REFERENCES Plots(plot_id),
    plant_id NUMBER REFERENCES Plants(plant_id),
    planting_date DATE NOT NULL,
    expected_harvest_date DATE,
    status VARCHAR2(20) CHECK (status IN ('Planted', 'Growing', 'Harvested', 'Failed'))
);
```

#### 7. Resources
```sql
CREATE TABLE Resources (
    resource_id NUMBER PRIMARY KEY,
    resource_name VARCHAR2(100) NOT NULL,
    category VARCHAR2(50) NOT NULL,
    quantity_available NUMBER,
    unit_of_measure VARCHAR2(20),
    status VARCHAR2(20) CHECK (status IN ('Available', 'Low', 'Depleted'))
);
```

#### 8. Resource_Usage
```sql
CREATE TABLE Resource_Usage (
    usage_id NUMBER PRIMARY KEY,
    resource_id NUMBER REFERENCES Resources(resource_id),
    plot_id NUMBER REFERENCES Plots(plot_id),
    user_id NUMBER REFERENCES Users(user_id),
    quantity_used NUMBER NOT NULL,
    usage_date DATE DEFAULT SYSDATE,
    purpose VARCHAR2(200)
);
```

#### 9. Events
```sql
CREATE TABLE Events (
    event_id NUMBER PRIMARY KEY,
    garden_id NUMBER REFERENCES Gardens(garden_id),
    event_name VARCHAR2(100) NOT NULL,
    event_date DATE NOT NULL,
    description CLOB,
    max_participants NUMBER,
    status VARCHAR2(20) CHECK (status IN ('Planned', 'Active', 'Completed', 'Cancelled'))
);
```

#### 10. Event_Participants
```sql
CREATE TABLE Event_Participants (
    participation_id NUMBER PRIMARY KEY,
    event_id NUMBER REFERENCES Events(event_id),
    user_id NUMBER REFERENCES Users(user_id),
    registration_date DATE DEFAULT SYSDATE,
    status VARCHAR2(20) CHECK (status IN ('Registered', 'Attended', 'Cancelled')),
    UNIQUE (event_id, user_id)
);
```

### Indexes
```sql
-- Performance optimization indexes
CREATE INDEX idx_plots_garden ON Plots(garden_id);
CREATE INDEX idx_assignments_plot ON Plot_Assignments(plot_id);
CREATE INDEX idx_assignments_user ON Plot_Assignments(user_id);
CREATE INDEX idx_plot_plants_plot ON Plot_Plants(plot_id);
CREATE INDEX idx_resource_usage_plot ON Resource_Usage(plot_id);
CREATE INDEX idx_events_garden ON Events(garden_id);
CREATE INDEX idx_event_participants_event ON Event_Participants(event_id);
```

### Audit Tables
```sql
-- Example audit table structure (to be implemented for each main table)
CREATE TABLE Gardens_Audit (
    audit_id NUMBER PRIMARY KEY,
    garden_id NUMBER,
    action_type VARCHAR2(10),
    action_date DATE DEFAULT SYSDATE,
    action_by NUMBER,
    old_values CLOB,
    new_values CLOB
);
```

### Notes on Normalization
1. All tables are in 3NF
2. No transitive dependencies
3. All non-key attributes are fully dependent on primary keys
4. Composite keys used where appropriate
5. Referential integrity maintained through foreign keys

### Security Considerations
1. Role-based access control will be implemented
2. Sensitive data will be encrypted
3. Audit trails for all major tables
4. Regular backup procedures 