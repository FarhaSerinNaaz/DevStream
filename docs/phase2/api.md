# REST API Documentation

## Introduction

The DevStream Monitoring project exposes a REST API through the Spring Boot application to receive API failure events for AI-powered analysis.

During Phase 2, the REST API acts as the entry point into the monitoring workflow. When a failed API request is submitted, the application validates the incoming data and forwards it to the n8n workflow for processing.

The workflow records the failure in PostgreSQL, generates AI-powered analysis using Google Gemini, stores the analysis results, and updates the processing status.

This document describes the REST API implemented in Phase 2, including the endpoint, request and response formats, validation rules, and workflow integration.

---

## API Overview

The Phase 2 implementation exposes a single REST endpoint through the Spring Boot application for submitting API failure events to the AI-powered monitoring workflow.

The endpoint accepts structured API failure information, validates the incoming request, and forwards it to the configured n8n webhook for processing. The n8n workflow then stores the failure in PostgreSQL, performs AI analysis using Google Gemini, stores the generated analysis, and updates the AI processing status.

### API Summary

| Property | Value |
|----------|-------|
| API Style | REST |
| Method | POST |
| Endpoint | `/api/failures` |
| Content Type | `application/json` |
| Request Format | JSON |
| Response Format | JSON |
| Primary Consumer | Client applications submitting API failure events |

The API is designed to receive one API failure event per request, allowing each failure to be processed independently through the monitoring workflow.

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

Future production implementations should secure the API using an appropriate authentication and authorization mechanism.

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

The request body is submitted in JSON format and is mapped to the `IncidentEvent` model.

| Field | Data Type | Expected | Description |
|-------|-----------|----------|-------------|
| `serviceName` | String | Yes | Name of the service where the incident occurred. |
| `endpoint` | String | Yes | API endpoint associated with the failed request. |
| `httpMethod` | String | Yes | HTTP method used for the request. |
| `statusCode` | Integer | Yes | HTTP response status code returned by the failed request. |
| `responseTimeMs` | Long | Yes | Response time of the request in milliseconds. |
| `errorMessage` | String | Yes | Error message describing the failure. |
| `stackTrace` | String | Yes | Stack trace captured for diagnostic purposes. |

### Sample Request

```json
{
  "serviceName": "Order Service",
  "endpoint": "/api/orders",
  "httpMethod": "POST",
  "statusCode": 500,
  "responseTimeMs": 1250,
  "errorMessage": "Internal Server Error",
  "stackTrace": "java.lang.NullPointerException at com.farha.devstream.service.OrderService.processOrder(OrderService.java:45)"
}


### Success Response

Your controller returns HTTP `200 OK` with a plain-text response, not JSON.

```markdown
### Success Response

When the incident is accepted and forwarded to the notification service, the API returns HTTP status `200 OK`.

#### Example Response

```text
Incident received and forwarded to n8n from Order Service

