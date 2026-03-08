-- =============================================================================
-- V10__permisos_rol_tecnico.sql
-- Cierre integral de permisos para el rol base 'rol_tecnico'.
-- Asegura que el técnico pueda operar tickets, visitas y perfil sin errores.
-- =============================================================================

DO $$
BEGIN
    -- 1. Permisos de Esquema (USAGE)
    GRANT USAGE ON SCHEMA usuarios TO rol_tecnico;
    GRANT USAGE ON SCHEMA soporte TO rol_tecnico;
    GRANT USAGE ON SCHEMA catalogos TO rol_tecnico;
    GRANT USAGE ON SCHEMA clientes TO rol_tecnico;
    GRANT USAGE ON SCHEMA empresa TO rol_tecnico;
    GRANT USAGE ON SCHEMA notificaciones TO rol_tecnico;
    GRANT USAGE ON SCHEMA auditoria TO rol_tecnico;

    -- 2. Permisos sobre Tablas de Consulta (SELECT)
    GRANT SELECT ON ALL TABLES IN SCHEMA catalogos TO rol_tecnico;
    GRANT SELECT ON ALL TABLES IN SCHEMA empresa TO rol_tecnico;
    GRANT SELECT ON ALL TABLES IN SCHEMA clientes TO rol_tecnico;
    
    GRANT SELECT ON TABLE usuarios.usuario TO rol_tecnico;
    GRANT SELECT ON TABLE usuarios.persona TO rol_tecnico;
    GRANT SELECT ON TABLE usuarios.rol TO rol_tecnico;
    GRANT SELECT ON TABLE usuarios.usuario_bd TO rol_tecnico;
    
    GRANT SELECT ON ALL TABLES IN SCHEMA soporte TO rol_tecnico;
    GRANT SELECT ON ALL TABLES IN SCHEMA notificaciones TO rol_tecnico;

    -- 3. Permisos Operativos (INSERT, UPDATE)
    -- Tickets y Comentarios
    GRANT UPDATE (id_estado_item, id_categoria_item, fecha_actualizacion, impacto, urgencia, puntaje_prioridad) 
    ON soporte.ticket TO rol_tecnico;
    
    GRANT INSERT, UPDATE ON soporte.comentario_ticket TO rol_tecnico;
    GRANT INSERT, UPDATE ON soporte.solucion_ticket TO rol_tecnico;
    GRANT INSERT, UPDATE ON soporte.visita_tecnica TO rol_tecnico;
    GRANT INSERT ON soporte.documento_ticket TO rol_tecnico;
    GRANT INSERT ON soporte.historial_estado TO rol_tecnico;

    -- Notificaciones
    GRANT UPDATE (leida, fecha_lectura) ON notificaciones.notificacion_web TO rol_tecnico;
    GRANT INSERT ON notificaciones.cola_correo TO rol_tecnico;

    -- Auditoría (Obligatorio para que AuditService funcione)
    GRANT INSERT ON auditoria.auditoria_evento TO rol_tecnico;
    GRANT INSERT ON auditoria.auditoria_login TO rol_tecnico;
    GRANT INSERT ON auditoria.auditoria_estado_ticket TO rol_tecnico;

    -- 4. Permisos sobre Secuencias (USAGE, SELECT)
    -- Necesario para realizar INSERTs sin fallos de generación de ID
    GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA soporte TO rol_tecnico;
    GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA auditoria TO rol_tecnico;
    GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA notificaciones TO rol_tecnico;

    -- 5. Privilegios por Defecto (Opcional pero recomendado para consistencia futura)
    ALTER DEFAULT PRIVILEGES IN SCHEMA soporte GRANT SELECT ON TABLES TO rol_tecnico;
    ALTER DEFAULT PRIVILEGES IN SCHEMA catalogos GRANT SELECT ON TABLES TO rol_tecnico;

    RAISE NOTICE 'Cierre de permisos para rol_tecnico completado exitosamente.';
END $$;
