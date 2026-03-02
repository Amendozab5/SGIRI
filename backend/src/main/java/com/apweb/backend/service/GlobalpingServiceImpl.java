package com.apweb.backend.service;

import com.apweb.backend.model.NetworkProbeResult;
import com.apweb.backend.model.NetworkProbeRun;
import com.apweb.backend.repository.NetworkProbeResultRepository;
import com.apweb.backend.repository.NetworkProbeRunRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
public class GlobalpingServiceImpl implements GlobalpingService {
    private static final Logger logger = LoggerFactory.getLogger(GlobalpingServiceImpl.class);
    private static final String API_URL = "https://api.globalping.io/v1/measurements";

    private static final String PING_TARGET_IPV4 = "8.8.8.8";
    private static final String PING_TARGET_IPV6 = "2001:4860:4860::8888";

    @Autowired
    private NetworkProbeRunRepository runRepository;

    @Autowired
    private NetworkProbeResultRepository resultRepository;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper mapper = new ObjectMapper();

    @Override
    public NetworkProbeRun executePingMeasurement() {
        long globalStartTime = System.currentTimeMillis();

        // Strategy 1: IPv4 in Ecuador
        try {
            logger.info("globalping: Intentando IPv4 en Ecuador...");
            return executeMeasurementTarget(PING_TARGET_IPV4, "country", "EC", "REAL", globalStartTime);
        } catch (Exception e) {
            logger.warn("globalping: Error en IPv4 EC: {}. Reintentando con IPv6...", e.getMessage());
        }

        // Strategy 2: IPv6 in Ecuador
        try {
            logger.info("globalping: Intentando IPv6 en Ecuador...");
            return executeMeasurementTarget(PING_TARGET_IPV6, "country", "EC", "REAL", globalStartTime);
        } catch (Exception e) {
            logger.warn("globalping: Error en IPv6 EC: {}. Reintentando en Sudamerica...", e.getMessage());
        }

        // Strategy 3: IPv4 in South America
        try {
            logger.info("globalping: Intentando IPv4 en Sudamerica (SA)...");
            return executeMeasurementTarget(PING_TARGET_IPV4, "continent", "SA", "REAL_REGIONAL", globalStartTime);
        } catch (Exception e) {
            logger.error("globalping: Todos los intentos reales fallaron. Iniciando FALLBACK.", e);
            return executeFallback(e.getMessage(), globalStartTime);
        }
    }

    private NetworkProbeRun executeMeasurementTarget(String target, String locationType, String locationValue,
            String dataSourceLabel, long globalStartTime) throws Exception {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("type", "ping");
        requestBody.put("target", target);

        Map<String, Object> location = new HashMap<>();
        location.put(locationType, locationValue);
        location.put("limit", 5);

        requestBody.put("locations", new Object[] { location });
        // DO NOT FORCE IP_VERSION explicitly so API figures it out

        HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);
        String responseStr;
        try {
            responseStr = restTemplate.postForObject(API_URL, request, String.class);
        } catch (HttpClientErrorException ex) {
            throw new Exception("HTTP API Error: " + ex.getResponseBodyAsString(), ex);
        }

        JsonNode responseNode = mapper.readTree(responseStr);
        String measurementId = responseNode.get("id").asText();

        logger.info("Started Globalping measurement: {} for target: {}", measurementId, target);

        // Poll for results
        JsonNode resultNode = null;
        int retries = 0;
        while (retries < 15) { // 30 seconds max
            Thread.sleep(2000);
            try {
                String resultStr = restTemplate.getForObject(API_URL + "/" + measurementId, String.class);
                resultNode = mapper.readTree(resultStr);

                String status = resultNode.get("status").asText();
                if ("finished".equals(status)) {
                    break;
                }
            } catch (Exception ignored) {
            }
            retries++;
        }

        if (resultNode == null || !"finished".equals(resultNode.get("status").asText())) {
            throw new RuntimeException("Globalping measurement did not finish in time.");
        }

        // Process results
        int successfulProbes = 0;
        double totalLatency = 0.0;
        double totalPacketLoss = 0.0;
        JsonNode resultsArray = resultNode.get("results");

        if (resultsArray != null && resultsArray.isArray()) {
            for (JsonNode probeResult : resultsArray) {
                JsonNode resultObj = probeResult.get("result");
                if (resultObj != null && resultObj.has("stats")) {
                    JsonNode stats = resultObj.get("stats");
                    totalLatency += stats.get("avg").asDouble();
                    totalPacketLoss += stats.get("loss").asDouble();
                    successfulProbes++;
                }
            }
        }

        if (successfulProbes == 0) {
            throw new RuntimeException("No successful probes returned real data.");
        }

        double avgLatency = totalLatency / successfulProbes;
        double avgLoss = totalPacketLoss / successfulProbes;

        NetworkProbeRun run = new NetworkProbeRun();
        run.setTarget(target);
        run.setTool("ping");
        run.setProbeCount(successfulProbes);
        run.setDataSource(dataSourceLabel);
        run.setSuccess(true);
        run.setDurationMs(System.currentTimeMillis() - globalStartTime);
        run = runRepository.save(run);

        // Save overall EC/SA result
        NetworkProbeResult res = new NetworkProbeResult();
        res.setRun(run);
        res.setZoneType("COUNTRY");
        res.setZoneId(1);
        res.setLatencyMs(avgLatency);
        res.setPacketLoss(avgLoss);

        int score = calculateNetworkScore(avgLatency, avgLoss);
        res.setScore(score);
        res.setLevel(determineLevel(score));

        resultRepository.save(res);
        logger.info("Successfully saved {} Globalping measurement details. Score: {}, Latency: {}", dataSourceLabel,
                score, avgLatency);
        return run;
    }

    private NetworkProbeRun executeFallback(String errorMessage, long globalStartTime) {
        NetworkProbeRun run = new NetworkProbeRun();
        run.setTarget("FALLBACK");
        run.setTool("ping");
        run.setProbeCount(0);
        run.setDataSource("FALLBACK");
        run.setSuccess(false);
        run.setErrorMessage(errorMessage);
        run.setDurationMs(System.currentTimeMillis() - globalStartTime);
        run = runRepository.save(run);

        Optional<NetworkProbeRun> lastSuccess = runRepository.findTopBySuccessTrueOrderByCreatedAtDesc();
        if (lastSuccess.isPresent()) {
            List<NetworkProbeResult> oldResults = resultRepository.findByRun(lastSuccess.get());
            for (NetworkProbeResult oldRes : oldResults) {
                NetworkProbeResult newRes = new NetworkProbeResult();
                newRes.setRun(run);
                newRes.setZoneType(oldRes.getZoneType());
                newRes.setZoneId(oldRes.getZoneId());
                newRes.setLatencyMs(oldRes.getLatencyMs());
                newRes.setPacketLoss(oldRes.getPacketLoss());
                newRes.setScore(oldRes.getScore());
                newRes.setLevel(oldRes.getLevel());
                resultRepository.save(newRes);
            }
        }
        return run;
    }

    private int calculateNetworkScore(double latency, double loss) {
        int score = 100;

        if (latency > 150) {
            score -= 40;
        } else if (latency > 50) {
            double penalty = ((latency - 50) / 100.0) * 30;
            score -= (int) penalty;
        }

        if (loss > 0) {
            score -= Math.min(60, (int) (loss * 2));
        }

        return Math.max(0, Math.min(100, score));
    }

    private String determineLevel(int score) {
        if (score >= 80)
            return "GOOD";
        if (score >= 50)
            return "WARNING";
        return "CRITICAL";
    }
}
