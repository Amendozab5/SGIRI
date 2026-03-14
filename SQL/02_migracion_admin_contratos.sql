-- ============================================================
-- MIGRACIÓN: ADMIN_VISUAL  →  ADMIN_CONTRATOS
-- Fecha: 2026-03-13
-- Descripción:
--   Transforma el rol vacío "ADMIN_VISUAL" (solo lectura) en
--   "ADMIN_CONTRATOS", con permisos de escritura sobre el flujo
--   de RRHH (empleados, documentos y activación de acceso).
-- ============================================================
-- PREREQUISITO: Verificar que no existen usuarios físicos activos
-- con rol_admin_visual antes de ejecutar el DROP ROLE final:
--   SELECT nombre FROM usuarios.usuario_bd ub
--   INNER JOIN usuarios.rol_bd rb ON ub.id_rol_bd = rb.id_rol_bd
--   WHERE rb.nombre = 'rol_admin_visual';
-- ============================================================

-- Asegúrese de estar conectado a la base de datos "SGIM2" antes de ejecutar.

-- ─────────────────────────────────────────────────────────────
-- 1. TABLA APLICATIVA: usuarios.rol
-- ─────────────────────────────────────────────────────────────
UPDATE usuarios.rol
SET codigo      = 'ADMIN_CONTRATOS',
    descripcion = 'Administrador de contratos y acceso de empleados'
WHERE codigo = 'ADMIN_VISUAL';

-- ─────────────────────────────────────────────────────────────
-- 2. TABLA LÓGICA: usuarios.rol_bd
-- ─────────────────────────────────────────────────────────────
UPDATE usuarios.rol_bd
SET nombre      = 'rol_admin_contratos',
    descripcion = 'Rol BD administrador contratos'
WHERE nombre = 'rol_admin_visual';

-- ─────────────────────────────────────────────────────────────
-- 2b. TABLA DE CARGOS: empleados.cargo
-- ─────────────────────────────────────────────────────────────
UPDATE empleados.cargo
SET nombre = 'Administrador Contratos'
WHERE nombre = 'Administrador Visual';

-- ─────────────────────────────────────────────────────────────
-- 3. ROL FÍSICO EN POSTGRESQL
-- ─────────────────────────────────────────────────────────────

-- 3a. Crear el nuevo rol físico (hereda de postgres para poder
--     usar GRANT USAGE en schemas como el resto de roles del sistema)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_admin_contratos') THEN
        CREATE ROLE rol_admin_contratos;
        RAISE NOTICE 'Rol físico "rol_admin_contratos" creado.';
    ELSE
        RAISE NOTICE 'Rol "rol_admin_contratos" ya existe.';
    END IF;
END;
$$;

-- ─────────────────────────────────────────────────────────────
-- 4. PERMISOS DE SCHEMAS (mismos que tenía rol_admin_visual)
-- ─────────────────────────────────────────────────────────────
GRANT USAGE ON SCHEMA auditoria      TO rol_admin_contratos;
GRANT USAGE ON SCHEMA catalogos      TO rol_admin_contratos;
GRANT USAGE ON SCHEMA clientes       TO rol_admin_contratos;
GRANT USAGE ON SCHEMA empleados      TO rol_admin_contratos;
GRANT USAGE ON SCHEMA empresa        TO rol_admin_contratos;
GRANT USAGE ON SCHEMA notificaciones TO rol_admin_contratos;
GRANT USAGE ON SCHEMA reportes       TO rol_admin_contratos;
GRANT USAGE ON SCHEMA soporte        TO rol_admin_contratos;
GRANT USAGE ON SCHEMA usuarios       TO rol_admin_contratos;

-- ─────────────────────────────────────────────────────────────
-- 5. PERMISOS DE LECTURA GENERAL (heredados de ADMIN_VISUAL)
-- ─────────────────────────────────────────────────────────────

-- auditoria
GRANT SELECT, INSERT ON TABLE auditoria.auditoria_estado_ticket  TO rol_admin_contratos;
GRANT SELECT, USAGE  ON SEQUENCE auditoria.auditoria_estado_ticket_id_auditoria_seq TO rol_admin_contratos;
GRANT SELECT, INSERT ON TABLE auditoria.auditoria_evento         TO rol_admin_contratos;
GRANT SELECT, USAGE  ON SEQUENCE auditoria.auditoria_evento_id_evento_seq TO rol_admin_contratos;
GRANT SELECT, INSERT ON TABLE auditoria.auditoria_login          TO rol_admin_contratos;
GRANT SELECT, INSERT ON TABLE auditoria.auditoria_login_bd       TO rol_admin_contratos;
GRANT SELECT, USAGE  ON SEQUENCE auditoria.auditoria_login_bd_id_auditoria_login_bd_seq TO rol_admin_contratos;
GRANT SELECT, USAGE  ON SEQUENCE auditoria.auditoria_login_id_login_seq TO rol_admin_contratos;
GRANT SELECT, INSERT ON TABLE auditoria.vw_timeline_administrativa TO rol_admin_contratos;

-- catalogos
GRANT SELECT ON TABLE catalogos.catalogo      TO rol_admin_contratos;
GRANT SELECT ON TABLE catalogos.catalogo_item TO rol_admin_contratos;
GRANT SELECT, USAGE ON SEQUENCE catalogos.catalogo_id_catalogo_seq     TO rol_admin_contratos;
GRANT SELECT, USAGE ON SEQUENCE catalogos.catalogo_item_id_item_seq    TO rol_admin_contratos;

-- clientes
GRANT SELECT ON TABLE clientes.canton            TO rol_admin_contratos;
GRANT SELECT ON TABLE clientes.ciudad            TO rol_admin_contratos;
GRANT SELECT ON TABLE clientes.cliente           TO rol_admin_contratos;
GRANT SELECT ON TABLE clientes.documento_cliente TO rol_admin_contratos;
GRANT SELECT ON TABLE clientes.pais              TO rol_admin_contratos;
GRANT SELECT ON TABLE clientes.tipo_documento    TO rol_admin_contratos;
GRANT SELECT, USAGE ON SEQUENCE clientes.canton_id_canton_seq                        TO rol_admin_contratos;
GRANT SELECT, USAGE ON SEQUENCE clientes.ciudad_id_ciudad_seq                        TO rol_admin_contratos;
GRANT SELECT, USAGE ON SEQUENCE clientes.cliente_id_cliente_seq                      TO rol_admin_contratos;
GRANT SELECT, USAGE ON SEQUENCE clientes.documento_cliente_id_documento_seq          TO rol_admin_contratos;
GRANT SELECT, USAGE ON SEQUENCE clientes.pais_id_pais_seq                            TO rol_admin_contratos;
GRANT SELECT, USAGE ON SEQUENCE clientes.tipo_documento_id_tipo_documento_seq        TO rol_admin_contratos;

-- empresa
GRANT SELECT ON TABLE empresa.empresa           TO rol_admin_contratos;
GRANT SELECT ON TABLE empresa.documento_empresa TO rol_admin_contratos;
GRANT SELECT, USAGE ON SEQUENCE empresa.documento_empresa_id_documento_seq TO rol_admin_contratos;

-- notificaciones (lectura)
GRANT SELECT ON ALL TABLES IN SCHEMA notificaciones TO rol_admin_contratos;
GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA notificaciones TO rol_admin_contratos;

-- reportes
GRANT SELECT ON ALL TABLES IN SCHEMA reportes TO rol_admin_contratos;
GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA reportes TO rol_admin_contratos;

-- soporte (lectura)
GRANT SELECT ON ALL TABLES IN SCHEMA soporte TO rol_admin_contratos;
GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA soporte TO rol_admin_contratos;

-- ─────────────────────────────────────────────────────────────
-- 6. PERMISOS NUEVOS — FLUJO RRHH (escritura)
-- ─────────────────────────────────────────────────────────────

-- Empleados: crear, leer y actualizar empleados
GRANT SELECT, INSERT, UPDATE ON TABLE empleados.area           TO rol_admin_contratos;
GRANT SELECT, INSERT, UPDATE ON TABLE empleados.cargo          TO rol_admin_contratos;
GRANT SELECT, INSERT, UPDATE ON TABLE empleados.empleado       TO rol_admin_contratos;
GRANT SELECT, INSERT, UPDATE ON TABLE empleados.tipo_contrato  TO rol_admin_contratos;

-- Documentos de empleados: subir y cambiar estado
GRANT SELECT, INSERT, UPDATE ON TABLE empleados.documento_empleado TO rol_admin_contratos;

-- Secuencias de empleados
GRANT SELECT, USAGE ON SEQUENCE empleados.area_id_area_seq                           TO rol_admin_contratos;
GRANT SELECT, USAGE ON SEQUENCE empleados.cargo_id_cargo_seq                         TO rol_admin_contratos;
GRANT SELECT, USAGE ON SEQUENCE empleados.empleado_id_empleado_seq                   TO rol_admin_contratos;
GRANT SELECT, USAGE ON SEQUENCE empleados.tipo_contrato_id_tipo_contrato_seq         TO rol_admin_contratos;
GRANT SELECT, USAGE ON SEQUENCE empleados.documento_empleado_id_documento_seq        TO rol_admin_contratos;

-- Usuarios: leer tabla y permitir que fn_crear_usuario_empleado inserte
GRANT SELECT, INSERT, UPDATE ON TABLE usuarios.usuario    TO rol_admin_contratos;
GRANT SELECT, INSERT ON TABLE usuarios.persona    TO rol_admin_contratos;
GRANT SELECT, INSERT ON TABLE usuarios.rol        TO rol_admin_contratos;
GRANT SELECT         ON TABLE usuarios.rol_bd     TO rol_admin_contratos;
GRANT SELECT, INSERT ON TABLE usuarios.usuario_bd TO rol_admin_contratos;
GRANT SELECT, USAGE ON SEQUENCE usuarios.usuario_id_usuario_seq TO rol_admin_contratos;
GRANT SELECT, USAGE ON SEQUENCE usuarios.persona_id_persona_seq TO rol_admin_contratos;

-- ─────────────────────────────────────────────────────────────
-- 6b. SINCRONIZACIÓN DE SECUENCIAS (Fix PK duplicated)
-- ─────────────────────────────────────────────────────────────
-- Sincronizar secuencias de usuarios
SELECT setval('usuarios.persona_id_persona_seq', (SELECT MAX(id_persona) FROM usuarios.persona));
SELECT setval('usuarios.usuario_id_usuario_seq', (SELECT MAX(id_usuario) FROM usuarios.usuario));
SELECT setval('usuarios.usuario_bd_id_usuario_bd_seq', (SELECT MAX(id_usuario_bd) FROM usuarios.usuario_bd));

-- Sincronizar secuencias del flujo de empleados
SELECT setval('empleados.empleado_id_empleado_seq', (SELECT MAX(id_empleado) FROM empleados.empleado));
SELECT setval('empleados.documento_empleado_id_documento_seq', (SELECT MAX(id_documento) FROM empleados.documento_empleado));
SELECT setval('empleados.area_id_area_seq', (SELECT MAX(id_area) FROM empleados.area));
SELECT setval('empleados.cargo_id_cargo_seq', (SELECT MAX(id_cargo) FROM empleados.cargo));

-- Permitir ejecutar la función de creación de usuario empleado
GRANT EXECUTE ON FUNCTION usuarios.fn_crear_usuario_empleado(
    character varying, integer, integer, integer, integer
) TO rol_admin_contratos;

-- Permitir ejecutar la función de generación de credenciales
GRANT EXECUTE ON FUNCTION usuarios.fn_generar_credenciales(
    character varying, integer
) TO rol_admin_contratos;

-- ─────────────────────────────────────────────────────────────
-- 7. REVOCAR rol_admin_visual DEL ROL FÍSICO (si aplica)
-- ─────────────────────────────────────────────────────────────
-- Si existen usuarios físicos PostgreSQL que heredan de rol_admin_visual,
-- migrarlos al nuevo rol antes de hacer el DROP:
-- GRANT rol_admin_contratos TO <emp_xxx_yyy>;
-- REVOKE rol_admin_visual FROM <emp_xxx_yyy>;

-- 7a. Drop del rol antiguo (solo si NO tiene miembros activos)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_admin_visual') THEN
        BEGIN
            DROP ROLE rol_admin_visual;
            RAISE NOTICE 'Rol físico "rol_admin_visual" eliminado.';
        EXCEPTION WHEN others THEN
            RAISE WARNING 'No se pudo eliminar "rol_admin_visual": %. Elimínelo manualmente tras migrar sus miembros.', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'Rol físico "rol_admin_visual" no existía. Nada que eliminar.';
    END IF;
END;
$$;

-- ─────────────────────────────────────────────────────────────
-- 8. VERIFICACIÓN FINAL
-- ─────────────────────────────────────────────────────────────
SELECT 'usuarios.rol'    AS tabla, codigo AS valor FROM usuarios.rol    WHERE codigo = 'ADMIN_CONTRATOS'
UNION ALL
SELECT 'usuarios.rol_bd' AS tabla, nombre AS valor FROM usuarios.rol_bd WHERE nombre = 'rol_admin_contratos'
UNION ALL
SELECT 'pg_roles'        AS tabla, rolname AS valor FROM pg_roles       WHERE rolname IN ('rol_admin_contratos', 'rol_admin_visual');

-- ============================================================
-- REFUERZO DE PERMISOS: ADMIN_CONTRATOS (Fix Final)
-- ============================================================

-- Otorgar permisos completos sobre el esquema empresa (importante para el dashboard y HR)
GRANT SELECT ON ALL TABLES IN SCHEMA empresa TO rol_admin_contratos;
GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA empresa TO rol_admin_contratos;

-- Asegurar permisos sobre clientes (geografía, etc)
GRANT SELECT ON ALL TABLES IN SCHEMA clientes TO rol_admin_contratos;
GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA clientes TO rol_admin_contratos;

-- Sincronización de secuencias adicional
SELECT setval('empresa.empresa_id_empresa_seq', (SELECT MAX(id_empresa) FROM empresa.empresa));
SELECT setval('empresa.sucursal_id_sucursal_seq', (SELECT MAX(id_sucursal) FROM empresa.sucursal));

-- Permisos adicionales en el esquema usuarios
GRANT SELECT ON ALL TABLES IN SCHEMA usuarios TO rol_admin_contratos;
GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA usuarios TO rol_admin_contratos;

-- Mensaje de confirmación (compatible con SQL plano)
SELECT 'Permisos de ADMIN_CONTRATOS reforzados y actualizados correctamente' AS status;

