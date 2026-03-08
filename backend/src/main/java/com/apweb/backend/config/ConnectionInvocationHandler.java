package com.apweb.backend.config;

import com.apweb.backend.security.jwt.CustomUserDetails;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.sql.Connection;
import java.sql.Statement;
import java.util.regex.Pattern;

/**
 * Interceptor de conexiones JDBC que aplica SET ROLE antes de cada operación
 * SQL
 * y RESET ROLE al cerrar la conexión.
 *
 * Esto permite que, aunque el backend use un único usuario técnico (sgiri_app),
 * cada operación se ejecute bajo el rol real del usuario PostgreSQL autenticado
 * (emp_{cedula}_{id_usuario}).
 *
 * Solo tienen rol BD los empleados creados vía fn_crear_usuario_empleado.
 * Los clientes no tienen usuario BD; en ese caso el SET ROLE se omite y
 * la conexión opera como sgiri_app (permisos limitados al mínimo necesario).
 *
 * SEGURIDAD: el nombre del rol BD se valida con SAFE_ROLE_NAME antes de
 * interpolarlo en el SQL, previniendo inyección de comandos SQL.
 */
public class ConnectionInvocationHandler implements InvocationHandler {

    private static final Logger log = LoggerFactory.getLogger(ConnectionInvocationHandler.class);

    /**
     * Patrón restrictivo para nombres de rol PostgreSQL.
     * Solo letras (a-z, A-Z), números (0-9) y guiones bajos.
     * Ejemplos válidos: emp_0503360398_7, rol_tecnico, sgiri_app
     * Rechaza cualquier carácter que pudiera ser usado para inyección SQL.
     */
    private static final Pattern SAFE_ROLE_NAME = Pattern.compile("^[a-zA-Z0-9_]+$");

    private final Connection target;
    private boolean roleSet = false;

    public ConnectionInvocationHandler(Connection target) {
        this.target = target;
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        String methodName = method.getName();

        if (!roleSet && isExecutionMethod(methodName)) {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth != null && auth.getPrincipal() instanceof CustomUserDetails) {
                CustomUserDetails userDetails = (CustomUserDetails) auth.getPrincipal();
                String dbRole = userDetails.getDbUsername();

                if (dbRole != null && !dbRole.isBlank()) {
                    // SEGURIDAD: validar nombre del rol antes de usarlo en SQL
                    if (!SAFE_ROLE_NAME.matcher(dbRole).matches()) {
                        log.warn(
                                "[TRAZABILIDAD] Nombre de rol BD inválido '{}' para usuario '{}' — SET ROLE omitido por seguridad.",
                                dbRole, userDetails.getUsername());
                    } else {
                        try (Statement stmt = target.createStatement()) {
                            // Usamos identificador entre comillas dobles (estándar SQL) para seguridad
                            // adicional
                            stmt.execute("SET ROLE \"" + dbRole + "\"");
                            roleSet = true;
                            log.debug("[TRAZABILIDAD] SET ROLE '{}' aplicado para usuario app '{}'.",
                                    dbRole, userDetails.getUsername());
                        } catch (Exception e) {
                            log.error(
                                    "[TRAZABILIDAD] CRÍTICO: No se pudo aplicar SET ROLE '{}' para '{}' (Transacción abortada). Error: {}",
                                    dbRole, userDetails.getUsername(), e.getMessage());

                            // IMPORTANTE: Si un SET ROLE falla, PostgreSQL aborta físicamente la
                            // transacción actual.
                            // Si capturamos el error y permitimos que la aplicación continúe, cada query
                            // siguiente
                            // lanzará un críptico "current transaction is aborted, commands ignored".
                            // Lanzamos una excepción para forzar a Spring a realizar rollback y mostrar el
                            // error real.
                            throw new RuntimeException(
                                    "Error de Seguridad/Permisos: No se pudo establecer el contexto de base de datos para '"
                                            + dbRole + "'. " +
                                            "La transacción ha sido invalidada por PostgreSQL. Detalles: "
                                            + e.getMessage());
                        }
                    }
                } else {
                    log.debug(
                            "[TRAZABILIDAD] Usuario '{}' sin usuario BD asociado — opera como usuario técnico sgiri_app.",
                            userDetails.getUsername());
                }
            }
        }

        if ("close".equals(methodName)) {
            if (roleSet) {
                try (Statement stmt = target.createStatement()) {
                    stmt.execute("RESET ROLE");
                    log.debug("[TRAZABILIDAD] RESET ROLE ejecutado al liberar conexión.");
                } catch (Exception e) {
                    log.warn("[TRAZABILIDAD] No se pudo ejecutar RESET ROLE: {}", e.getMessage());
                }
                roleSet = false;
            }
        }

        return method.invoke(target, args);
    }

    private boolean isExecutionMethod(String methodName) {
        return "prepareStatement".equals(methodName)
                || "createStatement".equals(methodName)
                || "prepareCall".equals(methodName);
    }
}
