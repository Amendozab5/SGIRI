CREATE TABLE IF NOT EXISTS soporte.visita_tecnica (
    id_visita SERIAL PRIMARY KEY,
    id_ticket INTEGER NOT NULL,
    id_usuario_tecnico INTEGER NOT NULL,
    id_empresa INTEGER NOT NULL,
    fecha_visita DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME,
    id_catalogo_item_estado INTEGER NOT NULL,
    reporte_visita TEXT,
    fecha_creacion TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_visita_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket),
    CONSTRAINT fk_visita_tecnico FOREIGN KEY (id_usuario_tecnico) REFERENCES usuarios.usuario(id_usuario),
    CONSTRAINT fk_visita_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa),
    CONSTRAINT fk_visita_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item)
);

INSERT INTO catalogos.catalogo (nombre, descripcion, activo) 
SELECT 'ESTADO_VISITA', 'Estados para las visitas técnicas', true
WHERE NOT EXISTS (SELECT 1 FROM catalogos.catalogo WHERE nombre = 'ESTADO_VISITA');

DO $$
DECLARE
    v_id_cat INTEGER;
BEGIN
    SELECT id_catalogo INTO v_id_cat FROM catalogos.catalogo WHERE nombre = 'ESTADO_VISITA';
    
    INSERT INTO catalogos.catalogo_item (id_catalogo, codigo, nombre, orden, activo)
    SELECT v_id_cat, 'PROGRAMADA', 'Programada', 1, true
    WHERE NOT EXISTS (SELECT 1 FROM catalogos.catalogo_item WHERE codigo = 'PROGRAMADA' AND id_catalogo = v_id_cat);

    INSERT INTO catalogos.catalogo_item (id_catalogo, codigo, nombre, orden, activo)
    SELECT v_id_cat, 'CONFIRMADA', 'Confirmada', 2, true
    WHERE NOT EXISTS (SELECT 1 FROM catalogos.catalogo_item WHERE codigo = 'CONFIRMADA' AND id_catalogo = v_id_cat);

    INSERT INTO catalogos.catalogo_item (id_catalogo, codigo, nombre, orden, activo)
    SELECT v_id_cat, 'REPROGRAMADA', 'Reprogramada', 3, true
    WHERE NOT EXISTS (SELECT 1 FROM catalogos.catalogo_item WHERE codigo = 'REPROGRAMADA' AND id_catalogo = v_id_cat);

    INSERT INTO catalogos.catalogo_item (id_catalogo, codigo, nombre, orden, activo)
    SELECT v_id_cat, 'CANCELADA', 'Cancelada', 4, true
    WHERE NOT EXISTS (SELECT 1 FROM catalogos.catalogo_item WHERE codigo = 'CANCELADA' AND id_catalogo = v_id_cat);

    INSERT INTO catalogos.catalogo_item (id_catalogo, codigo, nombre, orden, activo)
    SELECT v_id_cat, 'FINALIZADA', 'Finalizada', 5, true
    WHERE NOT EXISTS (SELECT 1 FROM catalogos.catalogo_item WHERE codigo = 'FINALIZADA' AND id_catalogo = v_id_cat);
END $$;
