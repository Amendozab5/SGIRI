-- =============================================================================
-- Migración: Agregar acción BACKUP al catálogo ACCION_AUDITORIA
-- Usa la función fn_upsert_catalogo_item existente en el schema para
-- insertar el ítem de forma idempotente (se puede ejecutar más de una vez).
--
-- Parámetros de fn_upsert_catalogo_item:
--   p_nombre_catalogo   → nombre del catálogo padre ('ACCION_AUDITORIA')
--   p_descripcion       → descripción del catálogo (puede ser vacía si ya existe)
--   p_codigo_item       → código único del ítem a insertar ('BACKUP')
--   p_nombre_item       → nombre legible del ítem
--   p_orden             → orden de presentación
-- =============================================================================

SELECT catalogos.fn_upsert_catalogo_item(
    'ACCION_AUDITORIA',              -- catálogo existente
    'Acciones del sistema auditadas',-- descripción (ignorada si el catálogo ya existe)
    'BACKUP',                        -- código del nuevo ítem
    'Backup de base de datos',       -- nombre legible
    99                               -- orden (al final)
);
