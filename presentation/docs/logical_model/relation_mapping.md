# Relation Mapping

## Primary Relations

### 1. GARDEN
```sql
GARDEN (
    garden_id NUMBER PRIMARY KEY,
    garden_name VARCHAR2(100) NOT NULL UNIQUE,
    location VARCHAR2(200) NOT NULL,
    total_plots NUMBER NOT NULL CHECK (total_plots > 0),
    created_date DATE DEFAULT SYSDATE NOT NULL,
    status VARCHAR2(20) CHECK (status IN ('Active','Inactive','Maintenance')),
    -- Audit columns
    created_by NUMBER REFERENCES USER(user_id),
    modified_by NUMBER REFERENCES USER(user_id),
    modified_date DATE
)
```

### 2. PLOT
```sql
PLOT (
    plot_id NUMBER PRIMARY KEY,
    garden_id NUMBER NOT NULL REFERENCES GARDEN(garden_id),
    plot_number VARCHAR2(20) NOT NULL,
    size NUMBER NOT NULL,
    location VARCHAR2(100) NOT NULL,
    status VARCHAR2(20) CHECK (status IN ('Available','Assigned','Maintenance')),
    created_date DATE DEFAULT SYSDATE NOT NULL,
    -- Audit columns
    created_by NUMBER REFERENCES USER(user_id),
    modified_by NUMBER REFERENCES USER(user_id),
    modified_date DATE,
    -- Composite unique constraint
    CONSTRAINT uk_plot_garden UNIQUE (garden_id, plot_number)
)
```

### 3. USER
```sql
USER (
    user_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) NOT NULL UNIQUE,
    phone VARCHAR2(20) NOT NULL,
    join_date DATE DEFAULT SYSDATE NOT NULL,
    status VARCHAR2(20) CHECK (status IN ('Active','Inactive','Suspended')),
    user_type VARCHAR2(20) CHECK (user_type IN ('Admin','Member','Volunteer')),
    -- Audit columns
    created_by NUMBER REFERENCES USER(user_id),
    modified_by NUMBER REFERENCES USER(user_id),
    modified_date DATE
)
```

### 4. RESOURCE
```sql
RESOURCE (
    resource_id NUMBER PRIMARY KEY,
    resource_name VARCHAR2(100) NOT NULL,
    category VARCHAR2(50) NOT NULL,
    quantity_available NUMBER NOT NULL CHECK (quantity_available >= 0),
    unit_of_measure VARCHAR2(20) NOT NULL,
    minimum_threshold NUMBER NOT NULL CHECK (minimum_threshold >= 0),
    status VARCHAR2(20) CHECK (status IN ('Available','Low','Depleted')),
    -- Audit columns
    created_by NUMBER REFERENCES USER(user_id),
    modified_by NUMBER REFERENCES USER(user_id),
    modified_date DATE
)
```

### 5. PLANT
```sql
PLANT (
    plant_id NUMBER PRIMARY KEY,
    plant_name VARCHAR2(100) NOT NULL,
    species VARCHAR2(100) NOT NULL,
    growing_season VARCHAR2(50) NOT NULL,
    days_to_harvest NUMBER NOT NULL,
    spacing_requirements VARCHAR2(50) NOT NULL,
    sunlight_needs VARCHAR2(50) NOT NULL,
    -- Audit columns
    created_by NUMBER REFERENCES USER(user_id),
    modified_by NUMBER REFERENCES USER(user_id),
    modified_date DATE
)
```

### 6. EVENT
```sql
EVENT (
    event_id NUMBER PRIMARY KEY,
    garden_id NUMBER NOT NULL REFERENCES GARDEN(garden_id),
    event_name VARCHAR2(100) NOT NULL,
    event_type VARCHAR2(50) NOT NULL,
    event_date DATE NOT NULL,
    max_participants NUMBER NOT NULL CHECK (max_participants > 0),
    status VARCHAR2(20) CHECK (status IN ('Planned','Active','Completed','Cancelled')),
    description VARCHAR2(500) NOT NULL,
    -- Audit columns
    created_by NUMBER REFERENCES USER(user_id),
    modified_by NUMBER REFERENCES USER(user_id),
    modified_date DATE
)
```

## Relationship Relations (Junction Tables)

### 1. PLOT_ASSIGNMENT
```sql
PLOT_ASSIGNMENT (
    assignment_id NUMBER PRIMARY KEY,
    plot_id NUMBER NOT NULL REFERENCES PLOT(plot_id),
    user_id NUMBER NOT NULL REFERENCES USER(user_id),
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR2(20) CHECK (status IN ('Active','Expired','Terminated')),
    -- Audit columns
    created_by NUMBER REFERENCES USER(user_id),
    modified_by NUMBER REFERENCES USER(user_id),
    modified_date DATE,
    -- Business rule constraints
    CONSTRAINT chk_date_range CHECK (end_date IS NULL OR end_date > start_date),
    CONSTRAINT uk_active_plot UNIQUE (plot_id, status) 
        WHERE status = 'Active'
)
```

### 2. PLOT_PLANT
```sql
PLOT_PLANT (
    plot_plant_id NUMBER PRIMARY KEY,
    plot_id NUMBER NOT NULL REFERENCES PLOT(plot_id),
    plant_id NUMBER NOT NULL REFERENCES PLANT(plant_id),
    planting_date DATE NOT NULL,
    expected_harvest_date DATE,
    status VARCHAR2(20) CHECK (status IN ('Planted','Growing','Harvested','Failed')),
    quantity NUMBER NOT NULL CHECK (quantity > 0),
    -- Audit columns
    created_by NUMBER REFERENCES USER(user_id),
    modified_by NUMBER REFERENCES USER(user_id),
    modified_date DATE,
    -- Business rule constraints
    CONSTRAINT chk_harvest_date CHECK (
        expected_harvest_date IS NULL OR 
        expected_harvest_date > planting_date
    )
)
```

### 3. RESOURCE_USAGE
```sql
RESOURCE_USAGE (
    usage_id NUMBER PRIMARY KEY,
    resource_id NUMBER NOT NULL REFERENCES RESOURCE(resource_id),
    plot_id NUMBER NOT NULL REFERENCES PLOT(plot_id),
    user_id NUMBER NOT NULL REFERENCES USER(user_id),
    quantity_used NUMBER NOT NULL CHECK (quantity_used > 0),
    usage_date DATE DEFAULT SYSDATE NOT NULL,
    purpose VARCHAR2(200) NOT NULL,
    -- Audit columns
    created_by NUMBER REFERENCES USER(user_id),
    modified_by NUMBER REFERENCES USER(user_id),
    modified_date DATE,
    -- Partition by date for performance
    PARTITION BY RANGE (usage_date) (
        PARTITION p_current VALUES LESS THAN (MAXVALUE)
    )
)
```

### 4. EVENT_PARTICIPANT
```sql
EVENT_PARTICIPANT (
    participation_id NUMBER PRIMARY KEY,
    event_id NUMBER NOT NULL REFERENCES EVENT(event_id),
    user_id NUMBER NOT NULL REFERENCES USER(user_id),
    registration_date DATE DEFAULT SYSDATE NOT NULL,
    status VARCHAR2(20) CHECK (status IN ('Registered','Attended','Cancelled')),
    role VARCHAR2(50) NOT NULL,
    -- Audit columns
    created_by NUMBER REFERENCES USER(user_id),
    modified_by NUMBER REFERENCES USER(user_id),
    modified_date DATE,
    -- Business rule constraints
    CONSTRAINT uk_event_user UNIQUE (event_id, user_id)
)
```

## Indexes

### Primary and Foreign Key Indexes
```sql
-- Automatically created for primary keys
-- Created for foreign keys for performance
CREATE INDEX idx_plot_garden ON PLOT(garden_id);
CREATE INDEX idx_event_garden ON EVENT(garden_id);
CREATE INDEX idx_plotassign_plot ON PLOT_ASSIGNMENT(plot_id);
CREATE INDEX idx_plotassign_user ON PLOT_ASSIGNMENT(user_id);
CREATE INDEX idx_plotplant_plot ON PLOT_PLANT(plot_id);
CREATE INDEX idx_plotplant_plant ON PLOT_PLANT(plant_id);
CREATE INDEX idx_resusage_resource ON RESOURCE_USAGE(resource_id);
CREATE INDEX idx_resusage_plot ON RESOURCE_USAGE(plot_id);
CREATE INDEX idx_resusage_user ON RESOURCE_USAGE(user_id);
CREATE INDEX idx_eventpart_event ON EVENT_PARTICIPANT(event_id);
CREATE INDEX idx_eventpart_user ON EVENT_PARTICIPANT(user_id);
```

### Additional Performance Indexes
```sql
-- Frequently searched columns
CREATE INDEX idx_garden_status ON GARDEN(status);
CREATE INDEX idx_plot_status ON PLOT(status);
CREATE INDEX idx_user_status ON USER(status, user_type);
CREATE INDEX idx_resource_status ON RESOURCE(status);
CREATE INDEX idx_event_date ON EVENT(event_date);
CREATE INDEX idx_plotassign_dates ON PLOT_ASSIGNMENT(start_date, end_date);
CREATE INDEX idx_resusage_date ON RESOURCE_USAGE(usage_date);
```

## Sequences

```sql
-- For generating primary key values
CREATE SEQUENCE seq_garden_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_plot_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_user_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_resource_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_plant_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_event_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_assignment_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_plot_plant_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_usage_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_participation_id START WITH 1 INCREMENT BY 1;
```

## Triggers

### Audit Triggers
```sql
-- Example audit trigger (similar for all tables)
CREATE OR REPLACE TRIGGER trg_garden_audit
BEFORE INSERT OR UPDATE ON GARDEN
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_by := NVL(SYS_CONTEXT('USERENV','OS_USER'), USER);
        :NEW.created_date := SYSDATE;
    END IF;
    IF UPDATING THEN
        :NEW.modified_by := NVL(SYS_CONTEXT('USERENV','OS_USER'), USER);
        :NEW.modified_date := SYSDATE;
    END IF;
END;
/
```

### Business Rule Triggers
```sql
-- Example: Prevent plot assignment if user has reached maximum plots
CREATE OR REPLACE TRIGGER trg_max_plots_per_user
BEFORE INSERT ON PLOT_ASSIGNMENT
FOR EACH ROW
DECLARE
    v_plot_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_plot_count
    FROM PLOT_ASSIGNMENT
    WHERE user_id = :NEW.user_id
    AND status = 'Active';
    
    IF v_plot_count >= 3 THEN
        RAISE_APPLICATION_ERROR(-20001, 'User has reached maximum plot limit');
    END IF;
END;
/
``` 