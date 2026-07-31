# REST API Documentation

## Introduction

The DevStream Monitoring project exposes a REST API through the Spring Boot application to receive API incident events for AI-powered analysis.

During Phase 2, the REST API acts as the entry point into the monitoring workflow. When an API incident is submitted, the Spring Boot application accepts the request and forwards it to the configured n8n workflow for processing.

The n8n workflow validates the required fields, records the incident in PostgreSQL, generates AI-powered analysis using Google Gemini, stores the analysis results, and updates the processing status.

This document describes the REST API implemented in Phase 2, including the endpoint, request and response formats, and integration with the Phase 2 n8n workflow.

---

## API Overview

The Phase 2 implementation exposes a single REST endpoint through the Spring Boot application for submitting API incident events to the AI-powered monitoring workflow.

The endpoint accepts structured API incident information and forwards it to the configured n8n webhook. The workflow validates the required request fields, stores the incident in PostgreSQL, performs AI-powered analysis using Google Gemini, stores the generated analysis, updates the AI processing status, and conditionally sends an email notification for high-severity incidents.

### API Summary

| Property | Value |
|----------|-------|
| API Style | REST |
| Method | POST |
| Endpoint | `/api/incidents` |
| Content Type | `application/json` |
| Request Format | JSON |
| Response Format | Plain text |
| API Testing Tool | Postman |

The API is designed to receive one API incident event per request, allowing each failure to be processed independently through the monitoring workflow.

---

## Base URL

The REST API is exposed by the Spring Boot application.

```
http://localhost:8080
```

All endpoints documented in this guide are relative to the above base URL.

## Authentication

The Phase 2 implementation does not require authentication.

The REST endpoint is intended for local development and demonstration purposes. Requests can be submitted directly without API keys, bearer tokens, or other authentication mechanisms.

## Endpoint Summary

The Phase 2 implementation exposes a single REST endpoint for submitting API incident events to the monitoring workflow.

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/incidents` | Receives an incident event and forwards it to the n8n workflow. |

## POST /api/incidents

### Purpose

The `/api/incidents` endpoint receives incident events from client applications and forwards them to the configured n8n workflow.

The Spring Boot controller accepts the JSON request body as an `IncidentEvent` object and passes it to the `N8nNotificationService` for further processing.

### Request Body

The request body is submitted in JSON format and is mapped to the `IncidentEvent` model. The Spring Boot application forwards the incident to the n8n workflow, where the required fields are validated before further processing.

| Field          | Data Type | Required by Workflow | Description                                               |
| -------------- | --------- | -------------------- | --------------------------------------------------------- |
| serviceName    | String    | Yes                  | Name of the service where the incident occurred.          |
| endpoint       | String    | Yes                  | API endpoint associated with the failed request.          |
| httpMethod     | String    | No                   | HTTP method used for the request.                         |
| statusCode     | Integer   | Yes                  | HTTP response status code returned by the failed request. |
| responseTimeMs | Long      | No                   | Response time in milliseconds.                            |
| errorMessage   | String    | No                   | Error message describing the failure.                     |
| stackTrace     | String    | No                   | Stack trace captured for diagnostics.                     |

### Sample Request

```json
{
  "serviceName": "Order Service",
  "endpoint": "/api/orders",
  "httpMethod": "POST",
  "statusCode": 500,
  "responseTimeMs": 2400,
  "errorMessage": "NullPointerException while creating order",
  "stackTrace": "java.lang.NullPointerException at OrderService.createOrder(OrderService.java:45)"
}
```

### Success Response

When the request is successfully handled and forwarded to the n8n notification service, the API returns HTTP status `200 OK`.

#### Example Response

```text
Incident received and forwarded to n8n from Order Service
```
