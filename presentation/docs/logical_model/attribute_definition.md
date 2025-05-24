# Attribute Definitions and Normalization

## Entity Attributes and Constraints

### Garden
| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| garden_id | NUMBER | PK, NOT NULL | Unique identifier for garden |
| garden_name | VARCHAR2(100) | NOT NULL, UNIQUE | Name of the garden |
| location | VARCHAR2(200) | NOT NULL | Physical location |
| total_plots | NUMBER | NOT NULL, CHECK > 0 | Total number of plots |
| created_date | DATE | NOT NULL, DEFAULT SYSDATE | Garden creation date |
| status | VARCHAR2(20) | NOT NULL, CHECK IN ('Active','Inactive','Maintenance') | Current status |

### Plot
| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| plot_id | NUMBER | PK, NOT NULL | Unique identifier for plot |
| garden_id | NUMBER | FK, NOT NULL | Reference to garden |
| plot_number | VARCHAR2(20) | NOT NULL | Plot identifier within garden |
| size | NUMBER | NOT NULL | Size in square meters |
| location | VARCHAR2(100) | NOT NULL | Location within garden |
| status | VARCHAR2(20) | NOT NULL, CHECK IN ('Available','Assigned','Maintenance') | Current status |
| created_date | DATE | NOT NULL, DEFAULT SYSDATE | Plot creation date |

### User
| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| user_id | NUMBER | PK, NOT NULL | Unique identifier for user |
| first_name | VARCHAR2(50) | NOT NULL | User's first name |
| last_name | VARCHAR2(50) | NOT NULL | User's last name |
| email | VARCHAR2(100) | NOT NULL, UNIQUE | Email address |
| phone | VARCHAR2(20) | NOT NULL | Contact number |
| join_date | DATE | NOT NULL, DEFAULT SYSDATE | Membership start date |
| status | VARCHAR2(20) | NOT NULL, CHECK IN ('Active','Inactive','Suspended') | Account status |
| user_type | VARCHAR2(20) | NOT NULL, CHECK IN ('Admin','Member','Volunteer') | User role |

### Resource
| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| resource_id | NUMBER | PK, NOT NULL | Unique identifier for resource |
| resource_name | VARCHAR2(100) | NOT NULL | Name of resource |
| category | VARCHAR2(50) | NOT NULL | Resource category |
| quantity_available | NUMBER | NOT NULL, CHECK >= 0 | Current quantity |
| unit_of_measure | VARCHAR2(20) | NOT NULL | Measurement unit |
| minimum_threshold | NUMBER | NOT NULL, CHECK >= 0 | Reorder threshold |
| status | VARCHAR2(20) | NOT NULL, CHECK IN ('Available','Low','Depleted') | Current status |

### Plant
| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| plant_id | NUMBER | PK, NOT NULL | Unique identifier for plant |
| plant_name | VARCHAR2(100) | NOT NULL | Common name |
| species | VARCHAR2(100) | NOT NULL | Scientific name |
| growing_season | VARCHAR2(50) | NOT NULL | Suitable growing season |
| days_to_harvest | NUMBER | NOT NULL | Expected days to harvest |
| spacing_requirements | VARCHAR2(50) | NOT NULL | Required spacing |
| sunlight_needs | VARCHAR2(50) | NOT NULL | Sunlight requirements |

### Event
| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| event_id | NUMBER | PK, NOT NULL | Unique identifier for event |
| garden_id | NUMBER | FK, NOT NULL | Reference to garden |
| event_name | VARCHAR2(100) | NOT NULL | Event name |
| event_type | VARCHAR2(50) | NOT NULL | Type of event |
| event_date | DATE | NOT NULL | Event date and time |
| max_participants | NUMBER | NOT NULL, CHECK > 0 | Maximum participants |
| status | VARCHAR2(20) | NOT NULL, CHECK IN ('Planned','Active','Completed','Cancelled') | Event status |
| description | VARCHAR2(500) | NOT NULL | Event description |

## Relationship Entities

### PlotAssignment
| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| assignment_id | NUMBER | PK, NOT NULL | Unique identifier |
| plot_id | NUMBER | FK, NOT NULL | Reference to plot |
| user_id | NUMBER | FK, NOT NULL | Reference to user |
| start_date | DATE | NOT NULL | Assignment start date |
| end_date | DATE | NULL | Assignment end date |
| status | VARCHAR2(20) | NOT NULL, CHECK IN ('Active','Expired','Terminated') | Assignment status |

### PlotPlant
| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| plot_plant_id | NUMBER | PK, NOT NULL | Unique identifier |
| plot_id | NUMBER | FK, NOT NULL | Reference to plot |
| plant_id | NUMBER | FK, NOT NULL | Reference to plant |
| planting_date | DATE | NOT NULL | Date planted |
| expected_harvest_date | DATE | NULL | Expected harvest date |
| status | VARCHAR2(20) | NOT NULL, CHECK IN ('Planted','Growing','Harvested','Failed') | Growth status |
| quantity | NUMBER | NOT NULL, CHECK > 0 | Number of plants |

### ResourceUsage
| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| usage_id | NUMBER | PK, NOT NULL | Unique identifier |
| resource_id | NUMBER | FK, NOT NULL | Reference to resource |
| plot_id | NUMBER | FK, NOT NULL | Reference to plot |
| user_id | NUMBER | FK, NOT NULL | Reference to user |
| quantity_used | NUMBER | NOT NULL, CHECK > 0 | Amount used |
| usage_date | DATE | NOT NULL, DEFAULT SYSDATE | Usage date |
| purpose | VARCHAR2(200) | NOT NULL | Usage purpose |

### EventParticipant
| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| participation_id | NUMBER | PK, NOT NULL | Unique identifier |
| event_id | NUMBER | FK, NOT NULL | Reference to event |
| user_id | NUMBER | FK, NOT NULL | Reference to user |
| registration_date | DATE | NOT NULL, DEFAULT SYSDATE | Registration date |
| status | VARCHAR2(20) | NOT NULL, CHECK IN ('Registered','Attended','Cancelled') | Participation status |
| role | VARCHAR2(50) | NOT NULL | Role in event |

## Audit Fields (All Entities)
| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| created_by | NUMBER | FK, NOT NULL | User who created record |
| created_date | DATE | NOT NULL, DEFAULT SYSDATE | Creation timestamp |
| modified_by | NUMBER | FK, NULL | User who last modified |
| modified_date | DATE | NULL | Last modification timestamp | 