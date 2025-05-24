# Logical Model Documentation

This directory contains the logical model design for the Community Garden Management System.

## Files Structure

1. `er_model.puml`
   - Entity-Relationship diagram in PlantUML format
   - Shows all entities and their relationships
   - Includes attributes and cardinality

2. `attribute_definition.md`
   - Detailed attribute definitions for all entities
   - Data types and constraints
   - Description of each attribute's purpose
   - Validation rules and business constraints

3. `normalization.md`
   - Normalization analysis (1NF, 2NF, 3NF)
   - Relationship normalization
   - Denormalization considerations
   - Performance optimizations

## Model Overview

### Primary Entities
- Garden
- Plot
- User
- Resource
- Plant
- Event

### Relationship Entities
- PlotAssignment
- PlotPlant
- ResourceUsage
- EventParticipant

## Implementation Notes

### Data Types
- Using Oracle-specific data types
- Appropriate size allocations
- Consideration for international data

### Constraints
- Primary Keys
- Foreign Keys
- Check Constraints
- Unique Constraints
- Default Values

### Performance Features
- Indexes
- Materialized Views
- Partitioning Strategies

## Usage Guidelines

1. Entity-Relationship Model
   - Use PlantUML compatible tools to render
   - Reference for database structure
   - Guide for relationship understanding

2. Attribute Definitions
   - Reference for data validation
   - Guide for application development
   - Basis for database schema creation

3. Normalization Documentation
   - Understanding of data organization
   - Guide for maintaining data integrity
   - Reference for optimization decisions

## Maintenance

When updating the logical model:
1. Update the ER diagram first
2. Modify attribute definitions
3. Review normalization impact
4. Update relevant documentation
5. Consider performance implications 