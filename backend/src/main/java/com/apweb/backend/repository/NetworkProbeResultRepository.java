package com.apweb.backend.repository;

import com.apweb.backend.model.NetworkProbeResult;
import com.apweb.backend.model.NetworkProbeRun;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NetworkProbeResultRepository extends JpaRepository<NetworkProbeResult, Integer> {
    List<NetworkProbeResult> findByRun(NetworkProbeRun run);
}
