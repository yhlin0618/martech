---
id: "MP01"
title: "Primitive Terms and Definitions"
type: "meta-principle"
date_created: "2025-04-02"
author: "Claude"
derives_from:
  - "MP00": "Axiomatization System"
influences:
  - "P02": "Structural Blueprint"
  - "P03": "Project Principles"
  - "P04": "Script Separation"
  - "MP29": "Terminology Axiomatization"
---

# Primitive Terms and Definitions

This document establishes the fundamental vocabulary of the precision marketing system. It defines the primitive terms upon which all other principles and structures are built, ensuring consistent understanding and usage throughout the codebase.

## Purpose of Primitive Terms

In an axiomatic system, primitive terms are fundamental concepts that cannot be defined in terms of simpler concepts. They form the foundation upon which all other definitions, principles, and structures are built.

This document:
1. Defines the core vocabulary of the system
2. Establishes precise meanings for fundamental concepts
3. Prevents circular definitions
4. Creates a shared understanding across the entire system

## Core Primitive Terms

### System Structure Terms

#### Component
The fundamental unit of modular functionality in the system. A component is a self-contained piece of code that performs a specific function and presents a defined interface for interaction.

#### Module
A collection of related components that work together to provide a cohesive set of functionality.

#### Interface
The defined methods, properties, or contracts through which components communicate and interact with each other.

#### Implementation
The specific code that fulfills the contract defined by an interface.

#### Function
A reusable unit of code that performs a specific task, accepts defined inputs, and produces defined outputs.

#### Library
A collection of related functions that serve a common purpose.

#### Script
An executable sequence of operations that performs a specific task.

### Conceptual Terms

#### Principle Framework Terms

The following terms define the principle classification system:

##### Meta-Principle (MP)
A principle about principles. Meta-principles govern how principles themselves are structured, organized, and related to each other. They are abstract, conceptual, and foundational in nature, establishing the system-wide architecture and organization.

##### Principle (P)
A general rule or guideline that governs system design and implementation decisions. Principles are abstract and conceptual but practically oriented, providing broad implementation patterns and approaches. They are reusable and broadly applicable.

##### Rule (R)
A specific guideline for implementing principles. Rules are concrete, specific, and directly applicable, defining narrow implementation techniques and specific patterns.

##### Instance
A specific implementation of a principle or rule in a particular context. Instances are concrete, context-specific, and directly applicable to a particular situation. Unlike principles, instances are not meant to be reusable across contexts.

#### Axiomatic System Terms

The following terms relate to the formal axiomatic system and how they map to our MP/P/R framework:

##### Axiom
A statement that is accepted as true without proof, serving as a starting point for deriving other truths. In our MP/P/R system, axioms are typically expressed as Meta-Principles (MP).

##### Inference Rule
A logical rule that allows the derivation of new principles from existing ones. In our MP/P/R system, inference rules are typically expressed as certain Meta-Principles (MP) that establish relationships between other principles.

##### Theorem
A derived principle that follows logically from axioms through application of inference rules. In our MP/P/R system, theorems are typically expressed as Principles (P).

##### Corollary
A principle that follows directly from another principle with minimal additional proof. In our MP/P/R system, corollaries are typically expressed as Rules (R).

### Data Terms

#### Data Source
A named reference to a specific dataset used by application components, representing accessible data regardless of physical storage location.

#### Platform
The origin system or channel from which raw data is collected (e.g., Amazon, Official Website).

#### Raw Data
Unprocessed data collected directly from platforms, stored with minimal modifications from its original form.

#### Processed Data
Data that has undergone transformation, cleaning, and integration to make it suitable for use by application components.

#### Data Table
A structured collection of records (typically rows and columns) that can be queried, filtered, and manipulated as a unit.

#### View
A virtual data table defined by a query, presenting data from one or more underlying tables or data sources.

### Application Terms

#### Application
The complete software system that provides functionality to end users.

#### Parameter
A configuration value that controls component behavior. Parameters do not contain records but rather settings that modify functionality.

#### Role
The specific relationship between a data source and a component, defining how the data is used within the component.

## Term Relationships

These primitive terms relate to each other in fundamental ways:

1. **Functions** are combined to create **Components**
2. **Components** are organized into **Modules**
3. **Modules** are integrated to form an **Application**
4. **Interfaces** define how **Components** interact
5. **Implementations** fulfill the contracts defined by **Interfaces**
6. **Principles** guide the creation of **Instances**
7. **Meta-Principles** govern the organization of **Principles**
8. **Platforms** generate **Raw Data**
9. **Raw Data** is transformed into **Processed Data**
10. **Data Sources** provide access to **Processed Data**
11. **Parameters** configure **Component** behavior
12. **Roles** define the purpose of **Data Sources** within **Components**

## Example Usage

The following examples demonstrate how these primitive terms are used in context:

```r
# Function - a reusable unit of code
calculate_customer_value <- function(customer_id, transaction_history) {
  # Implementation details
}

# Component - a self-contained piece of functionality
customerProfileUI <- function(id) {
  # UI implementation
}

# Module - a collection of related components
customer_module <- list(
  ui = customerProfileUI,
  server = customerProfileServer
)

# Interface - defined methods or contracts
process_data_source <- function(data_source, table_names) {
  # Process according to interface contract
}
```

```yaml
# Data Source - named reference to a dataset
components:
  micro:
    customer_profile: sales_by_customer_dta

# Parameters - configuration values
components:
  trends:
    data_source: sales_trends
    parameters:
      show_kpi: true
      refresh_interval: 300

# Roles - specific relationships between data sources and components
components:
  advanced_profile:
    primary: customer_details
    history: customer_history
```

## Derived Terms

Additional technical terms may be defined throughout the system, but they must ultimately be defined in terms of these primitive concepts.

## Terminology Usage Rules

1. **Consistency**: These terms must be used consistently throughout the system
2. **Precision**: Use the exact term that matches the concept being referenced
3. **Specificity**: Avoid ambiguous terms when precise terms are available
4. **Documentation**: Reference these definitions when introducing new concepts

## Relationship to Other Principles

This document of primitive terms and definitions serves as the foundation for:

1. **Structural Blueprint** (02_structural_blueprint.md): Uses these primitive terms to define the system structure
2. **Terminology Axiomatization Principle** (29_terminology_axiomatization.md): Extends and formalizes the relationships between these terms
3. **All other principles**: Build upon this fundamental vocabulary

## Conclusion

By establishing clear definitions for these primitive terms, we create a solid foundation for the entire axiomatic system. This shared vocabulary ensures consistent understanding and usage across all principles, blueprints, and implementations, reducing ambiguity and enabling precise communication about system design and functionality.