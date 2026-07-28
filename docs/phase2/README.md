# DevStream – Phase 2 Engineering Documentation

| Item | Details |
|------|---------|
| Release | Phase 2 |
| Version | v2.0 |
| Status | Final |
| Last Updated | July 2026 |
| Author | Farha Serin Naaz |
| Related Release | Release 1 → Release 2 |

---

## Introduction

This document provides a high-level overview of the engineering enhancements introduced in Release 2 and serves as the entry point to the detailed technical documentation for this release.

Release 2 extends the backend capabilities of DevStream by integrating a Spring Boot application with the AI-powered monitoring workflow introduced in Release 1. The platform automates the collection, analysis, storage, and notification of failed API requests, reducing the manual effort required for incident investigation.

This document provides a technical overview of the Release 2 implementation, describing the system architecture, backend components, workflow orchestration, database design, API integration, and key engineering decisions. Detailed implementation specifics are documented separately in the architecture, API, database, and workflow guides.

The objective of this documentation is to provide engineers, collaborators, and reviewers with a clear understanding of how the platform is designed, how its components interact, and how the system can be extended in future releases.

## Project Objectives

Release 2 focuses on establishing a robust backend foundation for DevStream by integrating application services, workflow automation, artificial intelligence, and persistent data storage into a unified monitoring platform.

The primary objectives of this release are to:

- Integrate a Spring Boot backend with an n8n workflow for automated API failure processing.
- Capture and validate failed API request data through a structured workflow.
- Generate AI-assisted analysis using Google Gemini to accelerate incident investigation.
- Persist monitoring data, AI-generated insights, and notification records in PostgreSQL.
- Automate incident notifications based on predefined severity levels.
- Build a modular architecture that supports future enhancements, including incident fingerprinting, knowledge management, analytics, and production-ready deployment.

## Scope

Release 2 focuses on building the core backend infrastructure required to automate API failure monitoring and AI-assisted incident analysis. The implementation establishes a modular platform by integrating backend services, workflow automation, artificial intelligence, and persistent data storage.

### In Scope

- Spring Boot REST API for receiving failed API requests.
- Workflow orchestration using n8n.
- Request validation and processing.
- AI-assisted analysis using Google Gemini.
- PostgreSQL database integration for persistent monitoring.
- Automated email notifications based on incident severity.
- Structured project documentation and repository organization.

### Out of Scope

The following capabilities are intentionally excluded from Release 2 and are planned for future releases:

- Incident fingerprinting and deduplication.
- Knowledge Base integration.
- Grafana dashboards and advanced analytics.
- Docker containerization.
- Spring Security implementation.
- Automated testing.
- CI/CD pipeline.
- Production deployment.

## System Overview

Release 2 extends the AI-powered monitoring platform introduced in Release 1 by integrating a Spring Boot backend with the existing monitoring workflow.

The Spring Boot application exposes REST endpoints that receive failed API requests and forward them to the n8n workflow for processing. The workflow continues to orchestrate request validation, AI-assisted analysis using Google Gemini, PostgreSQL persistence, and email notifications.

By introducing a dedicated backend layer, Release 2 improves the system's integration capabilities and establishes a foundation for future enhancements while preserving the workflow-driven architecture developed in Release 1.

## Architecture Overview

Release 2 follows a modular architecture that integrates a Spring Boot backend with the existing AI-powered monitoring workflow introduced in Release 1.

The Spring Boot application acts as the system entry point by exposing REST endpoints for failed API requests. Incoming requests are forwarded to the n8n workflow, which orchestrates validation, AI-assisted analysis using Google Gemini, data persistence in PostgreSQL, and email notifications.

Each component has a clearly defined responsibility, allowing the backend, workflow automation, artificial intelligence, and database layers to evolve independently. This modular design improves maintainability and provides a foundation for future enhancements such as incident fingerprinting, knowledge management, and production-ready deployment.

> **Detailed architecture diagrams and component interactions are available in [architecture.md](architecture.md).**

## Component Responsibilities

The DevStream platform is composed of independent components, each responsible for a specific part of the incident monitoring lifecycle. This separation of responsibilities improves maintainability, simplifies future enhancements, and promotes loose coupling between the backend application, workflow automation, artificial intelligence, and data storage layers.

| Component | Responsibility |
|-----------|----------------|
| Spring Boot | Exposes REST endpoints, receives failed API requests, validates incoming payloads, and forwards requests to the monitoring workflow. |
| n8n Workflow | Orchestrates the end-to-end incident processing workflow, including validation, AI analysis, database operations, and notifications. |
| Google Gemini | Generates AI-assisted incident analysis, probable root causes, and troubleshooting recommendations. |
| PostgreSQL | Stores API failure records, AI-generated insights, incident history, and notification logs. |
| Email Service | Sends incident notifications based on configured severity levels. |

## Technology Stack

Release 2 integrates multiple technologies, each selected to address a specific responsibility within the DevStream platform.

| Technology | Purpose | Why Chosen |
|------------|---------|------------|
| Java 21 | Backend development | Modern LTS release offering improved language features, performance, and long-term support. |
| Spring Boot | REST API layer | Simplifies backend development, provides robust REST capabilities, and integrates well with enterprise Java applications. |
| n8n | Workflow orchestration | Enables rapid development of event-driven workflows through a visual, low-code automation platform. |
| PostgreSQL | Relational database | Reliable, open-source database with strong transactional support and excellent SQL capabilities. |
| Google Gemini | AI-powered incident analysis | Generates contextual root cause analysis and troubleshooting recommendations for failed API requests. |
| Gmail SMTP | Email notifications | Delivers automated incident alerts to stakeholders based on configured severity levels. |
| IntelliJ IDEA | Development environment | Primary IDE used for backend development, debugging, and project management. |
| Neon | Cloud PostgreSQL hosting | Provides managed PostgreSQL hosting for development without infrastructure overhead. |
| Git & GitHub | Version control | Tracks project history, supports collaboration, and hosts project documentation and source code. |

## Key Design Principles

The implementation of Release 2 follows these guiding principles:

- Separation of concerns between backend services and workflow orchestration.
- Modular architecture to support phased feature expansion.
- Automation-first approach for incident processing.
- AI-assisted analysis to reduce manual investigation effort.
- Persistent storage for auditability and historical analysis.
- Maintainable documentation aligned with project evolution.

## Data Flow

The following sequence describes the high-level flow of an API failure through the DevStream platform.

1. A failed API request is received by the Spring Boot REST endpoint.
2. Spring Boot forwards the request to the n8n monitoring workflow.
3. The workflow validates and processes the incoming payload.
4. Incident details are stored in PostgreSQL.
5. Google Gemini analyzes the incident and generates AI-assisted insights.
6. The generated analysis is persisted in the database.
7. Email notifications are sent based on the configured incident severity.
8. Monitoring data remains available for future reporting and analysis.

> Detailed workflow execution, node configuration, SQL queries, and AI prompts are documented in **workflow.md**.

## Release 2 Deliverables

Release 2 delivers the following enhancements:

- Spring Boot backend integration
- REST API endpoint for incident ingestion
- Backend integration with the existing n8n workflow
- Updated engineering documentation
- Modular project structure supporting future releases

## References

- [Root Repository README](../../README.md)
- [Architecture Documentation](architecture.md)
- [Workflow Documentation](workflow.md)
- [Database Documentation](database.md)
- [API Documentation](api.md)
- [Engineering Decisions](engineering-decisions.md)

 ## Document Purpose

This document provides a high-level engineering overview of Release 2.

Detailed implementation is documented separately in:

- [Architecture Documentation](architecture.md)
- [Workflow Documentation](workflow.md)
- [Database Documentation](database.md)
- [API Documentation](api.md)
- [Engineering Decisions](engineering-decisions.md)
