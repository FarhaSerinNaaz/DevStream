-- DevStream Database Schema
-- Creates the schema and tables required for the
-- AI-Powered Incident Monitoring Pipeline.

CREATE SCHEMA IF NOT EXISTS monitoring;

CREATE TABLE IF NOT EXISTS monitoring.api_failure_logs (
    failure_id BIGSERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    endpoint VARCHAR(500) NOT NULL,
    http_method VARCHAR(10),
    status_code INTEGER NOT NULL,
    response_time_ms INTEGER,
    severity VARCHAR(20) NOT NULL,
    error_message TEXT,
    stack_trace TEXT,
    ai_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS monitoring.ai_analysis (
    analysis_id BIGSERIAL PRIMARY KEY,
    failure_id BIGINT UNIQUE NOT NULL,
    root_cause TEXT,
    java_fix TEXT,
    unit_test TEXT,
    best_practice TEXT,
    confidence_score NUMERIC(4,3),
    recommended_action VARCHAR(30),
    analyzed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_ai_analysis_failure
        FOREIGN KEY (failure_id)
        REFERENCES monitoring.api_failure_logs(failure_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_confidence_score
        CHECK (
            confidence_score IS NULL
            OR confidence_score BETWEEN 0 AND 1
        ),

    CONSTRAINT chk_recommended_action
        CHECK (
            recommended_action IS NULL
            OR recommended_action IN (
                'CREATE_INCIDENT',
                'LOG_ONLY',
                'RETRY',
                'ESCALATE'
            )
        )
);
