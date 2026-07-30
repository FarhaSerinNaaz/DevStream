# DevStream – Phase 2 Workflow

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

This document describes the end-to-end workflow implemented in DevStream Release 2.

Release 2 extends the workflow introduced in Release 1 by integrating a Spring Boot backend as the primary entry point for incoming API requests while preserving the existing n8n workflow for orchestration.

The workflow automates API failure processing by validating incoming requests, performing AI-assisted incident analysis using Google Gemini, persisting monitoring data in PostgreSQL, and notifying engineers when high-severity incidents are detected.

This document describes the workflow execution, node responsibilities, AI integration, database operations, and decision logic implemented in Release 2.

## Workflow Objectives

The workflow is designed to achieve the following objectives:

- Automate the processing of failed API requests.
- Validate incoming request data before workflow execution.
- Calculate incident severity using predefined logic.
- Generate AI-assisted incident analysis using Google Gemini.
- Persist incident records and AI-generated insights in PostgreSQL.
- Trigger notifications for high-severity incidents.
- Maintain a modular workflow that can be extended with additional automation steps.

## Workflow Overview

The Release 2 workflow automates the end-to-end processing of failed API requests. It begins when the Spring Boot backend forwards a failed API request to the existing n8n workflow for orchestration.

During execution, the workflow validates the incoming request, calculates the incident severity, records the API failure in PostgreSQL, invokes the Google Gemini Chat Model for AI-assisted incident analysis, stores the generated analysis, updates the processing status, and determines whether an engineer notification should be sent.

The workflow integrates with external services, including Neon PostgreSQL for persistent storage, Google Gemini for AI-powered incident analysis, and the email notification service for conditional alerting. Together, these components provide an automated workflow for incident processing, AI-assisted diagnosis, data persistence, and notification.

## Workflow Diagram

The following diagram shows the complete n8n workflow implemented in Release 2. It illustrates the sequence of workflow nodes responsible for validating API failures, performing AI-assisted incident analysis, persisting monitoring data, updating workflow status, and triggering engineer notifications.

> <img width="2476" height="1308" alt="workflow phase 2" src="https://github.com/user-attachments/assets/4b57b0a5-51ec-4ddc-b166-fd7e6b945978" />


*Figure 1. DevStream Release 2 n8n Workflow*

## Workflow Node Summary

The Release 2 workflow consists of 10 nodes that collectively validate incoming API failures, perform AI-assisted incident analysis, persist monitoring data, and notify engineers when required.

| Step | Node | Purpose |
|------|------|---------|
| 1 | Receive Failure Event | Receives failed API requests from the Spring Boot backend. |
| 2 | Validate Payload | Validates required fields and normalizes the incoming request. |
| 3 | Calculate Severity | Determines LOW, MEDIUM, or HIGH severity based on the HTTP status code. |
| 4 | Log API Failure | Inserts the initial incident record into PostgreSQL. |
| 5 | Analyze Failure (Gemini AI) | Generates AI-assisted incident analysis and recommendations. |
| 6 | Parse AI Response | Parses and validates the AI-generated JSON response. |
| 7 | Store AI Analysis | Persists the AI-generated analysis in PostgreSQL. |
| 8 | Update AI Status | Updates the processing status of the incident record. |
| 9 | Check Severity | Evaluates whether the incident requires notification. |
| 10 | Notify Engineer Email | Sends an email notification for HIGH-severity incidents. |

The workflow uses the Google Gemini Chat Model as the language model configured within the AI Agent node. It is an external AI dependency rather than an independent workflow execution step.

## Node-by-Node Workflow Execution

The Release 2 workflow is composed of multiple n8n nodes that collectively automate incident detection, AI-assisted analysis, persistence, and notification. Each node performs a specific responsibility within the workflow while passing data to subsequent nodes for further processing.

The following sections describe each workflow node, its purpose, inputs, outputs, and role within the overall workflow.

### 1. Receive Failure Event

**Purpose**

Receives the failed API request from the Spring Boot backend and initiates workflow execution.

**Input**

- Failed API request payload

**Processing**

- Accepts the incoming HTTP request.
- Passes the payload to the validation node.

**Output**

- Validated request forwarded to the next workflow node.

### 2. Validate Payload

**Purpose**

Validates the incoming API failure request and ensures all mandatory fields are present before workflow execution continues.

**Input**

- API failure payload received from the Spring Boot backend.

**Processing**

- Extracts the request body from the incoming webhook.
- Validates the presence of the required fields:
  - `serviceName`
  - `endpoint`
  - `statusCode`
- Rejects the request if any mandatory field is missing.
- Normalizes the payload structure before passing it to the next node.

**Output**

- Validated and normalized request payload forwarded to the **Calculate Severity** node.

### 3. Calculate Severity

**Purpose**

Determines the severity level of the API failure based on the HTTP status code.

**Input**

- Validated API failure payload.

**Processing**

- Evaluates the HTTP status code using predefined rules:
  - **HIGH** for status codes **500 and above**
  - **MEDIUM** for status codes **400–499**
  - **LOW** for all other status codes
- Appends the calculated severity to the workflow payload.

**Output**

- Enriched payload containing the calculated severity forwarded to the **Log API Failure** node.

### 4. Log API Failure

**Purpose**

Creates the initial incident record in the PostgreSQL database before AI analysis begins.

**Input**

- API failure payload containing the calculated severity.

**Processing**

- Inserts a new record into the `monitoring.api_failure_logs` table.
- Stores key incident information, including:
  - Service name
  - Endpoint
  - HTTP method
  - Status code
  - Response time
  - Severity
  - Error message
  - Stack trace
  - AI processing status
- Initializes the AI processing status as **PENDING**.
- Returns the generated failure identifier for use in downstream nodes.

**Output**

- Database record created successfully.
- Generated `failure_id` forwarded to the AI analysis stage.

### 5. Analyze Failure (Gemini AI)

**Purpose**

Performs AI-assisted incident analysis by invoking the Google Gemini Chat Model through the AI Agent node.

**Input**

- Failure ID
- Service name
- Endpoint
- HTTP method
- HTTP status code
- Severity
- Error message
- Stack trace

**Processing**

- Constructs a structured prompt containing the incident details.
- Uses a system prompt that instructs Gemini to act as an expert Java Backend Incident Analysis Agent.
- Requests a structured JSON response containing:
  - `failureId`
  - `rootCause`
  - `assumptions`
  - `javaFix`
  - `unitTest`
  - `bestPractice`
  - `confidenceScore`
  - `recommendedAction`
- Retries the AI request automatically if execution fails.

**Output**

- Structured JSON response forwarded to the **Parse AI Response** node.

### 6. Parse AI Response

**Purpose**

Validates and transforms the AI-generated response into a structured format suitable for persistence.

**Input**

- JSON response returned by the AI Agent.

**Processing**

- Removes Markdown code block wrappers when present.
- Parses the AI response into JSON.
- Validates that the response is valid JSON.
- Extracts:
  - Root Cause
  - Assumptions
  - Java Fix
  - Unit Test
  - Best Practice
  - Confidence Score
  - Recommended Action
- Normalizes the confidence score to a value between **0** and **1**.
- Validates that the recommended action is one of:
  - CREATE_INCIDENT
  - LOG_ONLY
  - RETRY
  - ESCALATE
- Determines the AI processing status:
  - COMPLETED
  - FAILED

**Output**

- Structured AI analysis forwarded to the **Store AI Analysis** node.

### 7. Store AI Analysis

**Purpose**

Stores the AI-generated incident analysis in the PostgreSQL database.

**Input**

- Parsed AI analysis.
- Failure ID.

**Processing**

- Inserts a record into the `monitoring.ai_analysis` table.
- Persists:
  - Failure ID
  - Root Cause
  - Java Fix
  - Unit Test
  - Best Practice
  - Confidence Score
  - Recommended Action

**Output**

- AI analysis stored successfully.
- Workflow proceeds to the **Update AI Status** node.

### 8. Update AI Status

**Purpose**

Updates the AI processing status for the corresponding incident.

**Input**

- Failure ID.
- AI processing status.

**Processing**

- Updates the `monitoring.api_failure_logs` table.
- Matches the record using `failure_id`.
- Sets the `ai_status` field to either:
  - COMPLETED
  - FAILED

**Output**

- Updated incident record forwarded to the **Check Severity** node.

### 9. Check Severity

**Purpose**

Determines whether engineer notification is required.

**Input**

- Calculated severity level.

**Processing**

- Evaluates the severity assigned by the **Calculate Severity** node.
- Continues only when:
- If the severity is **HIGH**, the workflow proceeds to the **Notify Engineer Email** node.
- If the severity is **LOW** or **MEDIUM**, the workflow ends without sending a notification.

**Output**

- HIGH severity → Notify Engineer Email
- LOW/MEDIUM severity → Workflow ends

### 10. Notify Engineer Email

**Purpose**

Sends an automated email notification for HIGH-severity incidents.

**Input**

- API failure details.
- AI-generated analysis.

**Processing**

- Generates an email containing:
  - Failure ID
  - Service Name
  - Endpoint
  - HTTP Method
  - Status Code
  - Severity
  - Error Message
  - Stack Trace
  - Response Time
  - AI Processing Status
  - Root Cause
  - Recommended Java Fix
  - Recommended Action
  - Confidence Score
- Sends the notification using the configured Gmail node.

**Output**

- Engineer notification delivered successfully.
- Workflow execution completed.





