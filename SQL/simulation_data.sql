-- ==========================================================
-- SCRIPT DE SIMULACIÓN: AFILIACIÓN A EMPRESAS (ISPs)
-- ==========================================================

-- 1. Asegurar la existencia de las Empresas (Proveedores de Internet)
-- Nota: id_catalogo_item_estado = 1 asumiendo que es 'ACTIVO' según el catálogo inicial
INSERT INTO empresa.empresa (nombre_comercial, razon_social, ruc, tipo_empresa, id_catalogo_item_estado) VALUES 
('CNT', 'Corporación Nacional de Telecomunicaciones CNT EP', '1768152560001', 'PUBLICA', 1),
('Netlife', 'MEGADATOS S.A. (NETLIFE)', '1792161037001', 'PRIVADA', 1),
('Xtrim', 'TV CABLE / XTRIM', '0990793664001', 'PRIVADA', 1);

-- 2. Insertar Sucursales
INSERT INTO empresa.sucursal (id_empresa, nombre, direccion, id_catalogo_item_estado) 
SELECT id_empresa, 'Sucursal Matriz ' || nombre_comercial, 'Dirección Principal de ' || nombre_comercial, 1
FROM empresa.empresa
WHERE nombre_comercial IN ('CNT', 'Netlife', 'Xtrim');

-- 3. Insertar Personas (Datos reales proporcionados por el usuario)
-- Nota: El campo id_usuario es NULL porque aún no se han registrado en el aplicativo
INSERT INTO usuarios.persona (cedula, nombre, apellido, correo, id_usuario) VALUES 
('0503360398', 'Angello Agustin', 'Mendoza Bermello', 'angellomendoza46@gmail.com', NULL),
('1207445154', 'Elizabeth Anahis', 'Burgos Chilan', 'elizabethanahisb@gmail.com', NULL),
('1207910165', 'Justyn Keith', 'Cruz Perez', 'justyncruzperez@gmail.com', NULL);

-- 4. Afiliar Personas como Clientes de las empresas (Pre-registro)
-- Angello -> Netlife
INSERT INTO clientes.cliente (id_sucursal, id_persona, acceso_remoto, aprobacion_de_cambios, actualizaciones_automaticas) 
SELECT s.id_sucursal, p.id_persona, TRUE, FALSE, TRUE
FROM empresa.sucursal s, usuarios.persona p, empresa.empresa e
WHERE s.id_empresa = e.id_empresa 
AND e.nombre_comercial = 'Netlife'
AND p.cedula = '0503360398';

-- Elizabeth -> CNT
INSERT INTO clientes.cliente (id_sucursal, id_persona, acceso_remoto, aprobacion_de_cambios, actualizaciones_automaticas) 
SELECT s.id_sucursal, p.id_persona, TRUE, FALSE, TRUE
FROM empresa.sucursal s, usuarios.persona p, empresa.empresa e
WHERE s.id_empresa = e.id_empresa 
AND e.nombre_comercial = 'CNT'
AND p.cedula = '1207445154';

-- Justyn -> Xtrim
INSERT INTO clientes.cliente (id_sucursal, id_persona, acceso_remoto, aprobacion_de_cambios, actualizaciones_automaticas) 
SELECT s.id_sucursal, p.id_persona, TRUE, FALSE, TRUE
FROM empresa.sucursal s, usuarios.persona p, empresa.empresa e
WHERE s.id_empresa = e.id_empresa 
AND e.nombre_comercial = 'Xtrim'
AND p.cedula = '1207910165';

-- ==========================================================
-- FIN DEL SCRIPT
-- ==========================================================
