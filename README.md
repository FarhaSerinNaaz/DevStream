# DevStream

> AI-powered backend incident monitoring platform that automates API failure analysis, accelerates debugging, and helps engineering teams respond to production issues faster.

---

## Overview

DevStream is an AI-powered backend incident monitoring platform designed to automate the analysis of failed API requests.

The platform integrates a Spring Boot backend with an n8n workflow to capture API failures, validate incoming requests, generate AI-powered analysis using Google Gemini, store monitoring data in PostgreSQL, and send email notifications based on incident severity.

By combining backend engineering, workflow automation, artificial intelligence, and persistent data storage, DevStream transforms a traditionally manual debugging process into a structured, repeatable, and scalable monitoring solution.

---

## Business Problem

Modern applications rely on APIs to connect services, exchange data, and power business operations. When an API request fails, engineers often need to manually inspect logs, request payloads, error messages, and system responses before identifying the root cause.

This investigation process is repetitive, time-consuming, and difficult to scale, especially when similar failures occur across multiple services. As applications grow, manual analysis increases operational effort and delays incident resolution.

Engineering teams need an automated approach that captures failure information, performs consistent AI-assisted analysis, stores investigation results, and delivers actionable insights without disrupting existing development workflows.

---

## Solution

DevStream automates the end-to-end API failure analysis workflow by integrating backend services, workflow automation, artificial intelligence, and persistent data storage into a unified monitoring pipeline.

When a failed API request is received, the platform:

1. Receives the failure request from the Spring Boot application.
2. Validates and processes the incoming payload.
3. Records the failure details in PostgreSQL.
4. Invokes Google Gemini to generate AI-assisted analysis.
5. Updates the monitoring repository with AI-generated insights.
6. Sends email notifications based on the severity of the incident.

This automated workflow minimizes repetitive investigation tasks, standardizes incident analysis, and enables engineering teams to respond to failures more efficiently.

---

## Engineering Highlights

- Built with Java 21 and Spring Boot 3
- Automated workflow orchestration using n8n
- AI-assisted API failure analysis with Google Gemini
- PostgreSQL-based persistence layer for monitoring data
- RESTful backend integration for workflow execution
- Automated email notifications for incident reporting
- Modular architecture designed for future enhancements

## High-Level Architecture

DevStream follows a modular, event-driven architecture that integrates backend services, workflow automation, artificial intelligence, and persistent storage to automate API failure analysis.

The Spring Boot application serves as the entry point for failed API requests and communicates with an n8n workflow responsible for orchestrating the end-to-end monitoring process. The workflow validates incoming data, stores failure records in PostgreSQL, invokes Google Gemini for AI-assisted analysis, updates monitoring records with generated insights, and sends email notifications for critical incidents.

This modular architecture enables each component to operate independently while supporting future enhancements without impacting the core monitoring pipeline.

> **Architecture Diagram**
>
> *(Insert architecture diagram here.)*


## Technology Stack

| Layer | Technology |
|-------|------------|
| Programming Language | Java 21 |
| Backend Framework | Spring Boot 3 |
| Workflow Automation | n8n |
| Artificial Intelligence | Google Gemini |
| Database | PostgreSQL |
| Email Notifications | Gmail |
| API Testing | Postman |
| Version Control | Git & GitHub |
| IDE | IntelliJ IDEA |

## Database Overview

DevStream uses PostgreSQL as its primary persistence layer to store API failure events, AI-generated analysis, and notification records. The database provides a structured repository for monitoring data, enabling traceability, historical analysis, and future reporting capabilities.

The complete database schema, ER diagram, table definitions, relationships, and SQL scripts are available in:

📄 **docs/phase2/database.md**

---

## Documentation

Comprehensive technical documentation is available for every major component of DevStream.

| Document | Description |
|----------|-------------|
| `docs/phase2/README.md` | Engineering Design Document for Release 2 |
| `docs/phase2/architecture.md` | System architecture and component interactions |
| `docs/phase2/api.md` | REST API endpoints, request/response models, and integration details |
| `docs/phase2/database.md` | Database schema, relationships, and SQL scripts |
| `docs/phase2/workflow.md` | End-to-end workflow execution and node-level explanation |

---

## Repository Structure

```text
DevStream/
│
├── docs/
│   └── phase2/
│       ├── README.md
│       ├── architecture.md
│       ├── api.md
│       ├── database.md
│       └── workflow.md
│
├── springboot/
├── workflow/
├── database/
├── images/
├── README.md
└── LICENSE
```

---

## Roadmap

### ✅ Release 1 – AI Monitoring
- AI-powered API failure analysis
- Workflow automation using n8n
- PostgreSQL persistence
- Email notifications

### 🚧 Release 2 – Spring Boot Integration (Current)
- Spring Boot REST API integration
- End-to-end backend workflow
- Improved documentation
- Modular project structure

### 🔜 Release 3 – AI Incident Management
- Incident fingerprinting
- Incident deduplication
- Knowledge Base
- Enhanced AI analysis
- Smarter notifications
- Grafana dashboards

### 🔜 Release 4 – Production Readiness
- Docker
- Spring Security
- Automated testing
- CI/CD pipeline
- Deployment

---

## License

This project is licensed under the MIT License.

See the **LICENSE** file for details.

## Author

**Farha Serin Naaz**

Backend Engineering | Java | Spring Boot | Workflow Automation | Generative AI

DevStream is part of my hands-on journey in building production-oriented backend systems by combining modern Java development with AI-assisted automation and cloud-ready architecture.
