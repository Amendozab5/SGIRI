### 1) Diagnóstico Corto (Fuente de verdad y cuellos de botella)

- **Fuente de Verdad del Mapa**: La ubicación en el `Network Map` (`NetworkServiceImpl.java`) se calcula agrupando `clientes.ciudad` (Provincia) y haciendo un `LEFT JOIN` con `empresa.sucursal.id_ciudad`. 
- **Cuello de Botella Geográfico**: 
  - Ni `clientes.cliente` ni `usuarios.persona` afectan el mapa directamente. 
  - Todo ticket se enlaza al mapa vía su FK `id_sucursal`. Si una sucursal tiene `id_ciudad` en NULL, los tickets asignados a ella **quedan huerfanos geográficamente** en el reporte por "PROVINCIA".
- **Comportamiento ante carencias (Tickets ciegos)**: 
  - Si un ticket no tiene una sucursal con `id_ciudad`, ese ticket es derechamente ignorado en las sumatorias y puntajes del agrupamiento por provincia. No suma a "Zonas No Delimitadas" a menos que explícitamente la sucursal apuntara a ese ID.
- **Problema Crítico Detectado**: El query hace `MAX(p.id_prioridad)` uniendo `soporte.prioridad p ON p.id_item = t.id_prioridad_item`. Como actualmente `soporte.prioridad` tiene 0 filas, este `LEFT JOIN` devuelve NULL, invalidando los cálculos de severidad de tickets abiertos. **Es obligatorio** registrar las prioridades en la tabla `soporte.prioridad` vinculadas a sus respectivos `catalogos.catalogo_item`.

---

### 2) Script SQL Completamente Transaccional (SEED Seguro)

```sql
BEGIN;

DO $$
DECLARE
    -- Variables para IDs de Catálogos (se resolverán dinámicamente)
    v_cat_estado INT; v_cat_prioridad INT; v_cat_categoria INT;
    
    -- Variables de Items
    v_est_abierto INT; v_est_en_proceso INT; v_est_cerrado INT; v_est_resuelto INT;
    v_prio_baja INT; v_prio_media INT; v_prio_alta INT; v_prio_critica INT;
    v_cat_red INT; v_cat_hw INT; v_cat_sw INT;
    
    -- Entidades maestras
    v_empresa_id INT;
    v_servicio_id INT;
    v_sla_id INT;
    v_tec_usuario_id INT; v_tec_persona_id INT;
    
    -- Cursores para iterar
    rec_prov RECORD;
    i INT;
    
    -- Retornos de Inserciones
    v_persona_id INT; v_sucursal_id INT; v_cliente_id INT; v_ticket_id INT;

BEGIN
    -- 1. ASEGURAR EMPRESA BASE EXISTENTE
    SELECT id_empresa INTO v_empresa_id FROM empresa.empresa ORDER BY id_empresa ASC LIMIT 1;
    IF v_empresa_id IS NULL THEN
        INSERT INTO empresa.empresa(ruc, razon_social) VALUES ('1790000000001', 'Proveedor de Base') RETURNING id_empresa INTO v_empresa_id;
    END IF;

    -- 2. RESOLVER / INSERTAR CATÁLOGOS BASE
    INSERT INTO catalogos.catalogo (codigo, nombre) VALUES ('ESTADO_TICKET', 'Estado Ticket') ON CONFLICT DO NOTHING;
    SELECT id_catalogo INTO v_cat_estado FROM catalogos.catalogo WHERE codigo = 'ESTADO_TICKET';
    
    INSERT INTO catalogos.catalogo (codigo, nombre) VALUES ('PRIORIDAD', 'Prioridad de Ticket') ON CONFLICT DO NOTHING;
    SELECT id_catalogo INTO v_cat_prioridad FROM catalogos.catalogo WHERE codigo = 'PRIORIDAD';

    INSERT INTO catalogos.catalogo (codigo, nombre) VALUES ('CATEGORIA_TK', 'Categoría Resolutoria') ON CONFLICT DO NOTHING;
    SELECT id_catalogo INTO v_cat_categoria FROM catalogos.catalogo WHERE codigo = 'CATEGORIA_TK';

    -- Estados
    INSERT INTO catalogos.catalogo_item (id_catalogo, codigo, nombre) VALUES (v_cat_estado, 'EST_AB', 'Abierto') ON CONFLICT DO NOTHING;
    SELECT id_item INTO v_est_abierto FROM catalogos.catalogo_item WHERE codigo = 'EST_AB' AND id_catalogo = v_cat_estado;

    INSERT INTO catalogos.catalogo_item (id_catalogo, codigo, nombre) VALUES (v_cat_estado, 'EST_PR', 'En Proceso') ON CONFLICT DO NOTHING;
    SELECT id_item INTO v_est_en_proceso FROM catalogos.catalogo_item WHERE codigo = 'EST_PR' AND id_catalogo = v_cat_estado;

    INSERT INTO catalogos.catalogo_item (id_catalogo, codigo, nombre) VALUES (v_cat_estado, 'EST_RE', 'Resuelto') ON CONFLICT DO NOTHING;
    SELECT id_item INTO v_est_resuelto FROM catalogos.catalogo_item WHERE codigo = 'EST_RE' AND id_catalogo = v_cat_estado;

    INSERT INTO catalogos.catalogo_item (id_catalogo, codigo, nombre) VALUES (v_cat_estado, 'EST_CE', 'Cerrado') ON CONFLICT DO NOTHING;
    SELECT id_item INTO v_est_cerrado FROM catalogos.catalogo_item WHERE codigo = 'EST_CE' AND id_catalogo = v_cat_estado;

    -- Prioridades (Vinculadas forzosamente a `soporte.prioridad`)
    INSERT INTO catalogos.catalogo_item (id_catalogo, codigo, nombre) VALUES (v_cat_prioridad, 'PRI_BJ', 'Baja') ON CONFLICT DO NOTHING;
    SELECT id_item INTO v_prio_baja FROM catalogos.catalogo_item WHERE codigo = 'PRI_BJ' AND id_catalogo = v_cat_prioridad;
    INSERT INTO soporte.prioridad(nombre, id_item, descripcion) SELECT 'Baja', v_prio_baja, 'Prioridad Baja' WHERE NOT EXISTS (SELECT 1 FROM soporte.prioridad WHERE id_item = v_prio_baja);

    INSERT INTO catalogos.catalogo_item (id_catalogo, codigo, nombre) VALUES (v_cat_prioridad, 'PRI_MO', 'Media') ON CONFLICT DO NOTHING;
    SELECT id_item INTO v_prio_media FROM catalogos.catalogo_item WHERE codigo = 'PRI_MO' AND id_catalogo = v_cat_prioridad;
    INSERT INTO soporte.prioridad(nombre, id_item, descripcion) SELECT 'Media', v_prio_media, 'Prioridad Media' WHERE NOT EXISTS (SELECT 1 FROM soporte.prioridad WHERE id_item = v_prio_media);

    INSERT INTO catalogos.catalogo_item (id_catalogo, codigo, nombre) VALUES (v_cat_prioridad, 'PRI_AL', 'Alta') ON CONFLICT DO NOTHING;
    SELECT id_item INTO v_prio_alta FROM catalogos.catalogo_item WHERE codigo = 'PRI_AL' AND id_catalogo = v_cat_prioridad;
    INSERT INTO soporte.prioridad(nombre, id_item, descripcion) SELECT 'Alta', v_prio_alta, 'Prioridad Alta' WHERE NOT EXISTS (SELECT 1 FROM soporte.prioridad WHERE id_item = v_prio_alta);

    INSERT INTO catalogos.catalogo_item (id_catalogo, codigo, nombre) VALUES (v_cat_prioridad, 'PRI_CR', 'Crítica') ON CONFLICT DO NOTHING;
    SELECT id_item INTO v_prio_critica FROM catalogos.catalogo_item WHERE codigo = 'PRI_CR' AND id_catalogo = v_cat_prioridad;
    INSERT INTO soporte.prioridad(nombre, id_item, descripcion) SELECT 'Crítica', v_prio_critica, 'Prioridad Crítica' WHERE NOT EXISTS (SELECT 1 FROM soporte.prioridad WHERE id_item = v_prio_critica);

    -- Categorías
    INSERT INTO catalogos.catalogo_item (id_catalogo, codigo, nombre) VALUES (v_cat_categoria, 'CAT_RED', 'Redes / Enlaces') ON CONFLICT DO NOTHING;
    SELECT id_item INTO v_cat_red FROM catalogos.catalogo_item WHERE codigo = 'CAT_RED' AND id_catalogo = v_cat_categoria;
    INSERT INTO soporte.categoria(nombre, descripcion, id_item) SELECT 'Redes', 'Redes', v_cat_red WHERE NOT EXISTS (SELECT 1 FROM soporte.categoria WHERE id_item = v_cat_red);

    -- 3. CREADOR TECNICO Y SLA TICKET
    INSERT INTO soporte.sla_ticket(nombre, descripcion, tiempo_respuesta_min, tiempo_solucion_min, id_empresa) 
    SELECT 'SLA Estandar', '2h resp 24h sol', 120, 1440, v_empresa_id WHERE NOT EXISTS (SELECT 1 FROM soporte.sla_ticket WHERE nombre = 'SLA Estandar');
    SELECT id_sla INTO v_sla_id FROM soporte.sla_ticket WHERE nombre = 'SLA Estandar' LIMIT 1;

    INSERT INTO empresa.servicio(nombre, descripcion) SELECT 'Soporte Global', 'General' WHERE NOT EXISTS (SELECT 1 FROM empresa.servicio WHERE nombre = 'Soporte Global');
    SELECT id_servicio INTO v_servicio_id FROM empresa.servicio LIMIT 1;

    INSERT INTO usuarios.persona(cedula, nombre, apellido) SELECT '9999999999', 'Tecnico', 'Root' WHERE NOT EXISTS (SELECT 1 FROM usuarios.persona WHERE cedula = '9999999999');
    SELECT id_persona INTO v_tec_persona_id FROM usuarios.persona WHERE cedula = '9999999999' LIMIT 1;
    
    INSERT INTO usuarios.usuario(username, password_hash, id_rol, id_empresa, id_catalogo_item_estado) 
    SELECT 'tecnicoroot', '-', 1, v_empresa_id, v_est_abierto WHERE NOT EXISTS (SELECT 1 FROM usuarios.usuario WHERE username = 'tecnicoroot');
    SELECT id_usuario INTO v_tec_usuario_id FROM usuarios.usuario WHERE username = 'tecnicoroot' LIMIT 1;

    -- RECORRER PROVINCIAS REALES DE LA BASE DATOS
    FOR rec_prov IN SELECT c.id_ciudad, ca.id_canton, c.nombre as prov_nombre
                    FROM clientes.ciudad c
                    JOIN clientes.canton ca ON ca.id_ciudad = c.id_ciudad
    LOOP
        -- Generaremos 2 Clientes (y sucursales) por Cantón encontrado
        FOR i IN 1..2 LOOP
            -- A) PERSONA
            INSERT INTO usuarios.persona(cedula, nombre, apellido, correo, celular, id_canton)
            VALUES (lpad((rec_prov.id_canton*1000 + i)::text, 10, '0'), 'Cliente ' || i, prov_nombre, 'cl' || i || '_' || rec_prov.id_canton || '@test.com', '0990000000', rec_prov.id_canton)
            RETURNING id_persona INTO v_persona_id;

            -- B) SUCURSAL VINCULADA OBLIGATORIAMENTE A PROVINCIA (id_ciudad)
            INSERT INTO empresa.sucursal(id_empresa, nombre, direccion, id_ciudad, id_canton)
            VALUES (v_empresa_id, 'Base ' || rec_prov.prov_nombre || ' - ' || i, 'Calle Falsa 123', rec_prov.id_ciudad, rec_prov.id_canton)
            RETURNING id_sucursal INTO v_sucursal_id;

            -- C) CLIENTE
            INSERT INTO clientes.cliente(id_sucursal, id_persona, acceso_remoto)
            VALUES (v_sucursal_id, v_persona_id, true)
            RETURNING id_cliente INTO v_cliente_id;

            -- D) TICKETS (2 tickets por sucursal: 1 Abierto Critico/Alto, 1 Cerrado Bajo/Medio)
            -- ** Ticket 1: Abierto (Afecta Mapas con WARNING/CRITICAL) **
            INSERT INTO soporte.ticket(asunto, descripcion, id_servicio, id_sucursal, id_sla, id_estado_item, id_prioridad_item, id_categoria_item, id_cliente)
            VALUES ('Corte total en ' || rec_prov.prov_nombre, 'Nodo sin gestión', v_servicio_id, v_sucursal_id, v_sla_id, v_est_en_proceso, v_prio_critica, v_cat_red, v_cliente_id)
            RETURNING id_ticket INTO v_ticket_id;

            INSERT INTO soporte.historial_estado(id_ticket, usuario_bd, id_estado_nuevo, id_estado_anterior, id_estado, fecha_cambio) VALUES (v_ticket_id, 'seed_bot', v_est_abierto, v_est_abierto, v_est_abierto, NOW() - INTERVAL '2 days');
            INSERT INTO soporte.historial_estado(id_ticket, usuario_bd, id_estado_nuevo, id_estado_anterior, id_estado, fecha_cambio) VALUES (v_ticket_id, 'seed_bot', v_est_en_proceso, v_est_abierto, v_est_abierto, NOW() - INTERVAL '1 days');
            INSERT INTO soporte.asignacion(id_ticket, id_usuario) VALUES (v_ticket_id, v_tec_usuario_id);
            INSERT INTO soporte.comentario_ticket(id_ticket, id_usuario, contenido, id_estado_item, comentario, es_interno, id_empresa) VALUES (v_ticket_id, v_tec_usuario_id, 'Desplazamiento a nodo para revisar fibra', v_est_en_proceso, 'En vía', true, v_empresa_id);
            
            IF (i % 2 = 0) THEN
               INSERT INTO soporte.visita_tecnica(id_ticket, id_usuario_tecnico, id_empresa, fecha_visita, hora_inicio, id_catalogo_item_estado) VALUES (v_ticket_id, v_tec_usuario_id, v_empresa_id, CURRENT_DATE, CURRENT_TIME, v_est_en_proceso);
            END IF;

            -- ** Ticket 2: Cerrado (Histórico, afecta open_tickets=0) **
            INSERT INTO soporte.ticket(asunto, descripcion, id_servicio, id_sucursal, id_sla, id_estado_item, id_prioridad_item, id_categoria_item, id_cliente, fecha_cierre)
            VALUES ('Lentitud ' || rec_prov.prov_nombre, 'Baja de velocidad', v_servicio_id, v_sucursal_id, v_sla_id, v_est_cerrado, v_prio_baja, v_cat_red, v_cliente_id, NOW() - INTERVAL '1 days')
            RETURNING id_ticket INTO v_ticket_id;

            INSERT INTO soporte.solucion_ticket(id_ticket, descripcion_solucion, fue_resuelto, id_usuario_tecnico) VALUES (v_ticket_id, 'Reinicio equipo', true, v_tec_usuario_id);
            INSERT INTO soporte.historial_estado(id_ticket, usuario_bd, id_estado_nuevo, id_estado_anterior, id_estado, fecha_cambio) VALUES (v_ticket_id, 'seed_bot', v_est_cerrado, v_est_abierto, v_est_abierto, NOW() - INTERVAL '2 days');

        END LOOP;
    END LOOP;
END $$;

COMMIT;
```

---

### 3) Consultas SELECT de Verificación

Validación completa post-seed en base de datos.
```sql
-- 1. TICKETS TOTALES POR PROVINCIA (Mapa de Cobertura Base)
SELECT 
    ciu.nombre AS provincia, 
    COUNT(t.id_ticket) AS total_tickets
FROM soporte.ticket t
JOIN empresa.sucursal s ON t.id_sucursal = s.id_sucursal
JOIN clientes.ciudad ciu ON s.id_ciudad = ciu.id_ciudad
GROUP BY ciu.nombre
ORDER BY total_tickets DESC;

-- 2. TICKETS ACTIVOS VS CERRADOS (Crucial para el ScoreFinal)
SELECT 
    ciu.nombre AS provincia, 
    ci_estado.nombre AS estado_actual,
    COUNT(t.id_ticket) AS cant_tickets
FROM soporte.ticket t
JOIN empresa.sucursal s ON t.id_sucursal = s.id_sucursal
JOIN clientes.ciudad ciu ON s.id_ciudad = ciu.id_ciudad
JOIN catalogos.catalogo_item ci_estado ON t.id_estado_item = ci_estado.id_item
GROUP BY ciu.nombre, ci_estado.nombre
ORDER BY ciu.nombre ASC, cant_tickets DESC;

-- 3. CONSISTENCIA DE LLAVES FORÁNEAS Y REVISIÓN DE HUECOS ("Ciegos")
SELECT 
    (SELECT COUNT(*) FROM soporte.ticket WHERE id_sucursal IS NULL) as tck_sin_sucursal,
    (SELECT COUNT(*) FROM empresa.sucursal WHERE id_ciudad IS NULL) as suc_sin_provincia,
    (SELECT COUNT(*) FROM clientes.cliente WHERE id_persona IS NULL) as cli_sin_persona,
    (SELECT COUNT(*) FROM usuarios.persona WHERE id_canton IS NULL) as perd_sin_canton;

-- 4. JOIN COMPLETO REAL (Visión General de 10 tickets representativos)
SELECT 
    t.id_ticket,
    t.asunto,
    ci_estado.nombre as estado,
    ci_prio.nombre as prioridad_item,
    prio_tbl.nombre as prioridad_max_calc,
    s.nombre as sucursal_afectada,
    ciu.nombre as provincia,
    per.nombre || ' ' || per.apellido as solicitante
FROM soporte.ticket t
JOIN empresa.sucursal s ON t.id_sucursal = s.id_sucursal
JOIN clientes.ciudad ciu ON s.id_ciudad = ciu.id_ciudad
JOIN catalogos.catalogo_item ci_estado ON t.id_estado_item = ci_estado.id_item
JOIN catalogos.catalogo_item ci_prio ON t.id_prioridad_item = ci_prio.id_item
-- Esta era la tabla faltante que dejaba todo en NULL
LEFT JOIN soporte.prioridad prio_tbl ON ci_prio.id_item = prio_tbl.id_item
JOIN clientes.cliente cl ON t.id_cliente = cl.id_cliente
JOIN usuarios.persona per ON cl.id_persona = per.id_persona
LIMIT 10;
```
