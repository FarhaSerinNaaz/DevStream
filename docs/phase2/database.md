# Database Documentation

## Introduction

The DevStream Monitoring project uses a PostgreSQL database to persist API failure records and AI-generated analysis produced during workflow execution.

In Phase 2, the database serves as the central storage layer between the Spring Boot application and the n8n workflow. API failure events received from the application are stored in PostgreSQL, enriched with AI-generated root cause analysis and recommendations, and updated with the workflow processing status.

This document describes the database schema, table relationships, and database operations implemented in Phase 2.

---

## Database Overview

The Phase 2 implementation uses a PostgreSQL database hosted on Neon.

The database consists of two tables within the **monitoring** schema.

| Table | Purpose |
|--------|---------|
| `api_failure_logs` | Stores API failure details received from the Spring Boot application. |
| `ai_analysis` | Stores AI-generated analysis associated with each API failure. |

Together, these tables enable the workflow to:

- Persist API failure information.
- Store AI-generated root cause analysis.
- Store AI-generated resolution recommendations.
- Track AI processing status throughout workflow execution.

The n8n workflow performs database operations through PostgreSQL nodes to insert failure records, store AI analysis, and update the AI processing status after successful analysis.

---

## Database Schema

The Phase 2 database is organized under the **monitoring** schema and consists of two relational tables.

### Database Structure

| Table | Description |
|--------|-------------|
| `monitoring.api_failure_logs` | Stores API failure events received from the Spring Boot application. |
| `monitoring.ai_analysis` | Stores AI-generated analysis for each recorded API failure. |

The two tables are related through the `failure_id` column. Each AI analysis record references the corresponding API failure record, allowing the workflow to associate AI-generated insights with the original API failure.

### Entity Relationship

```
monitoring.api_failure_logs
───────────────────────────
failure_id (PK)
        │
        │ 1
        │
        └───────────────┐
                        │
                        │ 0..1
                        │
monitoring.ai_analysis
──────────────────────
analysis_id (PK)
failure_id (FK, UNIQUE)
```
The `monitoring.api_failure_logs` table acts as the parent table, while `monitoring.ai_analysis` stores the AI-generated results associated with each recorded API failure.

## Table: monitoring.api_failure_logs

### Purpose

The `monitoring.api_failure_logs` table stores API failure events received from the Spring Boot application. Each row represents a single failed API request captured during workflow execution.

This table serves as the primary source of failure data for the n8n workflow. Each failure record can have zero or one corresponding AI analysis stored in the `monitoring.ai_analysis` table.

### Primary Key

| Column | Description |
|--------|-------------|
| `failure_id` | Unique identifier for each API failure record. |

### Columns

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| `failure_id` | BIGSERIAL | No | Primary key generated automatically. |
| `service_name` | VARCHAR(255) | No | Name of the service where the failure occurred. |
| `endpoint` | VARCHAR(500) | No | API endpoint that generated the failure. |
| `http_method` | VARCHAR(20) | Yes | HTTP method used for the request. |
| `status_code` | INTEGER | No | HTTP response status code. |
| `response_time_ms` | INTEGER | Yes | Response time recorded for the failed request. |
| `severity` | VARCHAR(50) | No | Severity assigned to the API failure. |
| `error_message` | TEXT | Yes | Error message returned by the failed request. |
| `stack_trace` | TEXT | Yes | Stack trace captured for diagnostic purposes. |
| `ai_status` | VARCHAR(20) | No | AI processing status. Defaults to `PENDING`. |
| `created_at` | TIMESTAMP | No | Timestamp when the failure record was created. |

### Constraints

- `failure_id` is the primary key.
- `ai_status` defaults to `PENDING`.
- `created_at` defaults to `CURRENT_TIMESTAMP`.
- Required fields are enforced using `NOT NULL` constraints.

### Workflow Usage

The Phase 2 n8n workflow performs the following database operations on this table:

- Inserts a new API failure record received from the Spring Boot application.
- Retrieves the failure record for AI analysis.
- Updates the `ai_status` after AI processing completes.

---

## Table: monitoring.ai_analysis

### Purpose

The `monitoring.ai_analysis` table stores AI-generated analysis for API failures recorded in the `monitoring.api_failure_logs` table.

Each record contains the AI-generated root cause analysis, Java fix recommendation, unit test suggestion, best practice guidance, confidence score, and recommended action for a single API failure.

The table maintains a one-to-one relationship with monitoring.api_failure_logs, ensuring that each API failure can have at most one AI analysis.

### Primary Key

| Column | Description |
|--------|-------------|
| `analysis_id` | Unique identifier for each AI analysis record. |

### Foreign Key

| Column | References | Description |
|--------|------------|-------------|
| `failure_id` | `monitoring.api_failure_logs.failure_id` | Associates the AI analysis with the corresponding API failure record. |

### Columns

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| `analysis_id` | BIGSERIAL | No | Primary key generated automatically. |
| `failure_id` | BIGINT | No | References the corresponding API failure record. |
| `root_cause` | TEXT | Yes | AI-generated root cause analysis. |
| `java_fix` | TEXT | Yes | Suggested Java code fix generated by AI. |
| `unit_test` | TEXT | Yes | Suggested unit test for validating the fix. |
| `best_practice` | TEXT | Yes | AI-generated best practice recommendation. |
| `confidence_score` | NUMERIC | Yes | AI confidence score for the generated analysis. |
| `recommended_action` | VARCHAR(50) | Yes | Recommended action generated by the AI analysis. |
| `analyzed_at` | TIMESTAMP | No | Timestamp when the AI analysis was stored. |

### Constraints

- `analysis_id` is the primary key.
- `failure_id` is a foreign key referencing `monitoring.api_failure_logs.failure_id`.
- `failure_id` is unique, allowing at most one AI analysis for each API failure.
- `analyzed_at` defaults to `CURRENT_TIMESTAMP`.
- `confidence_score` must be between `0` and `1` when provided.
- `recommended_action` accepts only the predefined values:
  - `CREATE_INCIDENT`
  - `LOG_ONLY`
  - `RETRY`
  - `ESCALATE`

### Workflow Usage

The Phase 2 n8n workflow performs the following database operations on this table:

- Inserts the AI-generated analysis after receiving a successful response from Google Gemini.
- Associates the analysis with the corresponding API failure using `failure_id`.
- Stores structured AI recommendations for future review and debugging.

---

## Relationship Between Tables

The Phase 2 database consists of two related tables:

- `monitoring.api_failure_logs`
- `monitoring.ai_analysis`

Each API failure recorded in `monitoring.api_failure_logs` can have **zero or one** corresponding AI analysis stored in `monitoring.ai_analysis`.

The relationship is established through the `failure_id` column, which serves as a foreign key in the `monitoring.ai_analysis` table and references the primary key of `monitoring.api_failure_logs`.

### Entity Relationship

```
monitoring.api_failure_logs
───────────────────────────
failure_id (PK)
        │
        │ 1
        │
        └───────────────┐
                        │
                        │ 0..1
                        │
monitoring.ai_analysis
──────────────────────
analysis_id (PK)
failure_id (FK, UNIQUE)
```

This relationship ensures that each API failure can have at most one AI-generated analysis while allowing newly recorded failures to remain in a `PENDING` state until AI processing is completed.

---

## Database Operations in the n8n Workflow

During workflow execution, the PostgreSQL database is accessed through PostgreSQL nodes in n8n to persist API failure records and AI-generated analysis.

The workflow performs the following database operations:

| Operation | Table | Purpose |
|-----------|-------|---------|
| Insert | `monitoring.api_failure_logs` | Stores API failure details received from the Spring Boot application. |
| Select | `monitoring.api_failure_logs` | Retrieves the failure record for AI analysis. |
| Insert | `monitoring.ai_analysis` | Stores the AI-generated analysis returned by Google Gemini. |
| Update | `monitoring.api_failure_logs` | Updates the `ai_status` from `PENDING` to `COMPLETED` after successful AI processing. |

### Database Operation Flow

```
Spring Boot Application
            │
            ▼
Insert API Failure Record
(api_failure_logs)
            │
            ▼
Retrieve Failure Details
            │
            ▼
Google Gemini AI Analysis
            │
            ▼
Store AI Analysis
(ai_analysis)
            │
            ▼
Update AI Status
(api_failure_logs)
```

These operations ensure that API failures and their corresponding AI-generated analysis are stored separately while remaining linked through the `failure_id` relationship.

---

## Data Flow

The following sequence illustrates how data moves through the Phase 2 implementation.

```
Spring Boot Application
        │
        │ Failed API Request
        ▼
monitoring.api_failure_logs
        │
        │ Retrieve Failure Details
        ▼
n8n Workflow
        │
        │ Send Failure Context
        ▼
Google Gemini
        │
        │ AI Analysis
        ▼
monitoring.ai_analysis
        │
        │ Update AI Status
        ▼
monitoring.api_failure_logs
```

### Flow Description

1. The Spring Boot application detects an API failure and sends the failure details to the n8n workflow.

2. The workflow stores the API failure in the `monitoring.api_failure_logs` table with an initial AI processing status of `PENDING`.

3. The workflow retrieves the stored failure details and submits them to Google Gemini for analysis.

4. Google Gemini returns structured analysis, including the root cause, Java fix, unit test recommendation, best practice guidance, confidence score, and recommended action.

5. The workflow stores the AI-generated analysis in the `monitoring.ai_analysis` table.

6. After the AI analysis is successfully stored, the workflow updates the corresponding API failure record by changing the `ai_status` from `PENDING` to `COMPLETED`.

---

## Summary

The Phase 2 database implementation uses PostgreSQL hosted on Neon to persist API failure records and AI-generated analysis produced during workflow execution.

The database consists of two relational tables within the `monitoring` schema:

- `monitoring.api_failure_logs` stores API failure details received from the Spring Boot application.
- `monitoring.ai_analysis` stores AI-generated analysis associated with individual API failures.

The two tables are linked through the `failure_id` relationship, enabling each API failure to have at most one corresponding AI analysis.

Throughout the Phase 2 n8n workflow, the database is used to:

- Persist API failure records.
- Retrieve failure details for AI analysis.
- Store AI-generated recommendations.
- Track AI processing status from `PENDING` to `COMPLETED`.

This design provides a structured persistence layer that supports automated API failure analysis while maintaining a clear separation between raw failure data and AI-generated insights.
