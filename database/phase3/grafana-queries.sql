-- DevStream Phase 3: Grafana SQL catalogue
-- Author: Farha Serin Naaz
-- 59 read-only panel queries for the Grafana PostgreSQL data source.
-- Use one query per panel. Grafana expands the time macros.

-- 1. Incident Overview (7 queries)

-- Total Incidents
SELECT COUNT(*) AS total_incidents
FROM monitoring.incidents;

-- Open Incidents
SELECT COUNT(*) AS open_incidents
FROM monitoring.incidents
WHERE incident_status = 'OPEN';

-- Investigating Incidents
SELECT COUNT(*) AS investigating_incidents
FROM monitoring.incidents
WHERE incident_status = 'INVESTIGATING';

-- Resolved Incidents
SELECT COUNT(*) AS resolved_incidents
FROM monitoring.incidents
WHERE incident_status = 'RESOLVED';

-- Incidents by Severity
SELECT severity, COUNT(*) AS incident_count
FROM monitoring.incidents
GROUP BY severity
ORDER BY incident_count DESC;

-- Incidents by Status
SELECT incident_status, COUNT(*) AS incident_count
FROM monitoring.incidents
GROUP BY incident_status
ORDER BY incident_count DESC;

-- Incident Trend Over Time
SELECT $__timeGroupAlias(created_at, '1h'),
       COUNT(*) AS incidents_created
FROM monitoring.incidents
WHERE $__timeFilter(created_at)
GROUP BY 1
ORDER BY 1;

-- 2. Incident Lifecycle and Resolution (7 queries)

-- Reopened Incidents
SELECT COUNT(*) AS reopened_incidents
FROM monitoring.incidents
WHERE incident_status = 'REOPENED';

-- Closed Incidents
SELECT COUNT(*) AS closed_incidents
FROM monitoring.incidents
WHERE incident_status = 'CLOSED';

-- Resolved Incidents
SELECT COUNT(*) AS resolved_incidents
FROM monitoring.incidents
WHERE incident_status = 'RESOLVED';

-- Average Time to Resolve in Hours
SELECT ROUND(
    AVG(EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600)::numeric,
    1
) AS avg_resolution_hours
FROM monitoring.incidents
WHERE resolved_at IS NOT NULL;

-- Status Transition History
SELECT changed_at AS time, previous_status, new_status, changed_by
FROM monitoring.incident_status_history
ORDER BY changed_at DESC;

-- Resolutions Over Time
SELECT $__timeGroupAlias(changed_at, '1d'),
       COUNT(*) AS resolutions
FROM monitoring.incident_status_history
WHERE new_status = 'RESOLVED'
  AND $__timeFilter(changed_at)
GROUP BY 1
ORDER BY 1;

-- Reopened vs Resolved
SELECT new_status, COUNT(*) AS transition_count
FROM monitoring.incident_status_history
WHERE new_status IN ('REOPENED', 'RESOLVED')
GROUP BY new_status
ORDER BY transition_count DESC;

-- 3. AI Processing and Reliability (10 queries)

-- AI Analyses Completed
SELECT COUNT(*) AS completed_ai_analyses
FROM monitoring.ai_analysis;

-- Failed AI Processing Attempts
SELECT COUNT(*) AS failed_ai_processes
FROM monitoring.processing_logs
WHERE process_type = 'AI_ANALYSIS'
  AND process_status = 'FAILED';

-- Failures With AI Processing Errors
SELECT COUNT(DISTINCT failure_id) AS failures_with_ai_errors
FROM monitoring.processing_logs
WHERE process_type = 'AI_ANALYSIS'
  AND process_status = 'FAILED'
  AND failure_id IS NOT NULL;

-- Historical AI Attempts by Attempt Number
SELECT attempt_number::text AS attempt_number,
       COUNT(*) AS attempt_count
FROM monitoring.processing_logs
WHERE process_type = 'AI_ANALYSIS'
GROUP BY attempt_number
ORDER BY attempt_number::integer;

-- AI Processing Status Distribution
SELECT process_status, COUNT(*) AS status_count
FROM monitoring.processing_logs
WHERE process_type = 'AI_ANALYSIS'
GROUP BY process_status
ORDER BY status_count DESC;

-- AI Processing Trigger Source
SELECT triggered_by, COUNT(*) AS trigger_count
FROM monitoring.processing_logs
WHERE process_type = 'AI_ANALYSIS'
GROUP BY triggered_by
ORDER BY trigger_count DESC;

-- Historical AI Attempt Completion Rate
SELECT ROUND(
    100.0 * SUM(CASE WHEN process_status = 'COMPLETED' THEN 1 ELSE 0 END)
    / NULLIF(COUNT(*), 0),
    2
) AS success_rate_percent
FROM monitoring.processing_logs
WHERE process_type = 'AI_ANALYSIS';

-- Failure AI Status Distribution
SELECT ai_status, COUNT(*) AS failure_count
FROM monitoring.api_failure_logs
GROUP BY ai_status
ORDER BY failure_count DESC;

-- AI Analyses by Recommendation
SELECT recommended_action, COUNT(*) AS analysis_count
FROM monitoring.ai_analysis
GROUP BY recommended_action
ORDER BY analysis_count DESC;

-- Average AI Confidence Score
SELECT ROUND(AVG(confidence_score)::numeric, 3) AS avg_confidence_score
FROM monitoring.ai_analysis;

-- 4. Knowledge Base and Incident Patterns (8 queries)

-- Knowledge Base Entries
SELECT COUNT(*) AS knowledge_base_entries
FROM monitoring.incident_knowledge_base;

-- Knowledge Base Entries Used
SELECT COUNT(*) AS knowledge_base_entries_used
FROM monitoring.incident_knowledge_base
WHERE usage_count > 0;

-- Knowledge Base Usage Count
SELECT endpoint, usage_count
FROM monitoring.incident_knowledge_base
ORDER BY usage_count DESC, endpoint;

-- Active Knowledge Base Entries
SELECT COUNT(*) AS active_kb_entries
FROM monitoring.incident_knowledge_base
WHERE is_active = true;

-- Knowledge Base Coverage by Endpoint
SELECT endpoint, COUNT(*) AS kb_entries
FROM monitoring.incident_knowledge_base
GROUP BY endpoint
ORDER BY kb_entries DESC, endpoint;

-- Knowledge Base Details
SELECT service_name, endpoint, status_code, root_cause,
       recommended_solution, prevention_steps, usage_count,
       is_active, updated_at
FROM monitoring.incident_knowledge_base
ORDER BY updated_at DESC;

-- Knowledge Base Entries by Status Code
SELECT status_code::text AS status_code, COUNT(*) AS kb_entries
FROM monitoring.incident_knowledge_base
GROUP BY status_code
ORDER BY status_code;

-- Knowledge Base Last Updated
SELECT updated_at AS time, endpoint, usage_count
FROM monitoring.incident_knowledge_base
ORDER BY updated_at;

-- 5. Notifications and Alerting (9 queries)

-- Notifications Sent
SELECT COUNT(*) AS notifications_sent
FROM monitoring.notification_history
WHERE delivery_status = 'SENT';

-- Notifications Failed
SELECT COUNT(*) AS notifications_failed
FROM monitoring.notification_history
WHERE delivery_status = 'FAILED';

-- Notifications Suppressed
SELECT COUNT(*) AS notifications_suppressed
FROM monitoring.notification_history
WHERE delivery_status = 'SUPPRESSED';

-- Notifications by Type
SELECT notification_type, COUNT(*) AS notification_count
FROM monitoring.notification_history
GROUP BY notification_type
ORDER BY notification_count DESC;

-- Notification Delivery Status
SELECT delivery_status, COUNT(*) AS status_count
FROM monitoring.notification_history
GROUP BY delivery_status
ORDER BY status_count DESC;

-- Notifications Over Time
SELECT $__timeGroupAlias(created_at, '1h'),
       COUNT(*) AS notification_count
FROM monitoring.notification_history
WHERE $__timeFilter(created_at)
GROUP BY 1
ORDER BY 1;

-- Suppressed Notifications by Type
SELECT notification_type, COUNT(*) AS suppressed_count
FROM monitoring.notification_history
WHERE delivery_status = 'SUPPRESSED'
GROUP BY notification_type
ORDER BY suppressed_count DESC;

-- Sent Notifications by Type
SELECT notification_type, COUNT(*) AS sent_count
FROM monitoring.notification_history
WHERE delivery_status = 'SENT'
GROUP BY notification_type
ORDER BY sent_count DESC;

-- Notification History
SELECT created_at, incident_id, notification_type,
       delivery_status, sent_at, error_message
FROM monitoring.notification_history
ORDER BY created_at DESC;

-- 6. Failure and Service Analytics (8 queries)

-- Total API Failures
SELECT COUNT(*) AS total_api_failures
FROM monitoring.api_failure_logs;

-- Unique Incidents from Failures
SELECT COUNT(DISTINCT incident_id) AS unique_incidents
FROM monitoring.api_failure_logs
WHERE incident_id IS NOT NULL;

-- Failures by Severity
SELECT severity, COUNT(*) AS failure_count
FROM monitoring.api_failure_logs
GROUP BY severity
ORDER BY failure_count DESC;

-- Failures by Endpoint
SELECT endpoint, COUNT(*) AS failure_count
FROM monitoring.api_failure_logs
GROUP BY endpoint
ORDER BY failure_count DESC;

-- Failures Over Time
SELECT date_trunc('day', created_at) AS time, COUNT(*) AS failure_count
FROM monitoring.api_failure_logs
WHERE $__timeFilter(created_at)
GROUP BY 1
ORDER BY 1;

-- Failures by Status Code
SELECT status_code::text AS status_code, COUNT(*) AS failure_count
FROM monitoring.api_failure_logs
GROUP BY status_code
ORDER BY failure_count DESC;

-- Failures by Service
SELECT service_name, COUNT(*) AS failure_count
FROM monitoring.api_failure_logs
GROUP BY service_name
ORDER BY failure_count DESC;

-- Top Failure Messages
SELECT error_message, COUNT(*) AS failure_count
FROM monitoring.api_failure_logs
GROUP BY error_message
ORDER BY failure_count DESC
LIMIT 10;

-- 7. Operational Health (10 queries)

-- Active Incidents
SELECT COUNT(*) AS active_incidents
FROM monitoring.incidents
WHERE incident_status IN ('OPEN', 'INVESTIGATING', 'REOPENED');

-- Unresolved High Severity Incidents
SELECT COUNT(*) AS unresolved_high_severity_incidents
FROM monitoring.incidents
WHERE severity = 'HIGH'
  AND incident_status IN ('OPEN', 'INVESTIGATING', 'REOPENED');

-- Pending AI Failures
SELECT COUNT(*) AS pending_ai_failures
FROM monitoring.api_failure_logs
WHERE ai_status = 'PENDING';

-- Notification Failure Count
SELECT COUNT(*) AS notification_failures
FROM monitoring.notification_history
WHERE delivery_status = 'FAILED';

-- Active Knowledge Base Entries
SELECT COUNT(*) AS active_kb_entries
FROM monitoring.incident_knowledge_base
WHERE is_active = true;

-- Current Incident Status Distribution
SELECT incident_status, COUNT(*) AS incident_count
FROM monitoring.incidents
GROUP BY incident_status
ORDER BY incident_count DESC;

-- AI Failure Status Distribution
SELECT ai_status, COUNT(*) AS failure_count
FROM monitoring.api_failure_logs
GROUP BY ai_status
ORDER BY failure_count DESC;

-- Notification Delivery Health
SELECT delivery_status, COUNT(*) AS notification_count
FROM monitoring.notification_history
GROUP BY delivery_status
ORDER BY notification_count DESC;

-- Oldest Active Incident Age in Hours
SELECT ROUND(
    MAX(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - created_at)) / 3600)::numeric,
    1
) AS oldest_active_incident_hours
FROM monitoring.incidents
WHERE incident_status IN ('OPEN', 'INVESTIGATING', 'REOPENED');

-- Active Incident Aging
SELECT incident_id, service_name, endpoint, severity,
       incident_status, occurrence_count,
       ROUND(
           (EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - created_at)) / 3600)::numeric,
           1
       ) AS age_hours
FROM monitoring.incidents
WHERE incident_status IN ('OPEN', 'INVESTIGATING', 'REOPENED')
ORDER BY age_hours DESC;
