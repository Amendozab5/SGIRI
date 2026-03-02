package com.apweb.backend.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;

@Component
public class NetworkMapDatabaseInitializer {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @PostConstruct
    public void initialize() {
        String createRunTable = "CREATE TABLE IF NOT EXISTS soporte.network_probe_run (" +
                "id_run SERIAL PRIMARY KEY, " +
                "target VARCHAR(255) NOT NULL, " +
                "data_source VARCHAR(50) NOT NULL, " +
                "tool VARCHAR(50) NOT NULL, " +
                "probe_count INTEGER NOT NULL, " +
                "success BOOLEAN NOT NULL, " +
                "error_message TEXT, " +
                "duration_ms BIGINT, " +
                "created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()" +
                ");";

        String createResultTable = "CREATE TABLE IF NOT EXISTS soporte.network_probe_result (" +
                "id_result SERIAL PRIMARY KEY, " +
                "id_run INTEGER NOT NULL REFERENCES soporte.network_probe_run(id_run) ON DELETE CASCADE, " +
                "zone_type VARCHAR(50) NOT NULL, " +
                "zone_id INTEGER NOT NULL, " +
                "latency_ms FLOAT, " +
                "packet_loss FLOAT, " +
                "http_status INTEGER, " +
                "score INTEGER, " +
                "level VARCHAR(50)" +
                ");";

        jdbcTemplate.execute(createRunTable);
        jdbcTemplate.execute(createResultTable);

        try {
            jdbcTemplate.execute(
                    "ALTER TABLE soporte.network_probe_run ADD COLUMN IF NOT EXISTS tool VARCHAR(50) DEFAULT 'ping';");
            jdbcTemplate.execute(
                    "ALTER TABLE soporte.network_probe_run ADD COLUMN IF NOT EXISTS probe_count INTEGER DEFAULT 0;");
            jdbcTemplate.execute(
                    "ALTER TABLE soporte.network_probe_run ADD COLUMN IF NOT EXISTS success BOOLEAN DEFAULT false;");
            jdbcTemplate.execute("ALTER TABLE soporte.network_probe_run ADD COLUMN IF NOT EXISTS error_message TEXT;");
            jdbcTemplate.execute(
                    "ALTER TABLE soporte.network_probe_run ADD COLUMN IF NOT EXISTS duration_ms BIGINT DEFAULT 0;");
        } catch (Exception e) {
        }
    }
}
