package com.apweb.backend.service;

import com.apweb.backend.dto.NetworkMapDTO;
import com.apweb.backend.dto.HeatmapPointDTO;
import java.util.List;

public interface NetworkService {
    List<NetworkMapDTO> getNetworkMapData(String zoneType);
    List<HeatmapPointDTO> getHeatmapData();
}
