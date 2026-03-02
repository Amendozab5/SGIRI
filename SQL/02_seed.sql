-- B) Script de Seed Automático (PostgreSQL)
-- Diseñado para ser IDEMPOTENTE y no romper Foreign Keys. Uso de ON CONFLICT / INSERT WHERE NOT EXISTS

-- NOTA: Como la tabla de país y ciudad se mapean como país->provincia, aseguremos la existencia robusta:
INSERT INTO clientes.pais (id_pais, nombre, codigo) 
VALUES (1, 'Ecuador', 'EC')
ON CONFLICT DO NOTHING;

-- 1) Carga de Provincias (Ciudad) - 25 entradas
INSERT INTO clientes.ciudad (id_ciudad, nombre, id_pais) VALUES
(1, 'Pichincha', 1), (2, 'Guayas', 1), (3, 'Azuay', 1), (4, 'Manabí', 1), (5, 'Tungurahua', 1),
(6, 'Bolívar', 1), (7, 'Cañar', 1), (8, 'Carchi', 1), (9, 'Cotopaxi', 1), (10, 'Chimborazo', 1),
(11, 'El Oro', 1), (12, 'Esmeraldas', 1), (13, 'Imbabura', 1), (14, 'Loja', 1), (15, 'Los Ríos', 1),
(16, 'Morona Santiago', 1), (17, 'Napo', 1), (18, 'Pastaza', 1), (19, 'Zamora Chinchipe', 1),
(20, 'Galápagos', 1), (21, 'Sucumbíos', 1), (22, 'Orellana', 1), (23, 'Santo Domingo de los Tsáchilas', 1),
(24, 'Santa Elena', 1), (25, 'Zonas No Delimitadas', 1)
ON CONFLICT DO NOTHING;

SELECT setval('clientes.ciudad_id_ciudad_seq', (SELECT MAX(id_ciudad) FROM clientes.ciudad));

-- 2) Carga de Cantones Base (por lo menos 1 por provincia)
INSERT INTO clientes.canton (id_canton, nombre, id_ciudad) VALUES
(1, 'Quito', 1), (2, 'Rumiñahui', 1), (3, 'Mejía', 1),
(4, 'Guayaquil', 2), (5, 'Samborondón', 2), (6, 'Durán', 2),
(7, 'Cuenca', 3), (8, 'Gualaceo', 3),
(9, 'Manta', 4), (10, 'Portoviejo', 4), (11, 'Chone', 4),
(12, 'Ambato', 5), (13, 'Baños de Agua Santa', 5),
(14, 'Guaranda', 6), (15, 'Azogues', 7), (16, 'Tulcán', 8), (17, 'Latacunga', 9), (18, 'Riobamba', 10),
(19, 'Machala', 11), (20, 'Esmeraldas', 12), (21, 'Ibarra', 13), (22, 'Loja', 14), (23, 'Babahoyo', 15),
(24, 'Macas', 16), (25, 'Tena', 17), (26, 'Puyo', 18), (27, 'Zamora', 19), (28, 'Puerto Baquerizo Moreno', 20),
(29, 'Nueva Loja', 21), (30, 'El Coca', 22), (31, 'Santo Domingo', 23), (32, 'Santa Elena', 24),
(33, 'El Piedrero (No Delimitado)', 25)
ON CONFLICT DO NOTHING;
SELECT setval('clientes.canton_id_canton_seq', (SELECT MAX(id_canton) FROM clientes.canton));

-- 3) Catálogos
-- Insertar Configuración Base (si no existen)
INSERT INTO catalogos.catalogo (id_catalogo, codigo, nombre) VALUES 
(1, 'ESTADO_TICKET', 'Estado Ticket'), 
(2, 'PRIORIDAD', 'Prioridad de Ticket'), 
(3, 'CATEGORIA_TK', 'Categoría Resolutoria')
ON CONFLICT DO NOTHING;
SELECT setval('catalogos.catalogo_id_catalogo_seq', (SELECT MAX(id_catalogo) FROM catalogos.catalogo));

INSERT INTO catalogos.catalogo_item (id_item, id_catalogo, codigo, nombre) VALUES
-- Estados
(1, 1, 'EST_AB', 'Abierto'), (2, 1, 'EST_AS', 'Asignado'), (3, 1, 'EST_PR', 'En Proceso'), 
(4, 1, 'EST_ES', 'Escalado'), (5, 1, 'EST_RE', 'Resuelto'), (6, 1, 'EST_CE', 'Cerrado'),
-- Prioridades
(10, 2, 'PRI_BJ', 'Baja'), (11, 2, 'PRI_MO', 'Media'), (12, 2, 'PRI_AL', 'Alta'), (13, 2, 'PRI_CR', 'Crítica'),
-- Categorias
(20, 3, 'CAT_HW', 'Hardware'), (21, 3, 'CAT_SW', 'Software'), (22, 3, 'CAT_RED', 'Redes / Conectividad')
ON CONFLICT DO NOTHING;
SELECT setval('catalogos.catalogo_item_id_item_seq', (SELECT MAX(id_item) FROM catalogos.catalogo_item));

-- 4) Carga de Servicios Corporativos
INSERT INTO empresa.servicio (id_servicio, nombre, descripcion) VALUES
(1, 'Internet Troncalizado', 'Acometida Fibra Óptica Empresarial'),
(2, 'VPN Site to Site', 'Canal de Conectividad Nacional'),
(3, 'Telefonía IP', 'Troncales SIP')
ON CONFLICT DO NOTHING;
SELECT setval('empresa.servicio_id_servicio_seq', (SELECT MAX(id_servicio) FROM empresa.servicio));

-- Entidad dummy empresa si no existe
INSERT INTO empresa.empresa(id_empresa, ruc, razon_social) VALUES (1, '1790000000001', 'Proveedor de Internet Nacional') ON CONFLICT DO NOTHING;

-- 5) Carga de Usuarios/Roles, Personas, Sucursales y Clientes distribuidos.
DO $$
DECLARE
    prov RECORD;
    i INT;
    v_persona_base INT := 100;
    v_sucursal_base INT := 1000;
    v_cliente_base INT := 500;
    v_ticket_base INT := 2000;
BEGIN
    FOR prov IN SELECT c.id_ciudad, c.nombre AS prov_nombre, ca.id_canton, ca.nombre AS can_nombre 
                FROM clientes.ciudad c
                JOIN (SELECT id_ciudad, MIN(id_canton) as id_canton FROM clientes.canton GROUP BY id_ciudad) m_ca ON c.id_ciudad = m_ca.id_ciudad
                JOIN clientes.canton ca ON m_ca.id_canton = ca.id_canton
    LOOP
        -- Generar 3 clientes por provincia/ciudad
        FOR i IN 1..3 LOOP
            v_persona_base := v_persona_base + 1;
            v_sucursal_base := v_sucursal_base + 1;
            v_cliente_base := v_cliente_base + 1;

            -- Insert Persona
            INSERT INTO usuarios.persona(id_persona, cedula, nombre, apellido, correo, celular, id_canton)
            VALUES (v_persona_base, lpad(v_persona_base::text, 10, '0'), 'Cliente ' || i, 'De ' || prov.prov_nombre, 
                    'cliente' || v_persona_base || '@mail.com', '0990000000', prov.id_canton) ON CONFLICT DO NOTHING;
            
            -- Insert Sucursal Local
            INSERT INTO empresa.sucursal(id_sucursal, id_empresa, nombre, direccion, id_ciudad, id_canton)
            VALUES (v_sucursal_base, 1, 'Sucursal ' || prov.prov_nombre || ' ' || i, 'Av Principal ' || prov.can_nombre, 
                    prov.id_ciudad, prov.id_canton) ON CONFLICT DO NOTHING;

            -- Insert Cliente
            INSERT INTO clientes.cliente(id_cliente, id_sucursal, id_persona, acceso_remoto, fecha_inicio_contrato)
            VALUES (v_cliente_base, v_sucursal_base, v_persona_base, true, '2025-01-01') ON CONFLICT DO NOTHING;

            -- 6) Tickets: 2 tickets por cada cliente = 6 por provincia = ~150 Tickets
            -- Ticket 1: Abierto / En Proceso (Prioridad Random Alta/Media)
            v_ticket_base := v_ticket_base + 1;
            INSERT INTO soporte.ticket(id_ticket, asunto, descripcion, id_servicio, id_sucursal, id_cliente, id_estado_item, id_prioridad_item, id_categoria_item)
            VALUES (v_ticket_base, 'Caída Masiva en ' || prov.prov_nombre, 'Incidencia generada en el sector ' || prov.can_nombre, 
                    1, v_sucursal_base, v_cliente_base, 3, 12, 22) ON CONFLICT DO NOTHING;
            
            -- Historial, Asignación y Comentario para Ticket 1
            INSERT INTO soporte.historial_estado(id_historial, id_ticket, id_estado_item, fecha_cambio)
            VALUES ((v_ticket_base*10)+1, v_ticket_base, 1, NOW() - INTERVAL '2 days') ON CONFLICT DO NOTHING;
            INSERT INTO soporte.historial_estado(id_historial, id_ticket, id_estado_item, fecha_cambio)
            VALUES ((v_ticket_base*10)+2, v_ticket_base, 3, NOW() - INTERVAL '1 days') ON CONFLICT DO NOTHING;
            
            INSERT INTO soporte.asignacion(id_asignacion, id_ticket, id_usuario_asignado, fecha_asignacion)
            VALUES (v_ticket_base, v_ticket_base, 1, NOW() - INTERVAL '1 days') ON CONFLICT DO NOTHING;

            INSERT INTO soporte.comentario_ticket(id_comentario, id_ticket, comentario, interno)
            VALUES (v_ticket_base, v_ticket_base, 'Técnico notificado de caída óptica, se moviliza a la central', false) ON CONFLICT DO NOTHING;

            -- Visita Técnica (20% de probabilidad forzada, lo aplicamos al 1er cliente de la provincia)
            IF i = 1 THEN
                INSERT INTO soporte.visita_tecnica(id_visita, id_ticket, tecnico_asignado, fecha_programada, estado)
                VALUES (v_ticket_base, v_ticket_base, 1, NOW() + INTERVAL '1 day', 'Programada') ON CONFLICT DO NOTHING;
            END IF;

            -- Ticket 2: Cerrado/Resuelto (Prioridad Random Baja/Media)
            v_ticket_base := v_ticket_base + 1;
            INSERT INTO soporte.ticket(id_ticket, asunto, descripcion, id_servicio, id_sucursal, id_cliente, id_estado_item, id_prioridad_item, id_categoria_item, fecha_cierre)
            VALUES (v_ticket_base, 'C Lentitud intermitente', 'Cliente ' || prov.prov_nombre || ' reportó lentitud', 
                    2, v_sucursal_base, v_cliente_base, 6, 11, 22, NOW() - INTERVAL '3 days') ON CONFLICT DO NOTHING;

            INSERT INTO soporte.historial_estado(id_historial, id_ticket, id_estado_item, fecha_cambio)
            VALUES ((v_ticket_base*10)+1, v_ticket_base, 1, NOW() - INTERVAL '5 days') ON CONFLICT DO NOTHING;
            INSERT INTO soporte.historial_estado(id_historial, id_ticket, id_estado_item, fecha_cambio)
            VALUES ((v_ticket_base*10)+2, v_ticket_base, 6, NOW() - INTERVAL '3 days') ON CONFLICT DO NOTHING;

            INSERT INTO soporte.solucion_ticket(id_solucion, id_ticket, descripcion_solucion, fecha_solucion)
            VALUES (v_ticket_base, v_ticket_base, 'Se reinició el CPE y se estabilizaron los niveles ópticos.', NOW() - INTERVAL '3 days') ON CONFLICT DO NOTHING;

        END LOOP;
    END LOOP;
END $$;

-- Actualizamos todas las secuencias para que los inserts futuros de Spring Boot no revienten con "duplicate key"
SELECT setval('usuarios.persona_id_persona_seq', (SELECT MAX(id_persona) FROM usuarios.persona));
SELECT setval('empresa.sucursal_id_sucursal_seq', (SELECT MAX(id_sucursal) FROM empresa.sucursal));
SELECT setval('clientes.cliente_id_cliente_seq', (SELECT MAX(id_cliente) FROM clientes.cliente));
SELECT setval('soporte.ticket_id_ticket_seq', (SELECT MAX(id_ticket) FROM soporte.ticket));
SELECT setval('soporte.historial_estado_id_historial_seq', (SELECT MAX(id_historial) FROM soporte.historial_estado));
SELECT setval('soporte.asignacion_id_asignacion_seq', (SELECT MAX(id_asignacion) FROM soporte.asignacion));
SELECT setval('soporte.comentario_ticket_id_comentario_seq', (SELECT MAX(id_comentario) FROM soporte.comentario_ticket));
SELECT setval('soporte.visita_tecnica_id_visita_seq', (SELECT MAX(id_visita) FROM soporte.visita_tecnica));
SELECT setval('soporte.solucion_ticket_id_solucion_seq', (SELECT MAX(id_solucion) FROM soporte.solucion_ticket));
