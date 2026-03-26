package com.apweb.backend.scheduler;

import com.apweb.backend.model.ConfiguracionBackup;
import com.apweb.backend.service.BackupService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalTime;

@Component
public class BackupScheduler {

    private static final Logger log = LoggerFactory.getLogger(BackupScheduler.class);

    private final BackupService backupService;

    public BackupScheduler(BackupService backupService) {
        this.backupService = backupService;
    }

    /**
     * Revisa cada minuto si corresponde ejecutar un backup automático.
     */
    @Scheduled(cron = "0 * * * * *")
    public void verificarBackupProgramado() {
        ConfiguracionBackup config = backupService.getConfiguracionActual();

        if (config == null || !config.getActivo()) {
            return;
        }

        LocalTime ahora = LocalTime.now();
        LocalTime horaProg = config.getHoraEjecucion();

        // Si estamos en el minuto exacto de la programación
        if (ahora.getHour() == horaProg.getHour() && ahora.getMinute() == horaProg.getMinute()) {
            
            // Verificar si ya se hizo hoy para evitar duplicados en el mismo minuto si el scheduler es muy rápido
            // (Aunque con cron "0 * * * * *" solo entra una vez por minuto)
            log.info("[SCHEDULER] Iniciando backup automático programado a las {}", horaProg);
            
            try {
                backupService.ejecutarBackupCompleto(
                    BackupService.BackupType.DATABASE, 
                    BackupService.BackupFormat.CUSTOM, 
                    false
                );
            } catch (Exception e) {
                log.error("[SCHEDULER] Error en backup automático: {}", e.getMessage());
            }
        }
    }
}
