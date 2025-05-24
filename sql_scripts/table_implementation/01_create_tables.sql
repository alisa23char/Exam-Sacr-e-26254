-- Create Tables for Community Garden Management System
-- Run as cgms_owner

-- Enable Foreign Key Constraints
ALTER SESSION SET CONSTRAINTS = IMMEDIATE;

-- Create USER table first since it's referenced by audit columns
CREATE TABLE "USER" (
    user_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) NOT NULL UNIQUE,
    phone VARCHAR2(20) NOT NULL,
    join_date DATE DEFAULT SYSDATE NOT NULL,
    status VARCHAR2(20) CHECK (status IN ('Active','Inactive','Suspended')),
    user_type VARCHAR2(20) CHECK (user_type IN ('Admin','Member','Volunteer')),
    created_by NUMBER,
    created_date DATE DEFAULT SYSDATE NOT NULL,
    modified_by NUMBER,
    modified_date DATE,
    CONSTRAINT fk_user_created_by FOREIGN KEY (created_by) REFERENCES "USER"(user_id),
    CONSTRAINT fk_user_modified_by FOREIGN KEY (modified_by) REFERENCES "USER"(user_id)
);

-- Create GARDEN table
CREATE TABLE GARDEN (
    garden_id NUMBER PRIMARY KEY,
    garden_name VARCHAR2(100) NOT NULL UNIQUE,
    location VARCHAR2(200) NOT NULL,
    total_plots NUMBER NOT NULL CHECK (total_plots > 0),
    created_date DATE DEFAULT SYSDATE NOT NULL,
    status VARCHAR2(20) CHECK (status IN ('Active','Inactive','Maintenance')),
    created_by NUMBER REFERENCES "USER"(user_id),
    modified_by NUMBER REFERENCES "USER"(user_id),
    modified_date DATE
);

-- Create PLOT table
CREATE TABLE PLOT (
    plot_id NUMBER PRIMARY KEY,
    garden_id NUMBER NOT NULL REFERENCES GARDEN(garden_id),
    plot_number VARCHAR2(20) NOT NULL,
    size NUMBER NOT NULL,
    location VARCHAR2(100) NOT NULL,
    status VARCHAR2(20) CHECK (status IN ('Available','Assigned','Maintenance')),
    created_date DATE DEFAULT SYSDATE NOT NULL,
    created_by NUMBER REFERENCES "USER"(user_id),
    modified_by NUMBER REFERENCES "USER"(user_id),
    modified_date DATE,
    CONSTRAINT uk_plot_garden UNIQUE (garden_id, plot_number)
);

-- Create RESOURCE table
CREATE TABLE RESOURCE (
    resource_id NUMBER PRIMARY KEY,
    resource_name VARCHAR2(100) NOT NULL,
    category VARCHAR2(50) NOT NULL,
    quantity_available NUMBER NOT NULL CHECK (quantity_available >= 0),
    unit_of_measure VARCHAR2(20) NOT NULL,
    minimum_threshold NUMBER NOT NULL CHECK (minimum_threshold >= 0),
    status VARCHAR2(20) CHECK (status IN ('Available','Low','Depleted')),
    created_by NUMBER REFERENCES "USER"(user_id),
    modified_by NUMBER REFERENCES "USER"(user_id),
    modified_date DATE
);

-- Create PLANT table
CREATE TABLE PLANT (
    plant_id NUMBER PRIMARY KEY,
    plant_name VARCHAR2(100) NOT NULL,
    species VARCHAR2(100) NOT NULL,
    growing_season VARCHAR2(50) NOT NULL,
    days_to_harvest NUMBER NOT NULL,
    spacing_requirements VARCHAR2(50) NOT NULL,
    sunlight_needs VARCHAR2(50) NOT NULL,
    created_by NUMBER REFERENCES "USER"(user_id),
    modified_by NUMBER REFERENCES "USER"(user_id),
    modified_date DATE
);

-- Create EVENT table
CREATE TABLE EVENT (
    event_id NUMBER PRIMARY KEY,
    garden_id NUMBER NOT NULL REFERENCES GARDEN(garden_id),
    event_name VARCHAR2(100) NOT NULL,
    event_type VARCHAR2(50) NOT NULL,
    event_date DATE NOT NULL,
    max_participants NUMBER NOT NULL CHECK (max_participants > 0),
    status VARCHAR2(20) CHECK (status IN ('Planned','Active','Completed','Cancelled')),
    description VARCHAR2(500) NOT NULL,
    created_by NUMBER REFERENCES "USER"(user_id),
    modified_by NUMBER REFERENCES "USER"(user_id),
    modified_date DATE
);

-- Create PLOT_ASSIGNMENT table
CREATE TABLE PLOT_ASSIGNMENT (
    assignment_id NUMBER PRIMARY KEY,
    plot_id NUMBER NOT NULL REFERENCES PLOT(plot_id),
    user_id NUMBER NOT NULL REFERENCES "USER"(user_id),
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR2(20) CHECK (status IN ('Active','Expired','Terminated')),
    created_by NUMBER REFERENCES "USER"(user_id),
    modified_by NUMBER REFERENCES "USER"(user_id),
    modified_date DATE,
    CONSTRAINT chk_date_range CHECK (end_date IS NULL OR end_date > start_date),
    CONSTRAINT uk_active_plot UNIQUE (plot_id, status) WHERE status = 'Active'
);

-- Create PLOT_PLANT table
CREATE TABLE PLOT_PLANT (
    plot_plant_id NUMBER PRIMARY KEY,
    plot_id NUMBER NOT NULL REFERENCES PLOT(plot_id),
    plant_id NUMBER NOT NULL REFERENCES PLANT(plant_id),
    planting_date DATE NOT NULL,
    expected_harvest_date DATE,
    status VARCHAR2(20) CHECK (status IN ('Planted','Growing','Harvested','Failed')),
    quantity NUMBER NOT NULL CHECK (quantity > 0),
    created_by NUMBER REFERENCES "USER"(user_id),
    modified_by NUMBER REFERENCES "USER"(user_id),
    modified_date DATE,
    CONSTRAINT chk_harvest_date CHECK (expected_harvest_date IS NULL OR expected_harvest_date > planting_date)
);

-- Create RESOURCE_USAGE table
CREATE TABLE RESOURCE_USAGE (
    usage_id NUMBER PRIMARY KEY,
    resource_id NUMBER NOT NULL REFERENCES RESOURCE(resource_id),
    plot_id NUMBER NOT NULL REFERENCES PLOT(plot_id),
    user_id NUMBER NOT NULL REFERENCES "USER"(user_id),
    quantity_used NUMBER NOT NULL CHECK (quantity_used > 0),
    usage_date DATE DEFAULT SYSDATE NOT NULL,
    purpose VARCHAR2(200) NOT NULL,
    created_by NUMBER REFERENCES "USER"(user_id),
    modified_by NUMBER REFERENCES "USER"(user_id),
    modified_date DATE
)
PARTITION BY RANGE (usage_date) (
    PARTITION p_current VALUES LESS THAN (MAXVALUE)
);

-- Create EVENT_PARTICIPANT table
CREATE TABLE EVENT_PARTICIPANT (
    participation_id NUMBER PRIMARY KEY,
    event_id NUMBER NOT NULL REFERENCES EVENT(event_id),
    user_id NUMBER NOT NULL REFERENCES "USER"(user_id),
    registration_date DATE DEFAULT SYSDATE NOT NULL,
    status VARCHAR2(20) CHECK (status IN ('Registered','Attended','Cancelled')),
    role VARCHAR2(50) NOT NULL,
    created_by NUMBER REFERENCES "USER"(user_id),
    modified_by NUMBER REFERENCES "USER"(user_id),
    modified_date DATE,
    CONSTRAINT uk_event_user UNIQUE (event_id, user_id)
);

-- Create sequences for primary keys
CREATE SEQUENCE seq_user_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_garden_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_plot_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_resource_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_plant_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_event_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_assignment_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_plot_plant_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_usage_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_participation_id START WITH 1 INCREMENT BY 1;

-- Exit
EXIT; 