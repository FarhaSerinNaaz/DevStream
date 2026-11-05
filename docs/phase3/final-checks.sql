-- DevStream Phase 3: Final database checks
-- Author: Farha Serin Naaz
-- Read-only PostgreSQL queries for the monitoring schema.

-- 1. Column definitions
SELECT table_name, ordinal_position, column_name, data_type,
       is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'monitoring'
ORDER BY table_name, ordinal_position;

-- 2. Constraint definitions
SELECT c.conrelid::regclass AS table_name,
       c.conname AS constraint_name,
       pg_get_constraintdef(c.oid) AS definition
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
WHERE n.nspname = 'monitoring'
ORDER BY table_name, constraint_name;

-- 3. Seven integrity checks
SELECT 'unlinked_failures' AS check_name, COUNT(*) AS issue_count
FROM monitoring.api_failure_logs
WHERE incident_id IS NULL

UNION ALL

SELECT 'failures_linked_to_missing_incidents', COUNT(*)
FROM monitoring.api_failure_logs f
LEFT JOIN monitoring.incidents i ON i.incident_id = f.incident_id
WHERE f.incident_id IS NOT NULL AND i.incident_id IS NULL

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
      SELECT 1 FROM monitoring.ai_analysis a
      WHERE a.failure_id = f.failure_id
  )

UNION ALL

SELECT 'pending_failures_with_persisted_analysis', COUNT(*)
FROM monitoring.api_failure_logs f
WHERE f.ai_status = 'PENDING'
  AND EXISTS (
      SELECT 1 FROM monitoring.ai_analysis a
      WHERE a.failure_id = f.failure_id
  )

UNION ALL

SELECT 'incident_occurrence_count_mismatches', COUNT(*)
FROM (
    SELECT i.incident_id
    FROM monitoring.incidents i
    LEFT JOIN monitoring.api_failure_logs f ON f.incident_id = i.incident_id
    GROUP BY i.incident_id, i.occurrence_count
    HAVING i.occurrence_count IS DISTINCT FROM COUNT(f.failure_id)
) d;

-- 4. AI status totals
SELECT ai_status, COUNT(*) AS failure_count
FROM monitoring.api_failure_logs
GROUP BY ai_status
ORDER BY ai_status;

-- 5. Stored occurrence counts versus linked failures
SELECT i.incident_id, i.occurrence_count AS stored_count,
       COUNT(f.failure_id) AS linked_failure_count
FROM monitoring.incidents i
LEFT JOIN monitoring.api_failure_logs f ON f.incident_id = i.incident_id
GROUP BY i.incident_id, i.occurrence_count
ORDER BY i.incident_id;

-- 6. Recorded final regression: failure 100
SELECT failure_id, incident_id, endpoint, ai_status, created_at
FROM monitoring.api_failure_logs
WHERE failure_id = 100;

-- 7. Recorded duplicate suppression for incident 7
-- Notification history references the incident.
SELECT notification_history_id, incident_id, notification_type,
       delivery_status, suppression_reason, created_at
FROM monitoring.notification_history
WHERE notification_history_id = 51 AND incident_id = 7;

-- 8. Pending failures and their latest AI attempt by start time
-- The retry service applies its limit using the highest attempt number.
SELECT f.failure_id, f.incident_id, f.endpoint, f.ai_status, f.created_at,
       EXISTS (
           SELECT 1 FROM monitoring.ai_analysis a
           WHERE a.failure_id = f.failure_id
       ) AS has_ai_analysis,
       p.process_status, p.attempt_number, p.triggered_by,
       p.started_at, p.completed_at, p.process_message, p.error_message
FROM monitoring.api_failure_logs f
LEFT JOIN LATERAL (
    SELECT pl.*
    FROM monitoring.processing_logs pl
    WHERE pl.failure_id = f.failure_id AND pl.process_type = 'AI_ANALYSIS'
    ORDER BY pl.started_at DESC, pl.processing_log_id DESC
    LIMIT 1
) p ON TRUE
WHERE f.ai_status = 'PENDING'
ORDER BY f.created_at, f.failure_id;
