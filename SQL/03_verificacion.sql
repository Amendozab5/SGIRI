-- C) Verificación Post-Seed

-- 1. ¿Cuántos clientes tienen base geográfica validada mediante persona y sucursal?
SELECT 
    COUNT(c.id_cliente) AS total_clientes,
    COUNT(p.id_canton) AS clientes_con_canton_persona,
    COUNT(s.id_ciudad) AS clientes_con_provincia_sucursal
FROM clientes.cliente c
LEFT JOIN usuarios.persona p ON c.id_persona = p.id_persona
LEFT JOIN empresa.sucursal s ON c.id_sucursal = s.id_sucursal;

-- 2. Resumen de Tickets por Provincia y Estado
SELECT 
    ciu.nombre AS provincia, 
    ci_estado.nombre AS estado_ticket, 
    COUNT(t.id_ticket) AS total_tickets
FROM soporte.ticket t
JOIN empresa.sucursal s ON t.id_sucursal = s.id_sucursal
JOIN clientes.ciudad ciu ON s.id_ciudad = ciu.id_ciudad
JOIN catalogos.catalogo_item ci_estado ON t.id_estado_item = ci_estado.id_item
GROUP BY ciu.nombre, ci_estado.nombre
ORDER BY ciu.nombre, ci_estado.nombre;

-- 3. Top Provincias con más Tickets Abiertos (Excluyendo resueltos/cerrados)
SELECT 
    ciu.nombre AS provincia, 
    COUNT(t.id_ticket) AS tickets_activos
FROM soporte.ticket t
JOIN empresa.sucursal s ON t.id_sucursal = s.id_sucursal
JOIN clientes.ciudad ciu ON s.id_ciudad = ciu.id_ciudad
JOIN catalogos.catalogo_item ci_estado ON t.id_estado_item = ci_estado.id_item
WHERE ci_estado.codigo IN ('EST_AB', 'EST_PR', 'EST_AS', 'EST_ES')
GROUP BY ciu.nombre
ORDER BY tickets_activos DESC;

-- 4. Muestra de 5 Tickets con Full Join para comprobar consistencia (Persona + Sucursal + Ubicación + Catálogos)
SELECT 
    t.id_ticket, 
    t.asunto, 
    p.nombre || ' ' || p.apellido AS cliente_solicitante,
    s.nombre AS sucursal_afectada,
    ciu.nombre AS provincia_afectada,
    can.nombre AS canton_afectado,
    ci_est.nombre AS estado,
    ci_prio.nombre AS prioridad,
    ci_cat.nombre AS categoria
FROM soporte.ticket t
JOIN clientes.cliente c ON t.id_cliente = c.id_cliente
JOIN usuarios.persona p ON c.id_persona = p.id_persona
JOIN empresa.sucursal s ON t.id_sucursal = s.id_sucursal
JOIN clientes.ciudad ciu ON s.id_ciudad = ciu.id_ciudad
JOIN clientes.canton can ON s.id_canton = can.id_canton
JOIN catalogos.catalogo_item ci_est ON t.id_estado_item = ci_est.id_item
JOIN catalogos.catalogo_item ci_prio ON t.id_prioridad_item = ci_prio.id_item
JOIN catalogos.catalogo_item ci_cat ON t.id_categoria_item = ci_cat.id_item
LIMIT 5;
