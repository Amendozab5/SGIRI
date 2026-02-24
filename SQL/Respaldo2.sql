--
-- PostgreSQL database dump
--

\restrict 2uHxLY53jzXP67RBPFz6Sse6AcgfX8imeZO84aqyoxMgVkQjcVStTpZFrnXhZcT

-- Dumped from database version 18.2
-- Dumped by pg_dump version 18.2

-- Started on 2026-02-22 19:32:17

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 7 (class 2615 OID 22297)
-- Name: auditoria; Type: SCHEMA; Schema: -; Owner: empresa_owner
--

CREATE SCHEMA auditoria;


ALTER SCHEMA auditoria OWNER TO empresa_owner;

--
-- TOC entry 8 (class 2615 OID 22298)
-- Name: catalogos; Type: SCHEMA; Schema: -; Owner: empresa_owner
--

CREATE SCHEMA catalogos;


ALTER SCHEMA catalogos OWNER TO empresa_owner;

--
-- TOC entry 12 (class 2615 OID 22299)
-- Name: clientes; Type: SCHEMA; Schema: -; Owner: empresa_owner
--

CREATE SCHEMA clientes;


ALTER SCHEMA clientes OWNER TO empresa_owner;

--
-- TOC entry 13 (class 2615 OID 22300)
-- Name: empleados; Type: SCHEMA; Schema: -; Owner: empresa_owner
--

CREATE SCHEMA empleados;


ALTER SCHEMA empleados OWNER TO empresa_owner;

--
-- TOC entry 9 (class 2615 OID 22301)
-- Name: empresa; Type: SCHEMA; Schema: -; Owner: empresa_owner
--

CREATE SCHEMA empresa;


ALTER SCHEMA empresa OWNER TO empresa_owner;

--
-- TOC entry 10 (class 2615 OID 22302)
-- Name: notificaciones; Type: SCHEMA; Schema: -; Owner: empresa_owner
--

CREATE SCHEMA notificaciones;


ALTER SCHEMA notificaciones OWNER TO empresa_owner;

--
-- TOC entry 11 (class 2615 OID 22303)
-- Name: soporte; Type: SCHEMA; Schema: -; Owner: empresa_owner
--

CREATE SCHEMA soporte;


ALTER SCHEMA soporte OWNER TO empresa_owner;

--
-- TOC entry 14 (class 2615 OID 22304)
-- Name: usuarios; Type: SCHEMA; Schema: -; Owner: empresa_owner
--

CREATE SCHEMA usuarios;


ALTER SCHEMA usuarios OWNER TO empresa_owner;

--
-- TOC entry 2 (class 3079 OID 22305)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 5609 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 351 (class 1255 OID 22343)
-- Name: fn_upsert_catalogo_item(character varying, text, character varying, character varying, integer); Type: FUNCTION; Schema: catalogos; Owner: postgres
--

CREATE FUNCTION catalogos.fn_upsert_catalogo_item(p_nombre_catalogo character varying, p_descripcion_catalogo text, p_codigo_item character varying, p_nombre_item character varying, p_orden integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_catalogo INTEGER;
    v_id_item INTEGER;
BEGIN

    -- 1️ Buscar catálogo
    SELECT id_catalogo
    INTO v_id_catalogo
    FROM catalogos.catalogo
    WHERE nombre = p_nombre_catalogo;

    -- 2️ Si no existe, crearlo
    IF v_id_catalogo IS NULL THEN
        INSERT INTO catalogos.catalogo (nombre, descripcion)
        VALUES (p_nombre_catalogo, p_descripcion_catalogo)
        RETURNING id_catalogo INTO v_id_catalogo;
    END IF;

    -- 3️ Verificar si el item ya existe
    SELECT id_item
    INTO v_id_item
    FROM catalogos.catalogo_item
    WHERE id_catalogo = v_id_catalogo
    AND codigo = p_codigo_item;

    -- 4️ Si no existe, insertarlo
    IF v_id_item IS NULL THEN
        INSERT INTO catalogos.catalogo_item (
            id_catalogo,
            codigo,
            nombre,
            orden
        )
        VALUES (
            v_id_catalogo,
            p_codigo_item,
            p_nombre_item,
            p_orden
        )
        RETURNING id_item INTO v_id_item;
    END IF;

    -- 5️ Retornar id_item
    RETURN v_id_item;

END;
$$;


ALTER FUNCTION catalogos.fn_upsert_catalogo_item(p_nombre_catalogo character varying, p_descripcion_catalogo text, p_codigo_item character varying, p_nombre_item character varying, p_orden integer) OWNER TO postgres;

--
-- TOC entry 352 (class 1255 OID 22344)
-- Name: fn_crear_empleado(character varying, character varying, character varying, character varying, character varying, date, date, integer, integer, integer); Type: FUNCTION; Schema: empleados; Owner: postgres
--

CREATE FUNCTION empleados.fn_crear_empleado(p_cedula character varying, p_nombre character varying, p_apellido character varying, p_celular character varying, p_correo_personal character varying, p_fecha_nacimiento date, p_fecha_ingreso date, p_id_cargo integer, p_id_area integer, p_id_tipo_contrato integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_empleado INTEGER;
BEGIN

    -------------------------------------------------------
    -- Validar cédula única
    -------------------------------------------------------
    IF EXISTS (
        SELECT 1
        FROM empleados.empleado
        WHERE cedula = p_cedula
    ) THEN
        RAISE EXCEPTION 'La cédula ya está registrada';
    END IF;

    -------------------------------------------------------
    -- Validar FK
    -------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM empleados.cargo WHERE id_cargo = p_id_cargo) THEN
        RAISE EXCEPTION 'El cargo no existe';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM empleados.area WHERE id_area = p_id_area) THEN
        RAISE EXCEPTION 'El área no existe';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM empleados.tipo_contrato WHERE id_tipo_contrato = p_id_tipo_contrato) THEN
        RAISE EXCEPTION 'El tipo de contrato no existe';
    END IF;

    -------------------------------------------------------
    -- Insertar empleado
    -------------------------------------------------------
    INSERT INTO empleados.empleado (
        cedula,
        nombre,
        apellido,
        celular,
        correo_personal,
        fecha_nacimiento,
        fecha_ingreso,
        id_cargo,
        id_area,
        id_tipo_contrato,
        fecha_creacion
    )
    VALUES (
        p_cedula,
        p_nombre,
        p_apellido,
        p_celular,
        p_correo_personal,
        p_fecha_nacimiento,
        p_fecha_ingreso,
        p_id_cargo,
        p_id_area,
        p_id_tipo_contrato,
        now()
    )
    RETURNING id_empleado INTO v_id_empleado;

    RETURN v_id_empleado;

END;
$$;


ALTER FUNCTION empleados.fn_crear_empleado(p_cedula character varying, p_nombre character varying, p_apellido character varying, p_celular character varying, p_correo_personal character varying, p_fecha_nacimiento date, p_fecha_ingreso date, p_id_cargo integer, p_id_area integer, p_id_tipo_contrato integer) OWNER TO postgres;

--
-- TOC entry 353 (class 1255 OID 22345)
-- Name: fn_subir_documento(character varying, character varying, text, text); Type: FUNCTION; Schema: empleados; Owner: postgres
--

CREATE FUNCTION empleados.fn_subir_documento(p_cedula character varying, p_tipo_documento character varying, p_ruta_archivo text, p_descripcion text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_documento INTEGER;
BEGIN

    -- Validar que empleado exista
    IF NOT EXISTS (
        SELECT 1 
        FROM empleados.empleado
        WHERE cedula = p_cedula
    ) THEN
        RAISE EXCEPTION 'Empleado no existe';
    END IF;

    -- Insertar documento
    INSERT INTO empleados.documento_empleado(
        cedula_empleado,
        tipo_documento,
        ruta_archivo,
        descripcion,
        estado
    )
    VALUES (
        p_cedula,
        p_tipo_documento,
        p_ruta_archivo,
        p_descripcion,
        'ACTIVO'
    )
    RETURNING id_documento INTO v_id_documento;

    RETURN v_id_documento;

END;
$$;


ALTER FUNCTION empleados.fn_subir_documento(p_cedula character varying, p_tipo_documento character varying, p_ruta_archivo text, p_descripcion text) OWNER TO postgres;

--
-- TOC entry 354 (class 1255 OID 22346)
-- Name: fn_cambiar_credenciales(integer, character varying, text); Type: FUNCTION; Schema: usuarios; Owner: postgres
--

CREATE FUNCTION usuarios.fn_cambiar_credenciales(p_id_usuario integer, p_nuevo_username character varying, p_nueva_password text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN

    -- Validar que el usuario exista
    IF NOT EXISTS (
        SELECT 1
        FROM usuarios.usuario
        WHERE id_usuario = p_id_usuario
    ) THEN
        RAISE EXCEPTION 'El usuario no existe';
    END IF;

    -- Validar longitud mínima 8
    IF length(p_nuevo_username) < 8 THEN
        RAISE EXCEPTION 'El username debe tener mínimo 8 caracteres';
    END IF;

    -- Validar al menos una mayúscula
    IF p_nuevo_username !~ '[A-Z]' THEN
        RAISE EXCEPTION 'El username debe contener al menos una letra mayúscula';
    END IF;

    -- Validar al menos un número
    IF p_nuevo_username !~ '[0-9]' THEN
        RAISE EXCEPTION 'El username debe contener al menos un número';
    END IF;

    -- Validar que no esté en uso
    IF EXISTS (
        SELECT 1
        FROM usuarios.usuario
        WHERE username = p_nuevo_username
          AND id_usuario <> p_id_usuario
    ) THEN
        RAISE EXCEPTION 'El username ya está en uso';
    END IF;

    -- Actualizar credenciales
    UPDATE usuarios.usuario
    SET username = p_nuevo_username,
        password_hash = crypt(p_nueva_password, gen_salt('bf')),
        primer_login = FALSE,
        fecha_actualizacion = now()
    WHERE id_usuario = p_id_usuario;

END;
$$;


ALTER FUNCTION usuarios.fn_cambiar_credenciales(p_id_usuario integer, p_nuevo_username character varying, p_nueva_password text) OWNER TO postgres;

--
-- TOC entry 355 (class 1255 OID 22347)
-- Name: fn_crear_usuario_cliente(character varying, integer, integer, integer, integer); Type: FUNCTION; Schema: usuarios; Owner: postgres
--

CREATE FUNCTION usuarios.fn_crear_usuario_cliente(p_cedula character varying, p_anio_nacimiento integer, p_id_rol integer, p_id_empresa integer, p_id_estado_item integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_username VARCHAR;
    v_password_hash TEXT;
    v_password_plano TEXT;
    v_id_usuario INTEGER;
BEGIN

    -- Validar que cliente exista
    IF NOT EXISTS (
        SELECT 1 FROM clientes.cliente WHERE cedula = p_cedula
    ) THEN
        RAISE EXCEPTION 'El cliente no existe';
    END IF;

    -- Validar que usuario no exista
    IF EXISTS (
        SELECT 1 FROM usuarios.usuario WHERE username = p_cedula
    ) THEN
        RAISE EXCEPTION 'El usuario ya existe';
    END IF;

    -- Generar credenciales
    SELECT username, password_plano, password_hash
    INTO v_username, v_password_plano, v_password_hash
    FROM usuarios.fn_generar_credenciales(p_cedula, p_anio_nacimiento);

    -- Crear usuario aplicativo
    INSERT INTO usuarios.usuario (
        username,
        password_hash,
        id_rol,
        id_empresa,
        id_catalogo_item_estado,
        primer_login
    )
    VALUES (
        v_username,
        v_password_hash,
        p_id_rol,
        p_id_empresa,
        p_id_estado_item,
        TRUE
    )
    RETURNING id_usuario INTO v_id_usuario;

    -- Relacionar con cliente
    INSERT INTO usuarios.usuario_cliente (
        id_usuario,
        cedula_cliente,
        id_cliente
    )
    SELECT v_id_usuario, cedula, id_cliente
    FROM clientes.cliente
    WHERE cedula = p_cedula;

    RETURN v_id_usuario;
END;
$$;


ALTER FUNCTION usuarios.fn_crear_usuario_cliente(p_cedula character varying, p_anio_nacimiento integer, p_id_rol integer, p_id_empresa integer, p_id_estado_item integer) OWNER TO postgres;

--
-- TOC entry 356 (class 1255 OID 22348)
-- Name: fn_crear_usuario_empleado(character varying, integer, integer, integer); Type: FUNCTION; Schema: usuarios; Owner: postgres
--

CREATE FUNCTION usuarios.fn_crear_usuario_empleado(p_cedula character varying, p_anio_nacimiento integer, p_id_rol integer, p_id_estado_item integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_username VARCHAR;
    v_password_hash TEXT;
    v_password_plano TEXT;
    v_id_usuario INTEGER;
    v_nombre_bd TEXT;
    v_codigo_rol VARCHAR;
    v_nombre_rol_bd TEXT;
BEGIN

    -----------------------------------------------------
    -- 1️⃣ Validar que empleado exista
    -----------------------------------------------------
    IF NOT EXISTS (
        SELECT 1
        FROM empleados.empleado e
        WHERE e.cedula = p_cedula
    ) THEN
        RAISE EXCEPTION 'El empleado no existe';
    END IF;

    -----------------------------------------------------
    -- 2️⃣ Generar credenciales
    -----------------------------------------------------
    SELECT
        f.username,
        f.password_plano,
        f.password_hash
    INTO
        v_username,
        v_password_plano,
        v_password_hash
    FROM usuarios.fn_generar_credenciales(p_cedula, p_anio_nacimiento) f;

    -----------------------------------------------------
    -- 3️⃣ Obtener código del rol aplicativo
    -----------------------------------------------------
    SELECT r.codigo
    INTO v_codigo_rol
    FROM usuarios.rol r
    WHERE r.id_rol = p_id_rol;

    IF v_codigo_rol IS NULL THEN
        RAISE EXCEPTION 'El rol aplicativo no existe';
    END IF;

    -----------------------------------------------------
    -- 4️⃣ Construir nombre del rol físico BD
    -----------------------------------------------------
    v_nombre_rol_bd := 'rol_' || LOWER(v_codigo_rol);

    IF NOT EXISTS (
        SELECT 1
        FROM usuarios.rol_bd rb
        WHERE rb.nombre = v_nombre_rol_bd
    ) THEN
        RAISE EXCEPTION 'El rol BD asociado no existe';
    END IF;

    -----------------------------------------------------
    -- 5️⃣ Insertar usuario aplicativo
    -----------------------------------------------------
    INSERT INTO usuarios.usuario AS u (
        username,
        password_hash,
        id_rol,
        id_catalogo_item_estado,
        primer_login,
        fecha_creacion
    )
    VALUES (
        v_username,
        v_password_hash,
        p_id_rol,
        p_id_estado_item,
        TRUE,
        NOW()
    )
    RETURNING u.id_usuario INTO v_id_usuario;

    -----------------------------------------------------
    -- 6️⃣ Relacionar empleado
    -----------------------------------------------------
    INSERT INTO usuarios.usuario_empleado (
        id_usuario,
        cedula_empleado,
        id_empleado
    )
    SELECT
        v_id_usuario,
        e.cedula,
        e.id_empleado
    FROM empleados.empleado e
    WHERE e.cedula = p_cedula;

    -----------------------------------------------------
    -- 7️⃣ Crear usuario físico PostgreSQL
    -----------------------------------------------------
    v_nombre_bd := 'emp_' || p_cedula || '_' || v_id_usuario;

    EXECUTE format(
        'CREATE ROLE %I LOGIN PASSWORD %L',
        v_nombre_bd,
        v_password_plano
    );

    -----------------------------------------------------
    -- 8️⃣ Asignar rol físico
    -----------------------------------------------------
    EXECUTE format(
        'GRANT %I TO %I',
        v_nombre_rol_bd,
        v_nombre_bd
    );

    -----------------------------------------------------
    -- 9️⃣ Registrar usuario BD lógico
    -----------------------------------------------------
    INSERT INTO usuarios.usuario_bd (
        nombre,
        id_rol_bd,
        id_usuario,
        fecha_creacion
    )
    SELECT
        v_nombre_bd,
        rb.id_rol_bd,
        v_id_usuario,
        NOW()
    FROM usuarios.rol_bd rb
    WHERE rb.nombre = v_nombre_rol_bd;

    -----------------------------------------------------
    -- 🔟 Retornar solo el ID creado
    -----------------------------------------------------
    RETURN v_id_usuario;

END;
$$;


ALTER FUNCTION usuarios.fn_crear_usuario_empleado(p_cedula character varying, p_anio_nacimiento integer, p_id_rol integer, p_id_estado_item integer) OWNER TO postgres;

--
-- TOC entry 357 (class 1255 OID 22349)
-- Name: fn_crear_usuario_empleado(character varying, integer, integer, integer, integer); Type: FUNCTION; Schema: usuarios; Owner: postgres
--

CREATE FUNCTION usuarios.fn_crear_usuario_empleado(p_cedula character varying, p_anio_nacimiento integer, p_id_rol integer, p_id_empresa integer, p_id_estado_item integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_username VARCHAR;
    v_password_hash TEXT;
    v_password_plano TEXT;
    v_id_usuario INTEGER;
    v_nombre_bd TEXT;
    v_codigo_rol VARCHAR;
    v_nombre_rol_bd TEXT;
BEGIN

    -----------------------------------------------------
    -- 1️⃣ Validar que empleado exista
    -----------------------------------------------------
    IF NOT EXISTS (
        SELECT 1 FROM empleados.empleado WHERE cedula = p_cedula
    ) THEN
        RAISE EXCEPTION 'El empleado no existe';
    END IF;
	
-- Validar que tenga documento activo
IF NOT EXISTS (
    SELECT 1
    FROM empleados.documento_empleado d
    WHERE d.cedula_empleado = p_cedula
      AND d.estado = 'ACTIVO'
) THEN
    RAISE EXCEPTION 'El empleado no tiene documento validado';
END IF;

    -----------------------------------------------------
    -- 2️⃣ Generar credenciales
    -----------------------------------------------------
    SELECT username, password_plano, password_hash
    INTO v_username, v_password_plano, v_password_hash
    FROM usuarios.fn_generar_credenciales(p_cedula, p_anio_nacimiento);

    -----------------------------------------------------
    -- 3️⃣ Obtener código del rol aplicativo
    -----------------------------------------------------
    SELECT codigo
    INTO v_codigo_rol
    FROM usuarios.rol
    WHERE id_rol = p_id_rol;

    IF v_codigo_rol IS NULL THEN
        RAISE EXCEPTION 'El rol aplicativo no existe';
    END IF;

    -----------------------------------------------------
    -- 4️⃣ Construir nombre rol BD automáticamente
    -----------------------------------------------------
    v_nombre_rol_bd := 'rol_' || LOWER(v_codigo_rol);

    -----------------------------------------------------
    -- 5️⃣ Validar que rol BD exista en tabla lógica
    -----------------------------------------------------
    IF NOT EXISTS (
        SELECT 1 FROM usuarios.rol_bd
        WHERE nombre = v_nombre_rol_bd
    ) THEN
        RAISE EXCEPTION 'El rol BD asociado no existe';
    END IF;

    -----------------------------------------------------
    -- 6️⃣ Crear usuario aplicativo
    -----------------------------------------------------
    INSERT INTO usuarios.usuario (
        username,
        password_hash,
        id_rol,
        id_empresa,
        id_catalogo_item_estado,
        primer_login
    )
    VALUES (
        v_username,
        v_password_hash,
        p_id_rol,
        p_id_empresa,
        p_id_estado_item,
        TRUE
    )
    RETURNING id_usuario INTO v_id_usuario;

    -----------------------------------------------------
    -- 7️⃣ Relacionar con empleado
    -----------------------------------------------------
    INSERT INTO usuarios.usuario_empleado (
        id_usuario,
        cedula_empleado,
        id_empleado
    )
    SELECT v_id_usuario, cedula, id_empleado
    FROM empleados.empleado
    WHERE cedula = p_cedula;

    -----------------------------------------------------
    -- 8️⃣ Crear nombre usuario físico BD
    -- Permite múltiples usuarios por empleado
    -----------------------------------------------------
    v_nombre_bd := 'emp_' || p_cedula || '_' || v_id_usuario;

    -----------------------------------------------------
    -- 9️⃣ Crear usuario físico PostgreSQL
    -----------------------------------------------------
    EXECUTE format(
        'CREATE ROLE %I LOGIN PASSWORD %L',
        v_nombre_bd,
        v_password_plano
    );

    -----------------------------------------------------
    -- 🔟 Asignar rol BD automáticamente
    -----------------------------------------------------
    EXECUTE format(
        'GRANT %I TO %I',
        v_nombre_rol_bd,
        v_nombre_bd
    );

    -----------------------------------------------------
    -- 1️⃣1️⃣ Registrar usuario BD en tabla
    -----------------------------------------------------
    INSERT INTO usuarios.usuario_bd (
        nombre,
        id_rol_bd,
        id_usuario
    )
    SELECT
        v_nombre_bd,
        rb.id_rol_bd,
        v_id_usuario
    FROM usuarios.rol_bd rb
    WHERE rb.nombre = v_nombre_rol_bd;

    RETURN v_id_usuario;

END;
$$;


ALTER FUNCTION usuarios.fn_crear_usuario_empleado(p_cedula character varying, p_anio_nacimiento integer, p_id_rol integer, p_id_empresa integer, p_id_estado_item integer) OWNER TO postgres;

--
-- TOC entry 358 (class 1255 OID 23247)
-- Name: fn_generar_credenciales(character varying, integer); Type: FUNCTION; Schema: usuarios; Owner: postgres
--

CREATE FUNCTION usuarios.fn_generar_credenciales(p_cedula character varying, p_anio_nacimiento integer) RETURNS TABLE(r_username character varying, r_password_plano character varying, r_password_hash text)
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

    -- Construir username base: amendozab
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

    -- Generar contraseña temporal: cedula* + 5 dígitos aleatorios
    v_random_pass := p_cedula || '*' || (floor(random() * 90000 + 10000))::text;

    -- Asignar resultados
    r_username := v_final_username;
    r_password_plano := v_random_pass;
    r_password_hash := crypt(r_password_plano, gen_salt('bf'));

    RETURN NEXT;
END;
$$;


ALTER FUNCTION usuarios.fn_generar_credenciales(p_cedula character varying, p_anio_nacimiento integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 228 (class 1259 OID 22351)
-- Name: auditoria_estado_ticket; Type: TABLE; Schema: auditoria; Owner: empresa_owner
--

CREATE TABLE auditoria.auditoria_estado_ticket (
    id_auditoria integer NOT NULL,
    id_ticket integer NOT NULL,
    usuario_bd character varying(100) NOT NULL,
    fecha_cambio timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    id_estado_anterior integer,
    id_item_evento integer,
    id_usuario integer,
    id_estado_nuevo_item integer
);


ALTER TABLE auditoria.auditoria_estado_ticket OWNER TO empresa_owner;

--
-- TOC entry 229 (class 1259 OID 22359)
-- Name: auditoria_estado_ticket_id_auditoria_seq; Type: SEQUENCE; Schema: auditoria; Owner: empresa_owner
--

CREATE SEQUENCE auditoria.auditoria_estado_ticket_id_auditoria_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE auditoria.auditoria_estado_ticket_id_auditoria_seq OWNER TO empresa_owner;

--
-- TOC entry 5610 (class 0 OID 0)
-- Dependencies: 229
-- Name: auditoria_estado_ticket_id_auditoria_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: empresa_owner
--

ALTER SEQUENCE auditoria.auditoria_estado_ticket_id_auditoria_seq OWNED BY auditoria.auditoria_estado_ticket.id_auditoria;


--
-- TOC entry 230 (class 1259 OID 22360)
-- Name: auditoria_evento; Type: TABLE; Schema: auditoria; Owner: empresa_owner
--

CREATE TABLE auditoria.auditoria_evento (
    id_evento integer NOT NULL,
    esquema_afectado character varying(50) NOT NULL,
    tabla_afectada character varying(50) NOT NULL,
    id_registro integer NOT NULL,
    descripcion text,
    usuario_bd character varying(100) NOT NULL,
    rol_bd character varying(100) NOT NULL,
    fecha_evento timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    id_usuario integer,
    id_notificacion integer,
    id_accion_item integer NOT NULL
);


ALTER TABLE auditoria.auditoria_evento OWNER TO empresa_owner;

--
-- TOC entry 231 (class 1259 OID 22374)
-- Name: auditoria_evento_id_evento_seq; Type: SEQUENCE; Schema: auditoria; Owner: empresa_owner
--

CREATE SEQUENCE auditoria.auditoria_evento_id_evento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE auditoria.auditoria_evento_id_evento_seq OWNER TO empresa_owner;

--
-- TOC entry 5611 (class 0 OID 0)
-- Dependencies: 231
-- Name: auditoria_evento_id_evento_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: empresa_owner
--

ALTER SEQUENCE auditoria.auditoria_evento_id_evento_seq OWNED BY auditoria.auditoria_evento.id_evento;


--
-- TOC entry 232 (class 1259 OID 22375)
-- Name: auditoria_login; Type: TABLE; Schema: auditoria; Owner: empresa_owner
--

CREATE TABLE auditoria.auditoria_login (
    id_login integer NOT NULL,
    usuario_app character varying(100),
    usuario_bd character varying(100),
    exito boolean NOT NULL,
    ip_origen character varying(45),
    fecha_login timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    id_usuario integer,
    id_item_evento integer
);


ALTER TABLE auditoria.auditoria_login OWNER TO empresa_owner;

--
-- TOC entry 233 (class 1259 OID 22382)
-- Name: auditoria_login_bd; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.auditoria_login_bd (
    id_auditoria_login_bd integer NOT NULL,
    id_usuario_bd integer NOT NULL,
    id_item_evento integer NOT NULL,
    fecha_evento timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ip_origen character varying(45),
    observacion text
);


ALTER TABLE auditoria.auditoria_login_bd OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 22392)
-- Name: auditoria_login_bd_id_auditoria_login_bd_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

CREATE SEQUENCE auditoria.auditoria_login_bd_id_auditoria_login_bd_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE auditoria.auditoria_login_bd_id_auditoria_login_bd_seq OWNER TO postgres;

--
-- TOC entry 5612 (class 0 OID 0)
-- Dependencies: 234
-- Name: auditoria_login_bd_id_auditoria_login_bd_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: postgres
--

ALTER SEQUENCE auditoria.auditoria_login_bd_id_auditoria_login_bd_seq OWNED BY auditoria.auditoria_login_bd.id_auditoria_login_bd;


--
-- TOC entry 235 (class 1259 OID 22393)
-- Name: auditoria_login_id_login_seq; Type: SEQUENCE; Schema: auditoria; Owner: empresa_owner
--

CREATE SEQUENCE auditoria.auditoria_login_id_login_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE auditoria.auditoria_login_id_login_seq OWNER TO empresa_owner;

--
-- TOC entry 5613 (class 0 OID 0)
-- Dependencies: 235
-- Name: auditoria_login_id_login_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: empresa_owner
--

ALTER SEQUENCE auditoria.auditoria_login_id_login_seq OWNED BY auditoria.auditoria_login.id_login;


--
-- TOC entry 236 (class 1259 OID 22394)
-- Name: catalogo; Type: TABLE; Schema: catalogos; Owner: empresa_owner
--

CREATE TABLE catalogos.catalogo (
    id_catalogo integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    activo boolean DEFAULT true
);


ALTER TABLE catalogos.catalogo OWNER TO empresa_owner;

--
-- TOC entry 237 (class 1259 OID 22402)
-- Name: catalogo_id_catalogo_seq; Type: SEQUENCE; Schema: catalogos; Owner: empresa_owner
--

CREATE SEQUENCE catalogos.catalogo_id_catalogo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE catalogos.catalogo_id_catalogo_seq OWNER TO empresa_owner;

--
-- TOC entry 5614 (class 0 OID 0)
-- Dependencies: 237
-- Name: catalogo_id_catalogo_seq; Type: SEQUENCE OWNED BY; Schema: catalogos; Owner: empresa_owner
--

ALTER SEQUENCE catalogos.catalogo_id_catalogo_seq OWNED BY catalogos.catalogo.id_catalogo;


--
-- TOC entry 238 (class 1259 OID 22403)
-- Name: catalogo_item; Type: TABLE; Schema: catalogos; Owner: empresa_owner
--

CREATE TABLE catalogos.catalogo_item (
    id_item integer NOT NULL,
    id_catalogo integer NOT NULL,
    codigo character varying(50),
    nombre character varying(100) NOT NULL,
    orden integer,
    activo boolean DEFAULT true
);


ALTER TABLE catalogos.catalogo_item OWNER TO empresa_owner;

--
-- TOC entry 239 (class 1259 OID 22410)
-- Name: catalogo_item_id_item_seq; Type: SEQUENCE; Schema: catalogos; Owner: empresa_owner
--

CREATE SEQUENCE catalogos.catalogo_item_id_item_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE catalogos.catalogo_item_id_item_seq OWNER TO empresa_owner;

--
-- TOC entry 5615 (class 0 OID 0)
-- Dependencies: 239
-- Name: catalogo_item_id_item_seq; Type: SEQUENCE OWNED BY; Schema: catalogos; Owner: empresa_owner
--

ALTER SEQUENCE catalogos.catalogo_item_id_item_seq OWNED BY catalogos.catalogo_item.id_item;


--
-- TOC entry 240 (class 1259 OID 22411)
-- Name: canton; Type: TABLE; Schema: clientes; Owner: empresa_owner
--

CREATE TABLE clientes.canton (
    id_canton integer NOT NULL,
    nombre character varying(100) NOT NULL,
    id_ciudad integer NOT NULL
);


ALTER TABLE clientes.canton OWNER TO empresa_owner;

--
-- TOC entry 241 (class 1259 OID 22417)
-- Name: canton_id_canton_seq; Type: SEQUENCE; Schema: clientes; Owner: empresa_owner
--

CREATE SEQUENCE clientes.canton_id_canton_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE clientes.canton_id_canton_seq OWNER TO empresa_owner;

--
-- TOC entry 5617 (class 0 OID 0)
-- Dependencies: 241
-- Name: canton_id_canton_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: empresa_owner
--

ALTER SEQUENCE clientes.canton_id_canton_seq OWNED BY clientes.canton.id_canton;


--
-- TOC entry 242 (class 1259 OID 22418)
-- Name: ciudad; Type: TABLE; Schema: clientes; Owner: empresa_owner
--

CREATE TABLE clientes.ciudad (
    id_ciudad integer NOT NULL,
    nombre character varying(100) NOT NULL,
    id_pais integer NOT NULL
);


ALTER TABLE clientes.ciudad OWNER TO empresa_owner;

--
-- TOC entry 243 (class 1259 OID 22424)
-- Name: ciudad_id_ciudad_seq; Type: SEQUENCE; Schema: clientes; Owner: empresa_owner
--

CREATE SEQUENCE clientes.ciudad_id_ciudad_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE clientes.ciudad_id_ciudad_seq OWNER TO empresa_owner;

--
-- TOC entry 5619 (class 0 OID 0)
-- Dependencies: 243
-- Name: ciudad_id_ciudad_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: empresa_owner
--

ALTER SEQUENCE clientes.ciudad_id_ciudad_seq OWNED BY clientes.ciudad.id_ciudad;


--
-- TOC entry 244 (class 1259 OID 22425)
-- Name: cliente; Type: TABLE; Schema: clientes; Owner: empresa_owner
--

CREATE TABLE clientes.cliente (
    id_cliente integer NOT NULL,
    id_sucursal integer,
    id_persona integer,
    fecha_inicio_contrato date,
    fecha_fin_contrato date,
    acceso_remoto boolean DEFAULT true,
    aprobacion_de_cambios boolean DEFAULT false,
    actualizaciones_automaticas boolean DEFAULT true
);


ALTER TABLE clientes.cliente OWNER TO empresa_owner;

--
-- TOC entry 245 (class 1259 OID 22432)
-- Name: cliente_id_cliente_seq; Type: SEQUENCE; Schema: clientes; Owner: empresa_owner
--

CREATE SEQUENCE clientes.cliente_id_cliente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE clientes.cliente_id_cliente_seq OWNER TO empresa_owner;

--
-- TOC entry 5621 (class 0 OID 0)
-- Dependencies: 245
-- Name: cliente_id_cliente_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: empresa_owner
--

ALTER SEQUENCE clientes.cliente_id_cliente_seq OWNED BY clientes.cliente.id_cliente;


--
-- TOC entry 246 (class 1259 OID 22433)
-- Name: documento_cliente; Type: TABLE; Schema: clientes; Owner: empresa_owner
--

CREATE TABLE clientes.documento_cliente (
    id_documento integer NOT NULL,
    numero_documento character varying(10) CONSTRAINT documento_cliente_cedula_cliente_not_null NOT NULL,
    ruta_archivo text NOT NULL,
    descripcion text,
    fecha_subida timestamp without time zone DEFAULT now(),
    id_cliente integer NOT NULL,
    id_tipo_documento integer NOT NULL,
    id_catalogo_item_estado integer
);


ALTER TABLE clientes.documento_cliente OWNER TO empresa_owner;

--
-- TOC entry 247 (class 1259 OID 22444)
-- Name: documento_cliente_id_documento_seq; Type: SEQUENCE; Schema: clientes; Owner: empresa_owner
--

CREATE SEQUENCE clientes.documento_cliente_id_documento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE clientes.documento_cliente_id_documento_seq OWNER TO empresa_owner;

--
-- TOC entry 5623 (class 0 OID 0)
-- Dependencies: 247
-- Name: documento_cliente_id_documento_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: empresa_owner
--

ALTER SEQUENCE clientes.documento_cliente_id_documento_seq OWNED BY clientes.documento_cliente.id_documento;


--
-- TOC entry 248 (class 1259 OID 22445)
-- Name: pais; Type: TABLE; Schema: clientes; Owner: empresa_owner
--

CREATE TABLE clientes.pais (
    id_pais integer NOT NULL,
    nombre character varying(100) NOT NULL
);


ALTER TABLE clientes.pais OWNER TO empresa_owner;

--
-- TOC entry 249 (class 1259 OID 22450)
-- Name: pais_id_pais_seq; Type: SEQUENCE; Schema: clientes; Owner: empresa_owner
--

CREATE SEQUENCE clientes.pais_id_pais_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE clientes.pais_id_pais_seq OWNER TO empresa_owner;

--
-- TOC entry 5625 (class 0 OID 0)
-- Dependencies: 249
-- Name: pais_id_pais_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: empresa_owner
--

ALTER SEQUENCE clientes.pais_id_pais_seq OWNED BY clientes.pais.id_pais;


--
-- TOC entry 250 (class 1259 OID 22451)
-- Name: tipo_documento; Type: TABLE; Schema: clientes; Owner: postgres
--

CREATE TABLE clientes.tipo_documento (
    id_tipo_documento integer NOT NULL,
    codigo character varying(20) NOT NULL
);


ALTER TABLE clientes.tipo_documento OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 22456)
-- Name: tipo_documento_id_tipo_documento_seq; Type: SEQUENCE; Schema: clientes; Owner: postgres
--

CREATE SEQUENCE clientes.tipo_documento_id_tipo_documento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE clientes.tipo_documento_id_tipo_documento_seq OWNER TO postgres;

--
-- TOC entry 5627 (class 0 OID 0)
-- Dependencies: 251
-- Name: tipo_documento_id_tipo_documento_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: postgres
--

ALTER SEQUENCE clientes.tipo_documento_id_tipo_documento_seq OWNED BY clientes.tipo_documento.id_tipo_documento;


--
-- TOC entry 252 (class 1259 OID 22457)
-- Name: area; Type: TABLE; Schema: empleados; Owner: empresa_owner
--

CREATE TABLE empleados.area (
    id_area integer NOT NULL,
    nombre character varying(100) NOT NULL
);


ALTER TABLE empleados.area OWNER TO empresa_owner;

--
-- TOC entry 253 (class 1259 OID 22462)
-- Name: area_id_area_seq; Type: SEQUENCE; Schema: empleados; Owner: empresa_owner
--

CREATE SEQUENCE empleados.area_id_area_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE empleados.area_id_area_seq OWNER TO empresa_owner;

--
-- TOC entry 5629 (class 0 OID 0)
-- Dependencies: 253
-- Name: area_id_area_seq; Type: SEQUENCE OWNED BY; Schema: empleados; Owner: empresa_owner
--

ALTER SEQUENCE empleados.area_id_area_seq OWNED BY empleados.area.id_area;


--
-- TOC entry 254 (class 1259 OID 22463)
-- Name: cargo; Type: TABLE; Schema: empleados; Owner: empresa_owner
--

CREATE TABLE empleados.cargo (
    id_cargo integer NOT NULL,
    nombre character varying(100) NOT NULL
);


ALTER TABLE empleados.cargo OWNER TO empresa_owner;

--
-- TOC entry 255 (class 1259 OID 22468)
-- Name: cargo_id_cargo_seq; Type: SEQUENCE; Schema: empleados; Owner: empresa_owner
--

CREATE SEQUENCE empleados.cargo_id_cargo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE empleados.cargo_id_cargo_seq OWNER TO empresa_owner;

--
-- TOC entry 5631 (class 0 OID 0)
-- Dependencies: 255
-- Name: cargo_id_cargo_seq; Type: SEQUENCE OWNED BY; Schema: empleados; Owner: empresa_owner
--

ALTER SEQUENCE empleados.cargo_id_cargo_seq OWNED BY empleados.cargo.id_cargo;


--
-- TOC entry 256 (class 1259 OID 22469)
-- Name: documento_empleado; Type: TABLE; Schema: empleados; Owner: empresa_owner
--

CREATE TABLE empleados.documento_empleado (
    id_documento integer NOT NULL,
    numero_documento character varying(10) NOT NULL,
    ruta_archivo text NOT NULL,
    descripcion text,
    fecha_subida timestamp without time zone DEFAULT now(),
    id_empleado integer NOT NULL,
    id_tipo_documento integer,
    id_catalogo_item_estado integer,
    cedula_empleado character varying(10) NOT NULL
);


ALTER TABLE empleados.documento_empleado OWNER TO empresa_owner;

--
-- TOC entry 257 (class 1259 OID 22479)
-- Name: documento_empleado_id_documento_seq; Type: SEQUENCE; Schema: empleados; Owner: empresa_owner
--

CREATE SEQUENCE empleados.documento_empleado_id_documento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE empleados.documento_empleado_id_documento_seq OWNER TO empresa_owner;

--
-- TOC entry 5633 (class 0 OID 0)
-- Dependencies: 257
-- Name: documento_empleado_id_documento_seq; Type: SEQUENCE OWNED BY; Schema: empleados; Owner: empresa_owner
--

ALTER SEQUENCE empleados.documento_empleado_id_documento_seq OWNED BY empleados.documento_empleado.id_documento;


--
-- TOC entry 258 (class 1259 OID 22480)
-- Name: empleado_id_empleado_seq; Type: SEQUENCE; Schema: empleados; Owner: postgres
--

CREATE SEQUENCE empleados.empleado_id_empleado_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE empleados.empleado_id_empleado_seq OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 22481)
-- Name: empleado; Type: TABLE; Schema: empleados; Owner: empresa_owner
--

CREATE TABLE empleados.empleado (
    fecha_ingreso date NOT NULL,
    id_cargo integer NOT NULL,
    id_area integer NOT NULL,
    id_tipo_contrato integer NOT NULL,
    id_empleado integer DEFAULT nextval('empleados.empleado_id_empleado_seq'::regclass) NOT NULL,
    id_sucursal integer,
    id_persona integer
);


ALTER TABLE empleados.empleado OWNER TO empresa_owner;

--
-- TOC entry 260 (class 1259 OID 22490)
-- Name: tipo_contrato; Type: TABLE; Schema: empleados; Owner: empresa_owner
--

CREATE TABLE empleados.tipo_contrato (
    id_tipo_contrato integer NOT NULL,
    nombre character varying(100) NOT NULL
);


ALTER TABLE empleados.tipo_contrato OWNER TO empresa_owner;

--
-- TOC entry 261 (class 1259 OID 22495)
-- Name: tipo_contrato_id_tipo_contrato_seq; Type: SEQUENCE; Schema: empleados; Owner: empresa_owner
--

CREATE SEQUENCE empleados.tipo_contrato_id_tipo_contrato_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE empleados.tipo_contrato_id_tipo_contrato_seq OWNER TO empresa_owner;

--
-- TOC entry 5637 (class 0 OID 0)
-- Dependencies: 261
-- Name: tipo_contrato_id_tipo_contrato_seq; Type: SEQUENCE OWNED BY; Schema: empleados; Owner: empresa_owner
--

ALTER SEQUENCE empleados.tipo_contrato_id_tipo_contrato_seq OWNED BY empleados.tipo_contrato.id_tipo_contrato;


--
-- TOC entry 262 (class 1259 OID 22496)
-- Name: documento_empresa; Type: TABLE; Schema: empresa; Owner: empresa_owner
--

CREATE TABLE empresa.documento_empresa (
    id_documento integer NOT NULL,
    id_empresa integer NOT NULL,
    numero_documento character varying(50) CONSTRAINT documento_empresa_tipo_documento_not_null NOT NULL,
    ruta_archivo text NOT NULL,
    descripcion text,
    fecha_subida timestamp without time zone DEFAULT now(),
    id_tipo_documento integer NOT NULL,
    id_catalogo_item_estado integer
);


ALTER TABLE empresa.documento_empresa OWNER TO empresa_owner;

--
-- TOC entry 263 (class 1259 OID 22507)
-- Name: documento_empresa_id_documento_seq; Type: SEQUENCE; Schema: empresa; Owner: empresa_owner
--

CREATE SEQUENCE empresa.documento_empresa_id_documento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE empresa.documento_empresa_id_documento_seq OWNER TO empresa_owner;

--
-- TOC entry 5638 (class 0 OID 0)
-- Dependencies: 263
-- Name: documento_empresa_id_documento_seq; Type: SEQUENCE OWNED BY; Schema: empresa; Owner: empresa_owner
--

ALTER SEQUENCE empresa.documento_empresa_id_documento_seq OWNED BY empresa.documento_empresa.id_documento;


--
-- TOC entry 264 (class 1259 OID 22508)
-- Name: empresa; Type: TABLE; Schema: empresa; Owner: empresa_owner
--

CREATE TABLE empresa.empresa (
    id_empresa integer NOT NULL,
    nombre_comercial character varying(100) NOT NULL,
    razon_social character varying(150) NOT NULL,
    ruc character varying(13) NOT NULL,
    tipo_empresa character varying(30) NOT NULL,
    correo_contacto character varying(150),
    telefono_contacto character varying(20),
    direccion_principal text,
    fecha_creacion timestamp without time zone DEFAULT now(),
    id_catalogo_item_tipo_empresa integer,
    id_catalogo_item_estado integer
);


ALTER TABLE empresa.empresa OWNER TO empresa_owner;

--
-- TOC entry 265 (class 1259 OID 22519)
-- Name: empresa_id_empresa_seq; Type: SEQUENCE; Schema: empresa; Owner: empresa_owner
--

CREATE SEQUENCE empresa.empresa_id_empresa_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE empresa.empresa_id_empresa_seq OWNER TO empresa_owner;

--
-- TOC entry 5639 (class 0 OID 0)
-- Dependencies: 265
-- Name: empresa_id_empresa_seq; Type: SEQUENCE OWNED BY; Schema: empresa; Owner: empresa_owner
--

ALTER SEQUENCE empresa.empresa_id_empresa_seq OWNED BY empresa.empresa.id_empresa;


--
-- TOC entry 266 (class 1259 OID 22520)
-- Name: empresa_servicio; Type: TABLE; Schema: empresa; Owner: empresa_owner
--

CREATE TABLE empresa.empresa_servicio (
    id_empresa integer NOT NULL,
    id_servicio integer NOT NULL
);


ALTER TABLE empresa.empresa_servicio OWNER TO empresa_owner;

--
-- TOC entry 298 (class 1259 OID 23284)
-- Name: servicio; Type: TABLE; Schema: empresa; Owner: postgres
--

CREATE TABLE empresa.servicio (
    id_servicio integer NOT NULL,
    activo boolean,
    descripcion text,
    nombre character varying(100) NOT NULL
);


ALTER TABLE empresa.servicio OWNER TO postgres;

--
-- TOC entry 297 (class 1259 OID 23283)
-- Name: servicio_id_servicio_seq; Type: SEQUENCE; Schema: empresa; Owner: postgres
--

CREATE SEQUENCE empresa.servicio_id_servicio_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE empresa.servicio_id_servicio_seq OWNER TO postgres;

--
-- TOC entry 5640 (class 0 OID 0)
-- Dependencies: 297
-- Name: servicio_id_servicio_seq; Type: SEQUENCE OWNED BY; Schema: empresa; Owner: postgres
--

ALTER SEQUENCE empresa.servicio_id_servicio_seq OWNED BY empresa.servicio.id_servicio;


--
-- TOC entry 267 (class 1259 OID 22525)
-- Name: sucursal; Type: TABLE; Schema: empresa; Owner: empresa_owner
--

CREATE TABLE empresa.sucursal (
    id_sucursal integer NOT NULL,
    id_empresa integer NOT NULL,
    nombre character varying(100) NOT NULL,
    direccion text NOT NULL,
    telefono character varying(50),
    id_ciudad integer,
    id_canton integer,
    id_catalogo_item_estado integer
);


ALTER TABLE empresa.sucursal OWNER TO empresa_owner;

--
-- TOC entry 268 (class 1259 OID 22534)
-- Name: sucursal_id_sucursal_seq; Type: SEQUENCE; Schema: empresa; Owner: empresa_owner
--

CREATE SEQUENCE empresa.sucursal_id_sucursal_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE empresa.sucursal_id_sucursal_seq OWNER TO empresa_owner;

--
-- TOC entry 5641 (class 0 OID 0)
-- Dependencies: 268
-- Name: sucursal_id_sucursal_seq; Type: SEQUENCE OWNED BY; Schema: empresa; Owner: empresa_owner
--

ALTER SEQUENCE empresa.sucursal_id_sucursal_seq OWNED BY empresa.sucursal.id_sucursal;


--
-- TOC entry 269 (class 1259 OID 22535)
-- Name: canal_notificacion; Type: TABLE; Schema: notificaciones; Owner: empresa_owner
--

CREATE TABLE notificaciones.canal_notificacion (
    id_canal integer NOT NULL,
    nombre character varying(50) NOT NULL,
    activo boolean DEFAULT true
);


ALTER TABLE notificaciones.canal_notificacion OWNER TO empresa_owner;

--
-- TOC entry 270 (class 1259 OID 22541)
-- Name: canal_notificacion_id_canal_seq; Type: SEQUENCE; Schema: notificaciones; Owner: empresa_owner
--

CREATE SEQUENCE notificaciones.canal_notificacion_id_canal_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE notificaciones.canal_notificacion_id_canal_seq OWNER TO empresa_owner;

--
-- TOC entry 5642 (class 0 OID 0)
-- Dependencies: 270
-- Name: canal_notificacion_id_canal_seq; Type: SEQUENCE OWNED BY; Schema: notificaciones; Owner: empresa_owner
--

ALTER SEQUENCE notificaciones.canal_notificacion_id_canal_seq OWNED BY notificaciones.canal_notificacion.id_canal;


--
-- TOC entry 271 (class 1259 OID 22542)
-- Name: notificacion; Type: TABLE; Schema: notificaciones; Owner: empresa_owner
--

CREATE TABLE notificaciones.notificacion (
    id_notificacion integer NOT NULL,
    id_canal integer NOT NULL,
    destinatario character varying(150) NOT NULL,
    asunto character varying(150),
    mensaje text NOT NULL,
    enviado boolean DEFAULT false,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    id_ticket integer,
    id_usuario_destino integer,
    id_tipo_notificacion integer,
    id_usuario_origen integer,
    fecha_envio timestamp without time zone,
    error_envio text,
    id_empresa integer NOT NULL
);


ALTER TABLE notificaciones.notificacion OWNER TO empresa_owner;

--
-- TOC entry 272 (class 1259 OID 22554)
-- Name: notificacion_id_notificacion_seq; Type: SEQUENCE; Schema: notificaciones; Owner: empresa_owner
--

CREATE SEQUENCE notificaciones.notificacion_id_notificacion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE notificaciones.notificacion_id_notificacion_seq OWNER TO empresa_owner;

--
-- TOC entry 5643 (class 0 OID 0)
-- Dependencies: 272
-- Name: notificacion_id_notificacion_seq; Type: SEQUENCE OWNED BY; Schema: notificaciones; Owner: empresa_owner
--

ALTER SEQUENCE notificaciones.notificacion_id_notificacion_seq OWNED BY notificaciones.notificacion.id_notificacion;


--
-- TOC entry 273 (class 1259 OID 22555)
-- Name: asignacion; Type: TABLE; Schema: soporte; Owner: empresa_owner
--

CREATE TABLE soporte.asignacion (
    id_asignacion integer NOT NULL,
    id_ticket integer NOT NULL,
    fecha_asignacion timestamp without time zone DEFAULT now(),
    activo boolean DEFAULT true,
    id_usuario integer NOT NULL
);


ALTER TABLE soporte.asignacion OWNER TO empresa_owner;

--
-- TOC entry 274 (class 1259 OID 22563)
-- Name: asignacion_id_asignacion_seq; Type: SEQUENCE; Schema: soporte; Owner: empresa_owner
--

CREATE SEQUENCE soporte.asignacion_id_asignacion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE soporte.asignacion_id_asignacion_seq OWNER TO empresa_owner;

--
-- TOC entry 5644 (class 0 OID 0)
-- Dependencies: 274
-- Name: asignacion_id_asignacion_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: empresa_owner
--

ALTER SEQUENCE soporte.asignacion_id_asignacion_seq OWNED BY soporte.asignacion.id_asignacion;


--
-- TOC entry 300 (class 1259 OID 23297)
-- Name: categoria; Type: TABLE; Schema: soporte; Owner: postgres
--

CREATE TABLE soporte.categoria (
    id_categoria integer NOT NULL,
    descripcion text,
    nombre character varying(100) NOT NULL,
    id_item integer NOT NULL
);


ALTER TABLE soporte.categoria OWNER TO postgres;

--
-- TOC entry 299 (class 1259 OID 23296)
-- Name: categoria_id_categoria_seq; Type: SEQUENCE; Schema: soporte; Owner: postgres
--

CREATE SEQUENCE soporte.categoria_id_categoria_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE soporte.categoria_id_categoria_seq OWNER TO postgres;

--
-- TOC entry 5645 (class 0 OID 0)
-- Dependencies: 299
-- Name: categoria_id_categoria_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.categoria_id_categoria_seq OWNED BY soporte.categoria.id_categoria;


--
-- TOC entry 275 (class 1259 OID 22564)
-- Name: comentario_ticket; Type: TABLE; Schema: soporte; Owner: postgres
--

CREATE TABLE soporte.comentario_ticket (
    id_comentario integer NOT NULL,
    id_ticket integer NOT NULL,
    id_usuario integer NOT NULL,
    contenido text NOT NULL,
    visible_para_cliente boolean DEFAULT false,
    fecha_creacion timestamp without time zone DEFAULT now(),
    fecha_edicion timestamp without time zone,
    id_estado_item integer NOT NULL,
    comentario text NOT NULL,
    es_interno boolean,
    id_empresa integer NOT NULL
);


ALTER TABLE soporte.comentario_ticket OWNER TO postgres;

--
-- TOC entry 276 (class 1259 OID 22576)
-- Name: comentario_ticket_id_comentario_seq; Type: SEQUENCE; Schema: soporte; Owner: postgres
--

CREATE SEQUENCE soporte.comentario_ticket_id_comentario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE soporte.comentario_ticket_id_comentario_seq OWNER TO postgres;

--
-- TOC entry 5646 (class 0 OID 0)
-- Dependencies: 276
-- Name: comentario_ticket_id_comentario_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.comentario_ticket_id_comentario_seq OWNED BY soporte.comentario_ticket.id_comentario;


--
-- TOC entry 277 (class 1259 OID 22577)
-- Name: documento_ticket; Type: TABLE; Schema: soporte; Owner: postgres
--

CREATE TABLE soporte.documento_ticket (
    id_documento integer NOT NULL,
    id_ticket integer NOT NULL,
    id_tipo_documento_item integer NOT NULL,
    id_usuario_subio integer NOT NULL,
    nombre_archivo character varying(255) NOT NULL,
    ruta_archivo text NOT NULL,
    descripcion text,
    fecha_subida timestamp without time zone DEFAULT now(),
    id_estado_item integer NOT NULL
);


ALTER TABLE soporte.documento_ticket OWNER TO postgres;

--
-- TOC entry 278 (class 1259 OID 22590)
-- Name: documento_ticket_id_documento_seq; Type: SEQUENCE; Schema: soporte; Owner: postgres
--

CREATE SEQUENCE soporte.documento_ticket_id_documento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE soporte.documento_ticket_id_documento_seq OWNER TO postgres;

--
-- TOC entry 5647 (class 0 OID 0)
-- Dependencies: 278
-- Name: documento_ticket_id_documento_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.documento_ticket_id_documento_seq OWNED BY soporte.documento_ticket.id_documento;


--
-- TOC entry 279 (class 1259 OID 22591)
-- Name: historial_estado; Type: TABLE; Schema: soporte; Owner: empresa_owner
--

CREATE TABLE soporte.historial_estado (
    id_historial integer NOT NULL,
    id_ticket integer NOT NULL,
    usuario_bd character varying(100) NOT NULL,
    fecha_cambio timestamp without time zone DEFAULT now(),
    observacion text,
    id_estado_anterior integer,
    id_estado_nuevo integer NOT NULL,
    id_usuario integer,
    id_estado integer NOT NULL
);


ALTER TABLE soporte.historial_estado OWNER TO empresa_owner;

--
-- TOC entry 280 (class 1259 OID 22601)
-- Name: historial_estado_id_historial_seq; Type: SEQUENCE; Schema: soporte; Owner: empresa_owner
--

CREATE SEQUENCE soporte.historial_estado_id_historial_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE soporte.historial_estado_id_historial_seq OWNER TO empresa_owner;

--
-- TOC entry 5648 (class 0 OID 0)
-- Dependencies: 280
-- Name: historial_estado_id_historial_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: empresa_owner
--

ALTER SEQUENCE soporte.historial_estado_id_historial_seq OWNED BY soporte.historial_estado.id_historial;


--
-- TOC entry 302 (class 1259 OID 23312)
-- Name: prioridad; Type: TABLE; Schema: soporte; Owner: postgres
--

CREATE TABLE soporte.prioridad (
    id_prioridad integer NOT NULL,
    descripcion text,
    nombre character varying(30) NOT NULL,
    id_item integer NOT NULL
);


ALTER TABLE soporte.prioridad OWNER TO postgres;

--
-- TOC entry 301 (class 1259 OID 23311)
-- Name: prioridad_id_prioridad_seq; Type: SEQUENCE; Schema: soporte; Owner: postgres
--

CREATE SEQUENCE soporte.prioridad_id_prioridad_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE soporte.prioridad_id_prioridad_seq OWNER TO postgres;

--
-- TOC entry 5649 (class 0 OID 0)
-- Dependencies: 301
-- Name: prioridad_id_prioridad_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.prioridad_id_prioridad_seq OWNED BY soporte.prioridad.id_prioridad;


--
-- TOC entry 281 (class 1259 OID 22602)
-- Name: sla_ticket; Type: TABLE; Schema: soporte; Owner: postgres
--

CREATE TABLE soporte.sla_ticket (
    id_sla integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    tiempo_respuesta_min integer NOT NULL,
    tiempo_solucion_min integer NOT NULL,
    aplica_prioridad integer,
    activo boolean DEFAULT true,
    fecha_creacion timestamp without time zone DEFAULT now(),
    id_empresa integer NOT NULL
);


ALTER TABLE soporte.sla_ticket OWNER TO postgres;

--
-- TOC entry 282 (class 1259 OID 22613)
-- Name: sla_ticket_id_sla_seq; Type: SEQUENCE; Schema: soporte; Owner: postgres
--

CREATE SEQUENCE soporte.sla_ticket_id_sla_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE soporte.sla_ticket_id_sla_seq OWNER TO postgres;

--
-- TOC entry 5650 (class 0 OID 0)
-- Dependencies: 282
-- Name: sla_ticket_id_sla_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.sla_ticket_id_sla_seq OWNED BY soporte.sla_ticket.id_sla;


--
-- TOC entry 283 (class 1259 OID 22614)
-- Name: solucion_ticket; Type: TABLE; Schema: soporte; Owner: postgres
--

CREATE TABLE soporte.solucion_ticket (
    id_solucion integer NOT NULL,
    id_ticket integer NOT NULL,
    descripcion_solucion text NOT NULL,
    fue_resuelto boolean NOT NULL,
    fecha_solucion timestamp without time zone DEFAULT now(),
    id_usuario_tecnico integer NOT NULL
);


ALTER TABLE soporte.solucion_ticket OWNER TO postgres;

--
-- TOC entry 284 (class 1259 OID 22625)
-- Name: solucion_ticket_id_solucion_seq; Type: SEQUENCE; Schema: soporte; Owner: postgres
--

CREATE SEQUENCE soporte.solucion_ticket_id_solucion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE soporte.solucion_ticket_id_solucion_seq OWNER TO postgres;

--
-- TOC entry 5651 (class 0 OID 0)
-- Dependencies: 284
-- Name: solucion_ticket_id_solucion_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.solucion_ticket_id_solucion_seq OWNED BY soporte.solucion_ticket.id_solucion;


--
-- TOC entry 285 (class 1259 OID 22626)
-- Name: ticket; Type: TABLE; Schema: soporte; Owner: empresa_owner
--

CREATE TABLE soporte.ticket (
    id_ticket integer NOT NULL,
    asunto character varying(200) NOT NULL,
    descripcion text NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now(),
    fecha_actualizacion timestamp without time zone,
    id_servicio integer NOT NULL,
    id_sucursal integer NOT NULL,
    id_sla integer,
    id_estado_item integer,
    id_prioridad_item integer,
    id_categoria_item integer NOT NULL,
    id_usuario_creador integer,
    id_usuario_asignado integer,
    id_cliente integer NOT NULL,
    fecha_cierre timestamp without time zone
);


ALTER TABLE soporte.ticket OWNER TO empresa_owner;

--
-- TOC entry 286 (class 1259 OID 22639)
-- Name: ticket_id_ticket_seq; Type: SEQUENCE; Schema: soporte; Owner: empresa_owner
--

CREATE SEQUENCE soporte.ticket_id_ticket_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE soporte.ticket_id_ticket_seq OWNER TO empresa_owner;

--
-- TOC entry 5652 (class 0 OID 0)
-- Dependencies: 286
-- Name: ticket_id_ticket_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: empresa_owner
--

ALTER SEQUENCE soporte.ticket_id_ticket_seq OWNED BY soporte.ticket.id_ticket;


--
-- TOC entry 287 (class 1259 OID 22640)
-- Name: persona; Type: TABLE; Schema: usuarios; Owner: postgres
--

CREATE TABLE usuarios.persona (
    id_persona integer NOT NULL,
    cedula character varying(10) NOT NULL,
    nombre character varying(100) NOT NULL,
    apellido character varying(100) NOT NULL,
    celular character varying(15),
    correo character varying(150),
    fecha_nacimiento date,
    direccion text,
    id_canton integer,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion timestamp without time zone,
    id_usuario integer
);


ALTER TABLE usuarios.persona OWNER TO postgres;

--
-- TOC entry 288 (class 1259 OID 22650)
-- Name: persona_id_persona_seq; Type: SEQUENCE; Schema: usuarios; Owner: postgres
--

CREATE SEQUENCE usuarios.persona_id_persona_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE usuarios.persona_id_persona_seq OWNER TO postgres;

--
-- TOC entry 5654 (class 0 OID 0)
-- Dependencies: 288
-- Name: persona_id_persona_seq; Type: SEQUENCE OWNED BY; Schema: usuarios; Owner: postgres
--

ALTER SEQUENCE usuarios.persona_id_persona_seq OWNED BY usuarios.persona.id_persona;


--
-- TOC entry 289 (class 1259 OID 22651)
-- Name: rol; Type: TABLE; Schema: usuarios; Owner: empresa_owner
--

CREATE TABLE usuarios.rol (
    id_rol integer NOT NULL,
    codigo character varying(50) NOT NULL,
    descripcion text
);


ALTER TABLE usuarios.rol OWNER TO empresa_owner;

--
-- TOC entry 290 (class 1259 OID 22658)
-- Name: rol_bd; Type: TABLE; Schema: usuarios; Owner: empresa_owner
--

CREATE TABLE usuarios.rol_bd (
    id_rol_bd integer NOT NULL,
    nombre character varying(50) NOT NULL,
    descripcion text
);


ALTER TABLE usuarios.rol_bd OWNER TO empresa_owner;

--
-- TOC entry 291 (class 1259 OID 22665)
-- Name: rol_bd_id_rol_bd_seq; Type: SEQUENCE; Schema: usuarios; Owner: empresa_owner
--

CREATE SEQUENCE usuarios.rol_bd_id_rol_bd_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE usuarios.rol_bd_id_rol_bd_seq OWNER TO empresa_owner;

--
-- TOC entry 5657 (class 0 OID 0)
-- Dependencies: 291
-- Name: rol_bd_id_rol_bd_seq; Type: SEQUENCE OWNED BY; Schema: usuarios; Owner: empresa_owner
--

ALTER SEQUENCE usuarios.rol_bd_id_rol_bd_seq OWNED BY usuarios.rol_bd.id_rol_bd;


--
-- TOC entry 292 (class 1259 OID 22666)
-- Name: rol_id_rol_seq; Type: SEQUENCE; Schema: usuarios; Owner: empresa_owner
--

CREATE SEQUENCE usuarios.rol_id_rol_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE usuarios.rol_id_rol_seq OWNER TO empresa_owner;

--
-- TOC entry 5658 (class 0 OID 0)
-- Dependencies: 292
-- Name: rol_id_rol_seq; Type: SEQUENCE OWNED BY; Schema: usuarios; Owner: empresa_owner
--

ALTER SEQUENCE usuarios.rol_id_rol_seq OWNED BY usuarios.rol.id_rol;


--
-- TOC entry 293 (class 1259 OID 22667)
-- Name: usuario; Type: TABLE; Schema: usuarios; Owner: empresa_owner
--

CREATE TABLE usuarios.usuario (
    id_usuario integer NOT NULL,
    username character varying(50) NOT NULL,
    password_hash text NOT NULL,
    primer_login boolean DEFAULT true,
    id_rol integer NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion timestamp without time zone,
    id_empresa integer,
    id_catalogo_item_estado integer NOT NULL
);


ALTER TABLE usuarios.usuario OWNER TO empresa_owner;

--
-- TOC entry 294 (class 1259 OID 22679)
-- Name: usuario_bd; Type: TABLE; Schema: usuarios; Owner: empresa_owner
--

CREATE TABLE usuarios.usuario_bd (
    id_usuario_bd integer NOT NULL,
    nombre character varying(50) NOT NULL,
    id_rol_bd integer NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    id_usuario integer NOT NULL
);


ALTER TABLE usuarios.usuario_bd OWNER TO empresa_owner;

--
-- TOC entry 295 (class 1259 OID 22687)
-- Name: usuario_bd_id_usuario_bd_seq; Type: SEQUENCE; Schema: usuarios; Owner: empresa_owner
--

CREATE SEQUENCE usuarios.usuario_bd_id_usuario_bd_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE usuarios.usuario_bd_id_usuario_bd_seq OWNER TO empresa_owner;

--
-- TOC entry 5661 (class 0 OID 0)
-- Dependencies: 295
-- Name: usuario_bd_id_usuario_bd_seq; Type: SEQUENCE OWNED BY; Schema: usuarios; Owner: empresa_owner
--

ALTER SEQUENCE usuarios.usuario_bd_id_usuario_bd_seq OWNED BY usuarios.usuario_bd.id_usuario_bd;


--
-- TOC entry 296 (class 1259 OID 22688)
-- Name: usuario_id_usuario_seq; Type: SEQUENCE; Schema: usuarios; Owner: empresa_owner
--

CREATE SEQUENCE usuarios.usuario_id_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE usuarios.usuario_id_usuario_seq OWNER TO empresa_owner;

--
-- TOC entry 5662 (class 0 OID 0)
-- Dependencies: 296
-- Name: usuario_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: usuarios; Owner: empresa_owner
--

ALTER SEQUENCE usuarios.usuario_id_usuario_seq OWNED BY usuarios.usuario.id_usuario;


--
-- TOC entry 5097 (class 2604 OID 22689)
-- Name: auditoria_estado_ticket id_auditoria; Type: DEFAULT; Schema: auditoria; Owner: empresa_owner
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket ALTER COLUMN id_auditoria SET DEFAULT nextval('auditoria.auditoria_estado_ticket_id_auditoria_seq'::regclass);


--
-- TOC entry 5099 (class 2604 OID 22690)
-- Name: auditoria_evento id_evento; Type: DEFAULT; Schema: auditoria; Owner: empresa_owner
--

ALTER TABLE ONLY auditoria.auditoria_evento ALTER COLUMN id_evento SET DEFAULT nextval('auditoria.auditoria_evento_id_evento_seq'::regclass);


--
-- TOC entry 5101 (class 2604 OID 22691)
-- Name: auditoria_login id_login; Type: DEFAULT; Schema: auditoria; Owner: empresa_owner
--

ALTER TABLE ONLY auditoria.auditoria_login ALTER COLUMN id_login SET DEFAULT nextval('auditoria.auditoria_login_id_login_seq'::regclass);


--
-- TOC entry 5103 (class 2604 OID 22692)
-- Name: auditoria_login_bd id_auditoria_login_bd; Type: DEFAULT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd ALTER COLUMN id_auditoria_login_bd SET DEFAULT nextval('auditoria.auditoria_login_bd_id_auditoria_login_bd_seq'::regclass);


--
-- TOC entry 5105 (class 2604 OID 22693)
-- Name: catalogo id_catalogo; Type: DEFAULT; Schema: catalogos; Owner: empresa_owner
--

ALTER TABLE ONLY catalogos.catalogo ALTER COLUMN id_catalogo SET DEFAULT nextval('catalogos.catalogo_id_catalogo_seq'::regclass);


--
-- TOC entry 5107 (class 2604 OID 22694)
-- Name: catalogo_item id_item; Type: DEFAULT; Schema: catalogos; Owner: empresa_owner
--

ALTER TABLE ONLY catalogos.catalogo_item ALTER COLUMN id_item SET DEFAULT nextval('catalogos.catalogo_item_id_item_seq'::regclass);


--
-- TOC entry 5109 (class 2604 OID 22695)
-- Name: canton id_canton; Type: DEFAULT; Schema: clientes; Owner: empresa_owner
--

ALTER TABLE ONLY clientes.canton ALTER COLUMN id_canton SET DEFAULT nextval('clientes.canton_id_canton_seq'::regclass);


--
-- TOC entry 5110 (class 2604 OID 22696)
-- Name: ciudad id_ciudad; Type: DEFAULT; Schema: clientes; Owner: empresa_owner
--

ALTER TABLE ONLY clientes.ciudad ALTER COLUMN id_ciudad SET DEFAULT nextval('clientes.ciudad_id_ciudad_seq'::regclass);


--
-- TOC entry 5111 (class 2604 OID 22697)
-- Name: cliente id_cliente; Type: DEFAULT; Schema: clientes; Owner: empresa_owner
--

ALTER TABLE ONLY clientes.cliente ALTER COLUMN id_cliente SET DEFAULT nextval('clientes.cliente_id_cliente_seq'::regclass);


--
-- TOC entry 5115 (class 2604 OID 22698)
-- Name: documento_cliente id_documento; Type: DEFAULT; Schema: clientes; Owner: empresa_owner
--

ALTER TABLE ONLY clientes.documento_cliente ALTER COLUMN id_documento SET DEFAULT nextval('clientes.documento_cliente_id_documento_seq'::regclass);


--
-- TOC entry 5117 (class 2604 OID 22699)
-- Name: pais id_pais; Type: DEFAULT; Schema: clientes; Owner: empresa_owner
--

ALTER TABLE ONLY clientes.pais ALTER COLUMN id_pais SET DEFAULT nextval('clientes.pais_id_pais_seq'::regclass);


--
-- TOC entry 5118 (class 2604 OID 22700)
-- Name: tipo_documento id_tipo_documento; Type: DEFAULT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.tipo_documento ALTER COLUMN id_tipo_documento SET DEFAULT nextval('clientes.tipo_documento_id_tipo_documento_seq'::regclass);


--
-- TOC entry 5119 (class 2604 OID 22701)
-- Name: area id_area; Type: DEFAULT; Schema: empleados; Owner: empresa_owner
--

ALTER TABLE ONLY empleados.area ALTER COLUMN id_area SET DEFAULT nextval('empleados.area_id_area_seq'::regclass);


--
-- TOC entry 5120 (class 2604 OID 22702)
-- Name: cargo id_cargo; Type: DEFAULT; Schema: empleados; Owner: empresa_owner
--

ALTER TABLE ONLY empleados.cargo ALTER COLUMN id_cargo SET DEFAULT nextval('empleados.cargo_id_cargo_seq'::regclass);


--
-- TOC entry 5121 (class 2604 OID 22703)
-- Name: documento_empleado id_documento; Type: DEFAULT; Schema: empleados; Owner: empresa_owner
--

ALTER TABLE ONLY empleados.documento_empleado ALTER COLUMN id_documento SET DEFAULT nextval('empleados.documento_empleado_id_documento_seq'::regclass);


--
-- TOC entry 5124 (class 2604 OID 22704)
-- Name: tipo_contrato id_tipo_contrato; Type: DEFAULT; Schema: empleados; Owner: empresa_owner
--

ALTER TABLE ONLY empleados.tipo_contrato ALTER COLUMN id_tipo_contrato SET DEFAULT nextval('empleados.tipo_contrato_id_tipo_contrato_seq'::regclass);


--
-- TOC entry 5125 (class 2604 OID 22705)
-- Name: documento_empresa id_documento; Type: DEFAULT; Schema: empresa; Owner: empresa_owner
--

ALTER TABLE ONLY empresa.documento_empresa ALTER COLUMN id_documento SET DEFAULT nextval('empresa.documento_empresa_id_documento_seq'::regclass);


--
-- TOC entry 5127 (class 2604 OID 22706)
-- Name: empresa id_empresa; Type: DEFAULT; Schema: empresa; Owner: empresa_owner
--

ALTER TABLE ONLY empresa.empresa ALTER COLUMN id_empresa SET DEFAULT nextval('empresa.empresa_id_empresa_seq'::regclass);


--
-- TOC entry 5161 (class 2604 OID 23287)
-- Name: servicio id_servicio; Type: DEFAULT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.servicio ALTER COLUMN id_servicio SET DEFAULT nextval('empresa.servicio_id_servicio_seq'::regclass);


--
-- TOC entry 5129 (class 2604 OID 22707)
-- Name: sucursal id_sucursal; Type: DEFAULT; Schema: empresa; Owner: empresa_owner
--

ALTER TABLE ONLY empresa.sucursal ALTER COLUMN id_sucursal SET DEFAULT nextval('empresa.sucursal_id_sucursal_seq'::regclass);


--
-- TOC entry 5130 (class 2604 OID 22708)
-- Name: canal_notificacion id_canal; Type: DEFAULT; Schema: notificaciones; Owner: empresa_owner
--

ALTER TABLE ONLY notificaciones.canal_notificacion ALTER COLUMN id_canal SET DEFAULT nextval('notificaciones.canal_notificacion_id_canal_seq'::regclass);


--
-- TOC entry 5132 (class 2604 OID 22709)
-- Name: notificacion id_notificacion; Type: DEFAULT; Schema: notificaciones; Owner: empresa_owner
--

ALTER TABLE ONLY notificaciones.notificacion ALTER COLUMN id_notificacion SET DEFAULT nextval('notificaciones.notificacion_id_notificacion_seq'::regclass);


--
-- TOC entry 5135 (class 2604 OID 22710)
-- Name: asignacion id_asignacion; Type: DEFAULT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.asignacion ALTER COLUMN id_asignacion SET DEFAULT nextval('soporte.asignacion_id_asignacion_seq'::regclass);


--
-- TOC entry 5162 (class 2604 OID 23300)
-- Name: categoria id_categoria; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.categoria ALTER COLUMN id_categoria SET DEFAULT nextval('soporte.categoria_id_categoria_seq'::regclass);


--
-- TOC entry 5138 (class 2604 OID 22711)
-- Name: comentario_ticket id_comentario; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket ALTER COLUMN id_comentario SET DEFAULT nextval('soporte.comentario_ticket_id_comentario_seq'::regclass);


--
-- TOC entry 5141 (class 2604 OID 22712)
-- Name: documento_ticket id_documento; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.documento_ticket ALTER COLUMN id_documento SET DEFAULT nextval('soporte.documento_ticket_id_documento_seq'::regclass);


--
-- TOC entry 5143 (class 2604 OID 22713)
-- Name: historial_estado id_historial; Type: DEFAULT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.historial_estado ALTER COLUMN id_historial SET DEFAULT nextval('soporte.historial_estado_id_historial_seq'::regclass);


--
-- TOC entry 5163 (class 2604 OID 23315)
-- Name: prioridad id_prioridad; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.prioridad ALTER COLUMN id_prioridad SET DEFAULT nextval('soporte.prioridad_id_prioridad_seq'::regclass);


--
-- TOC entry 5145 (class 2604 OID 22714)
-- Name: sla_ticket id_sla; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.sla_ticket ALTER COLUMN id_sla SET DEFAULT nextval('soporte.sla_ticket_id_sla_seq'::regclass);


--
-- TOC entry 5148 (class 2604 OID 22715)
-- Name: solucion_ticket id_solucion; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.solucion_ticket ALTER COLUMN id_solucion SET DEFAULT nextval('soporte.solucion_ticket_id_solucion_seq'::regclass);


--
-- TOC entry 5150 (class 2604 OID 22716)
-- Name: ticket id_ticket; Type: DEFAULT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.ticket ALTER COLUMN id_ticket SET DEFAULT nextval('soporte.ticket_id_ticket_seq'::regclass);


--
-- TOC entry 5152 (class 2604 OID 22717)
-- Name: persona id_persona; Type: DEFAULT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.persona ALTER COLUMN id_persona SET DEFAULT nextval('usuarios.persona_id_persona_seq'::regclass);


--
-- TOC entry 5154 (class 2604 OID 22718)
-- Name: rol id_rol; Type: DEFAULT; Schema: usuarios; Owner: empresa_owner
--

ALTER TABLE ONLY usuarios.rol ALTER COLUMN id_rol SET DEFAULT nextval('usuarios.rol_id_rol_seq'::regclass);


--
-- TOC entry 5155 (class 2604 OID 22719)
-- Name: rol_bd id_rol_bd; Type: DEFAULT; Schema: usuarios; Owner: empresa_owner
--

ALTER TABLE ONLY usuarios.rol_bd ALTER COLUMN id_rol_bd SET DEFAULT nextval('usuarios.rol_bd_id_rol_bd_seq'::regclass);


--
-- TOC entry 5156 (class 2604 OID 22720)
-- Name: usuario id_usuario; Type: DEFAULT; Schema: usuarios; Owner: empresa_owner
--

ALTER TABLE ONLY usuarios.usuario ALTER COLUMN id_usuario SET DEFAULT nextval('usuarios.usuario_id_usuario_seq'::regclass);


--
-- TOC entry 5159 (class 2604 OID 22721)
-- Name: usuario_bd id_usuario_bd; Type: DEFAULT; Schema: usuarios; Owner: empresa_owner
--

ALTER TABLE ONLY usuarios.usuario_bd ALTER COLUMN id_usuario_bd SET DEFAULT nextval('usuarios.usuario_bd_id_usuario_bd_seq'::regclass);


--
-- TOC entry 5526 (class 0 OID 22351)
-- Dependencies: 228
-- Data for Name: auditoria_estado_ticket; Type: TABLE DATA; Schema: auditoria; Owner: empresa_owner
--

COPY auditoria.auditoria_estado_ticket (id_auditoria, id_ticket, usuario_bd, fecha_cambio, id_estado_anterior, id_item_evento, id_usuario, id_estado_nuevo_item) FROM stdin;
\.


--
-- TOC entry 5528 (class 0 OID 22360)
-- Dependencies: 230
-- Data for Name: auditoria_evento; Type: TABLE DATA; Schema: auditoria; Owner: empresa_owner
--

COPY auditoria.auditoria_evento (id_evento, esquema_afectado, tabla_afectada, id_registro, descripcion, usuario_bd, rol_bd, fecha_evento, id_usuario, id_notificacion, id_accion_item) FROM stdin;
\.


--
-- TOC entry 5530 (class 0 OID 22375)
-- Dependencies: 232
-- Data for Name: auditoria_login; Type: TABLE DATA; Schema: auditoria; Owner: empresa_owner
--

COPY auditoria.auditoria_login (id_login, usuario_app, usuario_bd, exito, ip_origen, fecha_login, id_usuario, id_item_evento) FROM stdin;
\.


--
-- TOC entry 5531 (class 0 OID 22382)
-- Dependencies: 233
-- Data for Name: auditoria_login_bd; Type: TABLE DATA; Schema: auditoria; Owner: postgres
--

COPY auditoria.auditoria_login_bd (id_auditoria_login_bd, id_usuario_bd, id_item_evento, fecha_evento, ip_origen, observacion) FROM stdin;
\.


--
-- TOC entry 5534 (class 0 OID 22394)
-- Dependencies: 236
-- Data for Name: catalogo; Type: TABLE DATA; Schema: catalogos; Owner: empresa_owner
--

COPY catalogos.catalogo (id_catalogo, nombre, descripcion, activo) FROM stdin;
1	ESTADO_USUARIO	Estados posibles del usuario	t
2	ESTADO_TICKET	Estados del ciclo de vida del ticket	t
3	PRIORIDAD_TICKET	Prioridades del ticket	t
4	CATEGORIA_TICKET	Categorias de soporte	t
5	TIPO_NOTIFICACION	Eventos que generan notificacion	t
6	TIPO_DOCUMENTO_TICKET	Tipos de documentos asociados al ticket	t
7	ESTADO_DOCUMENTO	Estados posibles de un documento	t
8	ACCION_AUDITORIA	Tipos de acciones registradas en auditoria	t
9	TIPO_EMPRESA	Tipos de empresa	t
10	ESTADO_EMPRESA	Estados de empresa	t
\.


--
-- TOC entry 5536 (class 0 OID 22403)
-- Dependencies: 238
-- Data for Name: catalogo_item; Type: TABLE DATA; Schema: catalogos; Owner: empresa_owner
--

COPY catalogos.catalogo_item (id_item, id_catalogo, codigo, nombre, orden, activo) FROM stdin;
1	1	ACTIVO	Activo	1	t
2	1	INACTIVO	Inactivo	2	t
3	1	BLOQUEADO	Bloqueado	3	t
4	2	ABIERTO	Abierto	1	t
5	2	ASIGNADO	Asignado	2	t
6	2	EN_PROCESO	En proceso	3	t
7	2	RESUELTO	Resuelto	4	t
8	2	CERRADO	Cerrado	5	t
9	2	RECHAZADO	Rechazado	6	t
10	3	BAJA	Baja	1	t
11	3	MEDIA	Media	2	t
12	3	ALTA	Alta	3	t
13	3	CRITICA	Crítica	4	t
14	4	INTERNET	Problema de Internet	1	t
15	4	FACTURACION	Facturacion	2	t
16	4	CONFIGURACION	Configuracion de equipo	3	t
17	4	INSTALACION	Instalacion	4	t
18	5	TICKET_CREADO	Ticket creado	1	t
19	5	TICKET_ASIGNADO	Ticket asignado	2	t
20	5	TICKET_CERRADO	Ticket cerrado	3	t
21	5	COMENTARIO_NUEVO	Comentario nuevo	4	t
22	5	SLA_ALERTA	Alerta SLA	5	t
23	6	DOC_CLIENTE	Documento enviado por cliente	1	t
24	6	EVIDENCIA_TECNICA	Evidencia tecnica	2	t
25	6	INFORME_SOLUCION	Informe de solucion	3	t
26	6	INFORME_NO_RESUELTO	Informe no resuelto	4	t
27	7	ACTIVO	Activo	1	t
28	7	ELIMINADO	Eliminado	2	t
29	7	REEMPLAZADO	Reemplazado	3	t
30	8	INSERT	Insercion	1	t
31	8	UPDATE	Actualizacion	2	t
32	8	DELETE	Eliminacion	3	t
33	8	LOGIN	Inicio de sesion	4	t
34	8	CAMBIO_ESTADO	Cambio de estado	5	t
35	9	ISP	Proveedor de Internet	1	t
36	9	CORPORATIVA	Corporativa	2	t
37	10	ACTIVA	Activa	1	t
38	10	INACTIVA	Inactiva	2	t
\.


--
-- TOC entry 5538 (class 0 OID 22411)
-- Dependencies: 240
-- Data for Name: canton; Type: TABLE DATA; Schema: clientes; Owner: empresa_owner
--

COPY clientes.canton (id_canton, nombre, id_ciudad) FROM stdin;
\.


--
-- TOC entry 5540 (class 0 OID 22418)
-- Dependencies: 242
-- Data for Name: ciudad; Type: TABLE DATA; Schema: clientes; Owner: empresa_owner
--

COPY clientes.ciudad (id_ciudad, nombre, id_pais) FROM stdin;
\.


--
-- TOC entry 5542 (class 0 OID 22425)
-- Dependencies: 244
-- Data for Name: cliente; Type: TABLE DATA; Schema: clientes; Owner: empresa_owner
--

COPY clientes.cliente (id_cliente, id_sucursal, id_persona, fecha_inicio_contrato, fecha_fin_contrato, acceso_remoto, aprobacion_de_cambios, actualizaciones_automaticas) FROM stdin;
1	2	1	\N	\N	t	f	t
2	1	2	\N	\N	t	f	t
3	3	3	\N	\N	t	f	t
\.


--
-- TOC entry 5544 (class 0 OID 22433)
-- Dependencies: 246
-- Data for Name: documento_cliente; Type: TABLE DATA; Schema: clientes; Owner: empresa_owner
--

COPY clientes.documento_cliente (id_documento, numero_documento, ruta_archivo, descripcion, fecha_subida, id_cliente, id_tipo_documento, id_catalogo_item_estado) FROM stdin;
\.


--
-- TOC entry 5546 (class 0 OID 22445)
-- Dependencies: 248
-- Data for Name: pais; Type: TABLE DATA; Schema: clientes; Owner: empresa_owner
--

COPY clientes.pais (id_pais, nombre) FROM stdin;
\.


--
-- TOC entry 5548 (class 0 OID 22451)
-- Dependencies: 250
-- Data for Name: tipo_documento; Type: TABLE DATA; Schema: clientes; Owner: postgres
--

COPY clientes.tipo_documento (id_tipo_documento, codigo) FROM stdin;
\.


--
-- TOC entry 5550 (class 0 OID 22457)
-- Dependencies: 252
-- Data for Name: area; Type: TABLE DATA; Schema: empleados; Owner: empresa_owner
--

COPY empleados.area (id_area, nombre) FROM stdin;
1	Sistemas
2	Soporte Técnico
3	Infraestructura
4	Desarrollo
5	Administración
6	Finanzas
7	Recursos Humanos
\.


--
-- TOC entry 5552 (class 0 OID 22463)
-- Dependencies: 254
-- Data for Name: cargo; Type: TABLE DATA; Schema: empleados; Owner: empresa_owner
--

COPY empleados.cargo (id_cargo, nombre) FROM stdin;
1	Administrador Master
2	Administrador Técnicos
3	Administrador Visual
4	Técnico
5	Soporte Nivel 1
6	Soporte Nivel 2
7	Jefe de Sistemas
8	Analista de Sistemas
\.


--
-- TOC entry 5554 (class 0 OID 22469)
-- Dependencies: 256
-- Data for Name: documento_empleado; Type: TABLE DATA; Schema: empleados; Owner: empresa_owner
--

COPY empleados.documento_empleado (id_documento, numero_documento, ruta_archivo, descripcion, fecha_subida, id_empleado, id_tipo_documento, id_catalogo_item_estado, cedula_empleado) FROM stdin;
\.


--
-- TOC entry 5557 (class 0 OID 22481)
-- Dependencies: 259
-- Data for Name: empleado; Type: TABLE DATA; Schema: empleados; Owner: empresa_owner
--

COPY empleados.empleado (fecha_ingreso, id_cargo, id_area, id_tipo_contrato, id_empleado, id_sucursal, id_persona) FROM stdin;
\.


--
-- TOC entry 5558 (class 0 OID 22490)
-- Dependencies: 260
-- Data for Name: tipo_contrato; Type: TABLE DATA; Schema: empleados; Owner: empresa_owner
--

COPY empleados.tipo_contrato (id_tipo_contrato, nombre) FROM stdin;
1	Indefinido
2	Temporal
3	Contrato por Servicios
4	Pasantía
5	Freelance
\.


--
-- TOC entry 5560 (class 0 OID 22496)
-- Dependencies: 262
-- Data for Name: documento_empresa; Type: TABLE DATA; Schema: empresa; Owner: empresa_owner
--

COPY empresa.documento_empresa (id_documento, id_empresa, numero_documento, ruta_archivo, descripcion, fecha_subida, id_tipo_documento, id_catalogo_item_estado) FROM stdin;
\.


--
-- TOC entry 5562 (class 0 OID 22508)
-- Dependencies: 264
-- Data for Name: empresa; Type: TABLE DATA; Schema: empresa; Owner: empresa_owner
--

COPY empresa.empresa (id_empresa, nombre_comercial, razon_social, ruc, tipo_empresa, correo_contacto, telefono_contacto, direccion_principal, fecha_creacion, id_catalogo_item_tipo_empresa, id_catalogo_item_estado) FROM stdin;
1	CNT	Corporación Nacional de Telecomunicaciones CNT EP	1768152560001	PUBLICA	\N	\N	\N	2026-02-22 10:54:48.394042	\N	1
2	Netlife	MEGADATOS S.A. (NETLIFE)	1792161037001	PRIVADA	\N	\N	\N	2026-02-22 10:54:48.394042	\N	1
3	Xtrim	TV CABLE / XTRIM	0990793664001	PRIVADA	\N	\N	\N	2026-02-22 10:54:48.394042	\N	1
\.


--
-- TOC entry 5564 (class 0 OID 22520)
-- Dependencies: 266
-- Data for Name: empresa_servicio; Type: TABLE DATA; Schema: empresa; Owner: empresa_owner
--

COPY empresa.empresa_servicio (id_empresa, id_servicio) FROM stdin;
\.


--
-- TOC entry 5596 (class 0 OID 23284)
-- Dependencies: 298
-- Data for Name: servicio; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.servicio (id_servicio, activo, descripcion, nombre) FROM stdin;
\.


--
-- TOC entry 5565 (class 0 OID 22525)
-- Dependencies: 267
-- Data for Name: sucursal; Type: TABLE DATA; Schema: empresa; Owner: empresa_owner
--

COPY empresa.sucursal (id_sucursal, id_empresa, nombre, direccion, telefono, id_ciudad, id_canton, id_catalogo_item_estado) FROM stdin;
1	1	Sucursal Matriz CNT	Dirección Principal de CNT	\N	\N	\N	1
2	2	Sucursal Matriz Netlife	Dirección Principal de Netlife	\N	\N	\N	1
3	3	Sucursal Matriz Xtrim	Dirección Principal de Xtrim	\N	\N	\N	1
\.


--
-- TOC entry 5567 (class 0 OID 22535)
-- Dependencies: 269
-- Data for Name: canal_notificacion; Type: TABLE DATA; Schema: notificaciones; Owner: empresa_owner
--

COPY notificaciones.canal_notificacion (id_canal, nombre, activo) FROM stdin;
\.


--
-- TOC entry 5569 (class 0 OID 22542)
-- Dependencies: 271
-- Data for Name: notificacion; Type: TABLE DATA; Schema: notificaciones; Owner: empresa_owner
--

COPY notificaciones.notificacion (id_notificacion, id_canal, destinatario, asunto, mensaje, enviado, fecha_creacion, id_ticket, id_usuario_destino, id_tipo_notificacion, id_usuario_origen, fecha_envio, error_envio, id_empresa) FROM stdin;
\.


--
-- TOC entry 5571 (class 0 OID 22555)
-- Dependencies: 273
-- Data for Name: asignacion; Type: TABLE DATA; Schema: soporte; Owner: empresa_owner
--

COPY soporte.asignacion (id_asignacion, id_ticket, fecha_asignacion, activo, id_usuario) FROM stdin;
\.


--
-- TOC entry 5598 (class 0 OID 23297)
-- Dependencies: 300
-- Data for Name: categoria; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.categoria (id_categoria, descripcion, nombre, id_item) FROM stdin;
\.


--
-- TOC entry 5573 (class 0 OID 22564)
-- Dependencies: 275
-- Data for Name: comentario_ticket; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.comentario_ticket (id_comentario, id_ticket, id_usuario, contenido, visible_para_cliente, fecha_creacion, fecha_edicion, id_estado_item, comentario, es_interno, id_empresa) FROM stdin;
\.


--
-- TOC entry 5575 (class 0 OID 22577)
-- Dependencies: 277
-- Data for Name: documento_ticket; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.documento_ticket (id_documento, id_ticket, id_tipo_documento_item, id_usuario_subio, nombre_archivo, ruta_archivo, descripcion, fecha_subida, id_estado_item) FROM stdin;
\.


--
-- TOC entry 5577 (class 0 OID 22591)
-- Dependencies: 279
-- Data for Name: historial_estado; Type: TABLE DATA; Schema: soporte; Owner: empresa_owner
--

COPY soporte.historial_estado (id_historial, id_ticket, usuario_bd, fecha_cambio, observacion, id_estado_anterior, id_estado_nuevo, id_usuario, id_estado) FROM stdin;
\.


--
-- TOC entry 5600 (class 0 OID 23312)
-- Dependencies: 302
-- Data for Name: prioridad; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.prioridad (id_prioridad, descripcion, nombre, id_item) FROM stdin;
\.


--
-- TOC entry 5579 (class 0 OID 22602)
-- Dependencies: 281
-- Data for Name: sla_ticket; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.sla_ticket (id_sla, nombre, descripcion, tiempo_respuesta_min, tiempo_solucion_min, aplica_prioridad, activo, fecha_creacion, id_empresa) FROM stdin;
\.


--
-- TOC entry 5581 (class 0 OID 22614)
-- Dependencies: 283
-- Data for Name: solucion_ticket; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.solucion_ticket (id_solucion, id_ticket, descripcion_solucion, fue_resuelto, fecha_solucion, id_usuario_tecnico) FROM stdin;
\.


--
-- TOC entry 5583 (class 0 OID 22626)
-- Dependencies: 285
-- Data for Name: ticket; Type: TABLE DATA; Schema: soporte; Owner: empresa_owner
--

COPY soporte.ticket (id_ticket, asunto, descripcion, fecha_creacion, fecha_actualizacion, id_servicio, id_sucursal, id_sla, id_estado_item, id_prioridad_item, id_categoria_item, id_usuario_creador, id_usuario_asignado, id_cliente, fecha_cierre) FROM stdin;
\.


--
-- TOC entry 5585 (class 0 OID 22640)
-- Dependencies: 287
-- Data for Name: persona; Type: TABLE DATA; Schema: usuarios; Owner: postgres
--

COPY usuarios.persona (id_persona, cedula, nombre, apellido, celular, correo, fecha_nacimiento, direccion, id_canton, fecha_creacion, fecha_actualizacion, id_usuario) FROM stdin;
3	1207910165	Justyn Keith	Cruz Perez	\N	justyncruzperez@gmail.com	\N	\N	\N	2026-02-22 10:54:48.394042	\N	\N
2	1207445154	Elizabeth Anahis	Burgos Chilan	\N	elizabethanahisb@gmail.com	\N	\N	\N	2026-02-22 10:54:48.394042	2026-02-22 12:30:37.862134	2
1	0503360398	Angello Agustin	Mendoza Bermello	\N	angellomendoza46@gmail.com	\N	\N	\N	2026-02-22 10:54:48.394042	2026-02-22 12:44:59.447101	\N
\.


--
-- TOC entry 5587 (class 0 OID 22651)
-- Dependencies: 289
-- Data for Name: rol; Type: TABLE DATA; Schema: usuarios; Owner: empresa_owner
--

COPY usuarios.rol (id_rol, codigo, descripcion) FROM stdin;
1	CLIENTE	Usuario cliente del sistema
2	TECNICO	Empleado técnico
3	ADMIN_TECNICOS	Administrador de técnicos
4	ADMIN_MASTER	Administrador general del sistema
5	ADMIN_VISUAL	Administrador solo lectura
\.


--
-- TOC entry 5588 (class 0 OID 22658)
-- Dependencies: 290
-- Data for Name: rol_bd; Type: TABLE DATA; Schema: usuarios; Owner: empresa_owner
--

COPY usuarios.rol_bd (id_rol_bd, nombre, descripcion) FROM stdin;
1	rol_cliente	Rol base de datos clientes
2	rol_tecnico	Rol base de datos técnicos
3	rol_admin_tecnicos	Rol BD administrador técnicos
4	rol_admin_master	Rol BD administrador master
5	rol_admin_visual	Rol BD administrador visual
\.


--
-- TOC entry 5591 (class 0 OID 22667)
-- Dependencies: 293
-- Data for Name: usuario; Type: TABLE DATA; Schema: usuarios; Owner: empresa_owner
--

COPY usuarios.usuario (id_usuario, username, password_hash, primer_login, id_rol, fecha_creacion, fecha_actualizacion, id_empresa, id_catalogo_item_estado) FROM stdin;
2	eburgosc	$2a$10$PEbYXTN/uQaNKujO/o9Hx.I9SmZQDrxrvcdm/iYptWou1XeDthNzO	f	1	2026-02-22 12:30:37.808543	2026-02-22 12:31:21.83017	1	1
\.


--
-- TOC entry 5592 (class 0 OID 22679)
-- Dependencies: 294
-- Data for Name: usuario_bd; Type: TABLE DATA; Schema: usuarios; Owner: empresa_owner
--

COPY usuarios.usuario_bd (id_usuario_bd, nombre, id_rol_bd, fecha_creacion, id_usuario) FROM stdin;
\.


--
-- TOC entry 5663 (class 0 OID 0)
-- Dependencies: 229
-- Name: auditoria_estado_ticket_id_auditoria_seq; Type: SEQUENCE SET; Schema: auditoria; Owner: empresa_owner
--

SELECT pg_catalog.setval('auditoria.auditoria_estado_ticket_id_auditoria_seq', 1, false);


--
-- TOC entry 5664 (class 0 OID 0)
-- Dependencies: 231
-- Name: auditoria_evento_id_evento_seq; Type: SEQUENCE SET; Schema: auditoria; Owner: empresa_owner
--

SELECT pg_catalog.setval('auditoria.auditoria_evento_id_evento_seq', 1, false);


--
-- TOC entry 5665 (class 0 OID 0)
-- Dependencies: 234
-- Name: auditoria_login_bd_id_auditoria_login_bd_seq; Type: SEQUENCE SET; Schema: auditoria; Owner: postgres
--

SELECT pg_catalog.setval('auditoria.auditoria_login_bd_id_auditoria_login_bd_seq', 1, false);


--
-- TOC entry 5666 (class 0 OID 0)
-- Dependencies: 235
-- Name: auditoria_login_id_login_seq; Type: SEQUENCE SET; Schema: auditoria; Owner: empresa_owner
--

SELECT pg_catalog.setval('auditoria.auditoria_login_id_login_seq', 1, false);


--
-- TOC entry 5667 (class 0 OID 0)
-- Dependencies: 237
-- Name: catalogo_id_catalogo_seq; Type: SEQUENCE SET; Schema: catalogos; Owner: empresa_owner
--

SELECT pg_catalog.setval('catalogos.catalogo_id_catalogo_seq', 10, true);


--
-- TOC entry 5668 (class 0 OID 0)
-- Dependencies: 239
-- Name: catalogo_item_id_item_seq; Type: SEQUENCE SET; Schema: catalogos; Owner: empresa_owner
--

SELECT pg_catalog.setval('catalogos.catalogo_item_id_item_seq', 38, true);


--
-- TOC entry 5669 (class 0 OID 0)
-- Dependencies: 241
-- Name: canton_id_canton_seq; Type: SEQUENCE SET; Schema: clientes; Owner: empresa_owner
--

SELECT pg_catalog.setval('clientes.canton_id_canton_seq', 1, false);


--
-- TOC entry 5670 (class 0 OID 0)
-- Dependencies: 243
-- Name: ciudad_id_ciudad_seq; Type: SEQUENCE SET; Schema: clientes; Owner: empresa_owner
--

SELECT pg_catalog.setval('clientes.ciudad_id_ciudad_seq', 1, false);


--
-- TOC entry 5671 (class 0 OID 0)
-- Dependencies: 245
-- Name: cliente_id_cliente_seq; Type: SEQUENCE SET; Schema: clientes; Owner: empresa_owner
--

SELECT pg_catalog.setval('clientes.cliente_id_cliente_seq', 3, true);


--
-- TOC entry 5672 (class 0 OID 0)
-- Dependencies: 247
-- Name: documento_cliente_id_documento_seq; Type: SEQUENCE SET; Schema: clientes; Owner: empresa_owner
--

SELECT pg_catalog.setval('clientes.documento_cliente_id_documento_seq', 1, false);


--
-- TOC entry 5673 (class 0 OID 0)
-- Dependencies: 249
-- Name: pais_id_pais_seq; Type: SEQUENCE SET; Schema: clientes; Owner: empresa_owner
--

SELECT pg_catalog.setval('clientes.pais_id_pais_seq', 1, false);


--
-- TOC entry 5674 (class 0 OID 0)
-- Dependencies: 251
-- Name: tipo_documento_id_tipo_documento_seq; Type: SEQUENCE SET; Schema: clientes; Owner: postgres
--

SELECT pg_catalog.setval('clientes.tipo_documento_id_tipo_documento_seq', 1, false);


--
-- TOC entry 5675 (class 0 OID 0)
-- Dependencies: 253
-- Name: area_id_area_seq; Type: SEQUENCE SET; Schema: empleados; Owner: empresa_owner
--

SELECT pg_catalog.setval('empleados.area_id_area_seq', 7, true);


--
-- TOC entry 5676 (class 0 OID 0)
-- Dependencies: 255
-- Name: cargo_id_cargo_seq; Type: SEQUENCE SET; Schema: empleados; Owner: empresa_owner
--

SELECT pg_catalog.setval('empleados.cargo_id_cargo_seq', 8, true);


--
-- TOC entry 5677 (class 0 OID 0)
-- Dependencies: 257
-- Name: documento_empleado_id_documento_seq; Type: SEQUENCE SET; Schema: empleados; Owner: empresa_owner
--

SELECT pg_catalog.setval('empleados.documento_empleado_id_documento_seq', 1, false);


--
-- TOC entry 5678 (class 0 OID 0)
-- Dependencies: 258
-- Name: empleado_id_empleado_seq; Type: SEQUENCE SET; Schema: empleados; Owner: postgres
--

SELECT pg_catalog.setval('empleados.empleado_id_empleado_seq', 4, true);


--
-- TOC entry 5679 (class 0 OID 0)
-- Dependencies: 261
-- Name: tipo_contrato_id_tipo_contrato_seq; Type: SEQUENCE SET; Schema: empleados; Owner: empresa_owner
--

SELECT pg_catalog.setval('empleados.tipo_contrato_id_tipo_contrato_seq', 5, true);


--
-- TOC entry 5680 (class 0 OID 0)
-- Dependencies: 263
-- Name: documento_empresa_id_documento_seq; Type: SEQUENCE SET; Schema: empresa; Owner: empresa_owner
--

SELECT pg_catalog.setval('empresa.documento_empresa_id_documento_seq', 1, false);


--
-- TOC entry 5681 (class 0 OID 0)
-- Dependencies: 265
-- Name: empresa_id_empresa_seq; Type: SEQUENCE SET; Schema: empresa; Owner: empresa_owner
--

SELECT pg_catalog.setval('empresa.empresa_id_empresa_seq', 4, true);


--
-- TOC entry 5682 (class 0 OID 0)
-- Dependencies: 297
-- Name: servicio_id_servicio_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.servicio_id_servicio_seq', 1, false);


--
-- TOC entry 5683 (class 0 OID 0)
-- Dependencies: 268
-- Name: sucursal_id_sucursal_seq; Type: SEQUENCE SET; Schema: empresa; Owner: empresa_owner
--

SELECT pg_catalog.setval('empresa.sucursal_id_sucursal_seq', 3, true);


--
-- TOC entry 5684 (class 0 OID 0)
-- Dependencies: 270
-- Name: canal_notificacion_id_canal_seq; Type: SEQUENCE SET; Schema: notificaciones; Owner: empresa_owner
--

SELECT pg_catalog.setval('notificaciones.canal_notificacion_id_canal_seq', 1, false);


--
-- TOC entry 5685 (class 0 OID 0)
-- Dependencies: 272
-- Name: notificacion_id_notificacion_seq; Type: SEQUENCE SET; Schema: notificaciones; Owner: empresa_owner
--

SELECT pg_catalog.setval('notificaciones.notificacion_id_notificacion_seq', 1, false);


--
-- TOC entry 5686 (class 0 OID 0)
-- Dependencies: 274
-- Name: asignacion_id_asignacion_seq; Type: SEQUENCE SET; Schema: soporte; Owner: empresa_owner
--

SELECT pg_catalog.setval('soporte.asignacion_id_asignacion_seq', 1, false);


--
-- TOC entry 5687 (class 0 OID 0)
-- Dependencies: 299
-- Name: categoria_id_categoria_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.categoria_id_categoria_seq', 1, false);


--
-- TOC entry 5688 (class 0 OID 0)
-- Dependencies: 276
-- Name: comentario_ticket_id_comentario_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.comentario_ticket_id_comentario_seq', 1, false);


--
-- TOC entry 5689 (class 0 OID 0)
-- Dependencies: 278
-- Name: documento_ticket_id_documento_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.documento_ticket_id_documento_seq', 1, false);


--
-- TOC entry 5690 (class 0 OID 0)
-- Dependencies: 280
-- Name: historial_estado_id_historial_seq; Type: SEQUENCE SET; Schema: soporte; Owner: empresa_owner
--

SELECT pg_catalog.setval('soporte.historial_estado_id_historial_seq', 1, false);


--
-- TOC entry 5691 (class 0 OID 0)
-- Dependencies: 301
-- Name: prioridad_id_prioridad_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.prioridad_id_prioridad_seq', 1, false);


--
-- TOC entry 5692 (class 0 OID 0)
-- Dependencies: 282
-- Name: sla_ticket_id_sla_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.sla_ticket_id_sla_seq', 1, false);


--
-- TOC entry 5693 (class 0 OID 0)
-- Dependencies: 284
-- Name: solucion_ticket_id_solucion_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.solucion_ticket_id_solucion_seq', 1, false);


--
-- TOC entry 5694 (class 0 OID 0)
-- Dependencies: 286
-- Name: ticket_id_ticket_seq; Type: SEQUENCE SET; Schema: soporte; Owner: empresa_owner
--

SELECT pg_catalog.setval('soporte.ticket_id_ticket_seq', 1, false);


--
-- TOC entry 5695 (class 0 OID 0)
-- Dependencies: 288
-- Name: persona_id_persona_seq; Type: SEQUENCE SET; Schema: usuarios; Owner: postgres
--

SELECT pg_catalog.setval('usuarios.persona_id_persona_seq', 3, true);


--
-- TOC entry 5696 (class 0 OID 0)
-- Dependencies: 291
-- Name: rol_bd_id_rol_bd_seq; Type: SEQUENCE SET; Schema: usuarios; Owner: empresa_owner
--

SELECT pg_catalog.setval('usuarios.rol_bd_id_rol_bd_seq', 5, true);


--
-- TOC entry 5697 (class 0 OID 0)
-- Dependencies: 292
-- Name: rol_id_rol_seq; Type: SEQUENCE SET; Schema: usuarios; Owner: empresa_owner
--

SELECT pg_catalog.setval('usuarios.rol_id_rol_seq', 5, true);


--
-- TOC entry 5698 (class 0 OID 0)
-- Dependencies: 295
-- Name: usuario_bd_id_usuario_bd_seq; Type: SEQUENCE SET; Schema: usuarios; Owner: empresa_owner
--

SELECT pg_catalog.setval('usuarios.usuario_bd_id_usuario_bd_seq', 1, false);


--
-- TOC entry 5699 (class 0 OID 0)
-- Dependencies: 296
-- Name: usuario_id_usuario_seq; Type: SEQUENCE SET; Schema: usuarios; Owner: empresa_owner
--

SELECT pg_catalog.setval('usuarios.usuario_id_usuario_seq', 3, true);


--
-- TOC entry 5165 (class 2606 OID 22723)
-- Name: auditoria_estado_ticket auditoria_estado_ticket_pkey; Type: CONSTRAINT; Schema: auditoria; Owner: empresa_owner
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT auditoria_estado_ticket_pkey PRIMARY KEY (id_auditoria);


--
-- TOC entry 5167 (class 2606 OID 22725)
-- Name: auditoria_evento auditoria_evento_pkey; Type: CONSTRAINT; Schema: auditoria; Owner: empresa_owner
--

ALTER TABLE ONLY auditoria.auditoria_evento
    ADD CONSTRAINT auditoria_evento_pkey PRIMARY KEY (id_evento);


--
-- TOC entry 5171 (class 2606 OID 22727)
-- Name: auditoria_login_bd auditoria_login_bd_pkey; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd
    ADD CONSTRAINT auditoria_login_bd_pkey PRIMARY KEY (id_auditoria_login_bd);


--
-- TOC entry 5169 (class 2606 OID 22729)
-- Name: auditoria_login auditoria_login_pkey; Type: CONSTRAINT; Schema: auditoria; Owner: empresa_owner
--

ALTER TABLE ONLY auditoria.auditoria_login
    ADD CONSTRAINT auditoria_login_pkey PRIMARY KEY (id_login);


--
-- TOC entry 5177 (class 2606 OID 22731)
-- Name: catalogo_item catalogo_item_pkey; Type: CONSTRAINT; Schema: catalogos; Owner: empresa_owner
--

ALTER TABLE ONLY catalogos.catalogo_item
    ADD CONSTRAINT catalogo_item_pkey PRIMARY KEY (id_item);


--
-- TOC entry 5173 (class 2606 OID 22733)
-- Name: catalogo catalogo_nombre_key; Type: CONSTRAINT; Schema: catalogos; Owner: empresa_owner
--

ALTER TABLE ONLY catalogos.catalogo
    ADD CONSTRAINT catalogo_nombre_key UNIQUE (nombre);


--
-- TOC entry 5175 (class 2606 OID 22735)
-- Name: catalogo catalogo_pkey; Type: CONSTRAINT; Schema: catalogos; Owner: empresa_owner
--

ALTER TABLE ONLY catalogos.catalogo
    ADD CONSTRAINT catalogo_pkey PRIMARY KEY (id_catalogo);


--
-- TOC entry 5179 (class 2606 OID 22737)
-- Name: canton canton_pkey; Type: CONSTRAINT; Schema: clientes; Owner: empresa_owner
--

ALTER TABLE ONLY clientes.canton
    ADD CONSTRAINT canton_pkey PRIMARY KEY (id_canton);


--
-- TOC entry 5181 (class 2606 OID 22739)
-- Name: ciudad ciudad_pkey; Type: CONSTRAINT; Schema: clientes; Owner: empresa_owner
--

ALTER TABLE ONLY clientes.ciudad
    ADD CONSTRAINT ciudad_pkey PRIMARY KEY (id_ciudad);


--
-- TOC entry 5189 (class 2606 OID 22741)
-- Name: documento_cliente documento_cliente_pkey; Type: CONSTRAINT; Schema: clientes; Owner: empresa_owner
--

ALTER TABLE ONLY clientes.documento_cliente
    ADD CONSTRAINT documento_cliente_pkey PRIMARY KEY (id_documento);


--
-- TOC entry 5193 (class 2606 OID 22743)
-- Name: pais pais_nombre_key; Type: CONSTRAINT; Schema: clientes; Owner: empresa_owner
--

ALTER TABLE ONLY clientes.pais
    ADD CONSTRAINT pais_nombre_key UNIQUE (nombre);


--
-- TOC entry 5195 (class 2606 OID 22745)
-- Name: pais pais_pkey; Type: CONSTRAINT; Schema: clientes; Owner: empresa_owner
--

ALTER TABLE ONLY clientes.pais
    ADD CONSTRAINT pais_pkey PRIMARY KEY (id_pais);


--
-- TOC entry 5183 (class 2606 OID 22747)
-- Name: cliente pk_cliente; Type: CONSTRAINT; Schema: clientes; Owner: empresa_owner
--

ALTER TABLE ONLY clientes.cliente
    ADD CONSTRAINT pk_cliente PRIMARY KEY (id_cliente);


--
-- TOC entry 5197 (class 2606 OID 22749)
-- Name: tipo_documento tipo_documento_codigo_key; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.tipo_documento
    ADD CONSTRAINT tipo_documento_codigo_key UNIQUE (codigo);


--
-- TOC entry 5199 (class 2606 OID 22751)
-- Name: tipo_documento tipo_documento_pkey; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.tipo_documento
    ADD CONSTRAINT tipo_documento_pkey PRIMARY KEY (id_tipo_documento);


--
-- TOC entry 5185 (class 2606 OID 22753)
-- Name: cliente uq_cliente_id_cliente; Type: CONSTRAINT; Schema: clientes; Owner: empresa_owner
--

ALTER TABLE ONLY clientes.cliente
    ADD CONSTRAINT uq_cliente_id_cliente UNIQUE (id_cliente);


--
-- TOC entry 5187 (class 2606 OID 22755)
-- Name: cliente uq_cliente_persona; Type: CONSTRAINT; Schema: clientes; Owner: empresa_owner
--

ALTER TABLE ONLY clientes.cliente
    ADD CONSTRAINT uq_cliente_persona UNIQUE (id_persona);


--
-- TOC entry 5191 (class 2606 OID 22757)
-- Name: documento_cliente uq_documento_cliente; Type: CONSTRAINT; Schema: clientes; Owner: empresa_owner
--

ALTER TABLE ONLY clientes.documento_cliente
    ADD CONSTRAINT uq_documento_cliente UNIQUE (id_tipo_documento, numero_documento);


--
-- TOC entry 5201 (class 2606 OID 22759)
-- Name: area area_nombre_key; Type: CONSTRAINT; Schema: empleados; Owner: empresa_owner
--

ALTER TABLE ONLY empleados.area
    ADD CONSTRAINT area_nombre_key UNIQUE (nombre);


--
-- TOC entry 5203 (class 2606 OID 22761)
-- Name: area area_pkey; Type: CONSTRAINT; Schema: empleados; Owner: empresa_owner
--

ALTER TABLE ONLY empleados.area
    ADD CONSTRAINT area_pkey PRIMARY KEY (id_area);


--
-- TOC entry 5205 (class 2606 OID 22763)
-- Name: cargo cargo_nombre_key; Type: CONSTRAINT; Schema: empleados; Owner: empresa_owner
--

ALTER TABLE ONLY empleados.cargo
    ADD CONSTRAINT cargo_nombre_key UNIQUE (nombre);


--
-- TOC entry 5207 (class 2606 OID 22765)
-- Name: cargo cargo_pkey; Type: CONSTRAINT; Schema: empleados; Owner: empresa_owner
--

ALTER TABLE ONLY empleados.cargo
    ADD CONSTRAINT cargo_pkey PRIMARY KEY (id_cargo);


--
-- TOC entry 5209 (class 2606 OID 22767)
-- Name: documento_empleado documento_empleado_pkey; Type: CONSTRAINT; Schema: empleados; Owner: empresa_owner
--

ALTER TABLE ONLY empleados.documento_empleado
    ADD CONSTRAINT documento_empleado_pkey PRIMARY KEY (id_documento);


--
-- TOC entry 5211 (class 2606 OID 22769)
-- Name: empleado pk_empleado; Type: CONSTRAINT; Schema: empleados; Owner: empresa_owner
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT pk_empleado PRIMARY KEY (id_empleado);


--
-- TOC entry 5217 (class 2606 OID 22771)
-- Name: tipo_contrato tipo_contrato_nombre_key; Type: CONSTRAINT; Schema: empleados; Owner: empresa_owner
--

ALTER TABLE ONLY empleados.tipo_contrato
    ADD CONSTRAINT tipo_contrato_nombre_key UNIQUE (nombre);


--
-- TOC entry 5219 (class 2606 OID 22773)
-- Name: tipo_contrato tipo_contrato_pkey; Type: CONSTRAINT; Schema: empleados; Owner: empresa_owner
--

ALTER TABLE ONLY empleados.tipo_contrato
    ADD CONSTRAINT tipo_contrato_pkey PRIMARY KEY (id_tipo_contrato);


--
-- TOC entry 5213 (class 2606 OID 22775)
-- Name: empleado uq_empleado_id_empleado; Type: CONSTRAINT; Schema: empleados; Owner: empresa_owner
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT uq_empleado_id_empleado UNIQUE (id_empleado);


--
-- TOC entry 5215 (class 2606 OID 22777)
-- Name: empleado uq_empleado_persona; Type: CONSTRAINT; Schema: empleados; Owner: empresa_owner
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT uq_empleado_persona UNIQUE (id_persona);


--
-- TOC entry 5221 (class 2606 OID 22779)
-- Name: documento_empresa documento_empresa_pkey; Type: CONSTRAINT; Schema: empresa; Owner: empresa_owner
--

ALTER TABLE ONLY empresa.documento_empresa
    ADD CONSTRAINT documento_empresa_pkey PRIMARY KEY (id_documento);


--
-- TOC entry 5225 (class 2606 OID 22781)
-- Name: empresa empresa_pkey; Type: CONSTRAINT; Schema: empresa; Owner: empresa_owner
--

ALTER TABLE ONLY empresa.empresa
    ADD CONSTRAINT empresa_pkey PRIMARY KEY (id_empresa);


--
-- TOC entry 5227 (class 2606 OID 22783)
-- Name: empresa empresa_ruc_key; Type: CONSTRAINT; Schema: empresa; Owner: empresa_owner
--

ALTER TABLE ONLY empresa.empresa
    ADD CONSTRAINT empresa_ruc_key UNIQUE (ruc);


--
-- TOC entry 5229 (class 2606 OID 22785)
-- Name: empresa_servicio empresa_servicio_pkey; Type: CONSTRAINT; Schema: empresa; Owner: empresa_owner
--

ALTER TABLE ONLY empresa.empresa_servicio
    ADD CONSTRAINT empresa_servicio_pkey PRIMARY KEY (id_empresa, id_servicio);


--
-- TOC entry 5280 (class 2606 OID 23293)
-- Name: servicio servicio_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.servicio
    ADD CONSTRAINT servicio_pkey PRIMARY KEY (id_servicio);


--
-- TOC entry 5231 (class 2606 OID 22787)
-- Name: sucursal sucursal_pkey; Type: CONSTRAINT; Schema: empresa; Owner: empresa_owner
--

ALTER TABLE ONLY empresa.sucursal
    ADD CONSTRAINT sucursal_pkey PRIMARY KEY (id_sucursal);


--
-- TOC entry 5282 (class 2606 OID 23295)
-- Name: servicio uk_5sp1r1csf8w09psuq7p8fatbs; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.servicio
    ADD CONSTRAINT uk_5sp1r1csf8w09psuq7p8fatbs UNIQUE (nombre);


--
-- TOC entry 5223 (class 2606 OID 22789)
-- Name: documento_empresa uq_documento_empresa; Type: CONSTRAINT; Schema: empresa; Owner: empresa_owner
--

ALTER TABLE ONLY empresa.documento_empresa
    ADD CONSTRAINT uq_documento_empresa UNIQUE (id_tipo_documento, numero_documento);


--
-- TOC entry 5233 (class 2606 OID 22791)
-- Name: canal_notificacion canal_notificacion_pkey; Type: CONSTRAINT; Schema: notificaciones; Owner: empresa_owner
--

ALTER TABLE ONLY notificaciones.canal_notificacion
    ADD CONSTRAINT canal_notificacion_pkey PRIMARY KEY (id_canal);


--
-- TOC entry 5237 (class 2606 OID 22793)
-- Name: notificacion notificacion_pkey; Type: CONSTRAINT; Schema: notificaciones; Owner: empresa_owner
--

ALTER TABLE ONLY notificaciones.notificacion
    ADD CONSTRAINT notificacion_pkey PRIMARY KEY (id_notificacion);


--
-- TOC entry 5235 (class 2606 OID 22795)
-- Name: canal_notificacion uq_canal_nombre; Type: CONSTRAINT; Schema: notificaciones; Owner: empresa_owner
--

ALTER TABLE ONLY notificaciones.canal_notificacion
    ADD CONSTRAINT uq_canal_nombre UNIQUE (nombre);


--
-- TOC entry 5239 (class 2606 OID 22797)
-- Name: asignacion asignacion_pkey; Type: CONSTRAINT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.asignacion
    ADD CONSTRAINT asignacion_pkey PRIMARY KEY (id_asignacion);


--
-- TOC entry 5284 (class 2606 OID 23307)
-- Name: categoria categoria_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.categoria
    ADD CONSTRAINT categoria_pkey PRIMARY KEY (id_categoria);


--
-- TOC entry 5242 (class 2606 OID 22799)
-- Name: comentario_ticket comentario_ticket_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket
    ADD CONSTRAINT comentario_ticket_pkey PRIMARY KEY (id_comentario);


--
-- TOC entry 5244 (class 2606 OID 22801)
-- Name: documento_ticket documento_ticket_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.documento_ticket
    ADD CONSTRAINT documento_ticket_pkey PRIMARY KEY (id_documento);


--
-- TOC entry 5246 (class 2606 OID 22803)
-- Name: historial_estado historial_estado_pkey; Type: CONSTRAINT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT historial_estado_pkey PRIMARY KEY (id_historial);


--
-- TOC entry 5288 (class 2606 OID 23322)
-- Name: prioridad prioridad_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.prioridad
    ADD CONSTRAINT prioridad_pkey PRIMARY KEY (id_prioridad);


--
-- TOC entry 5248 (class 2606 OID 22805)
-- Name: sla_ticket sla_ticket_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.sla_ticket
    ADD CONSTRAINT sla_ticket_pkey PRIMARY KEY (id_sla);


--
-- TOC entry 5250 (class 2606 OID 22807)
-- Name: solucion_ticket solucion_ticket_id_ticket_key; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.solucion_ticket
    ADD CONSTRAINT solucion_ticket_id_ticket_key UNIQUE (id_ticket);


--
-- TOC entry 5252 (class 2606 OID 22809)
-- Name: solucion_ticket solucion_ticket_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.solucion_ticket
    ADD CONSTRAINT solucion_ticket_pkey PRIMARY KEY (id_solucion);


--
-- TOC entry 5254 (class 2606 OID 22811)
-- Name: ticket ticket_pkey; Type: CONSTRAINT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT ticket_pkey PRIMARY KEY (id_ticket);


--
-- TOC entry 5286 (class 2606 OID 23325)
-- Name: categoria uk_35t4wyxqrevf09uwx9e9p6o75; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.categoria
    ADD CONSTRAINT uk_35t4wyxqrevf09uwx9e9p6o75 UNIQUE (nombre);


--
-- TOC entry 5290 (class 2606 OID 23327)
-- Name: prioridad uk_a578rljygcxqa65srjnxib9le; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.prioridad
    ADD CONSTRAINT uk_a578rljygcxqa65srjnxib9le UNIQUE (nombre);


--
-- TOC entry 5256 (class 2606 OID 22813)
-- Name: persona persona_cedula_key; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.persona
    ADD CONSTRAINT persona_cedula_key UNIQUE (cedula);


--
-- TOC entry 5258 (class 2606 OID 22815)
-- Name: persona persona_id_usuario_key; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.persona
    ADD CONSTRAINT persona_id_usuario_key UNIQUE (id_usuario);


--
-- TOC entry 5260 (class 2606 OID 22817)
-- Name: persona persona_pkey; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.persona
    ADD CONSTRAINT persona_pkey PRIMARY KEY (id_persona);


--
-- TOC entry 5266 (class 2606 OID 22819)
-- Name: rol_bd rol_bd_nombre_key; Type: CONSTRAINT; Schema: usuarios; Owner: empresa_owner
--

ALTER TABLE ONLY usuarios.rol_bd
    ADD CONSTRAINT rol_bd_nombre_key UNIQUE (nombre);


--
-- TOC entry 5268 (class 2606 OID 22821)
-- Name: rol_bd rol_bd_pkey; Type: CONSTRAINT; Schema: usuarios; Owner: empresa_owner
--

ALTER TABLE ONLY usuarios.rol_bd
    ADD CONSTRAINT rol_bd_pkey PRIMARY KEY (id_rol_bd);


--
-- TOC entry 5262 (class 2606 OID 22823)
-- Name: rol rol_codigo_key; Type: CONSTRAINT; Schema: usuarios; Owner: empresa_owner
--

ALTER TABLE ONLY usuarios.rol
    ADD CONSTRAINT rol_codigo_key UNIQUE (codigo);


--
-- TOC entry 5264 (class 2606 OID 22825)
-- Name: rol rol_pkey; Type: CONSTRAINT; Schema: usuarios; Owner: empresa_owner
--

ALTER TABLE ONLY usuarios.rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id_rol);


--
-- TOC entry 5270 (class 2606 OID 23329)
-- Name: usuario uk863n1y3x0jalatoir4325ehal; Type: CONSTRAINT; Schema: usuarios; Owner: empresa_owner
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT uk863n1y3x0jalatoir4325ehal UNIQUE (username);


--
-- TOC entry 5276 (class 2606 OID 22827)
-- Name: usuario_bd usuario_bd_nombre_key; Type: CONSTRAINT; Schema: usuarios; Owner: empresa_owner
--

ALTER TABLE ONLY usuarios.usuario_bd
    ADD CONSTRAINT usuario_bd_nombre_key UNIQUE (nombre);


--
-- TOC entry 5278 (class 2606 OID 22829)
-- Name: usuario_bd usuario_bd_pkey; Type: CONSTRAINT; Schema: usuarios; Owner: empresa_owner
--

ALTER TABLE ONLY usuarios.usuario_bd
    ADD CONSTRAINT usuario_bd_pkey PRIMARY KEY (id_usuario_bd);


--
-- TOC entry 5272 (class 2606 OID 22831)
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: usuarios; Owner: empresa_owner
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id_usuario);


--
-- TOC entry 5274 (class 2606 OID 22833)
-- Name: usuario usuario_username_key; Type: CONSTRAINT; Schema: usuarios; Owner: empresa_owner
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT usuario_username_key UNIQUE (username);


--
-- TOC entry 5240 (class 1259 OID 22834)
-- Name: uq_asignacion_activa; Type: INDEX; Schema: soporte; Owner: empresa_owner
--

CREATE UNIQUE INDEX uq_asignacion_activa ON soporte.asignacion USING btree (id_ticket) WHERE (activo = true);


--
-- TOC entry 5291 (class 2606 OID 22835)
-- Name: auditoria_estado_ticket fk_aud_estado_ant; Type: FK CONSTRAINT; Schema: auditoria; Owner: empresa_owner
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_aud_estado_ant FOREIGN KEY (id_estado_anterior) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5299 (class 2606 OID 22840)
-- Name: auditoria_login fk_aud_login_usuario; Type: FK CONSTRAINT; Schema: auditoria; Owner: empresa_owner
--

ALTER TABLE ONLY auditoria.auditoria_login
    ADD CONSTRAINT fk_aud_login_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 5297 (class 2606 OID 22845)
-- Name: auditoria_evento fk_auditoria_accion; Type: FK CONSTRAINT; Schema: auditoria; Owner: empresa_owner
--

ALTER TABLE ONLY auditoria.auditoria_evento
    ADD CONSTRAINT fk_auditoria_accion FOREIGN KEY (id_accion_item) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5292 (class 2606 OID 22850)
-- Name: auditoria_estado_ticket fk_auditoria_estado_ticket; Type: FK CONSTRAINT; Schema: auditoria; Owner: empresa_owner
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_auditoria_estado_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 5293 (class 2606 OID 22855)
-- Name: auditoria_estado_ticket fk_auditoria_estado_ticket_estado; Type: FK CONSTRAINT; Schema: auditoria; Owner: empresa_owner
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_auditoria_estado_ticket_estado FOREIGN KEY (id_estado_nuevo_item) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5294 (class 2606 OID 22860)
-- Name: auditoria_estado_ticket fk_auditoria_estado_ticket_evento; Type: FK CONSTRAINT; Schema: auditoria; Owner: empresa_owner
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_auditoria_estado_ticket_evento FOREIGN KEY (id_item_evento) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5295 (class 2606 OID 22865)
-- Name: auditoria_estado_ticket fk_auditoria_estado_ticket_ticket; Type: FK CONSTRAINT; Schema: auditoria; Owner: empresa_owner
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_auditoria_estado_ticket_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5296 (class 2606 OID 22870)
-- Name: auditoria_estado_ticket fk_auditoria_estado_ticket_usuario; Type: FK CONSTRAINT; Schema: auditoria; Owner: empresa_owner
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_auditoria_estado_ticket_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5302 (class 2606 OID 22875)
-- Name: auditoria_login_bd fk_auditoria_login_bd_evento; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd
    ADD CONSTRAINT fk_auditoria_login_bd_evento FOREIGN KEY (id_item_evento) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5303 (class 2606 OID 22880)
-- Name: auditoria_login_bd fk_auditoria_login_bd_usuario; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd
    ADD CONSTRAINT fk_auditoria_login_bd_usuario FOREIGN KEY (id_usuario_bd) REFERENCES usuarios.usuario_bd(id_usuario_bd) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5304 (class 2606 OID 22885)
-- Name: auditoria_login_bd fk_auditoria_login_bd_usuario_bd; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd
    ADD CONSTRAINT fk_auditoria_login_bd_usuario_bd FOREIGN KEY (id_usuario_bd) REFERENCES usuarios.usuario_bd(id_usuario_bd) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5300 (class 2606 OID 22890)
-- Name: auditoria_login fk_auditoria_login_evento; Type: FK CONSTRAINT; Schema: auditoria; Owner: empresa_owner
--

ALTER TABLE ONLY auditoria.auditoria_login
    ADD CONSTRAINT fk_auditoria_login_evento FOREIGN KEY (id_item_evento) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5301 (class 2606 OID 22895)
-- Name: auditoria_login fk_auditoria_login_usuario; Type: FK CONSTRAINT; Schema: auditoria; Owner: empresa_owner
--

ALTER TABLE ONLY auditoria.auditoria_login
    ADD CONSTRAINT fk_auditoria_login_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5298 (class 2606 OID 22900)
-- Name: auditoria_evento fk_auditoria_usuario; Type: FK CONSTRAINT; Schema: auditoria; Owner: empresa_owner
--

ALTER TABLE ONLY auditoria.auditoria_evento
    ADD CONSTRAINT fk_auditoria_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 5305 (class 2606 OID 22905)
-- Name: auditoria_login_bd fk_login_bd_evento; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd
    ADD CONSTRAINT fk_login_bd_evento FOREIGN KEY (id_item_evento) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5306 (class 2606 OID 22910)
-- Name: catalogo_item catalogo_item_id_catalogo_fkey; Type: FK CONSTRAINT; Schema: catalogos; Owner: empresa_owner
--

ALTER TABLE ONLY catalogos.catalogo_item
    ADD CONSTRAINT catalogo_item_id_catalogo_fkey FOREIGN KEY (id_catalogo) REFERENCES catalogos.catalogo(id_catalogo);


--
-- TOC entry 5307 (class 2606 OID 22915)
-- Name: canton fk_canton_ciudad; Type: FK CONSTRAINT; Schema: clientes; Owner: empresa_owner
--

ALTER TABLE ONLY clientes.canton
    ADD CONSTRAINT fk_canton_ciudad FOREIGN KEY (id_ciudad) REFERENCES clientes.ciudad(id_ciudad);


--
-- TOC entry 5308 (class 2606 OID 22920)
-- Name: ciudad fk_ciudad_pais; Type: FK CONSTRAINT; Schema: clientes; Owner: empresa_owner
--

ALTER TABLE ONLY clientes.ciudad
    ADD CONSTRAINT fk_ciudad_pais FOREIGN KEY (id_pais) REFERENCES clientes.pais(id_pais);


--
-- TOC entry 5309 (class 2606 OID 22925)
-- Name: cliente fk_cliente_persona; Type: FK CONSTRAINT; Schema: clientes; Owner: empresa_owner
--

ALTER TABLE ONLY clientes.cliente
    ADD CONSTRAINT fk_cliente_persona FOREIGN KEY (id_persona) REFERENCES usuarios.persona(id_persona) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5310 (class 2606 OID 22930)
-- Name: cliente fk_cliente_sucursal; Type: FK CONSTRAINT; Schema: clientes; Owner: empresa_owner
--

ALTER TABLE ONLY clientes.cliente
    ADD CONSTRAINT fk_cliente_sucursal FOREIGN KEY (id_sucursal) REFERENCES empresa.sucursal(id_sucursal);


--
-- TOC entry 5311 (class 2606 OID 23248)
-- Name: documento_cliente fk_doc_cli_estado; Type: FK CONSTRAINT; Schema: clientes; Owner: empresa_owner
--

ALTER TABLE ONLY clientes.documento_cliente
    ADD CONSTRAINT fk_doc_cli_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5312 (class 2606 OID 22940)
-- Name: documento_cliente fk_documento_cliente_cliente; Type: FK CONSTRAINT; Schema: clientes; Owner: empresa_owner
--

ALTER TABLE ONLY clientes.documento_cliente
    ADD CONSTRAINT fk_documento_cliente_cliente FOREIGN KEY (id_cliente) REFERENCES clientes.cliente(id_cliente);


--
-- TOC entry 5313 (class 2606 OID 22945)
-- Name: documento_cliente fk_documento_tipo; Type: FK CONSTRAINT; Schema: clientes; Owner: empresa_owner
--

ALTER TABLE ONLY clientes.documento_cliente
    ADD CONSTRAINT fk_documento_tipo FOREIGN KEY (id_tipo_documento) REFERENCES clientes.tipo_documento(id_tipo_documento);


--
-- TOC entry 5314 (class 2606 OID 23261)
-- Name: documento_empleado fk_doc_emp_estado; Type: FK CONSTRAINT; Schema: empleados; Owner: empresa_owner
--

ALTER TABLE ONLY empleados.documento_empleado
    ADD CONSTRAINT fk_doc_emp_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5315 (class 2606 OID 23272)
-- Name: documento_empleado fk_doc_emp_tipo_documento; Type: FK CONSTRAINT; Schema: empleados; Owner: empresa_owner
--

ALTER TABLE ONLY empleados.documento_empleado
    ADD CONSTRAINT fk_doc_emp_tipo_documento FOREIGN KEY (id_tipo_documento) REFERENCES clientes.tipo_documento(id_tipo_documento);


--
-- TOC entry 5316 (class 2606 OID 22960)
-- Name: documento_empleado fk_documento_empleado_empleado; Type: FK CONSTRAINT; Schema: empleados; Owner: empresa_owner
--

ALTER TABLE ONLY empleados.documento_empleado
    ADD CONSTRAINT fk_documento_empleado_empleado FOREIGN KEY (id_empleado) REFERENCES empleados.empleado(id_empleado);


--
-- TOC entry 5317 (class 2606 OID 22965)
-- Name: empleado fk_empleado_area; Type: FK CONSTRAINT; Schema: empleados; Owner: empresa_owner
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT fk_empleado_area FOREIGN KEY (id_area) REFERENCES empleados.area(id_area);


--
-- TOC entry 5318 (class 2606 OID 22970)
-- Name: empleado fk_empleado_cargo; Type: FK CONSTRAINT; Schema: empleados; Owner: empresa_owner
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT fk_empleado_cargo FOREIGN KEY (id_cargo) REFERENCES empleados.cargo(id_cargo);


--
-- TOC entry 5319 (class 2606 OID 22975)
-- Name: empleado fk_empleado_persona; Type: FK CONSTRAINT; Schema: empleados; Owner: empresa_owner
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT fk_empleado_persona FOREIGN KEY (id_persona) REFERENCES usuarios.persona(id_persona) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5320 (class 2606 OID 22980)
-- Name: empleado fk_empleado_sucursal; Type: FK CONSTRAINT; Schema: empleados; Owner: empresa_owner
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT fk_empleado_sucursal FOREIGN KEY (id_sucursal) REFERENCES empresa.sucursal(id_sucursal);


--
-- TOC entry 5321 (class 2606 OID 22985)
-- Name: empleado fk_empleado_tipo_contrato_catalogo; Type: FK CONSTRAINT; Schema: empleados; Owner: empresa_owner
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT fk_empleado_tipo_contrato_catalogo FOREIGN KEY (id_tipo_contrato) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5322 (class 2606 OID 22990)
-- Name: documento_empresa documento_empresa_id_empresa_fkey; Type: FK CONSTRAINT; Schema: empresa; Owner: empresa_owner
--

ALTER TABLE ONLY empresa.documento_empresa
    ADD CONSTRAINT documento_empresa_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa);


--
-- TOC entry 5327 (class 2606 OID 23330)
-- Name: empresa_servicio fk4v8ptw3ao3v85rsfvpm19cjpx; Type: FK CONSTRAINT; Schema: empresa; Owner: empresa_owner
--

ALTER TABLE ONLY empresa.empresa_servicio
    ADD CONSTRAINT fk4v8ptw3ao3v85rsfvpm19cjpx FOREIGN KEY (id_servicio) REFERENCES empresa.servicio(id_servicio);


--
-- TOC entry 5323 (class 2606 OID 22995)
-- Name: documento_empresa fk_doc_empresa_estado; Type: FK CONSTRAINT; Schema: empresa; Owner: empresa_owner
--

ALTER TABLE ONLY empresa.documento_empresa
    ADD CONSTRAINT fk_doc_empresa_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5324 (class 2606 OID 23000)
-- Name: documento_empresa fk_documento_empresa_tipo_documento; Type: FK CONSTRAINT; Schema: empresa; Owner: empresa_owner
--

ALTER TABLE ONLY empresa.documento_empresa
    ADD CONSTRAINT fk_documento_empresa_tipo_documento FOREIGN KEY (id_tipo_documento) REFERENCES clientes.tipo_documento(id_tipo_documento);


--
-- TOC entry 5325 (class 2606 OID 23005)
-- Name: empresa fk_empresa_estado; Type: FK CONSTRAINT; Schema: empresa; Owner: empresa_owner
--

ALTER TABLE ONLY empresa.empresa
    ADD CONSTRAINT fk_empresa_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5326 (class 2606 OID 23010)
-- Name: empresa fk_empresa_tipo; Type: FK CONSTRAINT; Schema: empresa; Owner: empresa_owner
--

ALTER TABLE ONLY empresa.empresa
    ADD CONSTRAINT fk_empresa_tipo FOREIGN KEY (id_catalogo_item_tipo_empresa) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5328 (class 2606 OID 23015)
-- Name: empresa_servicio fk_es_empresa; Type: FK CONSTRAINT; Schema: empresa; Owner: empresa_owner
--

ALTER TABLE ONLY empresa.empresa_servicio
    ADD CONSTRAINT fk_es_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa);


--
-- TOC entry 5329 (class 2606 OID 23020)
-- Name: sucursal fk_sucursal_canton; Type: FK CONSTRAINT; Schema: empresa; Owner: empresa_owner
--

ALTER TABLE ONLY empresa.sucursal
    ADD CONSTRAINT fk_sucursal_canton FOREIGN KEY (id_canton) REFERENCES clientes.canton(id_canton);


--
-- TOC entry 5330 (class 2606 OID 23025)
-- Name: sucursal fk_sucursal_ciudad; Type: FK CONSTRAINT; Schema: empresa; Owner: empresa_owner
--

ALTER TABLE ONLY empresa.sucursal
    ADD CONSTRAINT fk_sucursal_ciudad FOREIGN KEY (id_ciudad) REFERENCES clientes.ciudad(id_ciudad);


--
-- TOC entry 5331 (class 2606 OID 23030)
-- Name: sucursal fk_sucursal_empresa; Type: FK CONSTRAINT; Schema: empresa; Owner: empresa_owner
--

ALTER TABLE ONLY empresa.sucursal
    ADD CONSTRAINT fk_sucursal_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa);


--
-- TOC entry 5332 (class 2606 OID 23035)
-- Name: sucursal fk_sucursal_estado; Type: FK CONSTRAINT; Schema: empresa; Owner: empresa_owner
--

ALTER TABLE ONLY empresa.sucursal
    ADD CONSTRAINT fk_sucursal_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5333 (class 2606 OID 23040)
-- Name: notificacion fk_notificacion_empresa; Type: FK CONSTRAINT; Schema: notificaciones; Owner: empresa_owner
--

ALTER TABLE ONLY notificaciones.notificacion
    ADD CONSTRAINT fk_notificacion_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5334 (class 2606 OID 23045)
-- Name: notificacion fk_notificacion_ticket; Type: FK CONSTRAINT; Schema: notificaciones; Owner: empresa_owner
--

ALTER TABLE ONLY notificaciones.notificacion
    ADD CONSTRAINT fk_notificacion_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 5335 (class 2606 OID 23050)
-- Name: notificacion fk_notificacion_tipo; Type: FK CONSTRAINT; Schema: notificaciones; Owner: empresa_owner
--

ALTER TABLE ONLY notificaciones.notificacion
    ADD CONSTRAINT fk_notificacion_tipo FOREIGN KEY (id_tipo_notificacion) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5336 (class 2606 OID 23055)
-- Name: notificacion fk_notificacion_usuario; Type: FK CONSTRAINT; Schema: notificaciones; Owner: empresa_owner
--

ALTER TABLE ONLY notificaciones.notificacion
    ADD CONSTRAINT fk_notificacion_usuario FOREIGN KEY (id_usuario_destino) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 5337 (class 2606 OID 23060)
-- Name: notificacion fk_notificacion_usuario_origen; Type: FK CONSTRAINT; Schema: notificaciones; Owner: empresa_owner
--

ALTER TABLE ONLY notificaciones.notificacion
    ADD CONSTRAINT fk_notificacion_usuario_origen FOREIGN KEY (id_usuario_origen) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 5338 (class 2606 OID 23065)
-- Name: notificacion notificacion_id_canal_fkey; Type: FK CONSTRAINT; Schema: notificaciones; Owner: empresa_owner
--

ALTER TABLE ONLY notificaciones.notificacion
    ADD CONSTRAINT notificacion_id_canal_fkey FOREIGN KEY (id_canal) REFERENCES notificaciones.canal_notificacion(id_canal);


--
-- TOC entry 5360 (class 2606 OID 23360)
-- Name: ticket fk81l25qsiooc520ve4sm69chsy; Type: FK CONSTRAINT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk81l25qsiooc520ve4sm69chsy FOREIGN KEY (id_servicio) REFERENCES empresa.servicio(id_servicio);


--
-- TOC entry 5349 (class 2606 OID 23345)
-- Name: historial_estado fk86k65nur98avxs6ac5ue2sgj; Type: FK CONSTRAINT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk86k65nur98avxs6ac5ue2sgj FOREIGN KEY (id_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5339 (class 2606 OID 23070)
-- Name: asignacion fk_asignacion_ticket; Type: FK CONSTRAINT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.asignacion
    ADD CONSTRAINT fk_asignacion_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 5340 (class 2606 OID 23075)
-- Name: asignacion fk_asignacion_usuario; Type: FK CONSTRAINT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.asignacion
    ADD CONSTRAINT fk_asignacion_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5341 (class 2606 OID 23080)
-- Name: comentario_ticket fk_com_estado; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket
    ADD CONSTRAINT fk_com_estado FOREIGN KEY (id_estado_item) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5342 (class 2606 OID 23085)
-- Name: comentario_ticket fk_com_ticket; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket
    ADD CONSTRAINT fk_com_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket) ON DELETE CASCADE;


--
-- TOC entry 5343 (class 2606 OID 23090)
-- Name: comentario_ticket fk_com_usuario; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket
    ADD CONSTRAINT fk_com_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 5345 (class 2606 OID 23095)
-- Name: documento_ticket fk_doc_estado; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.documento_ticket
    ADD CONSTRAINT fk_doc_estado FOREIGN KEY (id_estado_item) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5346 (class 2606 OID 23100)
-- Name: documento_ticket fk_doc_ticket; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.documento_ticket
    ADD CONSTRAINT fk_doc_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket) ON DELETE CASCADE;


--
-- TOC entry 5347 (class 2606 OID 23105)
-- Name: documento_ticket fk_doc_tipo; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.documento_ticket
    ADD CONSTRAINT fk_doc_tipo FOREIGN KEY (id_tipo_documento_item) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5348 (class 2606 OID 23110)
-- Name: documento_ticket fk_doc_usuario; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.documento_ticket
    ADD CONSTRAINT fk_doc_usuario FOREIGN KEY (id_usuario_subio) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 5350 (class 2606 OID 23115)
-- Name: historial_estado fk_hist_estado_anterior; Type: FK CONSTRAINT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_hist_estado_anterior FOREIGN KEY (id_estado_anterior) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5351 (class 2606 OID 23120)
-- Name: historial_estado fk_hist_estado_nuevo; Type: FK CONSTRAINT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_hist_estado_nuevo FOREIGN KEY (id_estado_nuevo) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5352 (class 2606 OID 23125)
-- Name: historial_estado fk_historial_estado_anterior; Type: FK CONSTRAINT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_historial_estado_anterior FOREIGN KEY (id_estado_anterior) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5353 (class 2606 OID 23130)
-- Name: historial_estado fk_historial_estado_nuevo; Type: FK CONSTRAINT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_historial_estado_nuevo FOREIGN KEY (id_estado_nuevo) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5354 (class 2606 OID 23135)
-- Name: historial_estado fk_historial_ticket; Type: FK CONSTRAINT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_historial_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 5355 (class 2606 OID 23140)
-- Name: historial_estado fk_historial_usuario; Type: FK CONSTRAINT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_historial_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5356 (class 2606 OID 23145)
-- Name: sla_ticket fk_sla_prioridad; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.sla_ticket
    ADD CONSTRAINT fk_sla_prioridad FOREIGN KEY (aplica_prioridad) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5361 (class 2606 OID 23150)
-- Name: ticket fk_ticket_categoria_item; Type: FK CONSTRAINT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_categoria_item FOREIGN KEY (id_categoria_item) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5362 (class 2606 OID 23155)
-- Name: ticket fk_ticket_cliente; Type: FK CONSTRAINT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_cliente FOREIGN KEY (id_cliente) REFERENCES clientes.cliente(id_cliente);


--
-- TOC entry 5363 (class 2606 OID 23160)
-- Name: ticket fk_ticket_estado_item; Type: FK CONSTRAINT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_estado_item FOREIGN KEY (id_estado_item) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5364 (class 2606 OID 23165)
-- Name: ticket fk_ticket_prioridad_item; Type: FK CONSTRAINT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_prioridad_item FOREIGN KEY (id_prioridad_item) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5365 (class 2606 OID 23170)
-- Name: ticket fk_ticket_sla; Type: FK CONSTRAINT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_sla FOREIGN KEY (id_sla) REFERENCES soporte.sla_ticket(id_sla);


--
-- TOC entry 5366 (class 2606 OID 23175)
-- Name: ticket fk_ticket_sucursal; Type: FK CONSTRAINT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_sucursal FOREIGN KEY (id_sucursal) REFERENCES empresa.sucursal(id_sucursal);


--
-- TOC entry 5367 (class 2606 OID 23180)
-- Name: ticket fk_ticket_usuario_asignado; Type: FK CONSTRAINT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_usuario_asignado FOREIGN KEY (id_usuario_asignado) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 5368 (class 2606 OID 23185)
-- Name: ticket fk_ticket_usuario_creador; Type: FK CONSTRAINT; Schema: soporte; Owner: empresa_owner
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_usuario_creador FOREIGN KEY (id_usuario_creador) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5344 (class 2606 OID 23340)
-- Name: comentario_ticket fkbv5gyaxos7jsns8fsucflndds; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket
    ADD CONSTRAINT fkbv5gyaxos7jsns8fsucflndds FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa);


--
-- TOC entry 5378 (class 2606 OID 23350)
-- Name: prioridad fkcnj24dfocilmvv1yyfjxf89gd; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.prioridad
    ADD CONSTRAINT fkcnj24dfocilmvv1yyfjxf89gd FOREIGN KEY (id_item) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5377 (class 2606 OID 23335)
-- Name: categoria fke27el05povf1kt0jl2811tm7r; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.categoria
    ADD CONSTRAINT fke27el05povf1kt0jl2811tm7r FOREIGN KEY (id_item) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5357 (class 2606 OID 23355)
-- Name: sla_ticket fkm9bsgtiqm9fcxfjnewil1mgdw; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.sla_ticket
    ADD CONSTRAINT fkm9bsgtiqm9fcxfjnewil1mgdw FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa);


--
-- TOC entry 5358 (class 2606 OID 23190)
-- Name: solucion_ticket solucion_ticket_id_ticket_fkey; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.solucion_ticket
    ADD CONSTRAINT solucion_ticket_id_ticket_fkey FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 5359 (class 2606 OID 23195)
-- Name: solucion_ticket solucion_ticket_id_usuario_tecnico_fkey; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.solucion_ticket
    ADD CONSTRAINT solucion_ticket_id_usuario_tecnico_fkey FOREIGN KEY (id_usuario_tecnico) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 5369 (class 2606 OID 23200)
-- Name: persona fk_persona_canton; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.persona
    ADD CONSTRAINT fk_persona_canton FOREIGN KEY (id_canton) REFERENCES clientes.canton(id_canton);


--
-- TOC entry 5370 (class 2606 OID 23205)
-- Name: persona fk_persona_usuario; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.persona
    ADD CONSTRAINT fk_persona_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 5374 (class 2606 OID 23210)
-- Name: usuario_bd fk_usuario_bd_rol; Type: FK CONSTRAINT; Schema: usuarios; Owner: empresa_owner
--

ALTER TABLE ONLY usuarios.usuario_bd
    ADD CONSTRAINT fk_usuario_bd_rol FOREIGN KEY (id_rol_bd) REFERENCES usuarios.rol_bd(id_rol_bd);


--
-- TOC entry 5375 (class 2606 OID 23215)
-- Name: usuario_bd fk_usuario_bd_rol_bd; Type: FK CONSTRAINT; Schema: usuarios; Owner: empresa_owner
--

ALTER TABLE ONLY usuarios.usuario_bd
    ADD CONSTRAINT fk_usuario_bd_rol_bd FOREIGN KEY (id_rol_bd) REFERENCES usuarios.rol_bd(id_rol_bd) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5376 (class 2606 OID 23220)
-- Name: usuario_bd fk_usuario_bd_usuario; Type: FK CONSTRAINT; Schema: usuarios; Owner: empresa_owner
--

ALTER TABLE ONLY usuarios.usuario_bd
    ADD CONSTRAINT fk_usuario_bd_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON DELETE CASCADE;


--
-- TOC entry 5371 (class 2606 OID 23225)
-- Name: usuario fk_usuario_empresa; Type: FK CONSTRAINT; Schema: usuarios; Owner: empresa_owner
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT fk_usuario_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5372 (class 2606 OID 23230)
-- Name: usuario fk_usuario_estado; Type: FK CONSTRAINT; Schema: usuarios; Owner: empresa_owner
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT fk_usuario_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5373 (class 2606 OID 23235)
-- Name: usuario fk_usuario_rol; Type: FK CONSTRAINT; Schema: usuarios; Owner: empresa_owner
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT fk_usuario_rol FOREIGN KEY (id_rol) REFERENCES usuarios.rol(id_rol);


--
-- TOC entry 5606 (class 0 OID 0)
-- Dependencies: 12
-- Name: SCHEMA clientes; Type: ACL; Schema: -; Owner: empresa_owner
--

GRANT USAGE ON SCHEMA clientes TO rol_cliente;
GRANT USAGE ON SCHEMA clientes TO rol_tecnico;
GRANT USAGE ON SCHEMA clientes TO rol_admin_tecnicos;
GRANT USAGE ON SCHEMA clientes TO rol_admin_master;
GRANT USAGE ON SCHEMA clientes TO rol_admin_visual;


--
-- TOC entry 5607 (class 0 OID 0)
-- Dependencies: 13
-- Name: SCHEMA empleados; Type: ACL; Schema: -; Owner: empresa_owner
--

GRANT USAGE ON SCHEMA empleados TO rol_tecnico;
GRANT USAGE ON SCHEMA empleados TO rol_admin_tecnicos;
GRANT USAGE ON SCHEMA empleados TO rol_admin_master;


--
-- TOC entry 5608 (class 0 OID 0)
-- Dependencies: 14
-- Name: SCHEMA usuarios; Type: ACL; Schema: -; Owner: empresa_owner
--

GRANT USAGE ON SCHEMA usuarios TO rol_admin_master;


--
-- TOC entry 5616 (class 0 OID 0)
-- Dependencies: 240
-- Name: TABLE canton; Type: ACL; Schema: clientes; Owner: empresa_owner
--

GRANT SELECT ON TABLE clientes.canton TO rol_cliente;
GRANT ALL ON TABLE clientes.canton TO rol_admin_master;
GRANT SELECT ON TABLE clientes.canton TO rol_admin_visual;


--
-- TOC entry 5618 (class 0 OID 0)
-- Dependencies: 242
-- Name: TABLE ciudad; Type: ACL; Schema: clientes; Owner: empresa_owner
--

GRANT SELECT ON TABLE clientes.ciudad TO rol_cliente;
GRANT ALL ON TABLE clientes.ciudad TO rol_admin_master;
GRANT SELECT ON TABLE clientes.ciudad TO rol_admin_visual;


--
-- TOC entry 5620 (class 0 OID 0)
-- Dependencies: 244
-- Name: TABLE cliente; Type: ACL; Schema: clientes; Owner: empresa_owner
--

GRANT SELECT ON TABLE clientes.cliente TO rol_cliente;
GRANT SELECT ON TABLE clientes.cliente TO rol_tecnico;
GRANT SELECT ON TABLE clientes.cliente TO rol_admin_tecnicos;
GRANT ALL ON TABLE clientes.cliente TO rol_admin_master;
GRANT SELECT ON TABLE clientes.cliente TO rol_admin_visual;


--
-- TOC entry 5622 (class 0 OID 0)
-- Dependencies: 246
-- Name: TABLE documento_cliente; Type: ACL; Schema: clientes; Owner: empresa_owner
--

GRANT SELECT ON TABLE clientes.documento_cliente TO rol_cliente;


--
-- TOC entry 5624 (class 0 OID 0)
-- Dependencies: 248
-- Name: TABLE pais; Type: ACL; Schema: clientes; Owner: empresa_owner
--

GRANT SELECT ON TABLE clientes.pais TO rol_cliente;
GRANT ALL ON TABLE clientes.pais TO rol_admin_master;
GRANT SELECT ON TABLE clientes.pais TO rol_admin_visual;


--
-- TOC entry 5626 (class 0 OID 0)
-- Dependencies: 250
-- Name: TABLE tipo_documento; Type: ACL; Schema: clientes; Owner: postgres
--

GRANT SELECT ON TABLE clientes.tipo_documento TO rol_cliente;


--
-- TOC entry 5628 (class 0 OID 0)
-- Dependencies: 252
-- Name: TABLE area; Type: ACL; Schema: empleados; Owner: empresa_owner
--

GRANT ALL ON TABLE empleados.area TO rol_admin_master;
GRANT SELECT ON TABLE empleados.area TO rol_admin_visual;


--
-- TOC entry 5630 (class 0 OID 0)
-- Dependencies: 254
-- Name: TABLE cargo; Type: ACL; Schema: empleados; Owner: empresa_owner
--

GRANT ALL ON TABLE empleados.cargo TO rol_admin_master;
GRANT SELECT ON TABLE empleados.cargo TO rol_admin_visual;


--
-- TOC entry 5632 (class 0 OID 0)
-- Dependencies: 256
-- Name: TABLE documento_empleado; Type: ACL; Schema: empleados; Owner: empresa_owner
--

GRANT SELECT ON TABLE empleados.documento_empleado TO rol_tecnico;
GRANT SELECT ON TABLE empleados.documento_empleado TO rol_admin_master;


--
-- TOC entry 5634 (class 0 OID 0)
-- Dependencies: 258
-- Name: SEQUENCE empleado_id_empleado_seq; Type: ACL; Schema: empleados; Owner: postgres
--

GRANT SELECT,USAGE ON SEQUENCE empleados.empleado_id_empleado_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE empleados.empleado_id_empleado_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE empleados.empleado_id_empleado_seq TO rol_tecnico;


--
-- TOC entry 5635 (class 0 OID 0)
-- Dependencies: 259
-- Name: TABLE empleado; Type: ACL; Schema: empleados; Owner: empresa_owner
--

GRANT SELECT ON TABLE empleados.empleado TO rol_tecnico;
GRANT SELECT,UPDATE ON TABLE empleados.empleado TO rol_admin_tecnicos;
GRANT ALL ON TABLE empleados.empleado TO rol_admin_master;
GRANT SELECT ON TABLE empleados.empleado TO rol_admin_visual;


--
-- TOC entry 5636 (class 0 OID 0)
-- Dependencies: 260
-- Name: TABLE tipo_contrato; Type: ACL; Schema: empleados; Owner: empresa_owner
--

GRANT ALL ON TABLE empleados.tipo_contrato TO rol_admin_master;
GRANT SELECT ON TABLE empleados.tipo_contrato TO rol_admin_visual;


--
-- TOC entry 5653 (class 0 OID 0)
-- Dependencies: 287
-- Name: TABLE persona; Type: ACL; Schema: usuarios; Owner: postgres
--

GRANT ALL ON TABLE usuarios.persona TO rol_admin_master;


--
-- TOC entry 5655 (class 0 OID 0)
-- Dependencies: 289
-- Name: TABLE rol; Type: ACL; Schema: usuarios; Owner: empresa_owner
--

GRANT ALL ON TABLE usuarios.rol TO rol_admin_master;


--
-- TOC entry 5656 (class 0 OID 0)
-- Dependencies: 290
-- Name: TABLE rol_bd; Type: ACL; Schema: usuarios; Owner: empresa_owner
--

GRANT ALL ON TABLE usuarios.rol_bd TO rol_admin_master;


--
-- TOC entry 5659 (class 0 OID 0)
-- Dependencies: 293
-- Name: TABLE usuario; Type: ACL; Schema: usuarios; Owner: empresa_owner
--

GRANT ALL ON TABLE usuarios.usuario TO rol_admin_master;


--
-- TOC entry 5660 (class 0 OID 0)
-- Dependencies: 294
-- Name: TABLE usuario_bd; Type: ACL; Schema: usuarios; Owner: empresa_owner
--

GRANT ALL ON TABLE usuarios.usuario_bd TO rol_admin_master;


--
-- TOC entry 2290 (class 826 OID 23240)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: clientes; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA clientes GRANT SELECT ON TABLES TO rol_cliente;


--
-- TOC entry 2291 (class 826 OID 23241)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: empleados; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empleados GRANT SELECT ON TABLES TO rol_tecnico;


--
-- TOC entry 2292 (class 826 OID 23242)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: usuarios; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA usuarios GRANT ALL ON TABLES TO rol_admin_master;


-- Completed on 2026-02-22 19:32:18

--
-- PostgreSQL database dump complete
--

\unrestrict 2uHxLY53jzXP67RBPFz6Sse6AcgfX8imeZO84aqyoxMgVkQjcVStTpZFrnXhZcT

