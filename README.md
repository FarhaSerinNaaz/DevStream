# DevStream – AI-Powered Incident Monitoring Pipeline

![n8n](https://img.shields.io/badge/n8n-Workflow-orange)
![Gemini AI](https://img.shields.io/badge/AI-Gemini-blue)
![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## Project Overview

DevStream is an AI-powered incident monitoring pipeline built using **n8n**, **Gemini AI**, and **Neon PostgreSQL**.

The project automates API failure handling by receiving failure events, validating requests, calculating incident severity, generating AI-assisted root cause analysis, storing incident data in PostgreSQL, and notifying engineers about high-severity incidents.

It demonstrates workflow automation, AI integration, database persistence, and event-driven incident management in a backend engineering scenario.

## Project Flow

```text
API Failure
      │
      ▼
Webhook
      ▼
AI Analysis
      ▼
PostgreSQL
      ▼
Email Notification
```

## Features

- AI-assisted root cause analysis using **Gemini AI**
- Automated incident severity calculation
- PostgreSQL persistence for API failures and AI analysis
- Conditional email notifications for HIGH-severity incidents
- Workflow automation using **n8n**
- Structured storage of AI-generated analysis and recommendations
- Extensible architecture for future Spring Boot integration

## Tech Stack

| Category | Technology |
|----------|------------|
| Workflow Automation | n8n |
| AI Model | Gemini AI |
| Database | Neon PostgreSQL |
| Database Engine | PostgreSQL |
| Notification | Gmail |
| API Testing | Postman |
| Version Control | GitHub |
| Future Event Source | Spring Boot Microservice |

## Architecture Diagram

```mermaid
flowchart TD

A["API Failure Event"]
B["Receive Failure Event"]
C["Validate Payload"]
D["Calculate Severity"]
E["Log API Failure"]
F["Analyze Failure (Gemini AI)"]
G["Parse AI Response"]
H["Store AI Analysis"]
I["Update AI Status"]
J{"HIGH Severity?"}
K["Notify Engineer (Email)"]
L["End"]
M[("Neon PostgreSQL")]

A --> B
B --> C
C --> D
D --> E

E -->|"Save Failure Log"| M

E --> F
F --> G
G --> H

H -->|"Save AI Analysis"| M

H --> I
I --> J

J -->|Yes| K
J -->|No| L
```

> **Current Trigger:** Postman (Phase 1 – Testing)
>
> **Planned Trigger:** Spring Boot Microservice (Phase 2)

## Workflow Screenshot

The following screenshot shows the complete implementation of the AI-powered incident monitoring pipeline in **n8n**.

![DevStream Workflow](images/workflow.png)

## Database Schema

The project uses **Neon PostgreSQL** to store both raw API failure events and AI-generated incident analysis.

The database consists of two primary tables:

| Table | Purpose |
|-------|---------|
| `api_failure_logs` | Stores API failure details received by the workflow |
| `ai_analysis` | Stores AI-generated analysis linked to each API failure |

```mermaid
erDiagram

api_failure_logs ||--o{ ai_analysis : analyzes

api_failure_logs {
    int failure_id PK
    string service_name
    string endpoint
    int status_code
    string severity
    string ai_status
}

ai_analysis {
    int analysis_id PK
    int failure_id FK
    string root_cause
    string java_fix
    string recommended_action
    float confidence_score
}
```

Each API failure is stored first in `api_failure_logs`.

After AI processing, the generated root cause analysis, Java fix recommendations, confidence score, and other outputs are stored in `ai_analysis` using the corresponding `failure_id`.

## Sample API Payload

The workflow receives API failure events through an HTTP Webhook.

Example request:

```json
{
  "serviceName": "Order Service",
  "endpoint": "/api/orders",
  "httpMethod": "POST",
  "statusCode": 500,
  "responseTimeMs": 2400,
  "errorMessage": "NullPointerException while creating order",
  "stackTrace": "java.lang.NullPointerException..."
}
```

## Setup Guide

### Prerequisites

- n8n Cloud
- Google Gemini API Key
- Neon PostgreSQL
- Gmail Account
- Postman

### Installation

1. Clone the repository.
2. Create the PostgreSQL tables using the SQL scripts.
3. Import the n8n workflow JSON.
4. Configure the Gemini API credentials.
5. Configure PostgreSQL credentials.
6. Configure Gmail credentials.
7. Activate the workflow.
8. Send the sample payload using Postman.
9. Verify the AI analysis and database entries.

## Future Enhancements

### Phase 2

- Replace Postman with Spring Boot Microservice
- Automatic failure reporting
- Exception handling integration

### Planned Improvements

- Slack notifications
- Jira integration
- Monitoring dashboard
- Incident analytics
- Retry recommendations
- Historical incident search
- Docker deployment

## Project Structure

```text
DevStream/
│
├── README.md
├── workflow/
│   └── DevStream_AI_Incident_Monitoring.json
├── database/
│   ├── create_tables.sql
│   └── sample_data.sql
├── images/
│   └── workflow.png
└── LICENSE
```

## Project Status

**Current Phase**

Phase 1 – AI-powered incident monitoring workflow using Postman for event simulation.

**Next Phase**

Integrate a Spring Boot microservice to automatically report API failures to the n8n workflow.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
