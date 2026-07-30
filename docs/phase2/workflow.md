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

The Release 2 workflow consists of 11 nodes that collectively validate incoming API failures, perform AI-assisted incident analysis, persist monitoring data, and notify engineers when required.

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




