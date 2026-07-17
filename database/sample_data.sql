-- DevStream Sample Data
-- Demonstrates sample API failures and corresponding AI analysis.

-- ============================
-- Sample API Failure Records
-- ============================

INSERT INTO monitoring.api_failure_logs
(service_name, endpoint, http_method, status_code, response_time_ms, severity, error_message, stack_trace, ai_status)
VALUES
(
'Order Service',
'/api/orders',
'POST',
500,
2450,
'HIGH',
'NullPointerException while creating order',
'java.lang.NullPointerException at OrderService.java:87',
'COMPLETED'
),

(
'Payment Service',
'/api/payment',
'POST',
404,
620,
'MEDIUM',
'Payment endpoint not found',
'org.springframework.web.HttpRequestMethodNotSupportedException',
'COMPLETED'
),

(
'Inventory Service',
'/api/inventory',
'GET',
200,
1800,
'LOW',
'Slow API response',
NULL,
'COMPLETED'
);

-- ============================
-- Sample AI Analysis
-- ============================

INSERT INTO monitoring.ai_analysis
(failure_id, root_cause, java_fix, unit_test, best_practice, confidence_score, recommended_action)
VALUES
(
1,
'Possible null object reference while processing order request.',
'Validate request objects using Objects.requireNonNull() and add null checks before processing.',
'Add unit tests for null request scenarios and invalid payloads.',
'Validate inputs early and use defensive programming techniques.',
0.982,
'CREATE_INCIDENT'
),

(
2,
'Incorrect endpoint mapping or outdated API route.',
'Verify @RequestMapping annotations and API gateway routing configuration.',
'Add integration tests to validate endpoint mappings.',
'Maintain API versioning and route documentation.',
0.936,
'LOG_ONLY'
),

(
3,
'Slow database query or temporary resource contention.',
'Optimize SQL query and review indexing strategy.',
'Add performance tests for inventory APIs.',
'Monitor response times and configure application metrics.',
0.874,
'RETRY'
);
