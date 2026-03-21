package com.apweb.backend.controller;

import com.apweb.backend.dto.NetworkMapDTO;
import com.apweb.backend.dto.HeatmapPointDTO;
import com.apweb.backend.service.NetworkService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/network")
public class NetworkController {

    @Autowired
    private NetworkService networkService;

    @GetMapping("/map")
    public ResponseEntity<List<NetworkMapDTO>> getNetworkMap(
            @RequestParam(value = "zoneType", defaultValue = "PROVINCIA") String zoneType) {
        return ResponseEntity.ok(networkService.getNetworkMapData(zoneType));
    }

    @GetMapping("/heatmap")
    public ResponseEntity<List<HeatmapPointDTO>> getHeatmap() {
        return ResponseEntity.ok(networkService.getHeatmapData());
    }
}
