# DevStream – AI-Powered Incident Monitoring Pipeline

## Project Overview

DevStream is an AI-powered incident monitoring pipeline built using **n8n**, **Gemini AI**, and **Neon PostgreSQL**.

The workflow receives API failure events, validates incoming requests, calculates incident severity, performs AI-assisted root cause analysis, stores incident data and AI recommendations in PostgreSQL, and sends email notifications for high-severity incidents.

The project demonstrates workflow automation, AI integration, database persistence, and incident management in a backend monitoring scenario.

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
- Neon PostgreSQL Database
- Gmail Account
- Postman (for Phase 1 testing)

### Steps

1. Clone this repository.
2. Import the n8n workflow.
3. Configure Gemini API credentials.
4. Configure Neon PostgreSQL credentials.
5. Configure Gmail credentials.
6. Execute the workflow using the sample payload.
