package com.apweb.backend.scheduler;

import com.apweb.backend.service.GlobalpingService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import com.apweb.backend.model.NetworkProbeRun;

@Component
public class NetworkMapScheduler {

    private static final Logger logger = LoggerFactory.getLogger(NetworkMapScheduler.class);

    @Autowired
    private GlobalpingService globalpingService;

    // Ejecuta la medición cada 15 minutos
    @Scheduled(fixedRate = 900000, initialDelay = 10000)
    public void scheduleGlobalping() {
        logger.info("Initializing scheduled Globalping measurement task...");
        NetworkProbeRun run = globalpingService.executePingMeasurement();
        logger.info("Globalping run finished success={} source={} target={} durationMs={} probes={}",
                run.getSuccess(), run.getDataSource(), run.getTarget(), run.getDurationMs(), run.getProbeCount());
    }
}
