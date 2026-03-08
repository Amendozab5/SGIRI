-- =============================================================================
-- V9__audit_fix_trazabilidad.sql
-- Restaura la vinculación entre usuarios aplicativos y roles físicos de BD.
-- Evita que la auditoría guarde 'sgiri_app' o NULL por falta de datos lógicos.
-- =============================================================================

DO $$
DECLARE
    v_rec RECORD;
    v_id_rol_bd INTEGER;
BEGIN
    -- 1. Intentar obtener el ID del rol_bd genérico para empleados si existe
    -- (Basado en la lógica de usuarios.rol_bd del sistema)
    
    FOR v_rec IN 
        SELECT 
            u.id_usuario,
            u.username,
            p.cedula,
            r.codigo as rol_app
        FROM usuarios.usuario u
        INNER JOIN usuarios.persona p ON u.id_usuario = p.id_usuario
        INNER JOIN usuarios.rol r ON u.id_rol = r.id_rol
        WHERE r.codigo IN ('TECNICO', 'ADMIN_TECNICOS', 'ADMIN_MASTER', 'ADMIN_VISUAL')
    LOOP
        -- Construir el nombre del rol físico esperado: emp_{cedula}_{id}
        -- Este es el patrón que fn_crear_usuario_empleado debe haber usado
        
        -- Buscar el rol_bd lógico adecuado (ej. rol_tecnico)
        SELECT id_rol_bd INTO v_id_rol_bd
        FROM usuarios.rol_bd
        WHERE nombre = 'rol_' || LOWER(v_rec.rol_app);

        IF v_id_rol_bd IS NOT NULL THEN
            -- Insertar la relación si no existe
            INSERT INTO usuarios.usuario_bd (nombre, id_rol_bd, id_usuario)
            VALUES (
                'emp_' || v_rec.cedula || '_' || v_rec.id_usuario,
                v_id_rol_bd,
                v_rec.id_usuario
            )
            ON CONFLICT (id_usuario) DO UPDATE 
            SET nombre = EXCLUDED.nombre, id_rol_bd = EXCLUDED.id_rol_bd;
            
            RAISE NOTICE 'Vinculación restaurada para usuario: % (Role: %)', v_rec.username, v_rec.rol_app;
        END IF;
    END LOOP;
END $$;
