-- Migración: Sistema de calificación del técnico
-- Fecha: 2026-03-04
-- Descripción: Agrega columna de comentario de calificación al ticket
-- La columna calificacion_satisfaccion ya existe en el schema.

ALTER TABLE soporte.ticket 
    ADD COLUMN IF NOT EXISTS comentario_calificacion TEXT;

COMMENT ON COLUMN soporte.ticket.comentario_calificacion IS 
    'Comentario opcional del usuario al calificar al técnico';

-- Verificación
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'soporte' 
  AND table_name = 'ticket'
  AND column_name IN ('calificacion_satisfaccion', 'comentario_calificacion')
ORDER BY column_name;
