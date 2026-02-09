-- Borra los datos existentes para evitar duplicados y conflictos.
-- El orden es importante debido a las foreign keys.
DELETE FROM clientes.canton;
DELETE FROM clientes.ciudad;
DELETE FROM clientes.pais;

-- Inserta los países de Latinoamérica
INSERT INTO clientes.pais (nombre) VALUES
('Argentina'), ('Bolivia'), ('Brasil'), ('Chile'), ('Colombia'), ('Costa Rica'),
('Cuba'), ('Ecuador'), ('El Salvador'), ('Guatemala'), ('Haití'), ('Honduras'),
('México'), ('Nicaragua'), ('Panamá'), ('Paraguay'), ('Perú'), ('República Dominicana'),
('Uruguay'), ('Venezuela');

-- Script para poblar datos de Ecuador, México, Colombia y Argentina
DO $$
DECLARE
    -- IDs para Ecuador
    ecuador_id INT;
    guayaquil_id INT;
    quito_id INT;
    quevedo_id INT;
    ambato_id INT;
    loja_id INT;
    cuenca_id INT;
    manta_id INT;
    ibarra_id INT;
    banos_id INT;
    tena_id INT;

    -- IDs para Argentina
    argentina_id INT;
    bsas_id INT;
    cordoba_ar_id INT;
    rosario_id INT;

    -- IDs para Colombia
    colombia_id INT;
    bogota_id INT;
    medellin_id INT;
    cali_id INT;

    -- IDs para México
    mexico_id INT;
    cdmx_id INT;
    guadalajara_id INT;
    monterrey_id INT;

BEGIN
    -- =================================================================
    -- ECUADOR
    -- =================================================================
    SELECT id_pais INTO ecuador_id FROM clientes.pais WHERE nombre = 'Ecuador';

    -- Ciudades de Ecuador y sus cantones
    INSERT INTO clientes.ciudad (nombre, id_pais) VALUES ('Guayaquil', ecuador_id) RETURNING id_ciudad INTO guayaquil_id;
    INSERT INTO clientes.canton (nombre, id_ciudad) VALUES ('Guayaquil', guayaquil_id), ('Daule', guayaquil_id), ('Durán', guayaquil_id), ('Samborondón', guayaquil_id), ('Milagro', guayaquil_id);

    INSERT INTO clientes.ciudad (nombre, id_pais) VALUES ('Quito', ecuador_id) RETURNING id_ciudad INTO quito_id;
    INSERT INTO clientes.canton (nombre, id_ciudad) VALUES ('Quito', quito_id), ('Mejía', quito_id), ('Cayambe', quito_id), ('Rumiñahui', quito_id), ('Pedro Moncayo', quito_id);
    
    INSERT INTO clientes.ciudad (nombre, id_pais) VALUES ('Los Ríos', ecuador_id) RETURNING id_ciudad INTO quevedo_id;
    INSERT INTO clientes.canton (nombre, id_ciudad) VALUES ('Quevedo', quevedo_id), ('Buena Fe', quevedo_id), ('Mocache', quevedo_id), ('Valencia', quevedo_id), ('Ventanas', quevedo_id);

    INSERT INTO clientes.ciudad (nombre, id_pais) VALUES ('Ambato', ecuador_id) RETURNING id_ciudad INTO ambato_id;
    INSERT INTO clientes.canton (nombre, id_ciudad) VALUES ('Ambato', ambato_id), ('Pelileo', ambato_id), ('Píllaro', ambato_id), ('Cevallos', ambato_id), ('Mocha', ambato_id);

    INSERT INTO clientes.ciudad (nombre, id_pais) VALUES ('Loja', ecuador_id) RETURNING id_ciudad INTO loja_id;
    INSERT INTO clientes.canton (nombre, id_ciudad) VALUES ('Loja', loja_id), ('Calvas', loja_id), ('Catamayo', loja_id), ('Celica', loja_id), ('Macará', loja_id);

    INSERT INTO clientes.ciudad (nombre, id_pais) VALUES ('Cuenca', ecuador_id) RETURNING id_ciudad INTO cuenca_id;
    INSERT INTO clientes.canton (nombre, id_ciudad) VALUES ('Cuenca', cuenca_id), ('Gualaceo', cuenca_id), ('Paute', cuenca_id), ('Santa Isabel', cuenca_id), ('Girón', cuenca_id);

    INSERT INTO clientes.ciudad (nombre, id_pais) VALUES ('Manta', ecuador_id) RETURNING id_ciudad INTO manta_id;
    INSERT INTO clientes.canton (nombre, id_ciudad) VALUES ('Manta', manta_id), ('Montecristi', manta_id), ('Jaramijó', manta_id), ('Portoviejo', manta_id), ('Jipijapa', manta_id);

    INSERT INTO clientes.ciudad (nombre, id_pais) VALUES ('Ibarra', ecuador_id) RETURNING id_ciudad INTO ibarra_id;
    INSERT INTO clientes.canton (nombre, id_ciudad) VALUES ('Ibarra', ibarra_id), ('Otavalo', ibarra_id), ('Cotacachi', ibarra_id), ('Antonio Ante', ibarra_id), ('Pimampiro', ibarra_id);

    INSERT INTO clientes.ciudad (nombre, id_pais) VALUES ('Baños de Agua Santa', ecuador_id) RETURNING id_ciudad INTO banos_id;
    INSERT INTO clientes.canton (nombre, id_ciudad) VALUES ('Baños de Agua Santa', banos_id), ('Santa Clara', banos_id), ('Mera', banos_id), ('Palora', banos_id), ('Arajuno', banos_id);

    INSERT INTO clientes.ciudad (nombre, id_pais) VALUES ('Tena', ecuador_id) RETURNING id_ciudad INTO tena_id;
    INSERT INTO clientes.canton (nombre, id_ciudad) VALUES ('Tena', tena_id), ('Archidona', tena_id), ('Carlos Julio Arosemena Tola', tena_id), ('El Chaco', tena_id), ('Quijos', tena_id);

    -- =================================================================
    -- ARGENTINA
    -- =================================================================
    SELECT id_pais INTO argentina_id FROM clientes.pais WHERE nombre = 'Argentina';

    INSERT INTO clientes.ciudad (nombre, id_pais) VALUES ('Buenos Aires', argentina_id) RETURNING id_ciudad INTO bsas_id;
    INSERT INTO clientes.canton (nombre, id_ciudad) VALUES ('La Boca', bsas_id), ('Palermo', bsas_id), ('Recoleta', bsas_id), ('San Telmo', bsas_id), ('Belgrano', bsas_id);

    INSERT INTO clientes.ciudad (nombre, id_pais) VALUES ('Córdoba', argentina_id) RETURNING id_ciudad INTO cordoba_ar_id;
    INSERT INTO clientes.canton (nombre, id_ciudad) VALUES ('Centro', cordoba_ar_id), ('Nueva Córdoba', cordoba_ar_id), ('General Paz', cordoba_ar_id), ('Cerro de las Rosas', cordoba_ar_id), ('Alta Córdoba', cordoba_ar_id);

    INSERT INTO clientes.ciudad (nombre, id_pais) VALUES ('Rosario', argentina_id) RETURNING id_ciudad INTO rosario_id;
    INSERT INTO clientes.canton (nombre, id_ciudad) VALUES ('Centro', rosario_id), ('Pichincha', rosario_id), ('Norte', rosario_id), ('Sur', rosario_id), ('Oeste', rosario_id);

    -- =================================================================
    -- COLOMBIA
    -- =================================================================
    SELECT id_pais INTO colombia_id FROM clientes.pais WHERE nombre = 'Colombia';
    
    INSERT INTO clientes.ciudad (nombre, id_pais) VALUES ('Bogotá', colombia_id) RETURNING id_ciudad INTO bogota_id;
    INSERT INTO clientes.canton (nombre, id_ciudad) VALUES ('Usaquén', bogota_id), ('Chapinero', bogota_id), ('La Candelaria', bogota_id), ('Teusaquillo', bogota_id), ('Suba', bogota_id);

    INSERT INTO clientes.ciudad (nombre, id_pais) VALUES ('Medellín', colombia_id) RETURNING id_ciudad INTO medellin_id;
    INSERT INTO clientes.canton (nombre, id_ciudad) VALUES ('El Poblado', medellin_id), ('Laureles-Estadio', medellin_id), ('Belén', medellin_id), ('La Candelaria (Centro)', medellin_id), ('Guayabal', medellin_id);

    INSERT INTO clientes.ciudad (nombre, id_pais) VALUES ('Cali', colombia_id) RETURNING id_ciudad INTO cali_id;
    INSERT INTO clientes.canton (nombre, id_ciudad) VALUES ('El Peñón', cali_id), ('Granada', cali_id), ('San Antonio', cali_id), ('Ciudad Jardín', cali_id), ('Pance', cali_id);

    -- =================================================================
    -- MÉXICO
    -- =================================================================
    SELECT id_pais INTO mexico_id FROM clientes.pais WHERE nombre = 'México';
    
    INSERT INTO clientes.ciudad (nombre, id_pais) VALUES ('Ciudad de México', mexico_id) RETURNING id_ciudad INTO cdmx_id;
    INSERT INTO clientes.canton (nombre, id_ciudad) VALUES ('Coyoacán', cdmx_id), ('Cuauhtémoc', cdmx_id), ('Polanco', cdmx_id), ('Condesa', cdmx_id), ('Xochimilco', cdmx_id);
    
    INSERT INTO clientes.ciudad (nombre, id_pais) VALUES ('Guadalajara', mexico_id) RETURNING id_ciudad INTO guadalajara_id;
    INSERT INTO clientes.canton (nombre, id_ciudad) VALUES ('Centro', guadalajara_id), ('Zapopan', guadalajara_id), ('Tlaquepaque', guadalajara_id), ('Providencia', guadalajara_id), ('Chapalita', guadalajara_id);

    INSERT INTO clientes.ciudad (nombre, id_pais) VALUES ('Monterrey', mexico_id) RETURNING id_ciudad INTO monterrey_id;
    INSERT INTO clientes.canton (nombre, id_ciudad) VALUES ('San Pedro Garza García', monterrey_id), ('Centro', monterrey_id), ('Obispado', monterrey_id), ('Valle Oriente', monterrey_id), ('Cumbres', monterrey_id);

END $$;
