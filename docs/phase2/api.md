# REST API Documentation

## Introduction

The DevStream Monitoring project exposes a REST API through the Spring Boot application to receive API failure events for AI-powered analysis.

During Phase 2, the REST API acts as the entry point into the monitoring workflow. When a failed API request is submitted, the application validates the incoming data and forwards it to the n8n workflow for processing.

The workflow records the failure in PostgreSQL, generates AI-powered analysis using Google Gemini, stores the analysis results, and updates the processing status.

This document describes the REST API implemented in Phase 2, including the endpoint, request and response formats, validation rules, and workflow integration.

## API Overview

The Phase 2 implementation exposes a single REST endpoint through the Spring Boot application for submitting API failure events to the AI-powered monitoring workflow.

The endpoint accepts structured failure information, validates the incoming request, and forwards it to the n8n webhook for further processing. The n8n workflow then stores the failure in PostgreSQL, performs AI analysis using Google Gemini, stores the generated analysis, and updates the AI processing status.

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

## Base URL

The REST API is exposed by the Spring Boot application.

```
http://localhost:8080
```

All endpoints documented in this guide are relative to the above base URL.

### Local Development

## Authentication

The Phase 2 implementation does not require authentication.

The REST endpoint is intended for local development and demonstration purposes. Requests can be submitted directly without API keys, bearer tokens, or other authentication mechanisms.

Future production implementations should secure the API using an appropriate authentication and authorization mechanism.

## Endpoint Summary

The Phase 2 implementation exposes a single REST endpoint for submitting API failure events to the AI-powered monitoring workflow.

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/failures` | Receives an API failure event and forwards it to the n8n workflow for AI-powered analysis. |

## POST /api/failures

### Purpose

The `/api/failures` endpoint receives API failure events from client applications and initiates the AI-powered monitoring workflow.

Upon receiving a valid request, the Spring Boot application validates the payload and forwards it to the configured n8n webhook for processing. The workflow then stores the failure details in PostgreSQL, performs AI analysis using Google Gemini, stores the generated analysis, and updates the AI processing status.

### Request Headers

| Header | Required | Value |
|--------|----------|-------|
| `Content-Type` | Yes | `application/json` |
