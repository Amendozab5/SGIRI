package com.apweb.backend.repository;

import com.apweb.backend.model.NetworkProbeRun;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface NetworkProbeRunRepository extends JpaRepository<NetworkProbeRun, Integer> {
    Optional<NetworkProbeRun> findTopBySuccessTrueOrderByCreatedAtDesc();

    Optional<NetworkProbeRun> findTopByOrderByCreatedAtDesc();
}
