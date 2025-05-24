-- Create Indexes for Community Garden Management System
-- Run as cgms_owner

-- User Indexes
CREATE INDEX idx_user_email ON "USER"(email);
CREATE INDEX idx_user_status ON "USER"(status);
CREATE INDEX idx_user_type ON "USER"(user_type);
CREATE INDEX idx_user_name ON "USER"(last_name, first_name);

-- Garden Indexes
CREATE INDEX idx_garden_status ON GARDEN(status);
CREATE INDEX idx_garden_location ON GARDEN(location);

-- Plot Indexes
CREATE INDEX idx_plot_garden ON PLOT(garden_id);
CREATE INDEX idx_plot_status ON PLOT(status);
CREATE INDEX idx_plot_location ON PLOT(location);

-- Resource Indexes
CREATE INDEX idx_resource_category ON RESOURCE(category);
CREATE INDEX idx_resource_status ON RESOURCE(status);
CREATE INDEX idx_resource_name ON RESOURCE(resource_name);

-- Plant Indexes
CREATE INDEX idx_plant_season ON PLANT(growing_season);
CREATE INDEX idx_plant_name ON PLANT(plant_name);
CREATE INDEX idx_plant_species ON PLANT(species);

-- Event Indexes
CREATE INDEX idx_event_garden ON EVENT(garden_id);
CREATE INDEX idx_event_date ON EVENT(event_date);
CREATE INDEX idx_event_status ON EVENT(status);
CREATE INDEX idx_event_type ON EVENT(event_type);

-- Plot Assignment Indexes
CREATE INDEX idx_assignment_plot ON PLOT_ASSIGNMENT(plot_id);
CREATE INDEX idx_assignment_user ON PLOT_ASSIGNMENT(user_id);
CREATE INDEX idx_assignment_dates ON PLOT_ASSIGNMENT(start_date, end_date);
CREATE INDEX idx_assignment_status ON PLOT_ASSIGNMENT(status);

-- Plot Plant Indexes
CREATE INDEX idx_plotplant_plot ON PLOT_PLANT(plot_id);
CREATE INDEX idx_plotplant_plant ON PLOT_PLANT(plant_id);
CREATE INDEX idx_plotplant_dates ON PLOT_PLANT(planting_date, expected_harvest_date);
CREATE INDEX idx_plotplant_status ON PLOT_PLANT(status);

-- Resource Usage Indexes
CREATE INDEX idx_resusage_resource ON RESOURCE_USAGE(resource_id);
CREATE INDEX idx_resusage_plot ON RESOURCE_USAGE(plot_id);
CREATE INDEX idx_resusage_user ON RESOURCE_USAGE(user_id);
CREATE INDEX idx_resusage_date ON RESOURCE_USAGE(usage_date);

-- Event Participant Indexes
CREATE INDEX idx_eventpart_event ON EVENT_PARTICIPANT(event_id);
CREATE INDEX idx_eventpart_user ON EVENT_PARTICIPANT(user_id);
CREATE INDEX idx_eventpart_status ON EVENT_PARTICIPANT(status);
CREATE INDEX idx_eventpart_date ON EVENT_PARTICIPANT(registration_date);

-- Audit Column Indexes
CREATE INDEX idx_garden_audit ON GARDEN(created_by, modified_by);
CREATE INDEX idx_plot_audit ON PLOT(created_by, modified_by);
CREATE INDEX idx_resource_audit ON RESOURCE(created_by, modified_by);
CREATE INDEX idx_plant_audit ON PLANT(created_by, modified_by);
CREATE INDEX idx_event_audit ON EVENT(created_by, modified_by);
CREATE INDEX idx_assignment_audit ON PLOT_ASSIGNMENT(created_by, modified_by);
CREATE INDEX idx_plotplant_audit ON PLOT_PLANT(created_by, modified_by);
CREATE INDEX idx_resusage_audit ON RESOURCE_USAGE(created_by, modified_by);
CREATE INDEX idx_eventpart_audit ON EVENT_PARTICIPANT(created_by, modified_by);

-- Exit
EXIT; 