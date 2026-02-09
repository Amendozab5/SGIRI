CREATE OR REPLACE FUNCTION usuarios.generar_username_unico(
    p_nombres TEXT,
    p_apellidos TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_base_username TEXT;
    v_final_username TEXT;
    v_counter INT := 1;
BEGIN
    -- Generar username base con tu lógica:
    -- 1ra letra del 1er nombre + 1er apellido + 1ra letra del 2do apellido
    v_base_username := LOWER(
        SUBSTRING(TRIM(SPLIT_PART(p_nombres, ' ', 1)), 1, 1) || 
        TRIM(SPLIT_PART(p_apellidos, ' ', 1)) || 
        COALESCE(SUBSTRING(TRIM(SPLIT_PART(p_apellidos, ' ', 2)), 1, 1), '') -- Se usa COALESCE por si no hay segundo apellido
    );
    
    v_final_username := v_base_username;

    -- Bucle para asegurar que el username sea único
    WHILE EXISTS (SELECT 1 FROM usuarios.usuario WHERE username = v_final_username) LOOP
        v_final_username := v_base_username || v_counter;
        v_counter := v_counter + 1;
    END LOOP;

    RETURN v_final_username;
END;
$$;

ALTER FUNCTION usuarios.generar_username_unico(TEXT, TEXT)
    OWNER TO postgres; -- O el owner que corresponda
