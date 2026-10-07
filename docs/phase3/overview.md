# Phase 3 – Implementation Overview

## Purpose

Phase 3 extends the Spring Boot and n8n integration established in Phase 2 with incident management, expanded AI orchestration, reusable knowledge, Smart Notifications, and operational dashboards.

## Implementation Responsibilities

| Component | Phase 3 Responsibility |
|-----------|------------------------|
| Spring Boot | Captures failures, groups incidents, manages incident state, orchestrates AI processing, and applies notification decisions. |
| n8n | Executes the AI workflow and returns structured agent results. |
| AI agents | Produce analysis, knowledge-related output, and coordinator recommendations. |
| PostgreSQL | Preserves failures, incidents, AI outputs, knowledge, processing history, and notification history. |
| Grafana | Displays operational and historical metrics across seven dashboards. |

## Failure Processing

1. Capture an API failure in `api_failure_logs`.
2. Group the failure using an incident fingerprint.
3. Link the failure to its incident and track the occurrence.
4. Build AI context, including available incident knowledge.
5. Invoke the n8n AI workflow.
6. Validate the returned response.
7. Persist AI analysis, update incident knowledge, and store agent results.
8. Record processing completion and mark the failure's AI status `COMPLETED`.

Application logic controls incident grouping and operational state. AI supplies analysis and recommendations.

## Incident Management

Phase 3 supports:

- Incident grouping and occurrence tracking.
- Lifecycle transitions.
- Assignment and acknowledgement.
- Incident notes.
- Status and assignment history.

Individual failures remain available as raw records linked to their grouped incident.

## AI Processing and Retry Classes

| Class or Interface | Responsibility |
|--------------------|----------------|
| `AiOrchestrationService` | Executes AI processing for an existing failure and persists validated results. |
| `AiRetryService` | Selects pending failures and applies retry or recovery handling. |
| `AiRetryScheduler` | Invokes retry processing with a 60-second fixed delay after the previous scheduled execution completes. |
| `ApiFailureLogRepository` | Retrieves pending failures in creation-time order. |
| `ProcessingLogRepository` | Retrieves processing history and the highest recorded attempt number. |
| `KnowledgeBaseService` | Updates reusable incident knowledge from analysis. |

### Retry Behaviour

- Failures without an incident link are skipped.
- When analysis already exists, the recovery path updates knowledge and attempts to mark AI processing complete.
- Otherwise, failures with a highest recorded attempt number of three or more are skipped.
- Eligible failures are processed with the trigger value `RETRY`.
- Failed AI processing attempts are recorded in `processing_logs`.

The three-attempt limit applies to the normal analysis retry path. The persisted-analysis recovery path is checked before that limit.

Retries process existing failure IDs and do not add new incident occurrences.

## Smart Notifications

Smart Notifications record notification decisions and delivery outcomes.

Duplicate occurrences can be suppressed when they do not meet the configured notification threshold. Suppressed decisions remain visible in `notification_history`, including their suppression reason.

Notification history links to an incident rather than directly to an individual failure.

## Operational Monitoring

Seven Grafana dashboards provide visibility into failures, incidents, AI processing, and notification activity.

The dashboard SQL catalogue contains 59 documented queries.

## Verified Regression

The latest supplied regression evidence shows:

- Endpoint: `/test-error`
- Failure ID: `100`
- Incident ID: `7`
- AI status: `COMPLETED`
- Incident notification history entry: `51`
- Notification type: `DUPLICATE_OCCURRENCE`
- Delivery status: `SUPPRESSED`
- Reason: `Duplicate occurrence did not meet notification threshold`

Following database cleanup, unlinked failures and occurrence-count mismatches both returned zero.

The captured historical snapshot contains 53 pending AI failures. Subsequent bulk recovery has not been verified.

## Related Documentation

- [Phase 3 README](README.md)
- [Database Documentation](database.md)
- [Grafana Dashboards](dashboards.md)
- [Release Verification](release-verification.md)
- [Phase 2 Documentation](../phase2/README.md)
