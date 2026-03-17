-- Migration to add mutual agreement fields for ticket closure
ALTER TABLE soporte.ticket ADD COLUMN confirmacion_tecnico BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE soporte.ticket ADD COLUMN confirmacion_cliente BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN soporte.ticket.confirmacion_tecnico IS 'Indica si el técnico asignado ha confirmado el cierre del ticket';
COMMENT ON COLUMN soporte.ticket.confirmacion_cliente IS 'Indica si el cliente ha confirmado o solicitado el cierre del ticket';
