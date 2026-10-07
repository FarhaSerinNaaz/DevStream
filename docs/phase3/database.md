# Phase 3 – Database Documentation

## Overview

DevStream uses PostgreSQL hosted on Neon. The `monitoring` schema stores API failures, grouped incidents, AI outputs, incident knowledge, operational history, processing attempts, and notification decisions.

This reference covers **10 tables and 121 columns**, based on the verified Phase 3 schema exports.

Earlier phase database documentation and SQL files remain separate and unchanged.

## Table Inventory

| Table | Columns | Purpose |
|-------|---------|---------|
| `api_failure_logs` | 12 | Raw API failures and AI processing state |
| `incidents` | 28 | Grouped incidents and current operational state |
| `ai_analysis` | 9 | Persisted AI analysis for individual failures |
| `ai_agent_results` | 12 | Outputs of the three AI agent roles |
| `incident_status_history` | 7 | Incident lifecycle transition history |
| `incident_assignment_history` | 9 | Team and individual assignment history |
| `incident_notes` | 6 | Operational notes |
| `incident_knowledge_base` | 15 | Reusable diagnosis and resolution knowledge |
| `processing_logs` | 12 | Processing attempts, outcomes, and errors |
| `notification_history` | 11 | Notification delivery and suppression history |
| **Total** | **121** | |

## Reading the Data Dictionary

- `varchar` means PostgreSQL `character varying`.
- `timestamp` means `timestamp without time zone`.
- `timestamptz` means `timestamp with time zone`.
- Nullable `NO` represents a `NOT NULL` requirement.
- Default `None` means no column default was captured.
- Sequence defaults are listed separately.

Character lengths, numeric precision, indexes, and complete sequence configuration were not included in the supplied exports. This document is a database reference, not a complete schema recreation migration.

## 1. API Failure Logs

**Table:** `monitoring.api_failure_logs`

Preserves individual API failures and their AI processing status.

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| failure_id | bigint | NO | Sequence |
| service_name | varchar | NO | None |
| endpoint | varchar | NO | None |
| http_method | varchar | YES | None |
| status_code | integer | NO | None |
| response_time_ms | integer | YES | None |
| severity | varchar | NO | None |
| error_message | text | YES | None |
| stack_trace | text | YES | None |
| ai_status | varchar | NO | `'PENDING'::character varying` |
| created_at | timestamp | NO | `CURRENT_TIMESTAMP` |
| incident_id | bigint | YES | None |

### Sequence Default

```sql
nextval('monitoring.api_failure_logs_failure_id_seq'::regclass)
```

### Captured Constraints

```sql
-- api_failure_logs_pkey
PRIMARY KEY (failure_id)

-- fk_api_failure_incident
FOREIGN KEY (incident_id)
REFERENCES monitoring.incidents(incident_id)
```

## 2. Incidents

**Table:** `monitoring.incidents`

Stores grouped incidents, occurrence counts, lifecycle state, assignment, acknowledgement, and notification state.

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| incident_id | bigint | NO | Sequence |
| incident_fingerprint | varchar | NO | None |
| service_name | varchar | NO | None |
| endpoint | varchar | NO | None |
| status_code | integer | NO | None |
| error_message | text | YES | None |
| severity | varchar | NO | None |
| incident_status | varchar | NO | `'OPEN'::character varying` |
| occurrence_count | integer | NO | `1` |
| first_seen | timestamp | NO | None |
| last_seen | timestamp | NO | None |
| created_at | timestamp | NO | `CURRENT_TIMESTAMP` |
| updated_at | timestamp | NO | `CURRENT_TIMESTAMP` |
| assigned_team | varchar | YES | None |
| assigned_to | varchar | YES | None |
| acknowledged_by | varchar | YES | None |
| acknowledged_at | timestamptz | YES | None |
| resolved_by | varchar | YES | None |
| resolved_at | timestamptz | YES | None |
| closed_by | varchar | YES | None |
| closed_at | timestamptz | YES | None |
| reassignment_count | integer | NO | `0` |
| notification_status | varchar | NO | `'PENDING'::character varying` |
| notification_attempts | integer | NO | `0` |
| last_notification_attempt_at | timestamptz | YES | None |
| incident_category | varchar | NO | `'UNKNOWN'::character varying` |
| assignment_status | varchar | NO | `'NOT_ASSIGNED'::character varying` |
| acknowledgement_status | varchar | NO | `'PENDING'::character varying` |

### Sequence Default

```sql
nextval('monitoring.incidents_incident_id_seq'::regclass)
```

### Captured Constraints

```sql
-- incidents_pkey
PRIMARY KEY (incident_id)

-- incidents_incident_fingerprint_key
UNIQUE (incident_fingerprint)

-- chk_acknowledgement_status
CHECK (((acknowledgement_status)::text = ANY (
    (ARRAY['PENDING'::character varying,
           'ACKNOWLEDGED'::character varying])::text[]
)))

-- chk_assignment_status
CHECK (((assignment_status)::text = ANY (
    (ARRAY['NOT_ASSIGNED'::character varying,
           'ASSIGNED'::character varying])::text[]
)))

-- chk_incident_category
CHECK (((incident_category)::text = ANY (
    (ARRAY['DATABASE'::character varying,
           'NETWORK'::character varying,
           'AUTHENTICATION'::character varying,
           'TIMEOUT'::character varying,
           'VALIDATION'::character varying,
           'APPLICATION'::character varying,
           'DEPENDENCY'::character varying,
           'CONFIGURATION'::character varying,
           'UNKNOWN'::character varying])::text[]
)))

-- chk_incident_status
CHECK (((incident_status)::text = ANY (
    (ARRAY['OPEN'::character varying,
           'INVESTIGATING'::character varying,
           'RESOLVED'::character varying,
           'REOPENED'::character varying,
           'CLOSED'::character varying])::text[]
)))

-- chk_notification_attempts
CHECK ((notification_attempts >= 0))

-- chk_notification_status
CHECK (((notification_status)::text = ANY (
    (ARRAY['PENDING'::character varying,
           'SENT'::character varying,
           'FAILED'::character varying])::text[]
)))

-- chk_occurrence_count
CHECK ((occurrence_count >= 1))

-- chk_reassignment_count
CHECK ((reassignment_count >= 0))
```

## 3. AI Analysis

**Table:** `monitoring.ai_analysis`

Stores persisted AI analysis for a failure. The unique failure reference prevents multiple analysis rows for the same failure.

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| analysis_id | bigint | NO | Sequence |
| failure_id | bigint | NO | None |
| root_cause | text | YES | None |
| java_fix | text | YES | None |
| unit_test | text | YES | None |
| best_practice | text | YES | None |
| confidence_score | numeric | YES | None |
| recommended_action | varchar | YES | None |
| analyzed_at | timestamp | NO | `CURRENT_TIMESTAMP` |

### Sequence Default

```sql
nextval('monitoring.ai_analysis_analysis_id_seq'::regclass)
```

### Captured Constraints

```sql
-- ai_analysis_pkey
PRIMARY KEY (analysis_id)

-- ai_analysis_failure_id_key
UNIQUE (failure_id)

-- chk_confidence_score
CHECK (((confidence_score IS NULL)
    OR ((confidence_score >= (0)::numeric)
    AND (confidence_score <= (1)::numeric))))

-- chk_recommended_action
CHECK (((recommended_action IS NULL)
    OR ((recommended_action)::text = ANY (
        (ARRAY['CREATE_INCIDENT'::character varying,
               'LOG_ONLY'::character varying,
               'RETRY'::character varying,
               'ESCALATE'::character varying])::text[]
    ))))

-- fk_ai_analysis_failure
FOREIGN KEY (failure_id)
REFERENCES monitoring.api_failure_logs(failure_id)
ON DELETE CASCADE
```

## 4. AI Agent Results

**Table:** `monitoring.ai_agent_results`

Stores individual agent outputs and execution details, with references to the incident, failure, analysis, and processing attempt.

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| agent_result_id | bigint | NO | Sequence |
| processing_log_id | bigint | YES | None |
| failure_id | bigint | YES | None |
| incident_id | bigint | NO | None |
| analysis_id | bigint | YES | None |
| agent_name | varchar | NO | None |
| agent_output | text | YES | None |
| confidence_score | numeric | YES | None |
| execution_status | varchar | NO | None |
| execution_time_ms | integer | YES | None |
| error_message | text | YES | None |
| created_at | timestamptz | NO | `CURRENT_TIMESTAMP` |

### Sequence Default

```sql
nextval('monitoring.ai_agent_results_agent_result_id_seq'::regclass)
```

### Captured Constraints

```sql
-- ai_agent_results_pkey
PRIMARY KEY (agent_result_id)

-- chk_agent_results_completed_output
CHECK ((((execution_status)::text <> 'COMPLETED'::text)
    OR (agent_output IS NOT NULL)))

-- chk_agent_results_confidence
CHECK (((confidence_score IS NULL)
    OR ((confidence_score >= (0)::numeric)
    AND (confidence_score <= (1)::numeric))))

-- chk_agent_results_execution_time
CHECK (((execution_time_ms IS NULL) OR (execution_time_ms >= 0)))

-- chk_agent_results_failed_error
CHECK ((((execution_status)::text <> 'FAILED'::text)
    OR (error_message IS NOT NULL)))

-- chk_agent_results_name
CHECK (((agent_name)::text = ANY (
    (ARRAY['INCIDENT_ANALYSIS_AGENT'::character varying,
           'KNOWLEDGE_BASE_AGENT'::character varying,
           'INCIDENT_COORDINATOR_AGENT'::character varying])::text[]
)))

-- chk_agent_results_status
CHECK (((execution_status)::text = ANY (
    (ARRAY['COMPLETED'::character varying,
           'FAILED'::character varying,
           'SKIPPED'::character varying])::text[]
)))

-- fk_agent_results_analysis
FOREIGN KEY (analysis_id)
REFERENCES monitoring.ai_analysis(analysis_id)
ON DELETE SET NULL

-- fk_agent_results_failure
FOREIGN KEY (failure_id)
REFERENCES monitoring.api_failure_logs(failure_id)
ON DELETE CASCADE

-- fk_agent_results_incident
FOREIGN KEY (incident_id)
REFERENCES monitoring.incidents(incident_id)
ON DELETE CASCADE

-- fk_agent_results_processing_log
FOREIGN KEY (processing_log_id)
REFERENCES monitoring.processing_logs(processing_log_id)
ON DELETE SET NULL
```

## 5. Incident Status History

**Table:** `monitoring.incident_status_history`

Records lifecycle transitions, who made the change, and the reason.

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| status_history_id | bigint | NO | Sequence |
| incident_id | bigint | NO | None |
| previous_status | varchar | YES | None |
| new_status | varchar | NO | None |
| changed_by | varchar | NO | None |
| change_reason | text | YES | None |
| changed_at | timestamptz | NO | `CURRENT_TIMESTAMP` |

### Sequence Default

```sql
nextval('monitoring.incident_status_history_status_history_id_seq'::regclass)
```

### Captured Constraints

```sql
-- incident_status_history_pkey
PRIMARY KEY (status_history_id)

-- chk_status_history_new_status
CHECK (((new_status)::text = ANY (
    (ARRAY['OPEN'::character varying,
           'INVESTIGATING'::character varying,
           'RESOLVED'::character varying,
           'REOPENED'::character varying,
           'CLOSED'::character varying])::text[]
)))

-- chk_status_history_previous_status
CHECK (((previous_status IS NULL)
    OR ((previous_status)::text = ANY (
        (ARRAY['OPEN'::character varying,
               'INVESTIGATING'::character varying,
               'RESOLVED'::character varying,
               'REOPENED'::character varying,
               'CLOSED'::character varying])::text[]
    ))))

-- chk_status_history_transition
CHECK (((previous_status IS NULL)
    OR ((previous_status)::text <> (new_status)::text)))

-- fk_status_history_incident
FOREIGN KEY (incident_id)
REFERENCES monitoring.incidents(incident_id)
ON DELETE CASCADE
```

## 6. Incident Assignment History

**Table:** `monitoring.incident_assignment_history`

Preserves previous and new assignment details with the actor and reason.

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| assignment_history_id | bigint | NO | Sequence |
| incident_id | bigint | NO | None |
| previous_assigned_team | varchar | YES | None |
| previous_assigned_to | varchar | YES | None |
| new_assigned_team | varchar | YES | None |
| new_assigned_to | varchar | YES | None |
| assigned_by | varchar | NO | None |
| assignment_reason | text | YES | None |
| assigned_at | timestamptz | NO | `CURRENT_TIMESTAMP` |

### Sequence Default

```sql
nextval('monitoring.incident_assignment_history_assignment_history_id_seq'::regclass)
```

### Captured Constraints

```sql
-- incident_assignment_history_pkey
PRIMARY KEY (assignment_history_id)

-- chk_assignment_history_has_target
CHECK (((new_assigned_team IS NOT NULL)
    OR (new_assigned_to IS NOT NULL)
    OR ((previous_assigned_team IS NOT NULL)
    OR (previous_assigned_to IS NOT NULL))))

-- fk_assignment_history_incident
FOREIGN KEY (incident_id)
REFERENCES monitoring.incidents(incident_id)
ON DELETE CASCADE
```

## 7. Incident Notes

**Table:** `monitoring.incident_notes`

Stores operational notes associated with incidents.

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| note_id | bigint | NO | Sequence |
| incident_id | bigint | NO | None |
| note_type | varchar | NO | None |
| note_text | text | NO | None |
| created_by | varchar | NO | None |
| created_at | timestamptz | NO | `CURRENT_TIMESTAMP` |

### Sequence Default

```sql
nextval('monitoring.incident_notes_note_id_seq'::regclass)
```

### Captured Constraints

```sql
-- incident_notes_pkey
PRIMARY KEY (note_id)

-- chk_incident_note_type
CHECK (((note_type)::text = ANY (
    (ARRAY['INVESTIGATION'::character varying,
           'WORKAROUND'::character varying,
           'ROOT_CAUSE'::character varying,
           'FIX'::character varying,
           'VALIDATION'::character varying,
           'HANDOVER'::character varying,
           'GENERAL'::character varying])::text[]
)))

-- fk_incident_notes_incident
FOREIGN KEY (incident_id)
REFERENCES monitoring.incidents(incident_id)
ON DELETE CASCADE
```

## 8. Incident Knowledge Base

**Table:** `monitoring.incident_knowledge_base`

Stores reusable diagnosis and resolution knowledge identified by incident fingerprint.

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| knowledge_id | bigint | NO | Sequence |
| incident_fingerprint | varchar | NO | None |
| service_name | varchar | NO | None |
| endpoint | varchar | NO | None |
| status_code | integer | NO | None |
| error_message | text | NO | None |
| root_cause | text | NO | None |
| recommended_solution | text | NO | None |
| prevention_steps | text | YES | None |
| source_analysis_id | bigint | YES | None |
| usage_count | integer | NO | `0` |
| last_used_at | timestamptz | YES | None |
| is_active | boolean | NO | `true` |
| created_at | timestamptz | NO | `CURRENT_TIMESTAMP` |
| updated_at | timestamptz | NO | `CURRENT_TIMESTAMP` |

### Sequence Default

```sql
nextval('monitoring.incident_knowledge_base_knowledge_id_seq'::regclass)
```

### Captured Constraints

```sql
-- incident_knowledge_base_pkey
PRIMARY KEY (knowledge_id)

-- incident_knowledge_base_incident_fingerprint_key
UNIQUE (incident_fingerprint)

-- chk_knowledge_usage_count
CHECK ((usage_count >= 0))

-- fk_knowledge_source_analysis
FOREIGN KEY (source_analysis_id)
REFERENCES monitoring.ai_analysis(analysis_id)
```

## 9. Processing Logs

**Table:** `monitoring.processing_logs`

Records processing attempts, their trigger, status, timing, and diagnostic messages.

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| processing_log_id | bigint | NO | Sequence |
| failure_id | bigint | YES | None |
| incident_id | bigint | YES | None |
| process_type | varchar | NO | None |
| process_status | varchar | NO | None |
| attempt_number | integer | NO | `1` |
| triggered_by | varchar | NO | None |
| started_at | timestamptz | NO | `CURRENT_TIMESTAMP` |
| completed_at | timestamptz | YES | None |
| process_message | text | YES | None |
| error_message | text | YES | None |
| created_at | timestamptz | NO | `CURRENT_TIMESTAMP` |

### Sequence Default

```sql
nextval('monitoring.processing_logs_processing_log_id_seq'::regclass)
```

### Captured Constraints

```sql
-- processing_logs_pkey
PRIMARY KEY (processing_log_id)

-- chk_processing_logs_attempt_number
CHECK ((attempt_number >= 1))

-- chk_processing_logs_completed_at
CHECK ((((process_status)::text <> ALL (
    (ARRAY['COMPLETED'::character varying,
           'FAILED'::character varying,
           'SKIPPED'::character varying])::text[]
)) OR (completed_at IS NOT NULL)))

-- chk_processing_logs_error_message
CHECK ((((process_status)::text <> 'FAILED'::text)
    OR (error_message IS NOT NULL)))

-- chk_processing_logs_reference
CHECK (((failure_id IS NOT NULL) OR (incident_id IS NOT NULL)))

-- chk_processing_logs_skipped_message
CHECK ((((process_status)::text <> 'SKIPPED'::text)
    OR (process_message IS NOT NULL)))

-- chk_processing_logs_status
CHECK (((process_status)::text = ANY (
    (ARRAY['STARTED'::character varying,
           'COMPLETED'::character varying,
           'FAILED'::character varying,
           'SKIPPED'::character varying])::text[]
)))

-- chk_processing_logs_triggered_by
CHECK (((triggered_by)::text = ANY (
    (ARRAY['WEBHOOK'::character varying,
           'SCHEDULER'::character varying,
           'RETRY'::character varying,
           'MANUAL'::character varying])::text[]
)))

-- chk_processing_logs_type
CHECK (((process_type)::text = ANY (
    (ARRAY['AI_ANALYSIS'::character varying,
           'INCIDENT_GROUPING'::character varying,
           'KNOWLEDGE_BASE_UPDATE'::character varying,
           'NOTIFICATION'::character varying])::text[]
)))

-- fk_processing_logs_failure
FOREIGN KEY (failure_id)
REFERENCES monitoring.api_failure_logs(failure_id)
ON DELETE CASCADE

-- fk_processing_logs_incident
FOREIGN KEY (incident_id)
REFERENCES monitoring.incidents(incident_id)
ON DELETE CASCADE
```

## 10. Notification History

**Table:** `monitoring.notification_history`

Records notification delivery and suppression decisions. It references an incident, not an individual failure.

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| notification_history_id | bigint | NO | Sequence |
| incident_id | bigint | NO | None |
| notification_type | varchar | NO | None |
| channel | varchar | NO | `'EMAIL'::character varying` |
| recipient | varchar | YES | None |
| delivery_status | varchar | NO | None |
| suppression_reason | text | YES | None |
| attempt_number | integer | NO | `1` |
| error_message | text | YES | None |
| sent_at | timestamptz | YES | None |
| created_at | timestamptz | NO | `CURRENT_TIMESTAMP` |

### Sequence Default

```sql
nextval('monitoring.notification_history_notification_history_id_seq'::regclass)
```

### Captured Constraints

```sql
-- notification_history_pkey
PRIMARY KEY (notification_history_id)

-- chk_notification_attempt_number
CHECK ((attempt_number >= 1))

-- chk_notification_channel
CHECK (((channel)::text = 'EMAIL'::text))

-- chk_notification_delivery_status
CHECK (((delivery_status)::text = ANY (
    (ARRAY['PENDING'::character varying,
           'SENT'::character varying,
           'FAILED'::character varying,
           'SUPPRESSED'::character varying])::text[]
)))

-- chk_notification_error_message
CHECK ((((delivery_status)::text <> 'FAILED'::text)
    OR (error_message IS NOT NULL)))

-- chk_notification_sent_at
CHECK ((((delivery_status)::text <> 'SENT'::text)
    OR (sent_at IS NOT NULL)))

-- chk_notification_suppression_reason
CHECK ((((delivery_status)::text <> 'SUPPRESSED'::text)
    OR (suppression_reason IS NOT NULL)))

-- chk_notification_type
CHECK (((notification_type)::text = ANY (
    (ARRAY['NEW_INCIDENT'::character varying,
           'SEVERITY_ESCALATION'::character varying,
           'SEVERITY_DEESCALATION'::character varying,
           'OCCURRENCE_THRESHOLD'::character varying,
           'REOPENED'::character varying,
           'RESOLVED'::character varying,
           'ASSIGNMENT'::character varying,
           'ACKNOWLEDGEMENT_PENDING'::character varying,
           'OPEN_INCIDENT_REMINDER'::character varying,
           'DUPLICATE_OCCURRENCE'::character varying])::text[]
)))

-- fk_notification_history_incident
FOREIGN KEY (incident_id)
REFERENCES monitoring.incidents(incident_id)
ON DELETE CASCADE
```

## SQL Reference Notes

The constraint blocks above contain captured definition fragments for documentation. They are not standalone executable migrations.

The inspection and verification queries below are read-only and can run in Neon SQL Editor.

Grafana-specific queries are documented separately because Grafana macros do not run directly in Neon SQL Editor.

## Schema Inspection

### Column Definitions

```sql
SELECT
    table_name,
    ordinal_position,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'monitoring'
ORDER BY table_name, ordinal_position;
```

### Constraint Definitions

```sql
SELECT
    c.conrelid::regclass AS table_name,
    c.conname AS constraint_name,
    pg_get_constraintdef(c.oid) AS definition
FROM pg_constraint c
JOIN pg_namespace n
    ON n.oid = c.connamespace
WHERE n.nspname = 'monitoring'
ORDER BY table_name, constraint_name;
```

## Database Integrity Checks

```sql
SELECT 'unlinked_failures' AS check_name, COUNT(*) AS issue_count
FROM monitoring.api_failure_logs
WHERE incident_id IS NULL

UNION ALL

SELECT 'failures_linked_to_missing_incidents', COUNT(*)
FROM monitoring.api_failure_logs f
LEFT JOIN monitoring.incidents i
    ON i.incident_id = f.incident_id
WHERE f.incident_id IS NOT NULL
  AND i.incident_id IS NULL

UNION ALL

SELECT 'duplicate_incident_fingerprints', COUNT(*)
FROM (
    SELECT incident_fingerprint
    FROM monitoring.incidents
    GROUP BY incident_fingerprint
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT 'duplicate_ai_analyses', COUNT(*)
FROM (
    SELECT failure_id
    FROM monitoring.ai_analysis
    GROUP BY failure_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT 'completed_failures_without_analysis', COUNT(*)
FROM monitoring.api_failure_logs f
WHERE f.ai_status = 'COMPLETED'
  AND NOT EXISTS (
      SELECT 1
      FROM monitoring.ai_analysis a
      WHERE a.failure_id = f.failure_id
  )

UNION ALL

SELECT 'pending_failures_with_persisted_analysis', COUNT(*)
FROM monitoring.api_failure_logs f
WHERE f.ai_status = 'PENDING'
  AND EXISTS (
      SELECT 1
      FROM monitoring.ai_analysis a
      WHERE a.failure_id = f.failure_id
  )

UNION ALL

SELECT 'incident_occurrence_count_mismatches', COUNT(*)
FROM (
    SELECT i.incident_id
    FROM monitoring.incidents i
    LEFT JOIN monitoring.api_failure_logs f
        ON f.incident_id = i.incident_id
    GROUP BY i.incident_id, i.occurrence_count
    HAVING i.occurrence_count
        IS DISTINCT FROM COUNT(f.failure_id)
) d;
```

## Operational Queries

### AI Status Totals

```sql
SELECT ai_status, COUNT(*) AS failure_count
FROM monitoring.api_failure_logs
GROUP BY ai_status
ORDER BY ai_status;
```

### Incident Occurrence Comparison

```sql
SELECT
    i.incident_id,
    i.occurrence_count AS stored_count,
    COUNT(f.failure_id) AS linked_failure_count
FROM monitoring.incidents i
LEFT JOIN monitoring.api_failure_logs f
    ON f.incident_id = i.incident_id
GROUP BY i.incident_id, i.occurrence_count
ORDER BY i.incident_id;
```

### Verified Regression Failure

This query retrieves the specific failure used as final regression evidence.

```sql
SELECT
    failure_id,
    incident_id,
    endpoint,
    ai_status,
    created_at
FROM monitoring.api_failure_logs
WHERE failure_id = 100;
```

### Verified Duplicate Notification

```sql
SELECT
    notification_history_id,
    incident_id,
    notification_type,
    delivery_status,
    suppression_reason,
    created_at
FROM monitoring.notification_history
WHERE notification_history_id = 51
  AND incident_id = 7;
```

### Pending Failures and Latest AI Attempt

This query selects the latest attempt by start time. The retry service separately uses the highest recorded attempt number when applying its retry limit.

```sql
SELECT
    f.failure_id,
    f.incident_id,
    f.endpoint,
    f.ai_status,
    f.created_at,
    EXISTS (
        SELECT 1
        FROM monitoring.ai_analysis a
        WHERE a.failure_id = f.failure_id
    ) AS has_ai_analysis,
    p.process_status,
    p.attempt_number,
    p.triggered_by,
    p.started_at,
    p.completed_at,
    p.process_message,
    p.error_message
FROM monitoring.api_failure_logs f
LEFT JOIN LATERAL (
    SELECT pl.*
    FROM monitoring.processing_logs pl
    WHERE pl.failure_id = f.failure_id
      AND pl.process_type = 'AI_ANALYSIS'
    ORDER BY pl.started_at DESC, pl.processing_log_id DESC
    LIMIT 1
) p ON TRUE
WHERE f.ai_status = 'PENDING'
ORDER BY f.created_at, f.failure_id;
```

## Historical Database Cleanup

The final cleanup linked 17 historical failure records to uniquely matched existing incidents.

| Failure IDs | Incident ID |
|-------------|-------------|
| 34, 35, 36 | 1 |
| 49, 50, 51, 54, 55, 58, 59, 62, 63, 72, 73 | 7 |
| 65 | 10 |
| 67 | 11 |
| 69 | 12 |

Occurrence counts were recalculated for incidents `1`, `7`, `10`, `11`, and `12`.

The repair changed failure links and occurrence counts. It did not change AI statuses, incident fingerprints, lifecycle states, or timestamps.

The executed transaction is retained separately in [Archived Repair SQL](../../database/phase3/archive/2026-10-06-link-count-repair.sql) as historical evidence.

### Verified Post-Cleanup Results

| Check | Issue Count |
|-------|-------------|
| Unlinked failures | 0 |
| Incident occurrence-count mismatches | 0 |

The other five integrity checks returned zero in the initial supplied check. The post-cleanup result supplied separately verified the two checks shown above.

## Historical AI Backlog

The captured historical snapshot contains **53 pending failures without persisted AI analysis**.

| Latest Recorded AI Processing State | Failures |
|-------------------------------------|----------|
| FAILED | 47 |
| STARTED | 1 |
| No AI processing log | 5 |
| **Total** | **53** |

Of these failures, 48 had a highest recorded attempt number of at least three. Five had no recorded AI analysis attempt.

This is historical snapshot evidence. Subsequent bulk recovery has not been verified.

## Schema Management

The captured application configuration uses:

```properties
spring.jpa.hibernate.ddl-auto=none
```

A complete recreation migration requires an authoritative schema export including type lengths, numeric precision, indexes, and sequence configuration.

## Related Documentation

- [Phase 3 README](README.md)
- [Implementation Overview](overview.md)
- [Grafana Dashboards](dashboards.md)
- [Release Verification](release-verification.md)
- [Final Checks SQL](../../database/phase3/final-checks.sql)
- [Phase 2 Database Documentation](../phase2/database.md)

---

**Created by Farha Serin Naaz**
