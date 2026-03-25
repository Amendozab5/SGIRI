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
import java.nio.file.StandardCopyOption;

/**
 * Servicio de backup y restauración de la base de datos PostgreSQL.
 *
 * <h3>Principios de diseño:</h3>
 * <ul>
 *   <li>Solo una operación fuerte (backup o restore) puede ejecutarse a la vez.</li>
 *   <li>Uso de PGPASSWORD seguro para subprocesos.</li>
 *   <li>Restauración protegida mediante base de datos de Sandbox.</li>
 *   <li>Toda ejecución se registra en auditoría centralizada.</li>
 * </ul>
 */
@Service
public class BackupService {

    private static final Logger log = LoggerFactory.getLogger(BackupService.class);
    private static final DateTimeFormatter FILENAME_FMT = DateTimeFormatter.ofPattern("dd-MM-yyyy_HH-mm-ss");

    /** Evita que dos solicitudes simultáneas generen operaciones de escritura en paralelo. */
    private final AtomicBoolean operationEnCurso = new AtomicBoolean(false);

    // ── Inyección de propiedades ──────────────────────────────────────────────

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

    // Dependencias
    private final AuditService auditService;
    private final JdbcTemplate jdbcTemplate;

    public BackupService(AuditService auditService, JdbcTemplate jdbcTemplate) {
        this.auditService = auditService;
        this.jdbcTemplate = jdbcTemplate;
    }

    // ── Enums de configuración ──────────────────────────────────────────────

    public enum BackupType   { DATABASE, GLOBALS, FULL }
    public enum BackupFormat { CUSTOM, PLAIN }

    // ── Resultado del servicio ────────────────────────────────────────────────

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

    // ── Método principal ──────────────────────────────────────────────────────

    /**
     * Ejecuta pg_dump o pg_dumpall y retorna el resultado listo para descarga.
     */
    public BackupResult ejecutarBackup(BackupType type, BackupFormat format) throws BackupException {
        // ── 1. Verificar compatibilidad ─────────────────────────────────────
        if (type != BackupType.DATABASE && format == BackupFormat.CUSTOM) {
            throw new BackupException(BackupException.Tipo.PROCESO_FALLIDO,
                    "pg_dumpall solo soporta formato PLAIN (SQL).");
        }

        // ── 2. Verificar concurrencia ─────────────────────────────────────────
        if (!operationEnCurso.compareAndSet(false, true)) {
            throw new BackupException(
                    BackupException.Tipo.CONCURRENCIA,
                    "Ya hay un backup en curso. Espere a que finalice antes de iniciar otro.");
        }

        long inicio = System.currentTimeMillis();
        String extension = (format == BackupFormat.CUSTOM) ? ".dump" : ".sql";
        String nombreArchivo = buildFileName(type, extension);
        File archivoSalida = null;

        try {
            // ── 3. Preparar directorio de salida ──────────────────────────────
            Path dirPath = Paths.get(backupDir);
            Files.createDirectories(dirPath);
            archivoSalida = dirPath.resolve(nombreArchivo).toFile();

            // ── 4. Parsear parámetros de conexión ─────────────────────────────
            JdbcParams params = parseJdbcUrl(datasourceUrl);

            // ── 5. Construir el comando ───────────────────────────────────────
            List<String> cmd = buildCommand(params, archivoSalida.getAbsolutePath(), type, format);
            log.info("[BACKUP] Iniciando {} → archivo: {}", (type == BackupType.DATABASE ? "pg_dump" : "pg_dumpall"), archivoSalida.getAbsolutePath());

            ProcessBuilder pb = new ProcessBuilder(cmd);
            pb.environment().put("PGPASSWORD", backupPassword);
            pb.redirectErrorStream(false);

            // ── 6. Ejecutar con timeout ───────────────────────────────────────
            Process proceso = pb.start();

            // Capturar stderr
            StringBuilder stderrCaptura = new StringBuilder();
            Thread stderrReader = new Thread(() -> {
                try (InputStream err = proceso.getErrorStream()) {
                    byte[] buf = err.readAllBytes();
                    stderrCaptura.append(new String(buf));
                } catch (IOException ignored) {}
            });
            stderrReader.setDaemon(true);
            stderrReader.start();

            boolean termino = proceso.waitFor(timeoutMinutes, TimeUnit.MINUTES);

            if (!termino) {
                proceso.destroyForcibly();
                registrarAuditoria(nombreArchivo, 0L, System.currentTimeMillis() - inicio, false, "Timeout");
                throw new BackupException(BackupException.Tipo.TIMEOUT, "El backup excedió el tiempo límite.");
            }

            int exitCode = proceso.exitValue();
            stderrReader.join(3_000);
            String stderr = stderrCaptura.toString().trim();

            if (exitCode != 0) {
                String errorMsg = stderr.isEmpty() ? "Error code " + exitCode : stderr;
                registrarAuditoria(nombreArchivo, 0L, System.currentTimeMillis() - inicio, false, errorMsg);
                throw new BackupException(BackupException.Tipo.PROCESO_FALLIDO, "Fallo al generar archivo: " + errorMsg);
            }

            // ── 7. Validar y Auditoría de éxito ───────────────────────────────
            if (!archivoSalida.exists() || archivoSalida.length() == 0) {
                throw new BackupException(BackupException.Tipo.ARCHIVO_INVALIDO, "Archivo generado vacío.");
            }

            long tamano = archivoSalida.length();
            long duracion = System.currentTimeMillis() - inicio;
            registrarAuditoria(nombreArchivo, tamano, duracion, true, null);

            archivoSalida.deleteOnExit();
            return new BackupResult(archivoSalida, nombreArchivo, tamano);

        } catch (BackupException e) {
            limpiarArchivoSiExiste(archivoSalida);
            throw e;
        } catch (Exception e) {
            limpiarArchivoSiExiste(archivoSalida);
            log.error("[BACKUP] Error fatal: {}", e.getMessage(), e);
            throw new BackupException(BackupException.Tipo.PROCESO_FALLIDO, e.getMessage());
        } finally {
            operationEnCurso.set(false);
        }
    }

    /**
     * Mantiene compatibilidad con el endpoint anterior si es necesario.
     */
    public BackupResult ejecutarBackup() throws BackupException {
        return ejecutarBackup(BackupType.DATABASE, BackupFormat.CUSTOM);
    }

    /**
     * Procesa la restauración de un archivo de backup sobre la base de datos SANDBOX.
     * @param file El archivo Multipart subido.
     * @param format El formato (CUSTOM o PLAIN).
     */
    public void restaurarBackup(MultipartFile file, BackupFormat format) throws BackupException {
        if (file == null || file.isEmpty()) {
            throw new BackupException(BackupException.Tipo.ARCHIVO_INVALIDO, "Archivo de restauración no proporcionado.");
        }

        if (!operationEnCurso.compareAndSet(false, true)) {
            throw new BackupException(BackupException.Tipo.CONCURRENCIA, "Ya hay una operación de base de datos en curso.");
        }

        File tempFile = null;
        long inicio = System.currentTimeMillis();
        String originalName = file.getOriginalFilename();

        try {
            // 1. Guardar archivo temporalmente
            Path tempPath = Paths.get(backupDir).resolve("restore_temp_" + System.currentTimeMillis() + (format == BackupFormat.CUSTOM ? ".dump" : ".sql"));
            Files.createDirectories(tempPath.getParent());
            Files.copy(file.getInputStream(), tempPath, StandardCopyOption.REPLACE_EXISTING);
            tempFile = tempPath.toFile();

            log.info("[RESTORE] Iniciando restauración sobre {} usando archivo: {}", targetDatabase, originalName);

            // 2. Terminar conexiones activas en la DB destino para evitar bloqueos
            terminarConexionesBaseDatos(targetDatabase);

            // 3. Construir y ejecutar comando
            List<String> cmd = buildRestoreCommand(tempFile.getAbsolutePath(), format);
            ProcessBuilder pb = new ProcessBuilder(cmd);
            pb.environment().put("PGPASSWORD", backupPassword);

            Process proceso = pb.start();
            
            // Captura de errores
            StringBuilder stderrCaptura = new StringBuilder();
            Thread stderrReader = new Thread(() -> {
                try (InputStream is = proceso.getErrorStream()) {
                    int ch;
                    while ((ch = is.read()) != -1) stderrCaptura.append((char) ch);
                } catch (IOException ignored) {}
            });
            stderrReader.start();

            boolean finalizado = proceso.waitFor(timeoutMinutes, TimeUnit.MINUTES);
            if (!finalizado) {
                proceso.destroyForcibly();
                registrarAuditoria("RESTORE:" + originalName, 0L, System.currentTimeMillis() - inicio, false, "Timeout excedido");
                throw new BackupException(BackupException.Tipo.TIMEOUT, "La restauración excedió el tiempo límite.");
            }

            int exitCode = proceso.exitValue();
            stderrReader.join(3_000);
            String stderr = stderrCaptura.toString().trim();

            if (exitCode != 0) {
                String errorMsg = stderr.isEmpty() ? "Error code " + exitCode : stderr;
                registrarAuditoria("RESTORE:" + originalName, 0L, System.currentTimeMillis() - inicio, false, errorMsg);
                throw new BackupException(BackupException.Tipo.PROCESO_FALLIDO, "Fallo al restaurar: " + errorMsg);
            }

            log.info("[RESTORE] Restauración completada con éxito sobre {}", targetDatabase);
            registrarAuditoria("RESTORE:" + originalName, file.getSize(), System.currentTimeMillis() - inicio, true, null);

        } catch (BackupException e) {
            throw e;
        } catch (Exception e) {
            log.error("[RESTORE] Error crítico: {}", e.getMessage(), e);
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
            cmd.add("--clean");      // Limpiar objetos antes de crear
            cmd.add("--if-exists");  // No fallar si el objeto no existe al limpiar
            cmd.add("-v");           // Verbose para mejores logs de error
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
            log.info("[RESTORE] Terminando conexiones activas en base de datos: {}", dbName);
            String sql = "SELECT pg_terminate_backend(pid) FROM pg_stat_activity " +
                         "WHERE datname = ? AND pid <> pg_backend_pid()";
            jdbcTemplate.update(sql, dbName);
        } catch (Exception e) {
            log.warn("[RESTORE] No se pudieron terminar todas las conexiones de {}: {}", dbName, e.getMessage());
        }
    }

    public InputStream abrirYBorrarTrasLeer(File archivo) throws IOException {
        return new FileInputStream(archivo) {
            @Override
            public void close() throws IOException {
                try {
                    super.close();
                } finally {
                    if (archivo.exists()) {
                        archivo.delete();
                        log.debug("[BACKUP] Archivo temporal eliminado: {}", archivo.getName());
                    }
                }
            }
        };
    }

    // ── Helpers privados ─────────────────────────────────────────────────────

    private String buildFileName(BackupType type, String ext) {
        String prefix = switch (type) {
            case DATABASE -> "sgim2_db_";
            case GLOBALS  -> "sgim2_roles_";
            case FULL     -> "sgim2_full_";
        };
        return prefix + LocalDateTime.now().format(FILENAME_FMT) + ext;
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
            if (type == BackupType.GLOBALS) {
                cmd.add("-g"); // solo roles y tablespaces
            }
        }
        return cmd;
    }

    private JdbcParams parseJdbcUrl(String url) throws BackupException {
        try {
            String raw = url.replace("jdbc:postgresql://", "");
            int qMark = raw.indexOf('?');
            if (qMark >= 0) raw = raw.substring(0, qMark);

            int slashIdx = raw.indexOf('/');
            String hostPort = raw.substring(0, slashIdx);
            String dbName   = raw.substring(slashIdx + 1);

            String host = hostPort.contains(":") ? hostPort.split(":")[0] : hostPort;
            int port = hostPort.contains(":") ? Integer.parseInt(hostPort.split(":")[1]) : 5432;
            return new JdbcParams(host, port, dbName);
        } catch (Exception e) {
            throw new BackupException(BackupException.Tipo.PROCESO_FALLIDO, "URL JDBC inválida: " + url);
        }
    }

    private void registrarAuditoria(String nombreArchivo, long tamano, long duracion, boolean exito, String error) {
        try {
            auditService.registrarEventoConResultado(
                    AuditModulo.SISTEMA, "public", "database_backup", null,
                    AuditAccion.BACKUP, "Backup (" + nombreArchivo + ")", null,
                    Map.of("archivo", nombreArchivo, "tamano", tamano, "duracion", duracion),
                    auditService.resolveCurrentUserId(), exito, error
            );
        } catch (Exception e) {
            log.error("[BACKUP] Error auditoría: {}", e.getMessage());
        }
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
