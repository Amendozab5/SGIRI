package com.apweb.backend.service;

import com.apweb.backend.dto.NetworkMapDTO;
import com.apweb.backend.dto.HeatmapPointDTO;
import com.apweb.backend.model.NetworkProbeResult;
import com.apweb.backend.model.NetworkProbeRun;
import com.apweb.backend.repository.NetworkProbeResultRepository;
import com.apweb.backend.repository.NetworkProbeRunRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
public class NetworkServiceImpl implements NetworkService {

    @Autowired
    private NetworkProbeRunRepository runRepository;

    @Autowired
    private NetworkProbeResultRepository resultRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public List<NetworkMapDTO> getNetworkMapData(String zoneType) {

        // 1. Fetch latest network stats
        Optional<NetworkProbeRun> latestRunOpt = runRepository.findTopByOrderByCreatedAtDesc();
        Double latencyOverallMs = 0.0;
        Integer redScore = 100;
        String dataSource = "NONE";
        LocalDateTime generatedAt = LocalDateTime.now();
        LocalDateTime lastSuccessfulCheckAt = null;

        if (latestRunOpt.isPresent()) {
            NetworkProbeRun run = latestRunOpt.get();
            dataSource = run.getDataSource();
            generatedAt = run.getCreatedAt();

            if (run.getSuccess()) {
                lastSuccessfulCheckAt = run.getCreatedAt();
            } else {
                Optional<NetworkProbeRun> lastSuccess = runRepository.findTopBySuccessTrueOrderByCreatedAtDesc();
                lastSuccessfulCheckAt = lastSuccess.map(NetworkProbeRun::getCreatedAt).orElse(null);
            }

            List<NetworkProbeResult> results = resultRepository.findByRun(run);

            if (!results.isEmpty()) {
                NetworkProbeResult result = results.get(0);
                latencyOverallMs = result.getLatencyMs();
                if (result.getScore() != null) {
                    redScore = result.getScore();
                }
            }
        }

        // 2. Query open tickets and priority grouped by Zone
        String sql = "";
        if ("PROVINCIA".equalsIgnoreCase(zoneType)) {
            sql = "SELECT c.id_ciudad as zone_id, c.nombre as zone_name, " +
                    "COUNT(t.id_ticket) as open_tickets, " +
                    "MAX(ci.orden) as max_severity " + 
                    "FROM clientes.ciudad c " +
                    "LEFT JOIN empresa.sucursal s ON s.id_ciudad = c.id_ciudad " +
                    "LEFT JOIN soporte.ticket t ON t.id_sucursal = s.id_sucursal AND t.fecha_cierre IS NULL " +
                    "LEFT JOIN catalogos.catalogo_item ci ON ci.id_item = t.id_prioridad_item " +
                    "GROUP BY c.id_ciudad, c.nombre " +
                    "ORDER BY c.nombre";
        } else {
            // Default to CANTON
            sql = "SELECT c.id_canton as zone_id, c.nombre as zone_name, " +
                    "COUNT(t.id_ticket) as open_tickets, " +
                    "MAX(ci.orden) as max_severity " +
                    "FROM clientes.canton c " +
                    "LEFT JOIN empresa.sucursal s ON s.id_canton = c.id_canton " +
                    "LEFT JOIN soporte.ticket t ON t.id_sucursal = s.id_sucursal AND t.fecha_cierre IS NULL " +
                    "LEFT JOIN catalogos.catalogo_item ci ON ci.id_item = t.id_prioridad_item " +
                    "GROUP BY c.id_canton, c.nombre " +
                    "ORDER BY c.nombre";
        }

        List<Map<String, Object>> rows = jdbcTemplate.queryForList(sql);
        List<NetworkMapDTO> response = new ArrayList<>();

        if ("PROVINCIA".equalsIgnoreCase(zoneType)) {
            // ... (keep province normalization logic same)
            List<String> ALL_PROVINCES = java.util.Arrays.asList(
                    "Azuay", "Bolívar", "Cañar", "Carchi", "Cotopaxi", "Chimborazo", "El Oro",
                    "Esmeraldas", "Guayas", "Imbabura", "Loja", "Los Ríos", "Manabí",
                    "Morona Santiago", "Napo", "Pastaza", "Pichincha", "Tungurahua",
                    "Zamora Chinchipe", "Galápagos", "Sucumbíos", "Orellana",
                    "Santo Domingo de los Tsáchilas", "Santa Elena");

            Map<String, NetworkMapDTO> provMap = new java.util.HashMap<>();
            Map<String, String> normalizedSearchMap = new java.util.HashMap<>();

            for (int i = 0; i < ALL_PROVINCES.size(); i++) {
                String pName = ALL_PROVINCES.get(i);
                NetworkMapDTO dto = new NetworkMapDTO();
                dto.setZoneId(i + 1);
                dto.setZoneName(pName);
                dto.setOpenTickets(0);
                dto.setMaxPriority("BAJA");
                dto.setScoreTickets(100);
                dto.setScoreFinal(Math.min(redScore, 100));
                
                if (dto.getScoreFinal() >= 80) dto.setLevel("GOOD");
                else if (dto.getScoreFinal() >= 50) dto.setLevel("WARNING");
                else dto.setLevel("CRITICAL");

                dto.setDataSource(dataSource);
                dto.setLatencyOverallMs(latencyOverallMs);
                dto.setGeneratedAt(generatedAt);
                dto.setLastSuccessfulCheckAt(lastSuccessfulCheckAt);

                String key = pName.toUpperCase();
                provMap.put(key, dto);
                String norm = java.text.Normalizer.normalize(key, java.text.Normalizer.Form.NFD)
                        .replaceAll("\\p{InCombiningDiacriticalMarks}+", "").toUpperCase();
                normalizedSearchMap.put(norm, key);
            }

            for (Map<String, Object> row : rows) {
                String zoneName = (String) row.get("zone_name");
                if (zoneName == null) continue;
                String normalizedDB = zoneName.toUpperCase();
                NetworkMapDTO dto = provMap.get(normalizedDB);
                if (dto == null) {
                    String normDB = java.text.Normalizer.normalize(zoneName, java.text.Normalizer.Form.NFD)
                            .replaceAll("\\p{InCombiningDiacriticalMarks}+", "").toUpperCase();
                    String originalKey = normalizedSearchMap.get(normDB);
                    if (originalKey != null) dto = provMap.get(originalKey);
                }
                if (dto == null) {
                    dto = new NetworkMapDTO();
                    dto.setZoneId(((Number) row.get("zone_id")).intValue());
                    dto.setZoneName(zoneName);
                    dto.setDataSource(dataSource);
                    dto.setLatencyOverallMs(latencyOverallMs);
                    dto.setGeneratedAt(generatedAt);
                    dto.setLastSuccessfulCheckAt(lastSuccessfulCheckAt);
                    provMap.put(normalizedDB, dto);
                }

                int openTickets = ((Number) row.get("open_tickets")).intValue();
                dto.setOpenTickets(openTickets);

                int maxSeverity = row.get("max_severity") != null ? ((Number) row.get("max_severity")).intValue() : 0;
                String maxPriorityStr = "NINGUNA";
                int penalty = 0;

                if (openTickets > 0) {
                    if (maxSeverity >= 4) { // Orden 4: CRITICA, 5: ULTRA
                        maxPriorityStr = "CRITICA";
                        penalty = 40;
                    } else if (maxSeverity == 3) { // Orden 3: ALTA
                        maxPriorityStr = "ALTA";
                        penalty = 20;
                    } else if (maxSeverity == 2) { // Orden 2: MEDIA
                        maxPriorityStr = "MEDIA";
                        penalty = 10;
                    } else { // Orden 1: BAJA
                        maxPriorityStr = "BAJA";
                        penalty = 5;
                    }
                }

                int scoreTickets = Math.max(0, 100 - penalty - (openTickets * 2));
                int scoreFinal = Math.min(redScore, scoreTickets);

                dto.setMaxPriority(maxPriorityStr);
                dto.setScoreTickets(scoreTickets);
                dto.setScoreFinal(scoreFinal);

                if (scoreFinal >= 80) dto.setLevel("GOOD");
                else if (scoreFinal >= 50) dto.setLevel("WARNING");
                else dto.setLevel("CRITICAL");
            }
            response.addAll(provMap.values());
        } else {
            for (Map<String, Object> row : rows) {
                NetworkMapDTO dto = new NetworkMapDTO();
                dto.setZoneId(((Number) row.get("zone_id")).intValue());
                dto.setZoneName((String) row.get("zone_name"));
                int openTickets = ((Number) row.get("open_tickets")).intValue();
                dto.setOpenTickets(openTickets);

                int maxSeverity = row.get("max_severity") != null ? ((Number) row.get("max_severity")).intValue() : 0;
                String maxPriorityStr = "NINGUNA";
                int penalty = 0;

                if (openTickets > 0) {
                    if (maxSeverity >= 4) {
                        maxPriorityStr = "CRITICA";
                        penalty = 40;
                    } else if (maxSeverity == 3) {
                        maxPriorityStr = "ALTA";
                        penalty = 20;
                    } else if (maxSeverity == 2) {
                        maxPriorityStr = "MEDIA";
                        penalty = 10;
                    } else {
                        maxPriorityStr = "BAJA";
                        penalty = 5;
                    }
                }

                int scoreTickets = Math.max(0, 100 - penalty - (openTickets * 2));
                int scoreFinal = Math.min(redScore, scoreTickets);
                dto.setMaxPriority(maxPriorityStr);
                dto.setScoreTickets(scoreTickets);
                dto.setScoreFinal(scoreFinal);
                if (scoreFinal >= 80) dto.setLevel("GOOD");
                else if (scoreFinal >= 50) dto.setLevel("WARNING");
                else dto.setLevel("CRITICAL");

                dto.setDataSource(dataSource);
                dto.setLatencyOverallMs(latencyOverallMs);
                dto.setGeneratedAt(generatedAt);
                dto.setLastSuccessfulCheckAt(lastSuccessfulCheckAt);
                response.add(dto);
            }
        }
        return response;
    }

    @Override
    public List<HeatmapPointDTO> getHeatmapData() {
        List<HeatmapPointDTO> points = new ArrayList<>();
        String ticketSql = "SELECT t.asunto as label, " +
                "COALESCE(t.latitud, s.latitud) as latitud, " +
                "COALESCE(t.longitud, s.longitud) as longitud, " +
                "ci.orden as severity " +
                "FROM soporte.ticket t " +
                "JOIN empresa.sucursal s ON t.id_sucursal = s.id_sucursal " +
                "LEFT JOIN catalogos.catalogo_item ci ON ci.id_item = t.id_prioridad_item " +
                "WHERE t.fecha_cierre IS NULL " +
                "AND (t.latitud IS NOT NULL OR s.latitud IS NOT NULL)";

        List<Map<String, Object>> rows = jdbcTemplate.queryForList(ticketSql);
        for (Map<String, Object> row : rows) {
            java.math.BigDecimal lat = (java.math.BigDecimal) row.get("latitud");
            java.math.BigDecimal lng = (java.math.BigDecimal) row.get("longitud");
            int severity = row.get("severity") != null ? ((Number) row.get("severity")).intValue() : 1;

            // Intensity: 5 (Ultra) -> 1.0, 4 (Critica) -> 0.9, 3 (Alta) -> 0.7, 2 (Media) -> 0.5, 1 (Baja) -> 0.3
            double intensity = Math.min(1.0, 0.15 + (severity * 0.17));
            points.add(new HeatmapPointDTO(lat, lng, intensity, (String) row.get("label")));
        }

        if (points.isEmpty()) {
            points.add(new HeatmapPointDTO(new java.math.BigDecimal("-0.1807"), new java.math.BigDecimal("-78.4678"), 1.0, "Quito (MOCK)"));
            points.add(new HeatmapPointDTO(new java.math.BigDecimal("-2.1708"), new java.math.BigDecimal("-79.9224"), 0.9, "Guayaquil (MOCK)"));
            points.add(new HeatmapPointDTO(new java.math.BigDecimal("-2.9001"), new java.math.BigDecimal("-79.0059"), 0.8, "Cuenca (MOCK)"));
            points.add(new HeatmapPointDTO(new java.math.BigDecimal("-1.0242"), new java.math.BigDecimal("-79.4633"), 0.7, "Quevedo (MOCK)"));
            points.add(new HeatmapPointDTO(new java.math.BigDecimal("-0.9621"), new java.math.BigDecimal("-80.7127"), 0.6, "Manta (MOCK)"));
        }
        return points;
    }
}
