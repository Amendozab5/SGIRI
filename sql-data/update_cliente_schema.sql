-- Script para actualizar la tabla clientes.cliente

-- 1. Renombrar la columna 'apellido' a 'apellidos'
ALTER TABLE clientes.cliente RENAME COLUMN apellido TO apellidos;

-- 2. Agregar la columna 'nombres'
-- NOTA: Si la tabla ya tiene datos, este comando fallará porque la columna es NOT NULL.
-- Si ese es el caso, considera agregar la columna permitiendo nulos, actualizar los datos y luego hacerla NOT NULL.
ALTER TABLE clientes.cliente ADD COLUMN nombres character varying(100) NOT NULL;
