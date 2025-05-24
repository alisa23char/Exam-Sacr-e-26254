# Database Normalization Analysis

## First Normal Form (1NF)
All tables in the database satisfy 1NF requirements:
1. Each table has a primary key
2. All attributes are atomic (no multi-valued attributes)
3. No repeating groups
4. All attributes are scalar values

Example:
```sql
CREATE TABLE User (
    user_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(50),  -- Atomic value
    last_name VARCHAR2(50),   -- Atomic value
    email VARCHAR2(100),      -- Single email per user
    phone VARCHAR2(20)        -- Single phone per user
);
```

## Second Normal Form (2NF)
All tables satisfy 2NF requirements:
1. Tables are in 1NF
2. All non-key attributes are fully functionally dependent on the primary key

Example of 2NF compliance:
- PlotPlant table separates plot-specific and plant-specific attributes
- ResourceUsage table separates resource properties from usage records
- EventParticipant table separates event details from participation records

## Third Normal Form (3NF)
All tables satisfy 3NF requirements:
1. Tables are in 2NF
2. No transitive dependencies
3. All attributes depend on the key, the whole key, and nothing but the key

Examples of 3NF compliance:

### Garden Table
- garden_id → garden_name, location (no transitive dependencies)
- All attributes directly depend on garden_id

### Resource Table
- resource_id → resource_name, category, quantity
- No derived attributes
- Status is determined by business rules, not stored values

## Relationship Normalization

### Many-to-Many Relationships
Properly normalized through junction tables:

1. Plot-Plant Relationship
```sql
CREATE TABLE PlotPlant (
    plot_plant_id NUMBER PRIMARY KEY,
    plot_id NUMBER REFERENCES Plot,
    plant_id NUMBER REFERENCES Plant
);
```

2. Event-User Relationship
```sql
CREATE TABLE EventParticipant (
    participation_id NUMBER PRIMARY KEY,
    event_id NUMBER REFERENCES Event,
    user_id NUMBER REFERENCES User
);
```

### One-to-Many Relationships
Implemented through foreign keys:

1. Garden-Plot Relationship
```sql
CREATE TABLE Plot (
    plot_id NUMBER PRIMARY KEY,
    garden_id NUMBER REFERENCES Garden
);
```

2. User-PlotAssignment Relationship
```sql
CREATE TABLE PlotAssignment (
    assignment_id NUMBER PRIMARY KEY,
    user_id NUMBER REFERENCES User
);
```

## Denormalization Considerations

### Controlled Denormalization
Some calculated values are stored for performance:

1. Resource Status
- Derived from quantity_available and minimum_threshold
- Updated through triggers
- Improves query performance

2. Plot Status
- Derived from assignments and maintenance schedule
- Updated through triggers
- Facilitates faster searches

### Materialized Views
Used for frequently accessed aggregated data:

1. Garden Statistics
```sql
CREATE MATERIALIZED VIEW mv_garden_stats AS
SELECT garden_id,
       COUNT(plot_id) as total_plots,
       SUM(CASE WHEN status = 'Assigned' THEN 1 ELSE 0 END) as assigned_plots
FROM Plot
GROUP BY garden_id;
```

2. Resource Usage Summary
```sql
CREATE MATERIALIZED VIEW mv_resource_usage AS
SELECT resource_id,
       SUM(quantity_used) as total_used,
       COUNT(DISTINCT user_id) as unique_users
FROM ResourceUsage
GROUP BY resource_id;
```

## Data Integrity

### Primary Keys
- All tables have synthetic primary keys
- Using sequences for key generation
- No natural keys used as primary keys

### Foreign Keys
- Proper referential integrity
- ON DELETE restrictions
- ON UPDATE restrictions

### Check Constraints
- Value range validations
- Status value validations
- Date range validations

### Unique Constraints
- Email addresses
- Garden names
- Plot numbers within gardens

## Performance Considerations

### Indexes
1. Primary Key Indexes (automatic)
2. Foreign Key Indexes
3. Frequently Searched Fields
4. Sort Fields

### Partitioning
Considered for:
1. ResourceUsage table (by date)
2. EventParticipant table (by event_date)
3. PlotAssignment history (by year) 