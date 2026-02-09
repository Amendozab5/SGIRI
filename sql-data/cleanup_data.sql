-- Este script borra los datos transaccionales para permitir un nuevo registro limpio.
-- El orden es importante para respetar las foreign keys.

-- 1. Borrar los enlaces entre usuarios y perfiles
DELETE FROM usuarios.usuario_cliente;
DELETE FROM usuarios.usuario_empleado;

-- 2. Borrar los usuarios de la aplicación (los de sistema se recrearán al arrancar)
DELETE FROM usuarios.usuario;

-- 3. Borrar los perfiles de cliente y empleado
DELETE FROM clientes.cliente;
DELETE FROM empleados.empleado;

-- NOTA: Este script NO borra los datos de referencia como roles, pais, ciudad, o canton.
-- Los usuarios de sistema (admin, tech, user) serán recreados automáticamente por el DataLoader la próxima vez que inicies el backend.

SELECT 'Datos transaccionales de usuarios y clientes limpiados con éxito.';
