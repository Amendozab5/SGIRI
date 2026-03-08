-- =============================================================================
-- V8__audit_catalogo_fix.sql
-- Asegura que los códigos de acción básicos existan en el catálogo.
-- =============================================================================

INSERT INTO catalogos.catalogo_item (id_catalogo, codigo, nombre, activo, orden)
VALUES 
(8, 'INSERT', 'Inserción de registro', true, 1),
(8, 'UPDATE', 'Actualización de registro', true, 2),
(8, 'DELETE', 'Eliminación de registro', true, 3),
(8, 'LOGIN', 'Inicio de sesión exitoso', true, 4),
(8, 'CAMBIO_ESTADO', 'Cambio de estado funcional', true, 5),
(8, 'LOGOUT', 'Cierre de sesión manual', true, 15)
ON CONFLICT (id_catalogo, codigo) DO UPDATE 
SET activo = true, nombre = EXCLUDED.nombre;

-- Verificación:
-- SELECT * FROM catalogos.catalogo_item WHERE id_catalogo = 8;
