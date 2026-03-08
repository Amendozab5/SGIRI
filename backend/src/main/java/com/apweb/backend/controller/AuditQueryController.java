package com.apweb.backend.controller;

import com.apweb.backend.dto.AuditDetailDTO;
import com.apweb.backend.dto.AuditTimelineDTO;
import com.apweb.backend.service.AuditQueryService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;

/**
 * Controlador para consultas administrativas de auditoría.
 * Acceso restringido a ADMIN_MASTER y ADMIN_VISUAL.
 */
@RestController
@RequestMapping("/api/admin/audit")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AuditQueryController {

    private final AuditQueryService auditQueryService;

    @GetMapping("/timeline")
    @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_VISUAL')")
    public ResponseEntity<Page<AuditTimelineDTO>> getTimeline(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate,
            @RequestParam(required = false) String modulo,
            @RequestParam(required = false) String accion,
            @RequestParam(required = false) String username,
            @RequestParam(required = false) Boolean exito,
            @RequestParam(required = false) String tabla,
            @RequestParam(required = false) Integer idRegistro,
            @PageableDefault(size = 20, sort = "fecha", direction = Sort.Direction.DESC) Pageable pageable) {

        return ResponseEntity.ok(auditQueryService.getTimeline(startDate, endDate, modulo, accion, username, exito, null, tabla, idRegistro, pageable));
    }

    @GetMapping("/timeline/{eventKey}")
    @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_VISUAL')")
    public ResponseEntity<AuditDetailDTO> getEventDetail(@PathVariable String eventKey) {
        return auditQueryService.getEventDetail(eventKey)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
