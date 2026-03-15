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

/**
 * Servicio de backup completo de la base de datos PostgreSQL mediante pg_dump.
 *
 * <h3>Principios de diseño:</h3>
 * <ul>
 *   <li>Solo un backup puede ejecutarse a la vez (AtomicBoolean).</li>
 *   <li>PGPASSWORD se pasa como variable de entorno al proceso hijo, nunca como argumento CLI.</li>
 *   <li>El archivo temporal se elimina tras ser servido al cliente.</li>
 *   <li>Toda ejecución (exitosa o fallida) se registra en auditoría.</li>
 *   <li>El timeout es configurable vía {@code backup.timeout.minutes}.</li>
 * </ul>
 */
@Service
public class BackupService {

    private static final Logger log = LoggerFactory.getLogger(BackupService.class);
    private static final DateTimeFormatter FILENAME_FMT = DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss");

    /** Evita que dos solicitudes simultáneas generen backups en paralelo. */
    private final AtomicBoolean backupEnCurso = new AtomicBoolean(false);

    // ── Inyección de propiedades ──────────────────────────────────────────────

    @Value("${backup.dir:backups}")
    private String backupDir;

    @Value("${backup.pg_dump.path:pg_dump}")
    private String pgDumpPath;

    @Value("${backup.timeout.minutes:5}")
    private int timeoutMinutes;

    @Value("${spring.datasource.url}")
    private String datasourceUrl;

    @Value("${spring.datasource.username}")
    private String datasourceUsername;

    @Value("${spring.datasource.password}")
    private String datasourcePassword;

    // Dependencia de auditoría
    private final AuditService auditService;

    public BackupService(AuditService auditService) {
        this.auditService = auditService;
    }

    // ── Resultado del servicio ────────────────────────────────────────────────

    /**
     * Resultado encapsulado de la ejecución del backup.
     * Lleva el archivo generado (para streaming) y metadatos para la respuesta HTTP.
     */
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
     * Ejecuta pg_dump y retorna el resultado listo para ser servido como descarga.
     *
     * @throws BackupException si ya hay un backup en curso, si pg_dump falla o si el archivo es inválido.
     */
    public BackupResult ejecutarBackup() throws BackupException {
        // ── 1. Verificar concurrencia ─────────────────────────────────────────
        if (!backupEnCurso.compareAndSet(false, true)) {
            throw new BackupException(
                    BackupException.Tipo.CONCURRENCIA,
                    "Ya hay un backup en curso. Espere a que finalice antes de iniciar otro.");
        }

        long inicio = System.currentTimeMillis();
        String nombreArchivo = buildFileName();
        File archivoSalida = null;

        try {
            // ── 2. Preparar directorio de salida ──────────────────────────────
            Path dirPath = Paths.get(backupDir);
            Files.createDirectories(dirPath);
            archivoSalida = dirPath.resolve(nombreArchivo).toFile();

            // ── 3. Parsear parámetros de conexión ─────────────────────────────
            JdbcParams params = parseJdbcUrl(datasourceUrl);

            // ── 4. Construir el comando pg_dump ───────────────────────────────
            List<String> cmd = buildCommand(params, archivoSalida.getAbsolutePath());
            log.info("[BACKUP] Iniciando pg_dump → archivo: {}", archivoSalida.getAbsolutePath());
            log.debug("[BACKUP] Comando: {} -h {} -p {} -U {} -F c -f {}", pgDumpPath, params.host(), params.port(), datasourceUsername, archivoSalida.getAbsolutePath());

            ProcessBuilder pb = new ProcessBuilder(cmd);
            pb.environment().put("PGPASSWORD", datasourcePassword);   // nunca en CLI
            pb.redirectErrorStream(false);  // stdout y stderr separados

            // ── 5. Ejecutar con timeout ───────────────────────────────────────
            Process proceso = pb.start();

            // Capturar stderr en un hilo separado para no bloquear el proceso
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
                // ── 5a. Timeout ───────────────────────────────────────────────
                proceso.destroyForcibly();
                long duracion = System.currentTimeMillis() - inicio;
                registrarAuditoria(nombreArchivo, 0L, duracion, false,
                        "Timeout: pg_dump no completó en " + timeoutMinutes + " minutos");
                log.error("[BACKUP] Timeout al ejecutar pg_dump ({}min). Proceso destruido.", timeoutMinutes);
                throw new BackupException(
                        BackupException.Tipo.TIMEOUT,
                        "El backup tardó más de " + timeoutMinutes + " minutos y fue cancelado. " +
                        "Intente de nuevo o contacte al administrador.");
            }

            int exitCode = proceso.exitValue();
            stderrReader.join(3_000); // esperar captura stderr máximo 3s
            String stderr = stderrCaptura.toString().trim();

            if (exitCode != 0) {
                // ── 5b. pg_dump terminó con error ─────────────────────────────
                long duracion = System.currentTimeMillis() - inicio;
                String errorMsg = stderr.isEmpty()
                        ? "pg_dump finalizó con código de error " + exitCode
                        : stderr;
                registrarAuditoria(nombreArchivo, 0L, duracion, false, errorMsg);
                log.error("[BACKUP] pg_dump falló (exit={}): {}", exitCode, errorMsg);
                throw new BackupException(
                        BackupException.Tipo.PROCESO_FALLIDO,
                        "Error al ejecutar el backup: " + errorMsg);
            }

            // ── 6. Validar archivo generado ───────────────────────────────────
            if (!archivoSalida.exists() || archivoSalida.length() == 0) {
                long duracion = System.currentTimeMillis() - inicio;
                registrarAuditoria(nombreArchivo, 0L, duracion, false,
                        "El archivo generado está vacío o no existe");
                throw new BackupException(
                        BackupException.Tipo.ARCHIVO_INVALIDO,
                        "El backup fue ejecutado pero el archivo generado está vacío.");
            }

            long tamano = archivoSalida.length();
            long duracion = System.currentTimeMillis() - inicio;

            // ── 7. Registrar auditoría de éxito ───────────────────────────────
            registrarAuditoria(nombreArchivo, tamano, duracion, true, null);
            log.info("[BACKUP] Completado exitosamente → archivo: {}, tamaño: {} bytes, duración: {}ms",
                    nombreArchivo, tamano, duracion);

            archivoSalida.deleteOnExit(); // limpieza de respaldo si el servidor se cierra antes

            return new BackupResult(archivoSalida, nombreArchivo, tamano);

        } catch (BackupException e) {
            limpiarArchivoSiExiste(archivoSalida);
            throw e;
        } catch (IOException e) {
            long duracion = System.currentTimeMillis() - inicio;
            registrarAuditoria(nombreArchivo, 0L, duracion, false, e.getMessage());
            limpiarArchivoSiExiste(archivoSalida);
            log.error("[BACKUP] Error de IO al ejecutar el backup: {}", e.getMessage(), e);
            throw new BackupException(
                    BackupException.Tipo.PROCESO_FALLIDO,
                    "Error interno al ejecutar el backup: " + e.getMessage());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            long duracion = System.currentTimeMillis() - inicio;
            registrarAuditoria(nombreArchivo, 0L, duracion, false, "Proceso interrumpido");
            limpiarArchivoSiExiste(archivoSalida);
            throw new BackupException(
                    BackupException.Tipo.PROCESO_FALLIDO,
                    "El proceso de backup fue interrumpido inesperadamente.");
        } finally {
            backupEnCurso.set(false);
        }
    }

    /**
     * Abre un InputStream sobre el archivo de backup y lo elimina del disco
     * una vez que el stream es cerrado.
     *
     * <p>Se usa en el controller para hacer stream-y-delete del archivo temporal.</p>
     */
    public InputStream abrirYBorrarTrasLeer(File archivo) throws IOException {
        return new FileInputStream(archivo) {
            @Override
            public void close() throws IOException {
                try {
                    super.close();
                } finally {
                    if (archivo.exists()) {
                        boolean borrado = archivo.delete();
                        if (!borrado) {
                            log.warn("[BACKUP] No se pudo eliminar el archivo temporal: {}", archivo.getAbsolutePath());
                        } else {
                            log.debug("[BACKUP] Archivo temporal eliminado tras descarga: {}", archivo.getName());
                        }
                    }
                }
            }
        };
    }

    // ── Helpers privados ─────────────────────────────────────────────────────

    private String buildFileName() {
        return "sgim2_backup_" + LocalDateTime.now().format(FILENAME_FMT) + ".dump";
    }

    private List<String> buildCommand(JdbcParams params, String outputPath) {
        List<String> cmd = new ArrayList<>();
        cmd.add(pgDumpPath);
        cmd.add("-h"); cmd.add(params.host);
        cmd.add("-p"); cmd.add(String.valueOf(params.port));
        cmd.add("-U"); cmd.add(datasourceUsername);
        cmd.add("-F"); cmd.add("c");          // formato custom (comprimido, selectivo)
        cmd.add("-f"); cmd.add(outputPath);
        cmd.add(params.dbName);
        return cmd;
    }

    /**
     * Parsea la URL JDBC de PostgreSQL para extraer host, puerto y nombre de BD.
     * Soporta formato: {@code jdbc:postgresql://host:port/dbname[?params]}
     */
    private JdbcParams parseJdbcUrl(String url) throws BackupException {
        try {
            // Eliminar prefijo "jdbc:postgresql://"
            String raw = url.replace("jdbc:postgresql://", "");
            // Eliminar query params si existen
            int qMark = raw.indexOf('?');
            if (qMark >= 0) raw = raw.substring(0, qMark);

            // Separar host:port del dbname
            int slashIdx = raw.indexOf('/');
            String hostPort = raw.substring(0, slashIdx);
            String dbName   = raw.substring(slashIdx + 1);

            String host;
            int port;
            if (hostPort.contains(":")) {
                String[] parts = hostPort.split(":", 2);
                host = parts[0];
                port = Integer.parseInt(parts[1]);
            } else {
                host = hostPort;
                port = 5432;
            }
            return new JdbcParams(host, port, dbName);
        } catch (Exception e) {
            throw new BackupException(
                    BackupException.Tipo.PROCESO_FALLIDO,
                    "No se pudo parsear la URL de conexión a la base de datos: " + url);
        }
    }

    private void registrarAuditoria(String nombreArchivo, long tamanoBytes,
                                    long duracionMs, boolean exito, String errorMsg) {
        try {
            Integer idUsuario = auditService.resolveCurrentUserId();
            auditService.registrarEventoConResultado(
                    AuditModulo.SISTEMA,
                    "public",
                    "database_backup",
                    null,
                    AuditAccion.BACKUP,
                    "Backup de BD: " + nombreArchivo,
                    null,
                    Map.of(
                            "archivo",      nombreArchivo,
                            "tamano_bytes", tamanoBytes,
                            "duracion_ms",  duracionMs
                    ),
                    idUsuario,
                    exito,
                    errorMsg
            );
        } catch (Exception e) {
            log.error("[BACKUP] Error al registrar auditoría del backup: {}", e.getMessage());
        }
    }

    private void limpiarArchivoSiExiste(File archivo) {
        if (archivo != null && archivo.exists()) {
            boolean borrado = archivo.delete();
            if (!borrado) {
                log.warn("[BACKUP] No se pudo eliminar el archivo temporal fallido: {}", archivo.getAbsolutePath());
            }
        }
    }

    // ── Clases internas ───────────────────────────────────────────────────────

    private record JdbcParams(String host, int port, String dbName) {}

    /**
     * Excepción tipificada del proceso de backup.
     * Permite al controller diferenciar timeouts de errores de proceso o concurrencia.
     */
    public static class BackupException extends Exception {
        public enum Tipo { TIMEOUT, PROCESO_FALLIDO, ARCHIVO_INVALIDO, CONCURRENCIA }
        private final Tipo tipo;

        public BackupException(Tipo tipo, String message) {
            super(message);
            this.tipo = tipo;
        }

        public Tipo getTipo() { return tipo; }
    }
}
