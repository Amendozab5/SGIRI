-- Script: Create informe_trabajo_tecnico table
-- Schema: soporte
-- Description: Stores the technical work report for each ticket attended by a technician

CREATE TABLE IF NOT EXISTS soporte.informe_trabajo_tecnico (
    id_informe              SERIAL PRIMARY KEY,
    id_ticket               INTEGER NOT NULL REFERENCES soporte.ticket(id_ticket),
    id_tecnico              INTEGER NOT NULL REFERENCES usuarios.usuario(id_usuario),
    resultado               VARCHAR(20) NOT NULL CHECK (resultado IN ('RESUELTO', 'NO_RESUELTO')),
    implementos_usados      TEXT,
    problemas_encontrados   TEXT,
    solucion_aplicada       TEXT,
    pruebas_realizadas      TEXT,
    motivo_no_resolucion    TEXT,
    comentario_tecnico      TEXT,
    url_adjunto             TEXT,
    tiempo_trabajo_minutos  INTEGER,
    fecha_registro          TIMESTAMP DEFAULT NOW() NOT NULL
);

COMMENT ON TABLE soporte.informe_trabajo_tecnico IS 'Informe técnico del trabajo realizado por el técnico al atender un ticket';
COMMENT ON COLUMN soporte.informe_trabajo_tecnico.resultado IS 'RESUELTO o NO_RESUELTO';
COMMENT ON COLUMN soporte.informe_trabajo_tecnico.implementos_usados IS 'Lista de implementos/herramientas usados (texto libre o JSON)';
COMMENT ON COLUMN soporte.informe_trabajo_tecnico.problemas_encontrados IS 'Descripción de problemas encontrados durante el diagnóstico';
COMMENT ON COLUMN soporte.informe_trabajo_tecnico.solucion_aplicada IS 'Descripción de la solución aplicada';
COMMENT ON COLUMN soporte.informe_trabajo_tecnico.pruebas_realizadas IS 'Descripción de pruebas realizadas para verificar la solución';
COMMENT ON COLUMN soporte.informe_trabajo_tecnico.motivo_no_resolucion IS 'Motivo por el cual no se pudo resolver (cuando resultado=NO_RESUELTO)';
COMMENT ON COLUMN soporte.informe_trabajo_tecnico.url_adjunto IS 'URL o ruta de archivo adjunto de evidencia';
COMMENT ON COLUMN soporte.informe_trabajo_tecnico.tiempo_trabajo_minutos IS 'Tiempo total de trabajo en minutos';
