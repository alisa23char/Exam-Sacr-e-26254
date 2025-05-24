# Database Normalization Analysis
## Community Garden Management System

### First Normal Form (1NF)
All tables in our schema satisfy 1NF because:
1. Each table has a primary key
2. All columns contain atomic values (no arrays or nested structures)
3. No repeating groups

Example verification:
```sql
-- Gardens table: Primary Key (garden_id)
-- Atomic values: garden_name, location, total_plots, status
CREATE TABLE Gardens (
    garden_id NUMBER PRIMARY KEY,
    garden_name VARCHAR2(100) NOT NULL,
    location VARCHAR2(200) NOT NULL,
    total_plots NUMBER NOT NULL,
    created_date DATE DEFAULT SYSDATE,
    status VARCHAR2(20) CHECK (status IN ('Active', 'Inactive', 'Maintenance'))
);
```

### Second Normal Form (2NF)
All tables satisfy 2NF because:
1. They are in 1NF
2. All non-key attributes are fully dependent on the primary key

Example analysis:
```sql
-- Plot_Plants table demonstrates 2NF:
-- Primary Key: plot_plant_id
-- All attributes (plot_id, plant_id, planting_date, etc.) are fully dependent on plot_plant_id
CREATE TABLE Plot_Plants (
    plot_plant_id NUMBER PRIMARY KEY,
    plot_id NUMBER REFERENCES Plots(plot_id),
    plant_id NUMBER REFERENCES Plants(plant_id),
    planting_date DATE NOT NULL,
    expected_harvest_date DATE,
    status VARCHAR2(20)
);
```

### Third Normal Form (3NF)
All tables satisfy 3NF because:
1. They are in 2NF
2. No transitive dependencies exist
3. All attributes depend on the key, the whole key, and nothing but the key

Example verification:
```sql
-- Resource_Usage table demonstrates 3NF:
-- No transitive dependencies between:
-- - resource_id and resource properties (stored in Resources table)
-- - plot_id and plot properties (stored in Plots table)
-- - user_id and user properties (stored in Users table)
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

### Relationship Analysis

#### One-to-Many Relationships
1. Gardens to Plots
   - One garden can have many plots
   - Implemented through foreign key in Plots table

2. Users to Plot_Assignments
   - One user can have multiple plot assignments
   - Implemented through foreign key in Plot_Assignments table

#### Many-to-Many Relationships
1. Events and Users (through Event_Participants)
   ```sql
   CREATE TABLE Event_Participants (
       participation_id NUMBER PRIMARY KEY,
       event_id NUMBER REFERENCES Events(event_id),
       user_id NUMBER REFERENCES Users(user_id),
       registration_date DATE DEFAULT SYSDATE,
       status VARCHAR2(20)
   );
   ```

2. Plots and Plants (through Plot_Plants)
   ```sql
   CREATE TABLE Plot_Plants (
       plot_plant_id NUMBER PRIMARY KEY,
       plot_id NUMBER REFERENCES Plots(plot_id),
       plant_id NUMBER REFERENCES Plants(plant_id),
       planting_date DATE NOT NULL,
       expected_harvest_date DATE,
       status VARCHAR2(20)
   );
   ```

### Normalization Verification Checklist

#### 1. No Redundant Data
- Each entity has its own table
- Lookup tables used for common values
- Foreign keys used to establish relationships

#### 2. Referential Integrity
- All foreign keys properly defined
- Relationships maintained through constraints
- No orphaned records possible

#### 3. Data Consistency
- Status values controlled through CHECK constraints
- Default values defined where appropriate
- NOT NULL constraints applied to required fields

### Potential Denormalization Considerations

While the schema is fully normalized, certain scenarios might benefit from controlled denormalization:

1. Resource Status Calculation
   - Currently computed in functions
   - Could be materialized for performance if needed

2. User Activity Summary
   - Currently calculated through joins
   - Could be summarized in a materialized view

### Conclusion
The current database schema satisfies all three normal forms while maintaining:
1. Data integrity through proper constraints
2. Efficient relationships through appropriate keys
3. Minimal redundancy through proper normalization
4. Flexibility for future extensions

No further normalization is required as the schema already meets all normal form requirements up to 3NF. 