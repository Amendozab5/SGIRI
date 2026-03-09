-- Script de reparación de permisos para roles físicos de empleados
-- Este script otorga permisos básicos a los roles que heredan los usuarios "emp_{cedula}_{id}"
-- para que puedan realizar el cambio de contraseña inicial y operar el sistema.

-- 1. Permisos de Esquema (USAGE)
GRANT USAGE ON SCHEMA usuarios TO rol_tecnico, rol_admin_tecnicos, rol_admin_visual, rol_cliente;
GRANT USAGE ON SCHEMA catalogos TO rol_tecnico, rol_admin_tecnicos, rol_admin_visual, rol_cliente;
GRANT USAGE ON SCHEMA auditoria TO rol_tecnico, rol_admin_tecnicos, rol_admin_visual, rol_cliente;
GRANT USAGE ON SCHEMA soporte TO rol_tecnico, rol_admin_tecnicos, rol_admin_visual;
GRANT USAGE ON SCHEMA empleados TO rol_tecnico, rol_admin_tecnicos, rol_admin_visual;
GRANT USAGE ON SCHEMA clientes TO rol_tecnico, rol_admin_tecnicos, rol_admin_visual;
GRANT USAGE ON SCHEMA empresa TO rol_tecnico, rol_admin_tecnicos, rol_admin_visual;
GRANT USAGE ON SCHEMA notificaciones TO rol_tecnico, rol_admin_tecnicos, rol_admin_visual;

-- 2. Permisos de Tabla (SELECT/UPDATE en usuarios.usuario)
-- Necesario para que el usuario pueda actualizar su propia contraseña y estado de primer login
GRANT SELECT, UPDATE ON TABLE usuarios.usuario TO rol_tecnico, rol_admin_tecnicos, rol_admin_visual;
-- También necesitamos SELECT en catálogos para mapeos de DTO
GRANT SELECT ON TABLE catalogos.catalogo TO rol_tecnico, rol_admin_tecnicos, rol_admin_visual, rol_cliente;
GRANT SELECT ON TABLE catalogos.catalogo_item TO rol_tecnico, rol_admin_tecnicos, rol_admin_visual, rol_cliente;

-- 3. Permisos de Secuencia (USAGE)
-- Si intentan registrar auditoría o insertar comentarios, necesitarán secuencias
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA usuarios TO rol_tecnico, rol_admin_tecnicos, rol_admin_visual;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA auditoria TO rol_tecnico, rol_admin_tecnicos, rol_admin_visual;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA soporte TO rol_tecnico, rol_admin_tecnicos, rol_admin_visual;

-- 4. Otros permisos básicos (Soporte)
GRANT SELECT, INSERT, UPDATE ON TABLE soporte.ticket TO rol_tecnico, rol_admin_tecnicos;
GRANT SELECT, INSERT, UPDATE ON TABLE soporte.comentario_ticket TO rol_tecnico, rol_admin_tecnicos;
GRANT SELECT, INSERT, UPDATE ON TABLE soporte.historial_estado TO rol_tecnico, rol_admin_tecnicos;

-- 5. Auditoría (Permitir registrar eventos)
GRANT INSERT ON TABLE auditoria.auditoria_evento TO rol_tecnico, rol_admin_tecnicos, rol_admin_visual, rol_cliente;
GRANT INSERT ON TABLE auditoria.auditoria_login TO rol_tecnico, rol_admin_tecnicos, rol_admin_visual, rol_cliente;
