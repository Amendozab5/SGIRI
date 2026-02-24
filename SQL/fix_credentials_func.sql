-- 1. Eliminar la versión con error
DROP FUNCTION IF EXISTS usuarios.fn_generar_credenciales(character varying, integer);

-- 2. Crear la versión definitiva corregida con contraseña temporal aleatoria
CREATE OR REPLACE FUNCTION usuarios.fn_generar_credenciales(
    p_cedula CHARACTER VARYING, 
    p_anio_nacimiento INTEGER
) 
RETURNS TABLE(
    r_username CHARACTER VARYING, 
    r_password_plano CHARACTER VARYING, 
    r_password_hash TEXT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_nombres TEXT;
    v_apellidos TEXT;
    v_primer_nombre_ini TEXT;
    v_primer_apellido TEXT;
    v_segundo_apellido_ini TEXT;
    v_base_username TEXT;
    v_final_username TEXT;
    v_contador INTEGER := 0;
    v_random_pass TEXT;
BEGIN
    -- Obtener nombres y apellidos
    SELECT trim(nombre), trim(apellido) INTO v_nombres, v_apellidos 
    FROM usuarios.persona 
    WHERE cedula = p_cedula;

    -- Construir base (ej: amendozab)
    v_primer_nombre_ini := lower(left(split_part(v_nombres, ' ', 1), 1));
    v_primer_apellido := lower(split_part(v_apellidos, ' ', 1));
    v_segundo_apellido_ini := lower(left(split_part(v_apellidos, ' ', 2), 1));

    v_base_username := v_primer_nombre_ini || v_primer_apellido || v_segundo_apellido_ini;

    -- Asegurar unicidad del username
    v_final_username := v_base_username;
    WHILE EXISTS (SELECT 1 FROM usuarios.usuario u WHERE u.username = v_final_username) LOOP
        v_contador := v_contador + 1;
        v_final_username := v_base_username || v_contador;
    END LOOP;

    -- Generar contraseña temporal: cedula* + 5 dígitos aleatorios (ej: 1207445154*54876)
    v_random_pass := p_cedula || '*' || (floor(random() * 90000 + 10000))::text;

    -- Asignar resultados
    r_username := v_final_username;
    r_password_plano := v_random_pass;
    r_password_hash := crypt(r_password_plano, gen_salt('bf'));

    RETURN NEXT;
END;
$$;
