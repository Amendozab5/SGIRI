CREATE TABLE IF NOT EXISTS soporte.network_probe_run (
    id_run SERIAL PRIMARY KEY,
    target VARCHAR(255) NOT NULL,
    data_source VARCHAR(50) NOT NULL,
    tool VARCHAR(50) NOT NULL,
    probe_count INTEGER NOT NULL,
    success BOOLEAN NOT NULL,
    error_message TEXT,
    duration_ms BIGINT,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS soporte.network_probe_result (
    id_result SERIAL PRIMARY KEY,
    id_run INTEGER NOT NULL REFERENCES soporte.network_probe_run(id_run) ON DELETE CASCADE,
    zone_type VARCHAR(50) NOT NULL,
    zone_id INTEGER NOT NULL,
    latency_ms FLOAT,
    packet_loss FLOAT,
    http_status INTEGER,
    score INTEGER,
    level VARCHAR(50)
);

GRANT ALL PRIVILEGES ON TABLE soporte.network_probe_run TO postgres;
GRANT ALL PRIVILEGES ON TABLE soporte.network_probe_result TO postgres;
GRANT USAGE, SELECT ON SEQUENCE soporte.network_probe_run_id_run_seq TO postgres;
GRANT USAGE, SELECT ON SEQUENCE soporte.network_probe_result_id_result_seq TO postgres;
