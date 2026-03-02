package com.apweb.backend.service;

import com.apweb.backend.model.NetworkProbeRun;

public interface GlobalpingService {
    NetworkProbeRun executePingMeasurement();
}
