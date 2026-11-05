-- DevStream Phase 3: Historical link and occurrence-count repair
-- Already executed and verified on 6 October 2026.
-- Archive only. Do not use as a startup or deployment migration.

BEGIN;

LOCK TABLE monitoring.api_failure_logs, monitoring.incidents
IN SHARE ROW EXCLUSIVE MODE;

WITH verified_links (failure_id, incident_id) AS (
    VALUES
        (34, 1),
        (35, 1),
        (36, 1),
        (49, 7),
        (50, 7),
        (51, 7),
        (54, 7),
        (55, 7),
        (58, 7),
        (59, 7),
        (62, 7),
        (63, 7),
        (65, 10),
        (67, 11),
        (69, 12),
        (72, 7),
        (73, 7)
)
UPDATE monitoring.api_failure_logs f
SET incident_id = v.incident_id
FROM verified_links v, monitoring.incidents i
WHERE f.failure_id = v.failure_id
  AND i.incident_id = v.incident_id
  AND f.incident_id IS NULL
  AND LOWER(TRIM(f.service_name)) = LOWER(TRIM(i.service_name))
  AND LOWER(TRIM(f.endpoint)) = LOWER(TRIM(i.endpoint))
  AND f.status_code = i.status_code
  AND LOWER(TRIM(COALESCE(f.error_message, '')))
      = LOWER(TRIM(COALESCE(i.error_message, '')))
RETURNING f.failure_id, f.incident_id, f.ai_status;

WITH actual_counts AS (
    SELECT incident_id, COUNT(*)::integer AS actual_count
    FROM monitoring.api_failure_logs
    WHERE incident_id IN (1, 7, 10, 11, 12)
    GROUP BY incident_id
)
UPDATE monitoring.incidents i
SET occurrence_count = a.actual_count
FROM actual_counts a
WHERE i.incident_id = a.incident_id
  AND i.occurrence_count IS DISTINCT FROM a.actual_count
RETURNING i.incident_id, i.endpoint, i.occurrence_count;

COMMIT;
