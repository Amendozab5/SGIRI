package com.apweb.backend.service;

import com.apweb.backend.dto.NetworkMapDTO;
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

        // 2. Query open tickets and priority grouped by Zone (Provincia=ciudad or
        // Canton)
        // We match support tickets that don't have an explicitly "cerrado" status.
        // Assuming id_estado_item for closed is usually known, or we just count where
        // fecha_cierre IS NULL
        String sql = "";
        if ("PROVINCIA".equalsIgnoreCase(zoneType)) {
            sql = "SELECT c.id_ciudad as zone_id, c.nombre as zone_name, " +
                    "COUNT(t.id_ticket) as open_tickets, " +
                    "MAX(p.id_prioridad) as max_priority_id " + // Priority ID assumes higher = more critical, or we
                                                                // handle it via mapping
                    "FROM clientes.ciudad c " +
                    "LEFT JOIN empresa.sucursal s ON s.id_ciudad = c.id_ciudad " +
                    "LEFT JOIN soporte.ticket t ON t.id_sucursal = s.id_sucursal AND t.fecha_cierre IS NULL " +
                    "LEFT JOIN soporte.prioridad p ON p.id_item = t.id_prioridad_item " +
                    "GROUP BY c.id_ciudad, c.nombre " +
                    "ORDER BY c.nombre";
        } else {
            // Default to CANTON
            sql = "SELECT c.id_canton as zone_id, c.nombre as zone_name, " +
                    "COUNT(t.id_ticket) as open_tickets, " +
                    "MAX(p.id_prioridad) as max_priority_id " +
                    "FROM clientes.canton c " +
                    "LEFT JOIN empresa.sucursal s ON s.id_canton = c.id_canton " +
                    "LEFT JOIN soporte.ticket t ON t.id_sucursal = s.id_sucursal AND t.fecha_cierre IS NULL " +
                    "LEFT JOIN soporte.prioridad p ON p.id_item = t.id_prioridad_item " +
                    "GROUP BY c.id_canton, c.nombre " +
                    "ORDER BY c.nombre";
        }

        List<Map<String, Object>> rows = jdbcTemplate.queryForList(sql);
        List<NetworkMapDTO> response = new ArrayList<>();

        if ("PROVINCIA".equalsIgnoreCase(zoneType)) {
            List<String> ALL_PROVINCES = java.util.Arrays.asList(
                    "Azuay", "Bolívar", "Cañar", "Carchi", "Cotopaxi", "Chimborazo", "El Oro",
                    "Esmeraldas", "Guayas", "Imbabura", "Loja", "Los Ríos", "Manabí",
                    "Morona Santiago", "Napo", "Pastaza", "Pichincha", "Tungurahua",
                    "Zamora Chinchipe", "Galápagos", "Sucumbíos", "Orellana",
                    "Santo Domingo de los Tsáchilas", "Santa Elena", "Zonas No Delimitadas");

            Map<String, NetworkMapDTO> provMap = new java.util.HashMap<>();
            for (int i = 0; i < ALL_PROVINCES.size(); i++) {
                String pName = ALL_PROVINCES.get(i);
                NetworkMapDTO dto = new NetworkMapDTO();
                dto.setZoneId(i + 1);
                dto.setZoneName(pName);
                dto.setOpenTickets(0);
                dto.setMaxPriority("NINGUNA");
                dto.setScoreTickets(100);
                dto.setScoreFinal(Math.min(redScore, 100));

                if (dto.getScoreFinal() >= 80)
                    dto.setLevel("GOOD");
                else if (dto.getScoreFinal() >= 50)
                    dto.setLevel("WARNING");
                else
                    dto.setLevel("CRITICAL");

                dto.setDataSource(dataSource);
                dto.setLatencyOverallMs(latencyOverallMs);
                dto.setGeneratedAt(generatedAt);
                dto.setLastSuccessfulCheckAt(lastSuccessfulCheckAt);

                provMap.put(pName.toUpperCase(), dto);
            }

            for (Map<String, Object> row : rows) {
                String zoneName = (String) row.get("zone_name");
                if (zoneName == null)
                    continue;
                String normalizedDB = zoneName.toUpperCase();

                NetworkMapDTO dto = provMap.get(normalizedDB);
                if (dto == null) {
                    for (Map.Entry<String, NetworkMapDTO> entry : provMap.entrySet()) {
                        String k1 = java.text.Normalizer.normalize(entry.getKey(), java.text.Normalizer.Form.NFD)
                                .replaceAll("\\p{InCombiningDiacriticalMarks}+", "").toUpperCase();
                        String k2 = java.text.Normalizer.normalize(zoneName, java.text.Normalizer.Form.NFD)
                                .replaceAll("\\p{InCombiningDiacriticalMarks}+", "").toUpperCase();
                        if (k1.equals(k2)) {
                            dto = entry.getValue();
                            break;
                        }
                    }
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

                int maxPriorityId = row.get("max_priority_id") != null
                        ? ((Number) row.get("max_priority_id")).intValue()
                        : 0;
                String maxPriorityStr = "NINGUNA";
                int penalty = 0;

                if (openTickets > 0) {
                    if (maxPriorityId >= 4) {
                        maxPriorityStr = "CRITICA";
                        penalty = 40;
                    } else if (maxPriorityId == 3) {
                        maxPriorityStr = "ALTA";
                        penalty = 20;
                    } else if (maxPriorityId == 2) {
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

                if (scoreFinal >= 80)
                    dto.setLevel("GOOD");
                else if (scoreFinal >= 50)
                    dto.setLevel("WARNING");
                else
                    dto.setLevel("CRITICAL");
            }
            response.addAll(provMap.values());

        } else {
            for (Map<String, Object> row : rows) {
                NetworkMapDTO dto = new NetworkMapDTO();
                dto.setZoneId(((Number) row.get("zone_id")).intValue());
                dto.setZoneName((String) row.get("zone_name"));

                int openTickets = ((Number) row.get("open_tickets")).intValue();
                dto.setOpenTickets(openTickets);

                int maxPriorityId = row.get("max_priority_id") != null
                        ? ((Number) row.get("max_priority_id")).intValue()
                        : 0;
                String maxPriorityStr = "NINGUNA";
                int penalty = 0;

                if (openTickets > 0) {
                    if (maxPriorityId >= 4) {
                        maxPriorityStr = "CRITICA";
                        penalty = 40;
                    } else if (maxPriorityId == 3) {
                        maxPriorityStr = "ALTA";
                        penalty = 20;
                    } else if (maxPriorityId == 2) {
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

                if (scoreFinal >= 80)
                    dto.setLevel("GOOD");
                else if (scoreFinal >= 50)
                    dto.setLevel("WARNING");
                else
                    dto.setLevel("CRITICAL");

                dto.setDataSource(dataSource);
                dto.setLatencyOverallMs(latencyOverallMs);
                dto.setGeneratedAt(generatedAt);
                dto.setLastSuccessfulCheckAt(lastSuccessfulCheckAt);

                response.add(dto);
            }
        }

        return response;
    }
}
