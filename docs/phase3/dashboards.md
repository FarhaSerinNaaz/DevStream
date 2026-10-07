# Phase 3 – Grafana Dashboards

## Overview

Phase 3 includes seven Grafana dashboards backed by the PostgreSQL `monitoring` schema.

The dashboards provide visibility into incident state, lifecycle history, AI processing, knowledge reuse, notifications, API failures, and operational health.

This document contains the 59 queries recorded in the Phase 3 dashboard reference.

## Dashboard Inventory

| Dashboard | Queries | Purpose |
|-----------|---------|---------|
| Incident Overview | 7 | Incident totals, severity, status, and creation trends |
| Incident Lifecycle and Resolution | 7 | Resolution timing and lifecycle transitions |
| AI Processing and Reliability | 10 | AI analysis, attempts, outcomes, and confidence |
| Knowledge Base and Incident Patterns | 8 | Knowledge coverage, usage, and stored solutions |
| Notifications and Alerting | 9 | Notification delivery, failures, and suppression |
| Failure and Service Analytics | 8 | Failures by service, endpoint, severity, and status code |
| Operational Health | 10 | Active incidents, pending processing, and incident aging |
| **Total** | **59** | |

## Query Interpretation

- Queries containing `$__timeFilter` or `$__timeGroupAlias` require Grafana to expand those macros.
- Queries without a time filter show the full current database state or accumulated history.
- Changing the dashboard time range affects only queries that include a time filter.
- Processing attempts are different from individual failures. One failure can have several attempts.
- Notification suppression is a recorded decision, distinct from a delivery failure.
- Historical AI totals include the disclosed pending backlog.

The SQL below contains no passwords, API keys, database connection strings, or personal email addresses.

## 1. Incident Overview

### Total Incidents

```sql
SELECT COUNT(*) AS total_incidents
FROM monitoring.incidents;
```

### Open Incidents

```sql
SELECT COUNT(*) AS open_incidents
FROM monitoring.incidents
WHERE incident_status = 'OPEN';
```

### Investigating Incidents

```sql
SELECT COUNT(*) AS investigating_incidents
FROM monitoring.incidents
WHERE incident_status = 'INVESTIGATING';
```

### Resolved Incidents

```sql
SELECT COUNT(*) AS resolved_incidents
FROM monitoring.incidents
WHERE incident_status = 'RESOLVED';
```

### Incidents by Severity

```sql
SELECT severity, COUNT(*) AS incident_count
FROM monitoring.incidents
GROUP BY severity
ORDER BY incident_count DESC;
```

### Incidents by Status

```sql
SELECT incident_status, COUNT(*) AS incident_count
FROM monitoring.incidents
GROUP BY incident_status
ORDER BY incident_count DESC;
```

### Incident Trend Over Time

```sql
SELECT
    $__timeGroupAlias(created_at, '1h'),
    COUNT(*) AS incidents_created
FROM monitoring.incidents
WHERE $__timeFilter(created_at)
GROUP BY 1
ORDER BY 1;
```

## 2. Incident Lifecycle and Resolution

### Reopened Incidents

```sql
SELECT COUNT(*) AS reopened_incidents
FROM monitoring.incidents
WHERE incident_status = 'REOPENED';
```

### Closed Incidents

```sql
SELECT COUNT(*) AS closed_incidents
FROM monitoring.incidents
WHERE incident_status = 'CLOSED';
```

### Resolved Incidents

```sql
SELECT COUNT(*) AS resolved_incidents
FROM monitoring.incidents
WHERE incident_status = 'RESOLVED';
```

### Average Time to Resolve in Hours

```sql
SELECT ROUND(
    AVG(EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600)::numeric,
    1
) AS avg_resolution_hours
FROM monitoring.incidents
WHERE resolved_at IS NOT NULL;
```

This metric uses the incident row's stored resolution timestamp. It does not calculate a separate duration for every resolution cycle.

### Status Transition History

```sql
SELECT
    changed_at AS time,
    previous_status,
    new_status,
    changed_by
FROM monitoring.incident_status_history
ORDER BY changed_at DESC;
```

### Resolutions Over Time

```sql
SELECT
    $__timeGroupAlias(changed_at, '1d'),
    COUNT(*) AS resolutions
FROM monitoring.incident_status_history
WHERE new_status = 'RESOLVED'
  AND $__timeFilter(changed_at)
GROUP BY 1
ORDER BY 1;
```

### Reopened vs Resolved

```sql
SELECT
    new_status,
    COUNT(*) AS transition_count
FROM monitoring.incident_status_history
WHERE new_status IN ('REOPENED', 'RESOLVED')
GROUP BY new_status
ORDER BY transition_count DESC;
```

These history queries count transitions. An incident can contribute more than one transition.

## 3. AI Processing and Reliability

### AI Analyses Completed

```sql
SELECT COUNT(*) AS completed_ai_analyses
FROM monitoring.ai_analysis;
```

This counts persisted analysis rows. Failure completion status is tracked separately in `api_failure_logs`.

### Failed AI Processing Attempts

```sql
SELECT COUNT(*) AS failed_ai_processes
FROM monitoring.processing_logs
WHERE process_type = 'AI_ANALYSIS'
  AND process_status = 'FAILED';
```

### Failures With AI Processing Errors

```sql
SELECT COUNT(DISTINCT failure_id) AS failures_with_ai_errors
FROM monitoring.processing_logs
WHERE process_type = 'AI_ANALYSIS'
  AND process_status = 'FAILED'
  AND failure_id IS NOT NULL;
```

This includes failures that had a failed attempt even if a later attempt succeeded.

### Historical AI Attempts by Attempt Number

```sql
SELECT
    attempt_number::text AS attempt_number,
    COUNT(*) AS attempt_count
FROM monitoring.processing_logs
WHERE process_type = 'AI_ANALYSIS'
GROUP BY attempt_number
ORDER BY attempt_number::integer;
```

### AI Processing Status Distribution

```sql
SELECT
    process_status,
    COUNT(*) AS status_count
FROM monitoring.processing_logs
WHERE process_type = 'AI_ANALYSIS'
GROUP BY process_status
ORDER BY status_count DESC;
```

### AI Processing Trigger Source

```sql
SELECT
    triggered_by,
    COUNT(*) AS trigger_count
FROM monitoring.processing_logs
WHERE process_type = 'AI_ANALYSIS'
GROUP BY triggered_by
ORDER BY trigger_count DESC;
```

### Historical AI Attempt Completion Rate

```sql
SELECT
    ROUND(
        100.0 * SUM(
            CASE WHEN process_status = 'COMPLETED' THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS success_rate_percent
FROM monitoring.processing_logs
WHERE process_type = 'AI_ANALYSIS';
```

The denominator includes all recorded AI analysis attempts, including `STARTED`, `FAILED`, and `SKIPPED`. This is an attempt completion percentage, not a per-failure success percentage.

### Failure AI Status Distribution

```sql
SELECT
    ai_status,
    COUNT(*) AS failure_count
FROM monitoring.api_failure_logs
GROUP BY ai_status
ORDER BY failure_count DESC;
```

### AI Analyses by Recommendation

```sql
SELECT
    recommended_action,
    COUNT(*) AS analysis_count
FROM monitoring.ai_analysis
GROUP BY recommended_action
ORDER BY analysis_count DESC;
```

### Average AI Confidence Score

```sql
SELECT
    ROUND(AVG(confidence_score)::numeric, 3) AS avg_confidence_score
FROM monitoring.ai_analysis;
```

The average uses non-null stored confidence values. It represents AI-reported confidence, not independently measured diagnostic accuracy.

## 4. Knowledge Base and Incident Patterns

### Knowledge Base Entries

```sql
SELECT COUNT(*) AS knowledge_base_entries
FROM monitoring.incident_knowledge_base;
```

### Knowledge Base Entries Used

```sql
SELECT COUNT(*) AS knowledge_base_entries_used
FROM monitoring.incident_knowledge_base
WHERE usage_count > 0;
```

### Knowledge Base Usage Count

```sql
SELECT
    endpoint,
    usage_count
FROM monitoring.incident_knowledge_base
ORDER BY usage_count DESC, endpoint;
```

This returns individual knowledge entries. Multiple entries can share an endpoint.

### Active Knowledge Base Entries

```sql
SELECT COUNT(*) AS active_kb_entries
FROM monitoring.incident_knowledge_base
WHERE is_active = true;
```

### Knowledge Base Coverage by Endpoint

```sql
SELECT
    endpoint,
    COUNT(*) AS kb_entries
FROM monitoring.incident_knowledge_base
GROUP BY endpoint
ORDER BY kb_entries DESC, endpoint;
```

### Knowledge Base Details

```sql
SELECT
    service_name,
    endpoint,
    status_code,
    root_cause,
    recommended_solution,
    prevention_steps,
    usage_count,
    is_active,
    updated_at
FROM monitoring.incident_knowledge_base
ORDER BY updated_at DESC;
```

### Knowledge Base Entries by Status Code

```sql
SELECT
    status_code::text AS status_code,
    COUNT(*) AS kb_entries
FROM monitoring.incident_knowledge_base
GROUP BY status_code
ORDER BY status_code;
```

### Knowledge Base Last Updated

```sql
SELECT
    updated_at AS time,
    endpoint,
    usage_count
FROM monitoring.incident_knowledge_base
ORDER BY updated_at;
```

This shows each entry's current last-update timestamp, rather than a complete history of knowledge updates.

## 5. Notifications and Alerting

### Notifications Sent

```sql
SELECT COUNT(*) AS notifications_sent
FROM monitoring.notification_history
WHERE delivery_status = 'SENT';
```

### Notifications Failed

```sql
SELECT COUNT(*) AS notifications_failed
FROM monitoring.notification_history
WHERE delivery_status = 'FAILED';
```

### Notifications Suppressed

```sql
SELECT COUNT(*) AS notifications_suppressed
FROM monitoring.notification_history
WHERE delivery_status = 'SUPPRESSED';
```

### Notifications by Type

```sql
SELECT
    notification_type,
    COUNT(*) AS notification_count
FROM monitoring.notification_history
GROUP BY notification_type
ORDER BY notification_count DESC;
```

### Notification Delivery Status

```sql
SELECT
    delivery_status,
    COUNT(*) AS status_count
FROM monitoring.notification_history
GROUP BY delivery_status
ORDER BY status_count DESC;
```

### Notifications Over Time

```sql
SELECT
    $__timeGroupAlias(created_at, '1h'),
    COUNT(*) AS notification_count
FROM monitoring.notification_history
WHERE $__timeFilter(created_at)
GROUP BY 1
ORDER BY 1;
```

This counts all notification history entries in the selected period, including suppressed and failed decisions.

### Suppressed Notifications by Type

```sql
SELECT
    notification_type,
    COUNT(*) AS suppressed_count
FROM monitoring.notification_history
WHERE delivery_status = 'SUPPRESSED'
GROUP BY notification_type
ORDER BY suppressed_count DESC;
```

### Sent Notifications by Type

```sql
SELECT
    notification_type,
    COUNT(*) AS sent_count
FROM monitoring.notification_history
WHERE delivery_status = 'SENT'
GROUP BY notification_type
ORDER BY sent_count DESC;
```

### Notification History

```sql
SELECT
    created_at,
    incident_id,
    notification_type,
    delivery_status,
    sent_at,
    error_message
FROM monitoring.notification_history
ORDER BY created_at DESC;
```

Notification history references incidents rather than individual failure IDs.

## 6. Failure and Service Analytics

### Total API Failures

```sql
SELECT COUNT(*) AS total_api_failures
FROM monitoring.api_failure_logs;
```

### Unique Incidents from Failures

```sql
SELECT COUNT(DISTINCT incident_id) AS unique_incidents
FROM monitoring.api_failure_logs
WHERE incident_id IS NOT NULL;
```

This counts incidents referenced by captured failures. It is distinct from counting all rows in `incidents`.

### Failures by Severity

```sql
SELECT
    severity,
    COUNT(*) AS failure_count
FROM monitoring.api_failure_logs
GROUP BY severity
ORDER BY failure_count DESC;
```

### Failures by Endpoint

```sql
SELECT
    endpoint,
    COUNT(*) AS failure_count
FROM monitoring.api_failure_logs
GROUP BY endpoint
ORDER BY failure_count DESC;
```

### Failures Over Time

```sql
SELECT
    date_trunc('day', created_at) AS time,
    COUNT(*) AS failure_count
FROM monitoring.api_failure_logs
WHERE $__timeFilter(created_at)
GROUP BY 1
ORDER BY 1;
```

### Failures by Status Code

```sql
SELECT
    status_code::text AS status_code,
    COUNT(*) AS failure_count
FROM monitoring.api_failure_logs
GROUP BY status_code
ORDER BY failure_count DESC;
```

### Failures by Service

```sql
SELECT
    service_name,
    COUNT(*) AS failure_count
FROM monitoring.api_failure_logs
GROUP BY service_name
ORDER BY failure_count DESC;
```

### Top Failure Messages

```sql
SELECT
    error_message,
    COUNT(*) AS failure_count
FROM monitoring.api_failure_logs
GROUP BY error_message
ORDER BY failure_count DESC
LIMIT 10;
```

## 7. Operational Health

### Active Incidents

```sql
SELECT COUNT(*) AS active_incidents
FROM monitoring.incidents
WHERE incident_status IN ('OPEN', 'INVESTIGATING', 'REOPENED');
```

### Unresolved High Severity Incidents

```sql
SELECT COUNT(*) AS unresolved_high_severity_incidents
FROM monitoring.incidents
WHERE severity = 'HIGH'
  AND incident_status IN ('OPEN', 'INVESTIGATING', 'REOPENED');
```

### Pending AI Failures

```sql
SELECT COUNT(*) AS pending_ai_failures
FROM monitoring.api_failure_logs
WHERE ai_status = 'PENDING';
```

### Notification Failure Count

```sql
SELECT COUNT(*) AS notification_failures
FROM monitoring.notification_history
WHERE delivery_status = 'FAILED';
```

### Active Knowledge Base Entries

```sql
SELECT COUNT(*) AS active_kb_entries
FROM monitoring.incident_knowledge_base
WHERE is_active = true;
```

### Current Incident Status Distribution

```sql
SELECT
    incident_status,
    COUNT(*) AS incident_count
FROM monitoring.incidents
GROUP BY incident_status
ORDER BY incident_count DESC;
```

### AI Failure Status Distribution

```sql
SELECT
    ai_status,
    COUNT(*) AS failure_count
FROM monitoring.api_failure_logs
GROUP BY ai_status
ORDER BY failure_count DESC;
```

### Notification Delivery Health

```sql
SELECT
    delivery_status,
    COUNT(*) AS notification_count
FROM monitoring.notification_history
GROUP BY delivery_status
ORDER BY notification_count DESC;
```

### Oldest Active Incident Age in Hours

```sql
SELECT
    ROUND(
        MAX(
            EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - created_at)) / 3600
        )::numeric,
        1
    ) AS oldest_active_incident_hours
FROM monitoring.incidents
WHERE incident_status IN ('OPEN', 'INVESTIGATING', 'REOPENED');
```

### Active Incident Aging

```sql
SELECT
    incident_id,
    service_name,
    endpoint,
    severity,
    incident_status,
    occurrence_count,
    ROUND(
        (EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - created_at)) / 3600)::numeric,
        1
    ) AS age_hours
FROM monitoring.incidents
WHERE incident_status IN ('OPEN', 'INVESTIGATING', 'REOPENED')
ORDER BY age_hours DESC;
```

Incident age is measured from the original `created_at` value, including for reopened incidents.

## Timestamp Interpretation

The schema contains both timestamps without time zone and timestamps with time zone.

Metrics combining these types depend on the PostgreSQL session time zone. Interpret dashboard times consistently with the application's timestamp convention and the Grafana data source configuration.

## Verification Context

The latest supplied regression evidence records:

- Failure `100` linked to incident `7`.
- Failure AI status `COMPLETED`.
- Notification history entry `51` for incident `7` marked `SUPPRESSED`.
- Suppression reason: `Duplicate occurrence did not meet notification threshold`.

The historical snapshot contains 53 pending AI failures. Dashboard totals can therefore show historical pending and failed processing alongside a successful latest regression.

## Related Documentation

- [Phase 3 README](README.md)
- [Implementation Overview](overview.md)
- [Database Documentation](database.md)
- [Release Verification](release-verification.md)
- [Grafana SQL Catalogue](../../database/phase3/grafana-queries.sql)

---

**Created by Farha Serin Naaz**
