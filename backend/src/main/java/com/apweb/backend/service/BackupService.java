package com.apweb.backend.service;

import com.apweb.backend.util.AuditAccion;
import com.apweb.backend.util.AuditModulo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.multipart.MultipartFile;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;
import java.io.FileOutputStream;
import com.apweb.backend.model.ConfiguracionBackup;
import com.apweb.backend.model.RegistroBackup;
import com.apweb.backend.repository.ConfiguracionBackupRepository;
import com.apweb.backend.repository.RegistroBackupRepository;

/**
 * Servicio de backup y restauración de la base de datos PostgreSQL.
 */
@Service
public class BackupService {

    private static final Logger log = LoggerFactory.getLogger(BackupService.class);
    private static final DateTimeFormatter FILENAME_FMT = DateTimeFormatter.ofPattern("dd-MM-yyyy_HH-mm-ss");

    private final AtomicBoolean operationEnCurso = new AtomicBoolean(false);

    @Value("${backup.dir:backups}")
    private String backupDir;

    @Value("${backup.pg_dump.path:pg_dump}")
    private String pgDumpPath;

    @Value("${backup.pg_dumpall.path:pg_dumpall}")
    private String pgDumpallPath;

    @Value("${backup.pg_restore.path:pg_restore}")
    private String pgRestorePath;

    @Value("${backup.psql.path:psql}")
    private String psqlPath;

    @Value("${backup.restore.target-database:SGIM2_SANDBOX}")
    private String targetDatabase;

    @Value("${backup.timeout.minutes:10}")
    private int timeoutMinutes;

    @Value("${spring.datasource.url}")
    private String datasourceUrl;

    @Value("${backup.db.user:${spring.datasource.username}}")
    private String backupUsername;

    @Value("${backup.db.pass:${spring.datasource.password}}")
    private String backupPassword;

    private final AuditService auditService;
    private final JdbcTemplate jdbcTemplate;
    private final CloudinaryService cloudinaryService;
    private final ConfiguracionBackupRepository configuracionRepository;
    private final RegistroBackupRepository registroRepository;

    public BackupService(AuditService auditService, 
                         JdbcTemplate jdbcTemplate,
                         CloudinaryService cloudinaryService,
                         ConfiguracionBackupRepository configuracionRepository,
                         RegistroBackupRepository registroRepository) {
        this.auditService = auditService;
        this.jdbcTemplate = jdbcTemplate;
        this.cloudinaryService = cloudinaryService;
        this.configuracionRepository = configuracionRepository;
        this.registroRepository = registroRepository;
    }

    public enum BackupType   { DATABASE, GLOBALS, FULL }
    public enum BackupFormat { CUSTOM, PLAIN }

    public static class BackupResult {
        public final File   archivo;
        public final String nombreArchivo;
        public final long   tamanoBytes;

        public BackupResult(File archivo, String nombreArchivo, long tamanoBytes) {
            this.archivo       = archivo;
            this.nombreArchivo = nombreArchivo;
            this.tamanoBytes   = tamanoBytes;
        }
    }

    public BackupResult ejecutarBackup(BackupType type, BackupFormat format) throws BackupException {
        if (type != BackupType.DATABASE && format == BackupFormat.CUSTOM) {
            throw new BackupException(BackupException.Tipo.PROCESO_FALLIDO, "pg_dumpall solo soporta formato PLAIN (SQL).");
        }

        if (!operationEnCurso.compareAndSet(false, true)) {
            throw new BackupException(BackupException.Tipo.CONCURRENCIA, "Ya hay una operación de backup en curso.");
        }
        
        long inicio = System.currentTimeMillis();
        File tempFile = null;
        try {
            JdbcParams params = parseJdbcUrl(datasourceUrl);
            String extension = (format == BackupFormat.CUSTOM) ? ".dump" : ".sql";
            String nombreArchivo = buildFileName(type, extension);
            
            Path dirPath = Paths.get(backupDir);
            if (!Files.exists(dirPath)) Files.createDirectories(dirPath);
            tempFile = dirPath.resolve(nombreArchivo).toFile();

            List<String> cmd = buildCommand(params, tempFile.getAbsolutePath(), type, format);
            ProcessBuilder pb = new ProcessBuilder(cmd);
            pb.environment().put("PGPASSWORD", backupPassword);

            Process proceso = pb.start();
            StringBuilder stderr = new StringBuilder();
            try (InputStream is = proceso.getErrorStream()) {
                int ch;
                while ((ch = is.read()) != -1) stderr.append((char) ch);
            }

            boolean finalizado = proceso.waitFor(timeoutMinutes, TimeUnit.MINUTES);
            if (!finalizado) {
                proceso.destroyForcibly();
                registrarAuditoria(nombreArchivo, 0L, System.currentTimeMillis() - inicio, false, "Timeout excedido");
                throw new BackupException(BackupException.Tipo.TIMEOUT, "El backup excedió el tiempo límite.");
            }

            if (proceso.exitValue() != 0) {
                String errorMsg = stderr.toString().trim();
                registrarAuditoria(nombreArchivo, 0L, System.currentTimeMillis() - inicio, false, errorMsg);
                throw new BackupException(BackupException.Tipo.PROCESO_FALLIDO, "pg_dump fallo: " + errorMsg);
            }

            long tamano = tempFile.length();
            registrarAuditoria(nombreArchivo, tamano, System.currentTimeMillis() - inicio, true, null);
            return new BackupResult(tempFile, nombreArchivo, tamano);
        } catch (BackupException e) {
            limpiarArchivoSiExiste(tempFile);
            throw e;
        } catch (Exception e) {
            limpiarArchivoSiExiste(tempFile);
            throw new BackupException(BackupException.Tipo.PROCESO_FALLIDO, e.getMessage());
        } finally {
            operationEnCurso.set(false);
        }
    }

    public RegistroBackup ejecutarBackupCompleto(BackupType type, BackupFormat format, boolean esManual) throws BackupException {
        BackupResult result = this.ejecutarBackup(type, format);
        File zipFile = null;
        try {
            String zipName = result.nombreArchivo.substring(0, result.nombreArchivo.lastIndexOf(".")) + ".zip";
            zipFile = Paths.get(backupDir).resolve(zipName).toFile();
            
            try (FileOutputStream fos = new FileOutputStream(zipFile);
                 ZipOutputStream zos = new ZipOutputStream(fos);
                 FileInputStream fis = new FileInputStream(result.archivo)) {
                ZipEntry entry = new ZipEntry(result.archivo.getName());
                zos.putNextEntry(entry);
                byte[] buffer = new byte[1024];
                int len;
                while ((len = fis.read(buffer)) > 0) zos.write(buffer, 0, len);
                zos.closeEntry();
            }
            
            byte[] bytes = Files.readAllBytes(zipFile.toPath());
            String cloudUrl = cloudinaryService.uploadRaw(bytes, "backups_db", zipName);
            
            RegistroBackup registro = RegistroBackup.builder()
                .nombreArchivo(zipName)
                .urlCloudinary(cloudUrl)
                .tamanoBytes(zipFile.length())
                .tipo(esManual ? RegistroBackup.TipoBackup.MANUAL : RegistroBackup.TipoBackup.AUTOMATICO)
                .estado(RegistroBackup.EstadoBackup.EXITOSO)
                .build();
            
            RegistroBackup saved = registroRepository.save(registro);
            ConfiguracionBackup config = getConfiguracionActual();
            config.setUltimoNombreBackup(zipName);
            configuracionRepository.save(config);
            return saved;
        } catch (Exception e) {
            log.error("[BACKUP] Error en flujo completo: {}", e.getMessage());
            RegistroBackup fallido = RegistroBackup.builder()
                .nombreArchivo("ERROR_" + result.nombreArchivo)
                .estado(RegistroBackup.EstadoBackup.FALLIDO)
                .error(e.getMessage())
                .tipo(esManual ? RegistroBackup.TipoBackup.MANUAL : RegistroBackup.TipoBackup.AUTOMATICO)
                .build();
            return registroRepository.save(fallido);
        } finally {
            limpiarArchivoSiExiste(result.archivo);
        }
    }

    public ConfiguracionBackup getConfiguracionActual() {
        return configuracionRepository.findById(1)
            .orElseGet(() -> configuracionRepository.save(ConfiguracionBackup.builder().id(1).build()));
    }

    public ConfiguracionBackup guardarConfiguracion(ConfiguracionBackup config) {
        config.setId(1);
        return configuracionRepository.save(config);
    }

    public List<RegistroBackup> listarHistorial() {
        return registroRepository.findAllByOrderByFechaDesc();
    }

    public void restaurarBackup(MultipartFile file, BackupFormat format) throws BackupException {
        if (!operationEnCurso.compareAndSet(false, true)) {
            throw new BackupException(BackupException.Tipo.CONCURRENCIA, "Ya hay una operación en curso.");
        }
        
        long inicio = System.currentTimeMillis();
        String originalName = file.getOriginalFilename();
        File tempFile = null;
        try {
            tempFile = File.createTempFile("restore_", "_" + originalName);
            file.transferTo(tempFile);
            
            terminarConexionesBaseDatos(targetDatabase);
            List<String> cmd = buildRestoreCommand(tempFile.getAbsolutePath(), format);
            
            ProcessBuilder pb = new ProcessBuilder(cmd);
            pb.environment().put("PGPASSWORD", backupPassword);
            Process proceso = pb.start();
            
            StringBuilder stderrCaptura = new StringBuilder();
            try (InputStream is = proceso.getErrorStream()) {
                int ch;
                while ((ch = is.read()) != -1) stderrCaptura.append((char) ch);
            }

            if (!proceso.waitFor(timeoutMinutes, TimeUnit.MINUTES)) {
                proceso.destroyForcibly();
                registrarAuditoria("RESTORE:" + originalName, 0L, System.currentTimeMillis() - inicio, false, "Timeout");
                throw new BackupException(BackupException.Tipo.TIMEOUT, "Timeout en restauración.");
            }

            if (proceso.exitValue() != 0) {
                String error = stderrCaptura.toString();
                registrarAuditoria("RESTORE:" + originalName, 0L, System.currentTimeMillis() - inicio, false, error);
                throw new BackupException(BackupException.Tipo.PROCESO_FALLIDO, "Restore fallo: " + error);
            }

            registrarAuditoria("RESTORE:" + originalName, file.getSize(), System.currentTimeMillis() - inicio, true, null);
        } catch (Exception e) {
            throw new BackupException(BackupException.Tipo.PROCESO_FALLIDO, e.getMessage());
        } finally {
            if (tempFile != null && tempFile.exists()) tempFile.delete();
            operationEnCurso.set(false);
        }
    }

    private List<String> buildRestoreCommand(String filePath, BackupFormat format) throws BackupException {
        List<String> cmd = new ArrayList<>();
        JdbcParams params = parseJdbcUrl(datasourceUrl);
        if (format == BackupFormat.CUSTOM) {
            cmd.add(pgRestorePath);
            cmd.add("-h"); cmd.add(params.host);
            cmd.add("-p"); cmd.add(String.valueOf(params.port));
            cmd.add("-U"); cmd.add(backupUsername);
            cmd.add("-d"); cmd.add(targetDatabase);
            cmd.add("--clean"); cmd.add("--if-exists");
            cmd.add(filePath);
        } else {
            cmd.add(psqlPath);
            cmd.add("-h"); cmd.add(params.host);
            cmd.add("-p"); cmd.add(String.valueOf(params.port));
            cmd.add("-U"); cmd.add(backupUsername);
            cmd.add("-d"); cmd.add(targetDatabase);
            cmd.add("-f"); cmd.add(filePath);
        }
        return cmd;
    }

    private void terminarConexionesBaseDatos(String dbName) {
        try {
            String sql = "SELECT pg_terminate_backend(pid) FROM pg_stat_activity " +
                         "WHERE datname = ? AND pid <> pg_backend_pid()";
            jdbcTemplate.update(sql, dbName);
        } catch (Exception e) {
            log.warn("[RESTORE] Fallo terminar conexiones: {}", e.getMessage());
        }
    }

    public InputStream abrirYBorrarTrasLeer(File archivo) throws IOException {
        return new FileInputStream(archivo) {
            @Override
            public void close() throws IOException {
                try { super.close(); } finally { if (archivo.exists()) archivo.delete(); }
            }
        };
    }

    public void eliminarBackupLocalDisco(String nombreArchivo) throws IOException {
        Path path = Paths.get(this.backupDir).resolve(nombreArchivo);
        if (Files.exists(path)) {
            Files.delete(path);
        } else {
            throw new IOException("El archivo no existe.");
        }
    }

    private String buildFileName(BackupType type, String ext) {
        String p = switch (type) {
            case DATABASE -> "sgim2_db_";
            case GLOBALS  -> "sgim2_roles_";
            case FULL     -> "sgim2_full_";
        };
        return p + LocalDateTime.now().format(FILENAME_FMT) + ext;
    }

    private List<String> buildCommand(JdbcParams params, String outputPath, BackupType type, BackupFormat format) {
        List<String> cmd = new ArrayList<>();
        if (type == BackupType.DATABASE) {
            cmd.add(pgDumpPath);
            cmd.add("-h"); cmd.add(params.host);
            cmd.add("-p"); cmd.add(String.valueOf(params.port));
            cmd.add("-U"); cmd.add(backupUsername);
            cmd.add("-F"); cmd.add(format == BackupFormat.CUSTOM ? "c" : "p");
            cmd.add("-f"); cmd.add(outputPath);
            cmd.add(params.dbName);
        } else {
            cmd.add(pgDumpallPath);
            cmd.add("-h"); cmd.add(params.host);
            cmd.add("-p"); cmd.add(String.valueOf(params.port));
            cmd.add("-U"); cmd.add(backupUsername);
            cmd.add("--file=" + outputPath);
            if (type == BackupType.GLOBALS) cmd.add("-g");
        }
        return cmd;
    }

    private JdbcParams parseJdbcUrl(String url) throws BackupException {
        try {
            String raw = url.replace("jdbc:postgresql://", "");
            int slash = raw.indexOf('/');
            String hostPort = raw.substring(0, slash);
            String dbName = raw.substring(slash + 1);
            if (dbName.contains("?")) dbName = dbName.substring(0, dbName.indexOf('?'));
            String host = hostPort.contains(":") ? hostPort.split(":")[0] : hostPort;
            int port = hostPort.contains(":") ? Integer.parseInt(hostPort.split(":")[1]) : 5432;
            return new JdbcParams(host, port, dbName);
        } catch (Exception e) { throw new BackupException(BackupException.Tipo.PROCESO_FALLIDO, "JDBC URL Error"); }
    }

    private void registrarAuditoria(String nombreArchivo, long tamano, long duracion, boolean exito, String error) {
        try {
            auditService.registrarEventoConResultado(
                    AuditModulo.SISTEMA, "reportes", "registro_backup", null,
                    AuditAccion.BACKUP, "Backup (" + nombreArchivo + ")", null,
                    Map.of("archivo", nombreArchivo, "tamano", tamano, "duracion", duracion),
                    auditService.resolveCurrentUserId(), exito, error
            );
        } catch (Exception e) { log.error("[BACKUP] Auditoria Fallo: {}", e.getMessage()); }
    }

    private void limpiarArchivoSiExiste(File archivo) {
        if (archivo != null && archivo.exists()) archivo.delete();
    }

    private record JdbcParams(String host, int port, String dbName) {}

    public static class BackupException extends Exception {
        public enum Tipo { TIMEOUT, PROCESO_FALLIDO, ARCHIVO_INVALIDO, CONCURRENCIA }
        private final Tipo tipo;
        public BackupException(Tipo tipo, String msg) { super(msg); this.tipo = tipo; }
        public Tipo getTipo() { return tipo; }
    }
}
