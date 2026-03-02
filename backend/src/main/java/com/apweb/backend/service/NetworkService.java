package com.apweb.backend.service;

import com.apweb.backend.dto.NetworkMapDTO;
import java.util.List;

public interface NetworkService {
    List<NetworkMapDTO> getNetworkMapData(String zoneType);
}
