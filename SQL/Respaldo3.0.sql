--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.5

-- Started on 2026-02-26 07:13:10

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
-- TOC entry 7 (class 2615 OID 68372)
-- Name: auditoria; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA auditoria;


ALTER SCHEMA auditoria OWNER TO postgres;

--
-- TOC entry 8 (class 2615 OID 68373)
-- Name: catalogos; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA catalogos;


ALTER SCHEMA catalogos OWNER TO postgres;

--
-- TOC entry 9 (class 2615 OID 68374)
-- Name: clientes; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA clientes;


ALTER SCHEMA clientes OWNER TO postgres;

--
-- TOC entry 10 (class 2615 OID 68375)
-- Name: empleados; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA empleados;


ALTER SCHEMA empleados OWNER TO postgres;

--
-- TOC entry 11 (class 2615 OID 68376)
-- Name: empresa; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA empresa;


ALTER SCHEMA empresa OWNER TO postgres;

--
-- TOC entry 12 (class 2615 OID 68377)
-- Name: notificaciones; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA notificaciones;


ALTER SCHEMA notificaciones OWNER TO postgres;

--
-- TOC entry 13 (class 2615 OID 68378)
-- Name: soporte; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA soporte;


ALTER SCHEMA soporte OWNER TO postgres;

--
-- TOC entry 14 (class 2615 OID 68379)
-- Name: usuarios; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA usuarios;


ALTER SCHEMA usuarios OWNER TO postgres;

--
-- TOC entry 2 (class 3079 OID 68380)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 5501 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 350 (class 1255 OID 68417)
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
-- TOC entry 351 (class 1255 OID 68418)
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
-- TOC entry 352 (class 1255 OID 68419)
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
-- TOC entry 353 (class 1255 OID 68420)
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
-- TOC entry 354 (class 1255 OID 68421)
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
-- TOC entry 355 (class 1255 OID 68422)
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
-- TOC entry 356 (class 1255 OID 68423)
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
-- TOC entry 357 (class 1255 OID 68424)
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
-- TOC entry 226 (class 1259 OID 68425)
-- Name: auditoria_estado_ticket; Type: TABLE; Schema: auditoria; Owner: postgres
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


ALTER TABLE auditoria.auditoria_estado_ticket OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 68429)
-- Name: auditoria_estado_ticket_id_auditoria_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

CREATE SEQUENCE auditoria.auditoria_estado_ticket_id_auditoria_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE auditoria.auditoria_estado_ticket_id_auditoria_seq OWNER TO postgres;

--
-- TOC entry 5502 (class 0 OID 0)
-- Dependencies: 227
-- Name: auditoria_estado_ticket_id_auditoria_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: postgres
--

ALTER SEQUENCE auditoria.auditoria_estado_ticket_id_auditoria_seq OWNED BY auditoria.auditoria_estado_ticket.id_auditoria;


--
-- TOC entry 228 (class 1259 OID 68430)
-- Name: auditoria_evento; Type: TABLE; Schema: auditoria; Owner: postgres
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


ALTER TABLE auditoria.auditoria_evento OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 68436)
-- Name: auditoria_evento_id_evento_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

CREATE SEQUENCE auditoria.auditoria_evento_id_evento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE auditoria.auditoria_evento_id_evento_seq OWNER TO postgres;

--
-- TOC entry 5503 (class 0 OID 0)
-- Dependencies: 229
-- Name: auditoria_evento_id_evento_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: postgres
--

ALTER SEQUENCE auditoria.auditoria_evento_id_evento_seq OWNED BY auditoria.auditoria_evento.id_evento;


--
-- TOC entry 230 (class 1259 OID 68437)
-- Name: auditoria_login; Type: TABLE; Schema: auditoria; Owner: postgres
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


ALTER TABLE auditoria.auditoria_login OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 68441)
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
-- TOC entry 232 (class 1259 OID 68447)
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
-- TOC entry 5504 (class 0 OID 0)
-- Dependencies: 232
-- Name: auditoria_login_bd_id_auditoria_login_bd_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: postgres
--

ALTER SEQUENCE auditoria.auditoria_login_bd_id_auditoria_login_bd_seq OWNED BY auditoria.auditoria_login_bd.id_auditoria_login_bd;


--
-- TOC entry 233 (class 1259 OID 68448)
-- Name: auditoria_login_id_login_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

CREATE SEQUENCE auditoria.auditoria_login_id_login_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE auditoria.auditoria_login_id_login_seq OWNER TO postgres;

--
-- TOC entry 5505 (class 0 OID 0)
-- Dependencies: 233
-- Name: auditoria_login_id_login_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: postgres
--

ALTER SEQUENCE auditoria.auditoria_login_id_login_seq OWNED BY auditoria.auditoria_login.id_login;


--
-- TOC entry 234 (class 1259 OID 68449)
-- Name: catalogo; Type: TABLE; Schema: catalogos; Owner: postgres
--

CREATE TABLE catalogos.catalogo (
    id_catalogo integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    activo boolean DEFAULT true
);


ALTER TABLE catalogos.catalogo OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 68455)
-- Name: catalogo_id_catalogo_seq; Type: SEQUENCE; Schema: catalogos; Owner: postgres
--

CREATE SEQUENCE catalogos.catalogo_id_catalogo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE catalogos.catalogo_id_catalogo_seq OWNER TO postgres;

--
-- TOC entry 5506 (class 0 OID 0)
-- Dependencies: 235
-- Name: catalogo_id_catalogo_seq; Type: SEQUENCE OWNED BY; Schema: catalogos; Owner: postgres
--

ALTER SEQUENCE catalogos.catalogo_id_catalogo_seq OWNED BY catalogos.catalogo.id_catalogo;


--
-- TOC entry 236 (class 1259 OID 68456)
-- Name: catalogo_item; Type: TABLE; Schema: catalogos; Owner: postgres
--

CREATE TABLE catalogos.catalogo_item (
    id_item integer NOT NULL,
    id_catalogo integer NOT NULL,
    codigo character varying(50),
    nombre character varying(100) NOT NULL,
    orden integer,
    activo boolean DEFAULT true
);


ALTER TABLE catalogos.catalogo_item OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 68460)
-- Name: catalogo_item_id_item_seq; Type: SEQUENCE; Schema: catalogos; Owner: postgres
--

CREATE SEQUENCE catalogos.catalogo_item_id_item_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE catalogos.catalogo_item_id_item_seq OWNER TO postgres;

--
-- TOC entry 5507 (class 0 OID 0)
-- Dependencies: 237
-- Name: catalogo_item_id_item_seq; Type: SEQUENCE OWNED BY; Schema: catalogos; Owner: postgres
--

ALTER SEQUENCE catalogos.catalogo_item_id_item_seq OWNED BY catalogos.catalogo_item.id_item;


--
-- TOC entry 238 (class 1259 OID 68461)
-- Name: canton; Type: TABLE; Schema: clientes; Owner: postgres
--

CREATE TABLE clientes.canton (
    id_canton integer NOT NULL,
    nombre character varying(100) NOT NULL,
    id_ciudad integer NOT NULL
);


ALTER TABLE clientes.canton OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 68464)
-- Name: canton_id_canton_seq; Type: SEQUENCE; Schema: clientes; Owner: postgres
--

CREATE SEQUENCE clientes.canton_id_canton_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE clientes.canton_id_canton_seq OWNER TO postgres;

--
-- TOC entry 5508 (class 0 OID 0)
-- Dependencies: 239
-- Name: canton_id_canton_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: postgres
--

ALTER SEQUENCE clientes.canton_id_canton_seq OWNED BY clientes.canton.id_canton;


--
-- TOC entry 240 (class 1259 OID 68465)
-- Name: ciudad; Type: TABLE; Schema: clientes; Owner: postgres
--

CREATE TABLE clientes.ciudad (
    id_ciudad integer NOT NULL,
    nombre character varying(100) NOT NULL,
    id_pais integer NOT NULL
);


ALTER TABLE clientes.ciudad OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 68468)
-- Name: ciudad_id_ciudad_seq; Type: SEQUENCE; Schema: clientes; Owner: postgres
--

CREATE SEQUENCE clientes.ciudad_id_ciudad_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE clientes.ciudad_id_ciudad_seq OWNER TO postgres;

--
-- TOC entry 5509 (class 0 OID 0)
-- Dependencies: 241
-- Name: ciudad_id_ciudad_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: postgres
--

ALTER SEQUENCE clientes.ciudad_id_ciudad_seq OWNED BY clientes.ciudad.id_ciudad;


--
-- TOC entry 242 (class 1259 OID 68469)
-- Name: cliente; Type: TABLE; Schema: clientes; Owner: postgres
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


ALTER TABLE clientes.cliente OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 68475)
-- Name: cliente_id_cliente_seq; Type: SEQUENCE; Schema: clientes; Owner: postgres
--

CREATE SEQUENCE clientes.cliente_id_cliente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE clientes.cliente_id_cliente_seq OWNER TO postgres;

--
-- TOC entry 5510 (class 0 OID 0)
-- Dependencies: 243
-- Name: cliente_id_cliente_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: postgres
--

ALTER SEQUENCE clientes.cliente_id_cliente_seq OWNED BY clientes.cliente.id_cliente;


--
-- TOC entry 244 (class 1259 OID 68476)
-- Name: documento_cliente; Type: TABLE; Schema: clientes; Owner: postgres
--

CREATE TABLE clientes.documento_cliente (
    id_documento integer NOT NULL,
    numero_documento character varying(10) NOT NULL,
    ruta_archivo text NOT NULL,
    descripcion text,
    fecha_subida timestamp without time zone DEFAULT now(),
    id_cliente integer NOT NULL,
    id_tipo_documento integer NOT NULL,
    id_catalogo_item_estado integer
);


ALTER TABLE clientes.documento_cliente OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 68482)
-- Name: documento_cliente_id_documento_seq; Type: SEQUENCE; Schema: clientes; Owner: postgres
--

CREATE SEQUENCE clientes.documento_cliente_id_documento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE clientes.documento_cliente_id_documento_seq OWNER TO postgres;

--
-- TOC entry 5511 (class 0 OID 0)
-- Dependencies: 245
-- Name: documento_cliente_id_documento_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: postgres
--

ALTER SEQUENCE clientes.documento_cliente_id_documento_seq OWNED BY clientes.documento_cliente.id_documento;


--
-- TOC entry 246 (class 1259 OID 68483)
-- Name: pais; Type: TABLE; Schema: clientes; Owner: postgres
--

CREATE TABLE clientes.pais (
    id_pais integer NOT NULL,
    nombre character varying(100) NOT NULL
);


ALTER TABLE clientes.pais OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 68486)
-- Name: pais_id_pais_seq; Type: SEQUENCE; Schema: clientes; Owner: postgres
--

CREATE SEQUENCE clientes.pais_id_pais_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE clientes.pais_id_pais_seq OWNER TO postgres;

--
-- TOC entry 5512 (class 0 OID 0)
-- Dependencies: 247
-- Name: pais_id_pais_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: postgres
--

ALTER SEQUENCE clientes.pais_id_pais_seq OWNED BY clientes.pais.id_pais;


--
-- TOC entry 248 (class 1259 OID 68487)
-- Name: tipo_documento; Type: TABLE; Schema: clientes; Owner: postgres
--

CREATE TABLE clientes.tipo_documento (
    id_tipo_documento integer NOT NULL,
    codigo character varying(20) NOT NULL
);


ALTER TABLE clientes.tipo_documento OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 68490)
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
-- TOC entry 5513 (class 0 OID 0)
-- Dependencies: 249
-- Name: tipo_documento_id_tipo_documento_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: postgres
--

ALTER SEQUENCE clientes.tipo_documento_id_tipo_documento_seq OWNED BY clientes.tipo_documento.id_tipo_documento;


--
-- TOC entry 250 (class 1259 OID 68491)
-- Name: area; Type: TABLE; Schema: empleados; Owner: postgres
--

CREATE TABLE empleados.area (
    id_area integer NOT NULL,
    nombre character varying(100) NOT NULL
);


ALTER TABLE empleados.area OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 68494)
-- Name: area_id_area_seq; Type: SEQUENCE; Schema: empleados; Owner: postgres
--

CREATE SEQUENCE empleados.area_id_area_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE empleados.area_id_area_seq OWNER TO postgres;

--
-- TOC entry 5514 (class 0 OID 0)
-- Dependencies: 251
-- Name: area_id_area_seq; Type: SEQUENCE OWNED BY; Schema: empleados; Owner: postgres
--

ALTER SEQUENCE empleados.area_id_area_seq OWNED BY empleados.area.id_area;


--
-- TOC entry 252 (class 1259 OID 68495)
-- Name: cargo; Type: TABLE; Schema: empleados; Owner: postgres
--

CREATE TABLE empleados.cargo (
    id_cargo integer NOT NULL,
    nombre character varying(100) NOT NULL
);


ALTER TABLE empleados.cargo OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 68498)
-- Name: cargo_id_cargo_seq; Type: SEQUENCE; Schema: empleados; Owner: postgres
--

CREATE SEQUENCE empleados.cargo_id_cargo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE empleados.cargo_id_cargo_seq OWNER TO postgres;

--
-- TOC entry 5515 (class 0 OID 0)
-- Dependencies: 253
-- Name: cargo_id_cargo_seq; Type: SEQUENCE OWNED BY; Schema: empleados; Owner: postgres
--

ALTER SEQUENCE empleados.cargo_id_cargo_seq OWNED BY empleados.cargo.id_cargo;


--
-- TOC entry 254 (class 1259 OID 68499)
-- Name: documento_empleado; Type: TABLE; Schema: empleados; Owner: postgres
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


ALTER TABLE empleados.documento_empleado OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 68505)
-- Name: documento_empleado_id_documento_seq; Type: SEQUENCE; Schema: empleados; Owner: postgres
--

CREATE SEQUENCE empleados.documento_empleado_id_documento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE empleados.documento_empleado_id_documento_seq OWNER TO postgres;

--
-- TOC entry 5516 (class 0 OID 0)
-- Dependencies: 255
-- Name: documento_empleado_id_documento_seq; Type: SEQUENCE OWNED BY; Schema: empleados; Owner: postgres
--

ALTER SEQUENCE empleados.documento_empleado_id_documento_seq OWNED BY empleados.documento_empleado.id_documento;


--
-- TOC entry 256 (class 1259 OID 68506)
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
-- TOC entry 257 (class 1259 OID 68507)
-- Name: empleado; Type: TABLE; Schema: empleados; Owner: postgres
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


ALTER TABLE empleados.empleado OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 68511)
-- Name: tipo_contrato; Type: TABLE; Schema: empleados; Owner: postgres
--

CREATE TABLE empleados.tipo_contrato (
    id_tipo_contrato integer NOT NULL,
    nombre character varying(100) NOT NULL
);


ALTER TABLE empleados.tipo_contrato OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 68514)
-- Name: tipo_contrato_id_tipo_contrato_seq; Type: SEQUENCE; Schema: empleados; Owner: postgres
--

CREATE SEQUENCE empleados.tipo_contrato_id_tipo_contrato_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE empleados.tipo_contrato_id_tipo_contrato_seq OWNER TO postgres;

--
-- TOC entry 5517 (class 0 OID 0)
-- Dependencies: 259
-- Name: tipo_contrato_id_tipo_contrato_seq; Type: SEQUENCE OWNED BY; Schema: empleados; Owner: postgres
--

ALTER SEQUENCE empleados.tipo_contrato_id_tipo_contrato_seq OWNED BY empleados.tipo_contrato.id_tipo_contrato;


--
-- TOC entry 260 (class 1259 OID 68515)
-- Name: documento_empresa; Type: TABLE; Schema: empresa; Owner: postgres
--

CREATE TABLE empresa.documento_empresa (
    id_documento integer NOT NULL,
    id_empresa integer NOT NULL,
    numero_documento character varying(50) NOT NULL,
    ruta_archivo text NOT NULL,
    descripcion text,
    fecha_subida timestamp without time zone DEFAULT now(),
    id_tipo_documento integer NOT NULL,
    id_catalogo_item_estado integer
);


ALTER TABLE empresa.documento_empresa OWNER TO postgres;

--
-- TOC entry 261 (class 1259 OID 68521)
-- Name: documento_empresa_id_documento_seq; Type: SEQUENCE; Schema: empresa; Owner: postgres
--

CREATE SEQUENCE empresa.documento_empresa_id_documento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE empresa.documento_empresa_id_documento_seq OWNER TO postgres;

--
-- TOC entry 5518 (class 0 OID 0)
-- Dependencies: 261
-- Name: documento_empresa_id_documento_seq; Type: SEQUENCE OWNED BY; Schema: empresa; Owner: postgres
--

ALTER SEQUENCE empresa.documento_empresa_id_documento_seq OWNED BY empresa.documento_empresa.id_documento;


--
-- TOC entry 262 (class 1259 OID 68522)
-- Name: empresa; Type: TABLE; Schema: empresa; Owner: postgres
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


ALTER TABLE empresa.empresa OWNER TO postgres;

--
-- TOC entry 263 (class 1259 OID 68528)
-- Name: empresa_id_empresa_seq; Type: SEQUENCE; Schema: empresa; Owner: postgres
--

CREATE SEQUENCE empresa.empresa_id_empresa_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE empresa.empresa_id_empresa_seq OWNER TO postgres;

--
-- TOC entry 5519 (class 0 OID 0)
-- Dependencies: 263
-- Name: empresa_id_empresa_seq; Type: SEQUENCE OWNED BY; Schema: empresa; Owner: postgres
--

ALTER SEQUENCE empresa.empresa_id_empresa_seq OWNED BY empresa.empresa.id_empresa;


--
-- TOC entry 264 (class 1259 OID 68529)
-- Name: empresa_servicio; Type: TABLE; Schema: empresa; Owner: postgres
--

CREATE TABLE empresa.empresa_servicio (
    id_empresa integer NOT NULL,
    id_servicio integer NOT NULL
);


ALTER TABLE empresa.empresa_servicio OWNER TO postgres;

--
-- TOC entry 265 (class 1259 OID 68532)
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
-- TOC entry 266 (class 1259 OID 68537)
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
-- TOC entry 5520 (class 0 OID 0)
-- Dependencies: 266
-- Name: servicio_id_servicio_seq; Type: SEQUENCE OWNED BY; Schema: empresa; Owner: postgres
--

ALTER SEQUENCE empresa.servicio_id_servicio_seq OWNED BY empresa.servicio.id_servicio;


--
-- TOC entry 267 (class 1259 OID 68538)
-- Name: sucursal; Type: TABLE; Schema: empresa; Owner: postgres
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


ALTER TABLE empresa.sucursal OWNER TO postgres;

--
-- TOC entry 268 (class 1259 OID 68543)
-- Name: sucursal_id_sucursal_seq; Type: SEQUENCE; Schema: empresa; Owner: postgres
--

CREATE SEQUENCE empresa.sucursal_id_sucursal_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE empresa.sucursal_id_sucursal_seq OWNER TO postgres;

--
-- TOC entry 5521 (class 0 OID 0)
-- Dependencies: 268
-- Name: sucursal_id_sucursal_seq; Type: SEQUENCE OWNED BY; Schema: empresa; Owner: postgres
--

ALTER SEQUENCE empresa.sucursal_id_sucursal_seq OWNED BY empresa.sucursal.id_sucursal;


--
-- TOC entry 269 (class 1259 OID 68544)
-- Name: canal_notificacion; Type: TABLE; Schema: notificaciones; Owner: postgres
--

CREATE TABLE notificaciones.canal_notificacion (
    id_canal integer NOT NULL,
    nombre character varying(50) NOT NULL,
    activo boolean DEFAULT true
);


ALTER TABLE notificaciones.canal_notificacion OWNER TO postgres;

--
-- TOC entry 270 (class 1259 OID 68548)
-- Name: canal_notificacion_id_canal_seq; Type: SEQUENCE; Schema: notificaciones; Owner: postgres
--

CREATE SEQUENCE notificaciones.canal_notificacion_id_canal_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE notificaciones.canal_notificacion_id_canal_seq OWNER TO postgres;

--
-- TOC entry 5522 (class 0 OID 0)
-- Dependencies: 270
-- Name: canal_notificacion_id_canal_seq; Type: SEQUENCE OWNED BY; Schema: notificaciones; Owner: postgres
--

ALTER SEQUENCE notificaciones.canal_notificacion_id_canal_seq OWNED BY notificaciones.canal_notificacion.id_canal;


--
-- TOC entry 271 (class 1259 OID 68549)
-- Name: notificacion; Type: TABLE; Schema: notificaciones; Owner: postgres
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


ALTER TABLE notificaciones.notificacion OWNER TO postgres;

--
-- TOC entry 272 (class 1259 OID 68556)
-- Name: notificacion_id_notificacion_seq; Type: SEQUENCE; Schema: notificaciones; Owner: postgres
--

CREATE SEQUENCE notificaciones.notificacion_id_notificacion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE notificaciones.notificacion_id_notificacion_seq OWNER TO postgres;

--
-- TOC entry 5523 (class 0 OID 0)
-- Dependencies: 272
-- Name: notificacion_id_notificacion_seq; Type: SEQUENCE OWNED BY; Schema: notificaciones; Owner: postgres
--

ALTER SEQUENCE notificaciones.notificacion_id_notificacion_seq OWNED BY notificaciones.notificacion.id_notificacion;


--
-- TOC entry 273 (class 1259 OID 68557)
-- Name: asignacion; Type: TABLE; Schema: soporte; Owner: postgres
--

CREATE TABLE soporte.asignacion (
    id_asignacion integer NOT NULL,
    id_ticket integer NOT NULL,
    fecha_asignacion timestamp without time zone DEFAULT now(),
    activo boolean DEFAULT true,
    id_usuario integer NOT NULL
);


ALTER TABLE soporte.asignacion OWNER TO postgres;

--
-- TOC entry 274 (class 1259 OID 68562)
-- Name: asignacion_id_asignacion_seq; Type: SEQUENCE; Schema: soporte; Owner: postgres
--

CREATE SEQUENCE soporte.asignacion_id_asignacion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE soporte.asignacion_id_asignacion_seq OWNER TO postgres;

--
-- TOC entry 5524 (class 0 OID 0)
-- Dependencies: 274
-- Name: asignacion_id_asignacion_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.asignacion_id_asignacion_seq OWNED BY soporte.asignacion.id_asignacion;


--
-- TOC entry 275 (class 1259 OID 68563)
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
-- TOC entry 276 (class 1259 OID 68568)
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
-- TOC entry 5525 (class 0 OID 0)
-- Dependencies: 276
-- Name: categoria_id_categoria_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.categoria_id_categoria_seq OWNED BY soporte.categoria.id_categoria;


--
-- TOC entry 277 (class 1259 OID 68569)
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
-- TOC entry 278 (class 1259 OID 68576)
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
-- TOC entry 5526 (class 0 OID 0)
-- Dependencies: 278
-- Name: comentario_ticket_id_comentario_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.comentario_ticket_id_comentario_seq OWNED BY soporte.comentario_ticket.id_comentario;


--
-- TOC entry 279 (class 1259 OID 68577)
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
-- TOC entry 280 (class 1259 OID 68583)
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
-- TOC entry 5527 (class 0 OID 0)
-- Dependencies: 280
-- Name: documento_ticket_id_documento_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.documento_ticket_id_documento_seq OWNED BY soporte.documento_ticket.id_documento;


--
-- TOC entry 281 (class 1259 OID 68584)
-- Name: historial_estado; Type: TABLE; Schema: soporte; Owner: postgres
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


ALTER TABLE soporte.historial_estado OWNER TO postgres;

--
-- TOC entry 282 (class 1259 OID 68590)
-- Name: historial_estado_id_historial_seq; Type: SEQUENCE; Schema: soporte; Owner: postgres
--

CREATE SEQUENCE soporte.historial_estado_id_historial_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE soporte.historial_estado_id_historial_seq OWNER TO postgres;

--
-- TOC entry 5528 (class 0 OID 0)
-- Dependencies: 282
-- Name: historial_estado_id_historial_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.historial_estado_id_historial_seq OWNED BY soporte.historial_estado.id_historial;


--
-- TOC entry 283 (class 1259 OID 68591)
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
-- TOC entry 284 (class 1259 OID 68596)
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
-- TOC entry 5529 (class 0 OID 0)
-- Dependencies: 284
-- Name: prioridad_id_prioridad_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.prioridad_id_prioridad_seq OWNED BY soporte.prioridad.id_prioridad;


--
-- TOC entry 285 (class 1259 OID 68597)
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
-- TOC entry 286 (class 1259 OID 68604)
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
-- TOC entry 5530 (class 0 OID 0)
-- Dependencies: 286
-- Name: sla_ticket_id_sla_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.sla_ticket_id_sla_seq OWNED BY soporte.sla_ticket.id_sla;


--
-- TOC entry 287 (class 1259 OID 68605)
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
-- TOC entry 288 (class 1259 OID 68611)
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
-- TOC entry 5531 (class 0 OID 0)
-- Dependencies: 288
-- Name: solucion_ticket_id_solucion_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.solucion_ticket_id_solucion_seq OWNED BY soporte.solucion_ticket.id_solucion;


--
-- TOC entry 289 (class 1259 OID 68612)
-- Name: ticket; Type: TABLE; Schema: soporte; Owner: postgres
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


ALTER TABLE soporte.ticket OWNER TO postgres;

--
-- TOC entry 290 (class 1259 OID 68618)
-- Name: ticket_id_ticket_seq; Type: SEQUENCE; Schema: soporte; Owner: postgres
--

CREATE SEQUENCE soporte.ticket_id_ticket_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE soporte.ticket_id_ticket_seq OWNER TO postgres;

--
-- TOC entry 5532 (class 0 OID 0)
-- Dependencies: 290
-- Name: ticket_id_ticket_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.ticket_id_ticket_seq OWNED BY soporte.ticket.id_ticket;


--
-- TOC entry 302 (class 1259 OID 69256)
-- Name: visita_tecnica; Type: TABLE; Schema: soporte; Owner: postgres
--

CREATE TABLE soporte.visita_tecnica (
    id_visita integer NOT NULL,
    id_ticket integer NOT NULL,
    id_usuario_tecnico integer NOT NULL,
    id_empresa integer NOT NULL,
    fecha_visita date NOT NULL,
    hora_inicio time without time zone NOT NULL,
    hora_fin time without time zone,
    id_catalogo_item_estado integer NOT NULL,
    reporte_visita text,
    fecha_creacion timestamp without time zone DEFAULT now(),
    fecha_actualizacion timestamp without time zone
);


ALTER TABLE soporte.visita_tecnica OWNER TO postgres;

--
-- TOC entry 5533 (class 0 OID 0)
-- Dependencies: 302
-- Name: TABLE visita_tecnica; Type: COMMENT; Schema: soporte; Owner: postgres
--

COMMENT ON TABLE soporte.visita_tecnica IS 'Entidad que gestiona las citas presenciales vinculadas a un ticket de soporte';


--
-- TOC entry 301 (class 1259 OID 69255)
-- Name: visita_tecnica_id_visita_seq; Type: SEQUENCE; Schema: soporte; Owner: postgres
--

CREATE SEQUENCE soporte.visita_tecnica_id_visita_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE soporte.visita_tecnica_id_visita_seq OWNER TO postgres;

--
-- TOC entry 5534 (class 0 OID 0)
-- Dependencies: 301
-- Name: visita_tecnica_id_visita_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.visita_tecnica_id_visita_seq OWNED BY soporte.visita_tecnica.id_visita;


--
-- TOC entry 291 (class 1259 OID 68619)
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
    id_usuario integer,
    ruta_foto text
);


ALTER TABLE usuarios.persona OWNER TO postgres;

--
-- TOC entry 292 (class 1259 OID 68625)
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
-- TOC entry 5535 (class 0 OID 0)
-- Dependencies: 292
-- Name: persona_id_persona_seq; Type: SEQUENCE OWNED BY; Schema: usuarios; Owner: postgres
--

ALTER SEQUENCE usuarios.persona_id_persona_seq OWNED BY usuarios.persona.id_persona;


--
-- TOC entry 293 (class 1259 OID 68626)
-- Name: rol; Type: TABLE; Schema: usuarios; Owner: postgres
--

CREATE TABLE usuarios.rol (
    id_rol integer NOT NULL,
    codigo character varying(50) NOT NULL,
    descripcion text
);


ALTER TABLE usuarios.rol OWNER TO postgres;

--
-- TOC entry 294 (class 1259 OID 68631)
-- Name: rol_bd; Type: TABLE; Schema: usuarios; Owner: postgres
--

CREATE TABLE usuarios.rol_bd (
    id_rol_bd integer NOT NULL,
    nombre character varying(50) NOT NULL,
    descripcion text
);


ALTER TABLE usuarios.rol_bd OWNER TO postgres;

--
-- TOC entry 295 (class 1259 OID 68636)
-- Name: rol_bd_id_rol_bd_seq; Type: SEQUENCE; Schema: usuarios; Owner: postgres
--

CREATE SEQUENCE usuarios.rol_bd_id_rol_bd_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE usuarios.rol_bd_id_rol_bd_seq OWNER TO postgres;

--
-- TOC entry 5536 (class 0 OID 0)
-- Dependencies: 295
-- Name: rol_bd_id_rol_bd_seq; Type: SEQUENCE OWNED BY; Schema: usuarios; Owner: postgres
--

ALTER SEQUENCE usuarios.rol_bd_id_rol_bd_seq OWNED BY usuarios.rol_bd.id_rol_bd;


--
-- TOC entry 296 (class 1259 OID 68637)
-- Name: rol_id_rol_seq; Type: SEQUENCE; Schema: usuarios; Owner: postgres
--

CREATE SEQUENCE usuarios.rol_id_rol_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE usuarios.rol_id_rol_seq OWNER TO postgres;

--
-- TOC entry 5537 (class 0 OID 0)
-- Dependencies: 296
-- Name: rol_id_rol_seq; Type: SEQUENCE OWNED BY; Schema: usuarios; Owner: postgres
--

ALTER SEQUENCE usuarios.rol_id_rol_seq OWNED BY usuarios.rol.id_rol;


--
-- TOC entry 297 (class 1259 OID 68638)
-- Name: usuario; Type: TABLE; Schema: usuarios; Owner: postgres
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


ALTER TABLE usuarios.usuario OWNER TO postgres;

--
-- TOC entry 298 (class 1259 OID 68645)
-- Name: usuario_bd; Type: TABLE; Schema: usuarios; Owner: postgres
--

CREATE TABLE usuarios.usuario_bd (
    id_usuario_bd integer NOT NULL,
    nombre character varying(50) NOT NULL,
    id_rol_bd integer NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    id_usuario integer NOT NULL
);


ALTER TABLE usuarios.usuario_bd OWNER TO postgres;

--
-- TOC entry 299 (class 1259 OID 68649)
-- Name: usuario_bd_id_usuario_bd_seq; Type: SEQUENCE; Schema: usuarios; Owner: postgres
--

CREATE SEQUENCE usuarios.usuario_bd_id_usuario_bd_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE usuarios.usuario_bd_id_usuario_bd_seq OWNER TO postgres;

--
-- TOC entry 5538 (class 0 OID 0)
-- Dependencies: 299
-- Name: usuario_bd_id_usuario_bd_seq; Type: SEQUENCE OWNED BY; Schema: usuarios; Owner: postgres
--

ALTER SEQUENCE usuarios.usuario_bd_id_usuario_bd_seq OWNED BY usuarios.usuario_bd.id_usuario_bd;


--
-- TOC entry 300 (class 1259 OID 68650)
-- Name: usuario_id_usuario_seq; Type: SEQUENCE; Schema: usuarios; Owner: postgres
--

CREATE SEQUENCE usuarios.usuario_id_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE usuarios.usuario_id_usuario_seq OWNER TO postgres;

--
-- TOC entry 5539 (class 0 OID 0)
-- Dependencies: 300
-- Name: usuario_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: usuarios; Owner: postgres
--

ALTER SEQUENCE usuarios.usuario_id_usuario_seq OWNED BY usuarios.usuario.id_usuario;


--
-- TOC entry 4984 (class 2604 OID 69321)
-- Name: auditoria_estado_ticket id_auditoria; Type: DEFAULT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket ALTER COLUMN id_auditoria SET DEFAULT nextval('auditoria.auditoria_estado_ticket_id_auditoria_seq'::regclass);


--
-- TOC entry 4986 (class 2604 OID 69322)
-- Name: auditoria_evento id_evento; Type: DEFAULT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_evento ALTER COLUMN id_evento SET DEFAULT nextval('auditoria.auditoria_evento_id_evento_seq'::regclass);


--
-- TOC entry 4988 (class 2604 OID 69323)
-- Name: auditoria_login id_login; Type: DEFAULT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login ALTER COLUMN id_login SET DEFAULT nextval('auditoria.auditoria_login_id_login_seq'::regclass);


--
-- TOC entry 4990 (class 2604 OID 69324)
-- Name: auditoria_login_bd id_auditoria_login_bd; Type: DEFAULT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd ALTER COLUMN id_auditoria_login_bd SET DEFAULT nextval('auditoria.auditoria_login_bd_id_auditoria_login_bd_seq'::regclass);


--
-- TOC entry 4992 (class 2604 OID 69325)
-- Name: catalogo id_catalogo; Type: DEFAULT; Schema: catalogos; Owner: postgres
--

ALTER TABLE ONLY catalogos.catalogo ALTER COLUMN id_catalogo SET DEFAULT nextval('catalogos.catalogo_id_catalogo_seq'::regclass);


--
-- TOC entry 4994 (class 2604 OID 69326)
-- Name: catalogo_item id_item; Type: DEFAULT; Schema: catalogos; Owner: postgres
--

ALTER TABLE ONLY catalogos.catalogo_item ALTER COLUMN id_item SET DEFAULT nextval('catalogos.catalogo_item_id_item_seq'::regclass);


--
-- TOC entry 4996 (class 2604 OID 69327)
-- Name: canton id_canton; Type: DEFAULT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.canton ALTER COLUMN id_canton SET DEFAULT nextval('clientes.canton_id_canton_seq'::regclass);


--
-- TOC entry 4997 (class 2604 OID 69328)
-- Name: ciudad id_ciudad; Type: DEFAULT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.ciudad ALTER COLUMN id_ciudad SET DEFAULT nextval('clientes.ciudad_id_ciudad_seq'::regclass);


--
-- TOC entry 4998 (class 2604 OID 69329)
-- Name: cliente id_cliente; Type: DEFAULT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.cliente ALTER COLUMN id_cliente SET DEFAULT nextval('clientes.cliente_id_cliente_seq'::regclass);


--
-- TOC entry 5002 (class 2604 OID 69330)
-- Name: documento_cliente id_documento; Type: DEFAULT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.documento_cliente ALTER COLUMN id_documento SET DEFAULT nextval('clientes.documento_cliente_id_documento_seq'::regclass);


--
-- TOC entry 5004 (class 2604 OID 69331)
-- Name: pais id_pais; Type: DEFAULT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.pais ALTER COLUMN id_pais SET DEFAULT nextval('clientes.pais_id_pais_seq'::regclass);


--
-- TOC entry 5005 (class 2604 OID 69332)
-- Name: tipo_documento id_tipo_documento; Type: DEFAULT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.tipo_documento ALTER COLUMN id_tipo_documento SET DEFAULT nextval('clientes.tipo_documento_id_tipo_documento_seq'::regclass);


--
-- TOC entry 5006 (class 2604 OID 69333)
-- Name: area id_area; Type: DEFAULT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.area ALTER COLUMN id_area SET DEFAULT nextval('empleados.area_id_area_seq'::regclass);


--
-- TOC entry 5007 (class 2604 OID 69334)
-- Name: cargo id_cargo; Type: DEFAULT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.cargo ALTER COLUMN id_cargo SET DEFAULT nextval('empleados.cargo_id_cargo_seq'::regclass);


--
-- TOC entry 5008 (class 2604 OID 69335)
-- Name: documento_empleado id_documento; Type: DEFAULT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.documento_empleado ALTER COLUMN id_documento SET DEFAULT nextval('empleados.documento_empleado_id_documento_seq'::regclass);


--
-- TOC entry 5011 (class 2604 OID 69336)
-- Name: tipo_contrato id_tipo_contrato; Type: DEFAULT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.tipo_contrato ALTER COLUMN id_tipo_contrato SET DEFAULT nextval('empleados.tipo_contrato_id_tipo_contrato_seq'::regclass);


--
-- TOC entry 5012 (class 2604 OID 69337)
-- Name: documento_empresa id_documento; Type: DEFAULT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.documento_empresa ALTER COLUMN id_documento SET DEFAULT nextval('empresa.documento_empresa_id_documento_seq'::regclass);


--
-- TOC entry 5014 (class 2604 OID 69338)
-- Name: empresa id_empresa; Type: DEFAULT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.empresa ALTER COLUMN id_empresa SET DEFAULT nextval('empresa.empresa_id_empresa_seq'::regclass);


--
-- TOC entry 5016 (class 2604 OID 69339)
-- Name: servicio id_servicio; Type: DEFAULT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.servicio ALTER COLUMN id_servicio SET DEFAULT nextval('empresa.servicio_id_servicio_seq'::regclass);


--
-- TOC entry 5017 (class 2604 OID 69340)
-- Name: sucursal id_sucursal; Type: DEFAULT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.sucursal ALTER COLUMN id_sucursal SET DEFAULT nextval('empresa.sucursal_id_sucursal_seq'::regclass);


--
-- TOC entry 5018 (class 2604 OID 69341)
-- Name: canal_notificacion id_canal; Type: DEFAULT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.canal_notificacion ALTER COLUMN id_canal SET DEFAULT nextval('notificaciones.canal_notificacion_id_canal_seq'::regclass);


--
-- TOC entry 5020 (class 2604 OID 69342)
-- Name: notificacion id_notificacion; Type: DEFAULT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.notificacion ALTER COLUMN id_notificacion SET DEFAULT nextval('notificaciones.notificacion_id_notificacion_seq'::regclass);


--
-- TOC entry 5023 (class 2604 OID 69343)
-- Name: asignacion id_asignacion; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.asignacion ALTER COLUMN id_asignacion SET DEFAULT nextval('soporte.asignacion_id_asignacion_seq'::regclass);


--
-- TOC entry 5026 (class 2604 OID 69344)
-- Name: categoria id_categoria; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.categoria ALTER COLUMN id_categoria SET DEFAULT nextval('soporte.categoria_id_categoria_seq'::regclass);


--
-- TOC entry 5027 (class 2604 OID 69345)
-- Name: comentario_ticket id_comentario; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket ALTER COLUMN id_comentario SET DEFAULT nextval('soporte.comentario_ticket_id_comentario_seq'::regclass);


--
-- TOC entry 5030 (class 2604 OID 69346)
-- Name: documento_ticket id_documento; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.documento_ticket ALTER COLUMN id_documento SET DEFAULT nextval('soporte.documento_ticket_id_documento_seq'::regclass);


--
-- TOC entry 5032 (class 2604 OID 69347)
-- Name: historial_estado id_historial; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado ALTER COLUMN id_historial SET DEFAULT nextval('soporte.historial_estado_id_historial_seq'::regclass);


--
-- TOC entry 5034 (class 2604 OID 69348)
-- Name: prioridad id_prioridad; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.prioridad ALTER COLUMN id_prioridad SET DEFAULT nextval('soporte.prioridad_id_prioridad_seq'::regclass);


--
-- TOC entry 5035 (class 2604 OID 69349)
-- Name: sla_ticket id_sla; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.sla_ticket ALTER COLUMN id_sla SET DEFAULT nextval('soporte.sla_ticket_id_sla_seq'::regclass);


--
-- TOC entry 5038 (class 2604 OID 69350)
-- Name: solucion_ticket id_solucion; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.solucion_ticket ALTER COLUMN id_solucion SET DEFAULT nextval('soporte.solucion_ticket_id_solucion_seq'::regclass);


--
-- TOC entry 5040 (class 2604 OID 69351)
-- Name: ticket id_ticket; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket ALTER COLUMN id_ticket SET DEFAULT nextval('soporte.ticket_id_ticket_seq'::regclass);


--
-- TOC entry 5051 (class 2604 OID 69259)
-- Name: visita_tecnica id_visita; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.visita_tecnica ALTER COLUMN id_visita SET DEFAULT nextval('soporte.visita_tecnica_id_visita_seq'::regclass);


--
-- TOC entry 5042 (class 2604 OID 69352)
-- Name: persona id_persona; Type: DEFAULT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.persona ALTER COLUMN id_persona SET DEFAULT nextval('usuarios.persona_id_persona_seq'::regclass);


--
-- TOC entry 5044 (class 2604 OID 69353)
-- Name: rol id_rol; Type: DEFAULT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.rol ALTER COLUMN id_rol SET DEFAULT nextval('usuarios.rol_id_rol_seq'::regclass);


--
-- TOC entry 5045 (class 2604 OID 69354)
-- Name: rol_bd id_rol_bd; Type: DEFAULT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.rol_bd ALTER COLUMN id_rol_bd SET DEFAULT nextval('usuarios.rol_bd_id_rol_bd_seq'::regclass);


--
-- TOC entry 5046 (class 2604 OID 69355)
-- Name: usuario id_usuario; Type: DEFAULT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario ALTER COLUMN id_usuario SET DEFAULT nextval('usuarios.usuario_id_usuario_seq'::regclass);


--
-- TOC entry 5049 (class 2604 OID 69356)
-- Name: usuario_bd id_usuario_bd; Type: DEFAULT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_bd ALTER COLUMN id_usuario_bd SET DEFAULT nextval('usuarios.usuario_bd_id_usuario_bd_seq'::regclass);


--
-- TOC entry 5419 (class 0 OID 68425)
-- Dependencies: 226
-- Data for Name: auditoria_estado_ticket; Type: TABLE DATA; Schema: auditoria; Owner: postgres
--

COPY auditoria.auditoria_estado_ticket (id_auditoria, id_ticket, usuario_bd, fecha_cambio, id_estado_anterior, id_item_evento, id_usuario, id_estado_nuevo_item) FROM stdin;
\.


--
-- TOC entry 5421 (class 0 OID 68430)
-- Dependencies: 228
-- Data for Name: auditoria_evento; Type: TABLE DATA; Schema: auditoria; Owner: postgres
--

COPY auditoria.auditoria_evento (id_evento, esquema_afectado, tabla_afectada, id_registro, descripcion, usuario_bd, rol_bd, fecha_evento, id_usuario, id_notificacion, id_accion_item) FROM stdin;
\.


--
-- TOC entry 5423 (class 0 OID 68437)
-- Dependencies: 230
-- Data for Name: auditoria_login; Type: TABLE DATA; Schema: auditoria; Owner: postgres
--

COPY auditoria.auditoria_login (id_login, usuario_app, usuario_bd, exito, ip_origen, fecha_login, id_usuario, id_item_evento) FROM stdin;
\.


--
-- TOC entry 5424 (class 0 OID 68441)
-- Dependencies: 231
-- Data for Name: auditoria_login_bd; Type: TABLE DATA; Schema: auditoria; Owner: postgres
--

COPY auditoria.auditoria_login_bd (id_auditoria_login_bd, id_usuario_bd, id_item_evento, fecha_evento, ip_origen, observacion) FROM stdin;
\.


--
-- TOC entry 5427 (class 0 OID 68449)
-- Dependencies: 234
-- Data for Name: catalogo; Type: TABLE DATA; Schema: catalogos; Owner: postgres
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
11	ESTADO_VISITA	Estados del ciclo de vida de una visita técnica a domicilio	t
\.


--
-- TOC entry 5429 (class 0 OID 68456)
-- Dependencies: 236
-- Data for Name: catalogo_item; Type: TABLE DATA; Schema: catalogos; Owner: postgres
--

COPY catalogos.catalogo_item (id_item, id_catalogo, codigo, nombre, orden, activo) FROM stdin;
2	1	INACTIVO	Inactivo	2	t
3	1	BLOQUEADO	Bloqueado	3	t
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
1	1	ACTIVO	Activo	1	t
39	3	PRIORIDAD_ULTRA	ULTRA URGENTE	5	t
10	3	BAJA	Baja	1	t
5	2	ASIGNADO	Asignado	2	t
6	2	EN_PROCESO	En proceso	3	t
7	2	RESUELTO	Resuelto	4	t
8	2	CERRADO	Cerrado	5	t
9	2	RECHAZADO	Rechazado	6	t
4	2	ABIERTO	Abierto	1	t
40	11	PROGRAMADA	Programada	1	t
41	11	CONFIRMADA	Confirmada	2	t
42	11	REPROGRAMADA	Reprogramada	3	t
43	11	CANCELADA	Cancelada	4	t
44	11	FINALIZADA	Finalizada	5	t
45	2	REQUIERE_VISITA	Requiere Visita	7	t
\.


--
-- TOC entry 5431 (class 0 OID 68461)
-- Dependencies: 238
-- Data for Name: canton; Type: TABLE DATA; Schema: clientes; Owner: postgres
--

COPY clientes.canton (id_canton, nombre, id_ciudad) FROM stdin;
1	Quito	1
2	Rumiñahui	1
3	Mejía	1
4	Guayaquil	2
5	Samborondón	2
6	Durán	2
7	Cuenca	3
8	Gualaceo	3
9	Manta	4
10	Portoviejo	4
11	Chone	4
12	Ambato	5
13	Baños de Agua Santa	5
\.


--
-- TOC entry 5433 (class 0 OID 68465)
-- Dependencies: 240
-- Data for Name: ciudad; Type: TABLE DATA; Schema: clientes; Owner: postgres
--

COPY clientes.ciudad (id_ciudad, nombre, id_pais) FROM stdin;
1	Pichincha	1
2	Guayas	1
3	Azuay	1
4	Manabí	1
5	Tungurahua	1
\.


--
-- TOC entry 5435 (class 0 OID 68469)
-- Dependencies: 242
-- Data for Name: cliente; Type: TABLE DATA; Schema: clientes; Owner: postgres
--

COPY clientes.cliente (id_cliente, id_sucursal, id_persona, fecha_inicio_contrato, fecha_fin_contrato, acceso_remoto, aprobacion_de_cambios, actualizaciones_automaticas) FROM stdin;
1	2	1	\N	\N	t	f	t
2	1	2	\N	\N	t	f	t
3	3	3	\N	\N	t	f	t
4	3	6	\N	\N	t	f	t
\.


--
-- TOC entry 5437 (class 0 OID 68476)
-- Dependencies: 244
-- Data for Name: documento_cliente; Type: TABLE DATA; Schema: clientes; Owner: postgres
--

COPY clientes.documento_cliente (id_documento, numero_documento, ruta_archivo, descripcion, fecha_subida, id_cliente, id_tipo_documento, id_catalogo_item_estado) FROM stdin;
1	0503360398	amendozab_d025aabb-c660-4440-95cd-549e70f90b27.jpg	Foto de perfil	2026-02-22 19:47:08.801353	1	1	\N
2	1250062336	azambranoy_3bbd13fc-ca97-40e4-b886-5fb733ca3d51.png	Foto de perfil	2026-02-25 12:12:44.744385	4	1	\N
\.


--
-- TOC entry 5439 (class 0 OID 68483)
-- Dependencies: 246
-- Data for Name: pais; Type: TABLE DATA; Schema: clientes; Owner: postgres
--

COPY clientes.pais (id_pais, nombre) FROM stdin;
1	Ecuador
\.


--
-- TOC entry 5441 (class 0 OID 68487)
-- Dependencies: 248
-- Data for Name: tipo_documento; Type: TABLE DATA; Schema: clientes; Owner: postgres
--

COPY clientes.tipo_documento (id_tipo_documento, codigo) FROM stdin;
1	FOTO
\.


--
-- TOC entry 5443 (class 0 OID 68491)
-- Dependencies: 250
-- Data for Name: area; Type: TABLE DATA; Schema: empleados; Owner: postgres
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
-- TOC entry 5445 (class 0 OID 68495)
-- Dependencies: 252
-- Data for Name: cargo; Type: TABLE DATA; Schema: empleados; Owner: postgres
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
-- TOC entry 5447 (class 0 OID 68499)
-- Dependencies: 254
-- Data for Name: documento_empleado; Type: TABLE DATA; Schema: empleados; Owner: postgres
--

COPY empleados.documento_empleado (id_documento, numero_documento, ruta_archivo, descripcion, fecha_subida, id_empleado, id_tipo_documento, id_catalogo_item_estado, cedula_empleado) FROM stdin;
\.


--
-- TOC entry 5450 (class 0 OID 68507)
-- Dependencies: 257
-- Data for Name: empleado; Type: TABLE DATA; Schema: empleados; Owner: postgres
--

COPY empleados.empleado (fecha_ingreso, id_cargo, id_area, id_tipo_contrato, id_empleado, id_sucursal, id_persona) FROM stdin;
\.


--
-- TOC entry 5451 (class 0 OID 68511)
-- Dependencies: 258
-- Data for Name: tipo_contrato; Type: TABLE DATA; Schema: empleados; Owner: postgres
--

COPY empleados.tipo_contrato (id_tipo_contrato, nombre) FROM stdin;
1	Indefinido
2	Temporal
3	Contrato por Servicios
4	Pasantía
5	Freelance
\.


--
-- TOC entry 5453 (class 0 OID 68515)
-- Dependencies: 260
-- Data for Name: documento_empresa; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.documento_empresa (id_documento, id_empresa, numero_documento, ruta_archivo, descripcion, fecha_subida, id_tipo_documento, id_catalogo_item_estado) FROM stdin;
\.


--
-- TOC entry 5455 (class 0 OID 68522)
-- Dependencies: 262
-- Data for Name: empresa; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.empresa (id_empresa, nombre_comercial, razon_social, ruc, tipo_empresa, correo_contacto, telefono_contacto, direccion_principal, fecha_creacion, id_catalogo_item_tipo_empresa, id_catalogo_item_estado) FROM stdin;
1	CNT	Corporación Nacional de Telecomunicaciones CNT EP	1768152560001	PUBLICA	\N	\N	\N	2026-02-22 10:54:48.394042	\N	1
2	Netlife	MEGADATOS S.A. (NETLIFE)	1792161037001	PRIVADA	\N	\N	\N	2026-02-22 10:54:48.394042	\N	1
3	Xtrim	TV CABLE / XTRIM	0990793664001	PRIVADA	\N	\N	\N	2026-02-22 10:54:48.394042	\N	1
\.


--
-- TOC entry 5457 (class 0 OID 68529)
-- Dependencies: 264
-- Data for Name: empresa_servicio; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.empresa_servicio (id_empresa, id_servicio) FROM stdin;
1	1
1	3
2	2
2	5
3	4
3	5
\.


--
-- TOC entry 5458 (class 0 OID 68532)
-- Dependencies: 265
-- Data for Name: servicio; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.servicio (id_servicio, activo, descripcion, nombre) FROM stdin;
1	t	Servicio de internet de alta velocidad para hogares.	Internet Fibra Óptica 100Mbps
2	t	Servicio de internet de alta velocidad premium.	Internet Fibra Óptica 200Mbps
3	t	Servicio de internet vía línea telefónica tradicional.	Internet DSL / Cobre
4	t	Servicio de telefonía fija sobre protocolo de internet.	Telefonía IP
5	t	Combo de internet y televisión por cable.	Plan Duo (Internet + TV)
\.


--
-- TOC entry 5460 (class 0 OID 68538)
-- Dependencies: 267
-- Data for Name: sucursal; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.sucursal (id_sucursal, id_empresa, nombre, direccion, telefono, id_ciudad, id_canton, id_catalogo_item_estado) FROM stdin;
1	1	Sucursal Matriz CNT	Dirección Principal de CNT	\N	\N	\N	1
2	2	Sucursal Matriz Netlife	Dirección Principal de Netlife	\N	\N	\N	1
3	3	Sucursal Matriz Xtrim	Dirección Principal de Xtrim	\N	\N	\N	1
\.


--
-- TOC entry 5462 (class 0 OID 68544)
-- Dependencies: 269
-- Data for Name: canal_notificacion; Type: TABLE DATA; Schema: notificaciones; Owner: postgres
--

COPY notificaciones.canal_notificacion (id_canal, nombre, activo) FROM stdin;
\.


--
-- TOC entry 5464 (class 0 OID 68549)
-- Dependencies: 271
-- Data for Name: notificacion; Type: TABLE DATA; Schema: notificaciones; Owner: postgres
--

COPY notificaciones.notificacion (id_notificacion, id_canal, destinatario, asunto, mensaje, enviado, fecha_creacion, id_ticket, id_usuario_destino, id_tipo_notificacion, id_usuario_origen, fecha_envio, error_envio, id_empresa) FROM stdin;
\.


--
-- TOC entry 5466 (class 0 OID 68557)
-- Dependencies: 273
-- Data for Name: asignacion; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.asignacion (id_asignacion, id_ticket, fecha_asignacion, activo, id_usuario) FROM stdin;
5	2	2026-02-23 09:10:56.164386	t	7
6	5	2026-02-25 12:26:31.613722	t	7
8	3	2026-02-25 12:30:36.855151	t	10
9	4	2026-02-25 14:35:55.94614	t	7
10	8	2026-02-25 14:38:15.684769	t	7
11	10	2026-02-25 18:10:10.260461	t	7
12	9	2026-02-25 18:22:51.065184	t	7
\.


--
-- TOC entry 5468 (class 0 OID 68563)
-- Dependencies: 275
-- Data for Name: categoria; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.categoria (id_categoria, descripcion, nombre, id_item) FROM stdin;
\.


--
-- TOC entry 5470 (class 0 OID 68569)
-- Dependencies: 277
-- Data for Name: comentario_ticket; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.comentario_ticket (id_comentario, id_ticket, id_usuario, contenido, visible_para_cliente, fecha_creacion, fecha_edicion, id_estado_item, comentario, es_interno, id_empresa) FROM stdin;
5	2	7	Hola, estoy revisando su conexión, ¿podría decirme si ha reiniciado el router?	t	2026-02-23 10:16:07.953439	\N	6	Hola, estoy revisando su conexión, ¿podría decirme si ha reiniciado el router?	f	1
6	4	8	Hola	t	2026-02-25 14:35:43.132682	\N	4	Hola	f	3
7	8	7	Hola	t	2026-02-25 14:39:14.421612	\N	6	Hola	f	1
8	8	8	quien eres?	t	2026-02-25 14:39:21.761781	\N	6	quien eres?	f	3
9	8	7	oye pero te sirvio la vaina?	t	2026-02-25 14:55:34.773833	\N	6	oye pero te sirvio la vaina?	f	1
10	8	8	no	t	2026-02-25 14:55:39.192055	\N	6	no	f	3
11	8	7	bueno entonces dejame asignarte a un tecnico para que vaya a su casa para que le ayude de mejor manera	t	2026-02-25 14:56:16.076948	\N	6	bueno entonces dejame asignarte a un tecnico para que vaya a su casa para que le ayude de mejor manera	f	1
12	8	8	oki	t	2026-02-25 14:56:25.52485	\N	6	oki	f	3
13	10	7	hola	t	2026-02-25 18:12:32.48315	\N	6	hola	f	1
14	10	7	niña?	t	2026-02-25 18:12:45.514623	\N	6	niña?	f	1
15	10	2	hola	t	2026-02-25 18:12:59.402264	\N	6	hola	f	1
16	10	2	mire amigo angello y angel no hacen nada, yo tampoco pero ellos deben a hacer yo no	t	2026-02-25 18:13:17.715916	\N	6	mire amigo angello y angel no hacen nada, yo tampoco pero ellos deben a hacer yo no	f	1
17	10	7	chuuuuta amiga que vaina	t	2026-02-25 18:13:26.751864	\N	6	chuuuuta amiga que vaina	f	1
\.


--
-- TOC entry 5472 (class 0 OID 68577)
-- Dependencies: 279
-- Data for Name: documento_ticket; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.documento_ticket (id_documento, id_ticket, id_tipo_documento_item, id_usuario_subio, nombre_archivo, ruta_archivo, descripcion, fecha_subida, id_estado_item) FROM stdin;
\.


--
-- TOC entry 5474 (class 0 OID 68584)
-- Dependencies: 281
-- Data for Name: historial_estado; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.historial_estado (id_historial, id_ticket, usuario_bd, fecha_cambio, observacion, id_estado_anterior, id_estado_nuevo, id_usuario, id_estado) FROM stdin;
1	2	amendozab	2026-02-23 09:09:49.367346	Ticket creado por el cliente	\N	4	4	4
2	2	adminmaster	2026-02-23 09:10:56.167995	Ticket asignado a tecnico01	4	5	6	5
3	2	tecnico01	2026-02-23 09:49:44.38284	Hola, hemos recibido su reporte. Estamos procediendo a revisar la señal desde nuestra central. Por favor, no apague su módem	5	6	7	6
4	3	azambranoy	2026-02-25 12:23:45.423802	Ticket creado por el cliente	\N	4	8	4
5	4	azambranoy	2026-02-25 12:23:47.204747	Ticket creado por el cliente	\N	4	8	4
6	5	azambranoy	2026-02-25 12:24:32.935392	Ticket creado por el cliente	\N	4	8	4
7	5	adminmaster	2026-02-25 12:26:31.618239	Ticket asignado a tecnico01	4	5	6	5
8	5	tecnico01	2026-02-25 12:27:10.269349	HOLA MI ESTIMADO	5	6	7	6
9	3	adminmaster	2026-02-25 12:30:36.855151	Ticket asignado a aza	4	5	6	5
10	5	tecnico01	2026-02-25 14:10:41.478899	asd	6	7	7	7
11	4	adminmaster	2026-02-25 14:35:55.950611	Ticket asignado a tecnico01	4	5	6	5
12	6	azambranoy	2026-02-25 14:36:52.410631	Ticket creado por el cliente	\N	4	8	4
13	7	azambranoy	2026-02-25 14:36:53.746855	Ticket creado por el cliente	\N	4	8	4
14	8	azambranoy	2026-02-25 14:37:55.422805	Ticket creado por el cliente	\N	4	8	4
15	8	adminmaster	2026-02-25 14:38:15.687768	Ticket asignado a tecnico01	4	5	6	5
16	8	tecnico01	2026-02-25 14:38:58.649038	hola	5	6	7	6
17	8	tecnico01	2026-02-25 14:56:45.216734	EL CLIENTE TIENE PROBLEMAS CON EL CABLEADO SU PERRO LE MORDIO EL CABLE	6	45	7	45
18	4	tecnico01	2026-02-25 15:02:56.961717	asd	5	6	7	6
19	9	azambranoy	2026-02-25 18:08:55.165553	Ticket creado por el cliente	\N	4	8	4
20	10	eburgosc	2026-02-25 18:09:24.949951	Ticket creado por el cliente	\N	4	2	4
21	10	adminmaster	2026-02-25 18:10:10.263491	Ticket asignado a tecnico01	4	5	6	5
22	10	tecnico01	2026-02-25 18:10:39.134253	asdasd	5	6	7	6
23	10	tecnico01	2026-02-25 18:13:36.151776	asd	6	45	7	45
24	10	tecnico01	2026-02-25 18:16:24.825773	hola	45	8	7	8
25	9	adminmaster	2026-02-25 18:22:51.067183	Ticket asignado a tecnico01	4	5	6	5
\.


--
-- TOC entry 5476 (class 0 OID 68591)
-- Dependencies: 283
-- Data for Name: prioridad; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.prioridad (id_prioridad, descripcion, nombre, id_item) FROM stdin;
\.


--
-- TOC entry 5478 (class 0 OID 68597)
-- Dependencies: 285
-- Data for Name: sla_ticket; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.sla_ticket (id_sla, nombre, descripcion, tiempo_respuesta_min, tiempo_solucion_min, aplica_prioridad, activo, fecha_creacion, id_empresa) FROM stdin;
\.


--
-- TOC entry 5480 (class 0 OID 68605)
-- Dependencies: 287
-- Data for Name: solucion_ticket; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.solucion_ticket (id_solucion, id_ticket, descripcion_solucion, fue_resuelto, fecha_solucion, id_usuario_tecnico) FROM stdin;
\.


--
-- TOC entry 5482 (class 0 OID 68612)
-- Dependencies: 289
-- Data for Name: ticket; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.ticket (id_ticket, asunto, descripcion, fecha_creacion, fecha_actualizacion, id_servicio, id_sucursal, id_sla, id_estado_item, id_prioridad_item, id_categoria_item, id_usuario_creador, id_usuario_asignado, id_cliente, fecha_cierre) FROM stdin;
1	Falla total de internet - Luz roja parpadeando	Desde hace dos horas el módem tiene la luz de LOS en color rojo. Ya intenté desconectarlo de la corriente y volverlo a conectar pero el problema persiste. No tengo navegación en ningún dispositivo.	2026-02-23 08:40:46.369847	\N	2	2	\N	4	10	14	4	\N	1	\N
2	No tengo conexión a internet desde ayer en la noche	Desde el día de ayer (21/02/2026) aproximadamente a las 21:30 no tengo conexión a internet.\nEl módem está encendido, pero la luz de "Internet" está en rojo y parpadeando constantemente.	2026-02-23 09:09:49.326989	2026-02-23 09:49:44.427913	2	2	\N	6	10	14	4	7	1	\N
3	TENGO TENGO TENGO TENGO	TENGO TENGOTENGO TENGOTENGO TENGOTENGO TENGOTENGO TENGO	2026-02-25 12:23:45.421804	2026-02-25 12:30:36.858663	4	3	\N	5	10	14	8	10	4	\N
5	GONTE GONTE GONTE GONTE	GONTE GONTE GONTE GONTE GONTE GONTE	2026-02-25 12:24:32.932886	2026-02-25 14:10:41.505698	4	3	\N	7	10	14	8	7	4	2026-02-25 14:10:41.476892
6	TENGO MI FALLITO DE RED YA SABES	TENGO MI FALLITO DE RED YA SABESTENGO MI FALLITO DE RED YA SABESTENGO MI FALLITO DE RED YA SABES	2026-02-25 14:36:52.408091	\N	4	3	\N	4	10	14	8	\N	4	\N
7	TENGO MI FALLITO DE RED YA SABES	TENGO MI FALLITO DE RED YA SABESTENGO MI FALLITO DE RED YA SABESTENGO MI FALLITO DE RED YA SABES	2026-02-25 14:36:53.743848	\N	4	3	\N	4	10	14	8	\N	4	\N
8	HOLAAAAAAAAAA	HOLAAAAAAAAAA HOLAAAAAAAAAAHOLAAAAAAAAAAHOLAAAAAAAAAA	2026-02-25 14:37:55.420797	2026-02-25 14:56:45.227352	4	3	\N	45	10	14	8	7	4	\N
4	TENGO TENGO TENGO TENGO	TENGO TENGOTENGO TENGOTENGO TENGOTENGO TENGOTENGO TENGO	2026-02-25 12:23:47.203748	2026-02-25 15:02:56.964615	4	3	\N	6	10	14	8	7	4	\N
10	INSIDENCIA SOBRE MI VAINA	asdasdsadasdasdasdasdasda	2026-02-25 18:09:24.948352	2026-02-25 18:16:24.828277	1	1	\N	8	10	14	2	7	2	2026-02-25 18:16:24.825773
9	INSIDENCIA SOBRE MI VAINA	asdasdasdsadasdasdasdasd	2026-02-25 18:08:55.147609	2026-02-25 18:22:51.0712	4	3	\N	5	10	14	8	7	4	\N
\.


--
-- TOC entry 5495 (class 0 OID 69256)
-- Dependencies: 302
-- Data for Name: visita_tecnica; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.visita_tecnica (id_visita, id_ticket, id_usuario_tecnico, id_empresa, fecha_visita, hora_inicio, hora_fin, id_catalogo_item_estado, reporte_visita, fecha_creacion, fecha_actualizacion) FROM stdin;
1	8	11	1	2026-02-26	18:40:00	19:40:00	41	\N	2026-02-25 15:34:48.079159	\N
3	10	11	1	2026-02-28	19:20:00	21:20:00	40	Hola soy angello	2026-02-25 18:15:11.22517	\N
4	8	11	1	2026-03-01	19:20:00	20:20:00	42	\N	2026-02-25 18:18:51.618675	\N
\.


--
-- TOC entry 5484 (class 0 OID 68619)
-- Dependencies: 291
-- Data for Name: persona; Type: TABLE DATA; Schema: usuarios; Owner: postgres
--

COPY usuarios.persona (id_persona, cedula, nombre, apellido, celular, correo, fecha_nacimiento, direccion, id_canton, fecha_creacion, fecha_actualizacion, id_usuario, ruta_foto) FROM stdin;
3	1207910165	Justyn Keith	Cruz Perez	\N	justyncruzperez@gmail.com	\N	\N	\N	2026-02-22 10:54:48.394042	\N	\N	\N
2	1207445154	Elizabeth Anahis	Burgos Chilan	\N	elizabethanahisb@gmail.com	\N	\N	\N	2026-02-22 10:54:48.394042	2026-02-22 12:30:37.862134	2	\N
1	0503360398	Angello Agustin	Mendoza Bermello	0963136286	angellomendoza46@gmail.com	\N	\N	\N	2026-02-22 10:54:48.394042	2026-02-22 20:03:32.504119	4	\N
5	9999999999	Super	Administrador	0999999999	admin@sgim.com	\N	\N	\N	2026-02-22 20:31:01.463502	\N	6	\N
6	1250062336	Angel Daniel	Zambrano Yong	0995220227	azambranoy@uteq.edu.ec	\N	\N	\N	2026-02-25 12:08:45.194564	2026-02-25 12:13:04.427962	8	\N
\.


--
-- TOC entry 5486 (class 0 OID 68626)
-- Dependencies: 293
-- Data for Name: rol; Type: TABLE DATA; Schema: usuarios; Owner: postgres
--

COPY usuarios.rol (id_rol, codigo, descripcion) FROM stdin;
1	CLIENTE	Usuario cliente del sistema
2	TECNICO	Empleado técnico
3	ADMIN_TECNICOS	Administrador de técnicos
4	ADMIN_MASTER	Administrador general del sistema
5	ADMIN_VISUAL	Administrador solo lectura
\.


--
-- TOC entry 5487 (class 0 OID 68631)
-- Dependencies: 294
-- Data for Name: rol_bd; Type: TABLE DATA; Schema: usuarios; Owner: postgres
--

COPY usuarios.rol_bd (id_rol_bd, nombre, descripcion) FROM stdin;
1	rol_cliente	Rol base de datos clientes
2	rol_tecnico	Rol base de datos técnicos
3	rol_admin_tecnicos	Rol BD administrador técnicos
4	rol_admin_master	Rol BD administrador master
5	rol_admin_visual	Rol BD administrador visual
\.


--
-- TOC entry 5490 (class 0 OID 68638)
-- Dependencies: 297
-- Data for Name: usuario; Type: TABLE DATA; Schema: usuarios; Owner: postgres
--

COPY usuarios.usuario (id_usuario, username, password_hash, primer_login, id_rol, fecha_creacion, fecha_actualizacion, id_empresa, id_catalogo_item_estado) FROM stdin;
2	eburgosc	$2a$10$PEbYXTN/uQaNKujO/o9Hx.I9SmZQDrxrvcdm/iYptWou1XeDthNzO	f	1	2026-02-22 12:30:37.808543	2026-02-23 10:49:48.356337	1	27
4	amendozab	$2a$10$3leWLakWmgwhWQKpWz49UOdtCrobxA9TjAOXr2jFpBRcNjVH.iVeu	f	1	2026-02-22 19:45:13.203058	2026-02-23 10:50:21.310149	2	27
8	azambranoy	$2a$10$3dXvEbYOQNDOneJwRArYyejwrXbMn5Lp0FzqKpm.hqbHsiWQY5QvC	f	1	2026-02-25 12:11:27.164129	2026-02-25 12:12:32.740128	3	27
10	aza	$2a$10$31ZZkoaZ9stog.hZ90NVMu3f67IZ7UQxch8pJtTJtGWjNO5FYKu/O	f	2	2026-02-25 12:29:53.929094	2026-02-25 12:30:13.940889	1	27
7	tecnico01	$2a$10$1WnPLfhgkNoQ29Caq9hwDu0iGm186wUyw7lonDkVZP/xZ2/PQvycS	f	2	2026-02-23 08:58:54.4776	2026-02-23 09:00:35.768315	1	27
6	adminmaster	$2a$06$KUSBFI.E1d/PpaKW/rDozumKoIcoyV4E.44mcuxmnCgMkoiwuoQYe	f	4	2026-02-22 20:31:01.463502	\N	1	1
11	tecnicoadmin	$2a$10$pKe5IhDOMug5X0dd.syqaONl4BBz3n/ZEjKgntyUu8hcq.7vZbTh2	f	3	2026-02-25 14:16:34.950027	2026-02-25 14:17:06.576042	1	27
\.


--
-- TOC entry 5491 (class 0 OID 68645)
-- Dependencies: 298
-- Data for Name: usuario_bd; Type: TABLE DATA; Schema: usuarios; Owner: postgres
--

COPY usuarios.usuario_bd (id_usuario_bd, nombre, id_rol_bd, fecha_creacion, id_usuario) FROM stdin;
\.


--
-- TOC entry 5540 (class 0 OID 0)
-- Dependencies: 227
-- Name: auditoria_estado_ticket_id_auditoria_seq; Type: SEQUENCE SET; Schema: auditoria; Owner: postgres
--

SELECT pg_catalog.setval('auditoria.auditoria_estado_ticket_id_auditoria_seq', 1, false);


--
-- TOC entry 5541 (class 0 OID 0)
-- Dependencies: 229
-- Name: auditoria_evento_id_evento_seq; Type: SEQUENCE SET; Schema: auditoria; Owner: postgres
--

SELECT pg_catalog.setval('auditoria.auditoria_evento_id_evento_seq', 1, false);


--
-- TOC entry 5542 (class 0 OID 0)
-- Dependencies: 232
-- Name: auditoria_login_bd_id_auditoria_login_bd_seq; Type: SEQUENCE SET; Schema: auditoria; Owner: postgres
--

SELECT pg_catalog.setval('auditoria.auditoria_login_bd_id_auditoria_login_bd_seq', 1, false);


--
-- TOC entry 5543 (class 0 OID 0)
-- Dependencies: 233
-- Name: auditoria_login_id_login_seq; Type: SEQUENCE SET; Schema: auditoria; Owner: postgres
--

SELECT pg_catalog.setval('auditoria.auditoria_login_id_login_seq', 1, false);


--
-- TOC entry 5544 (class 0 OID 0)
-- Dependencies: 235
-- Name: catalogo_id_catalogo_seq; Type: SEQUENCE SET; Schema: catalogos; Owner: postgres
--

SELECT pg_catalog.setval('catalogos.catalogo_id_catalogo_seq', 10, true);


--
-- TOC entry 5545 (class 0 OID 0)
-- Dependencies: 237
-- Name: catalogo_item_id_item_seq; Type: SEQUENCE SET; Schema: catalogos; Owner: postgres
--

SELECT pg_catalog.setval('catalogos.catalogo_item_id_item_seq', 39, true);


--
-- TOC entry 5546 (class 0 OID 0)
-- Dependencies: 239
-- Name: canton_id_canton_seq; Type: SEQUENCE SET; Schema: clientes; Owner: postgres
--

SELECT pg_catalog.setval('clientes.canton_id_canton_seq', 1, false);


--
-- TOC entry 5547 (class 0 OID 0)
-- Dependencies: 241
-- Name: ciudad_id_ciudad_seq; Type: SEQUENCE SET; Schema: clientes; Owner: postgres
--

SELECT pg_catalog.setval('clientes.ciudad_id_ciudad_seq', 1, false);


--
-- TOC entry 5548 (class 0 OID 0)
-- Dependencies: 243
-- Name: cliente_id_cliente_seq; Type: SEQUENCE SET; Schema: clientes; Owner: postgres
--

SELECT pg_catalog.setval('clientes.cliente_id_cliente_seq', 4, true);


--
-- TOC entry 5549 (class 0 OID 0)
-- Dependencies: 245
-- Name: documento_cliente_id_documento_seq; Type: SEQUENCE SET; Schema: clientes; Owner: postgres
--

SELECT pg_catalog.setval('clientes.documento_cliente_id_documento_seq', 2, true);


--
-- TOC entry 5550 (class 0 OID 0)
-- Dependencies: 247
-- Name: pais_id_pais_seq; Type: SEQUENCE SET; Schema: clientes; Owner: postgres
--

SELECT pg_catalog.setval('clientes.pais_id_pais_seq', 1, false);


--
-- TOC entry 5551 (class 0 OID 0)
-- Dependencies: 249
-- Name: tipo_documento_id_tipo_documento_seq; Type: SEQUENCE SET; Schema: clientes; Owner: postgres
--

SELECT pg_catalog.setval('clientes.tipo_documento_id_tipo_documento_seq', 2, true);


--
-- TOC entry 5552 (class 0 OID 0)
-- Dependencies: 251
-- Name: area_id_area_seq; Type: SEQUENCE SET; Schema: empleados; Owner: postgres
--

SELECT pg_catalog.setval('empleados.area_id_area_seq', 7, true);


--
-- TOC entry 5553 (class 0 OID 0)
-- Dependencies: 253
-- Name: cargo_id_cargo_seq; Type: SEQUENCE SET; Schema: empleados; Owner: postgres
--

SELECT pg_catalog.setval('empleados.cargo_id_cargo_seq', 8, true);


--
-- TOC entry 5554 (class 0 OID 0)
-- Dependencies: 255
-- Name: documento_empleado_id_documento_seq; Type: SEQUENCE SET; Schema: empleados; Owner: postgres
--

SELECT pg_catalog.setval('empleados.documento_empleado_id_documento_seq', 1, false);


--
-- TOC entry 5555 (class 0 OID 0)
-- Dependencies: 256
-- Name: empleado_id_empleado_seq; Type: SEQUENCE SET; Schema: empleados; Owner: postgres
--

SELECT pg_catalog.setval('empleados.empleado_id_empleado_seq', 4, true);


--
-- TOC entry 5556 (class 0 OID 0)
-- Dependencies: 259
-- Name: tipo_contrato_id_tipo_contrato_seq; Type: SEQUENCE SET; Schema: empleados; Owner: postgres
--

SELECT pg_catalog.setval('empleados.tipo_contrato_id_tipo_contrato_seq', 5, true);


--
-- TOC entry 5557 (class 0 OID 0)
-- Dependencies: 261
-- Name: documento_empresa_id_documento_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.documento_empresa_id_documento_seq', 1, false);


--
-- TOC entry 5558 (class 0 OID 0)
-- Dependencies: 263
-- Name: empresa_id_empresa_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.empresa_id_empresa_seq', 4, true);


--
-- TOC entry 5559 (class 0 OID 0)
-- Dependencies: 266
-- Name: servicio_id_servicio_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.servicio_id_servicio_seq', 5, true);


--
-- TOC entry 5560 (class 0 OID 0)
-- Dependencies: 268
-- Name: sucursal_id_sucursal_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.sucursal_id_sucursal_seq', 3, true);


--
-- TOC entry 5561 (class 0 OID 0)
-- Dependencies: 270
-- Name: canal_notificacion_id_canal_seq; Type: SEQUENCE SET; Schema: notificaciones; Owner: postgres
--

SELECT pg_catalog.setval('notificaciones.canal_notificacion_id_canal_seq', 1, false);


--
-- TOC entry 5562 (class 0 OID 0)
-- Dependencies: 272
-- Name: notificacion_id_notificacion_seq; Type: SEQUENCE SET; Schema: notificaciones; Owner: postgres
--

SELECT pg_catalog.setval('notificaciones.notificacion_id_notificacion_seq', 4, true);


--
-- TOC entry 5563 (class 0 OID 0)
-- Dependencies: 274
-- Name: asignacion_id_asignacion_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.asignacion_id_asignacion_seq', 12, true);


--
-- TOC entry 5564 (class 0 OID 0)
-- Dependencies: 276
-- Name: categoria_id_categoria_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.categoria_id_categoria_seq', 1, false);


--
-- TOC entry 5565 (class 0 OID 0)
-- Dependencies: 278
-- Name: comentario_ticket_id_comentario_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.comentario_ticket_id_comentario_seq', 17, true);


--
-- TOC entry 5566 (class 0 OID 0)
-- Dependencies: 280
-- Name: documento_ticket_id_documento_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.documento_ticket_id_documento_seq', 1, false);


--
-- TOC entry 5567 (class 0 OID 0)
-- Dependencies: 282
-- Name: historial_estado_id_historial_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.historial_estado_id_historial_seq', 25, true);


--
-- TOC entry 5568 (class 0 OID 0)
-- Dependencies: 284
-- Name: prioridad_id_prioridad_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.prioridad_id_prioridad_seq', 1, false);


--
-- TOC entry 5569 (class 0 OID 0)
-- Dependencies: 286
-- Name: sla_ticket_id_sla_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.sla_ticket_id_sla_seq', 1, false);


--
-- TOC entry 5570 (class 0 OID 0)
-- Dependencies: 288
-- Name: solucion_ticket_id_solucion_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.solucion_ticket_id_solucion_seq', 1, false);


--
-- TOC entry 5571 (class 0 OID 0)
-- Dependencies: 290
-- Name: ticket_id_ticket_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.ticket_id_ticket_seq', 10, true);


--
-- TOC entry 5572 (class 0 OID 0)
-- Dependencies: 301
-- Name: visita_tecnica_id_visita_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.visita_tecnica_id_visita_seq', 4, true);


--
-- TOC entry 5573 (class 0 OID 0)
-- Dependencies: 292
-- Name: persona_id_persona_seq; Type: SEQUENCE SET; Schema: usuarios; Owner: postgres
--

SELECT pg_catalog.setval('usuarios.persona_id_persona_seq', 7, true);


--
-- TOC entry 5574 (class 0 OID 0)
-- Dependencies: 295
-- Name: rol_bd_id_rol_bd_seq; Type: SEQUENCE SET; Schema: usuarios; Owner: postgres
--

SELECT pg_catalog.setval('usuarios.rol_bd_id_rol_bd_seq', 5, true);


--
-- TOC entry 5575 (class 0 OID 0)
-- Dependencies: 296
-- Name: rol_id_rol_seq; Type: SEQUENCE SET; Schema: usuarios; Owner: postgres
--

SELECT pg_catalog.setval('usuarios.rol_id_rol_seq', 5, true);


--
-- TOC entry 5576 (class 0 OID 0)
-- Dependencies: 299
-- Name: usuario_bd_id_usuario_bd_seq; Type: SEQUENCE SET; Schema: usuarios; Owner: postgres
--

SELECT pg_catalog.setval('usuarios.usuario_bd_id_usuario_bd_seq', 1, false);


--
-- TOC entry 5577 (class 0 OID 0)
-- Dependencies: 300
-- Name: usuario_id_usuario_seq; Type: SEQUENCE SET; Schema: usuarios; Owner: postgres
--

SELECT pg_catalog.setval('usuarios.usuario_id_usuario_seq', 10, true);


--
-- TOC entry 5054 (class 2606 OID 68688)
-- Name: auditoria_estado_ticket auditoria_estado_ticket_pkey; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT auditoria_estado_ticket_pkey PRIMARY KEY (id_auditoria);


--
-- TOC entry 5056 (class 2606 OID 68690)
-- Name: auditoria_evento auditoria_evento_pkey; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_evento
    ADD CONSTRAINT auditoria_evento_pkey PRIMARY KEY (id_evento);


--
-- TOC entry 5060 (class 2606 OID 68692)
-- Name: auditoria_login_bd auditoria_login_bd_pkey; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd
    ADD CONSTRAINT auditoria_login_bd_pkey PRIMARY KEY (id_auditoria_login_bd);


--
-- TOC entry 5058 (class 2606 OID 68694)
-- Name: auditoria_login auditoria_login_pkey; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login
    ADD CONSTRAINT auditoria_login_pkey PRIMARY KEY (id_login);


--
-- TOC entry 5066 (class 2606 OID 68696)
-- Name: catalogo_item catalogo_item_pkey; Type: CONSTRAINT; Schema: catalogos; Owner: postgres
--

ALTER TABLE ONLY catalogos.catalogo_item
    ADD CONSTRAINT catalogo_item_pkey PRIMARY KEY (id_item);


--
-- TOC entry 5062 (class 2606 OID 68698)
-- Name: catalogo catalogo_nombre_key; Type: CONSTRAINT; Schema: catalogos; Owner: postgres
--

ALTER TABLE ONLY catalogos.catalogo
    ADD CONSTRAINT catalogo_nombre_key UNIQUE (nombre);


--
-- TOC entry 5064 (class 2606 OID 68700)
-- Name: catalogo catalogo_pkey; Type: CONSTRAINT; Schema: catalogos; Owner: postgres
--

ALTER TABLE ONLY catalogos.catalogo
    ADD CONSTRAINT catalogo_pkey PRIMARY KEY (id_catalogo);


--
-- TOC entry 5068 (class 2606 OID 68702)
-- Name: canton canton_pkey; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.canton
    ADD CONSTRAINT canton_pkey PRIMARY KEY (id_canton);


--
-- TOC entry 5070 (class 2606 OID 68704)
-- Name: ciudad ciudad_pkey; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.ciudad
    ADD CONSTRAINT ciudad_pkey PRIMARY KEY (id_ciudad);


--
-- TOC entry 5078 (class 2606 OID 68706)
-- Name: documento_cliente documento_cliente_pkey; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.documento_cliente
    ADD CONSTRAINT documento_cliente_pkey PRIMARY KEY (id_documento);


--
-- TOC entry 5082 (class 2606 OID 68708)
-- Name: pais pais_nombre_key; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.pais
    ADD CONSTRAINT pais_nombre_key UNIQUE (nombre);


--
-- TOC entry 5084 (class 2606 OID 68710)
-- Name: pais pais_pkey; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.pais
    ADD CONSTRAINT pais_pkey PRIMARY KEY (id_pais);


--
-- TOC entry 5072 (class 2606 OID 68712)
-- Name: cliente pk_cliente; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.cliente
    ADD CONSTRAINT pk_cliente PRIMARY KEY (id_cliente);


--
-- TOC entry 5086 (class 2606 OID 68714)
-- Name: tipo_documento tipo_documento_codigo_key; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.tipo_documento
    ADD CONSTRAINT tipo_documento_codigo_key UNIQUE (codigo);


--
-- TOC entry 5088 (class 2606 OID 68716)
-- Name: tipo_documento tipo_documento_pkey; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.tipo_documento
    ADD CONSTRAINT tipo_documento_pkey PRIMARY KEY (id_tipo_documento);


--
-- TOC entry 5074 (class 2606 OID 68718)
-- Name: cliente uq_cliente_id_cliente; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.cliente
    ADD CONSTRAINT uq_cliente_id_cliente UNIQUE (id_cliente);


--
-- TOC entry 5076 (class 2606 OID 68720)
-- Name: cliente uq_cliente_persona; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.cliente
    ADD CONSTRAINT uq_cliente_persona UNIQUE (id_persona);


--
-- TOC entry 5080 (class 2606 OID 68722)
-- Name: documento_cliente uq_documento_cliente; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.documento_cliente
    ADD CONSTRAINT uq_documento_cliente UNIQUE (id_tipo_documento, numero_documento);


--
-- TOC entry 5090 (class 2606 OID 68724)
-- Name: area area_nombre_key; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.area
    ADD CONSTRAINT area_nombre_key UNIQUE (nombre);


--
-- TOC entry 5092 (class 2606 OID 68726)
-- Name: area area_pkey; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.area
    ADD CONSTRAINT area_pkey PRIMARY KEY (id_area);


--
-- TOC entry 5094 (class 2606 OID 68728)
-- Name: cargo cargo_nombre_key; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.cargo
    ADD CONSTRAINT cargo_nombre_key UNIQUE (nombre);


--
-- TOC entry 5096 (class 2606 OID 68730)
-- Name: cargo cargo_pkey; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.cargo
    ADD CONSTRAINT cargo_pkey PRIMARY KEY (id_cargo);


--
-- TOC entry 5098 (class 2606 OID 68732)
-- Name: documento_empleado documento_empleado_pkey; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.documento_empleado
    ADD CONSTRAINT documento_empleado_pkey PRIMARY KEY (id_documento);


--
-- TOC entry 5100 (class 2606 OID 68734)
-- Name: empleado pk_empleado; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT pk_empleado PRIMARY KEY (id_empleado);


--
-- TOC entry 5106 (class 2606 OID 68736)
-- Name: tipo_contrato tipo_contrato_nombre_key; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.tipo_contrato
    ADD CONSTRAINT tipo_contrato_nombre_key UNIQUE (nombre);


--
-- TOC entry 5108 (class 2606 OID 68738)
-- Name: tipo_contrato tipo_contrato_pkey; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.tipo_contrato
    ADD CONSTRAINT tipo_contrato_pkey PRIMARY KEY (id_tipo_contrato);


--
-- TOC entry 5102 (class 2606 OID 68740)
-- Name: empleado uq_empleado_id_empleado; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT uq_empleado_id_empleado UNIQUE (id_empleado);


--
-- TOC entry 5104 (class 2606 OID 68742)
-- Name: empleado uq_empleado_persona; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT uq_empleado_persona UNIQUE (id_persona);


--
-- TOC entry 5110 (class 2606 OID 68744)
-- Name: documento_empresa documento_empresa_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.documento_empresa
    ADD CONSTRAINT documento_empresa_pkey PRIMARY KEY (id_documento);


--
-- TOC entry 5114 (class 2606 OID 68746)
-- Name: empresa empresa_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.empresa
    ADD CONSTRAINT empresa_pkey PRIMARY KEY (id_empresa);


--
-- TOC entry 5116 (class 2606 OID 68748)
-- Name: empresa empresa_ruc_key; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.empresa
    ADD CONSTRAINT empresa_ruc_key UNIQUE (ruc);


--
-- TOC entry 5118 (class 2606 OID 68750)
-- Name: empresa_servicio empresa_servicio_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.empresa_servicio
    ADD CONSTRAINT empresa_servicio_pkey PRIMARY KEY (id_empresa, id_servicio);


--
-- TOC entry 5120 (class 2606 OID 68752)
-- Name: servicio servicio_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.servicio
    ADD CONSTRAINT servicio_pkey PRIMARY KEY (id_servicio);


--
-- TOC entry 5124 (class 2606 OID 68754)
-- Name: sucursal sucursal_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.sucursal
    ADD CONSTRAINT sucursal_pkey PRIMARY KEY (id_sucursal);


--
-- TOC entry 5122 (class 2606 OID 68756)
-- Name: servicio uk_5sp1r1csf8w09psuq7p8fatbs; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.servicio
    ADD CONSTRAINT uk_5sp1r1csf8w09psuq7p8fatbs UNIQUE (nombre);


--
-- TOC entry 5112 (class 2606 OID 68758)
-- Name: documento_empresa uq_documento_empresa; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.documento_empresa
    ADD CONSTRAINT uq_documento_empresa UNIQUE (id_tipo_documento, numero_documento);


--
-- TOC entry 5126 (class 2606 OID 68760)
-- Name: canal_notificacion canal_notificacion_pkey; Type: CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.canal_notificacion
    ADD CONSTRAINT canal_notificacion_pkey PRIMARY KEY (id_canal);


--
-- TOC entry 5130 (class 2606 OID 68762)
-- Name: notificacion notificacion_pkey; Type: CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.notificacion
    ADD CONSTRAINT notificacion_pkey PRIMARY KEY (id_notificacion);


--
-- TOC entry 5128 (class 2606 OID 68764)
-- Name: canal_notificacion uq_canal_nombre; Type: CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.canal_notificacion
    ADD CONSTRAINT uq_canal_nombre UNIQUE (nombre);


--
-- TOC entry 5132 (class 2606 OID 68766)
-- Name: asignacion asignacion_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.asignacion
    ADD CONSTRAINT asignacion_pkey PRIMARY KEY (id_asignacion);


--
-- TOC entry 5135 (class 2606 OID 68768)
-- Name: categoria categoria_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.categoria
    ADD CONSTRAINT categoria_pkey PRIMARY KEY (id_categoria);


--
-- TOC entry 5139 (class 2606 OID 68770)
-- Name: comentario_ticket comentario_ticket_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket
    ADD CONSTRAINT comentario_ticket_pkey PRIMARY KEY (id_comentario);


--
-- TOC entry 5141 (class 2606 OID 68772)
-- Name: documento_ticket documento_ticket_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.documento_ticket
    ADD CONSTRAINT documento_ticket_pkey PRIMARY KEY (id_documento);


--
-- TOC entry 5143 (class 2606 OID 68774)
-- Name: historial_estado historial_estado_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT historial_estado_pkey PRIMARY KEY (id_historial);


--
-- TOC entry 5145 (class 2606 OID 68776)
-- Name: prioridad prioridad_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.prioridad
    ADD CONSTRAINT prioridad_pkey PRIMARY KEY (id_prioridad);


--
-- TOC entry 5149 (class 2606 OID 68778)
-- Name: sla_ticket sla_ticket_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.sla_ticket
    ADD CONSTRAINT sla_ticket_pkey PRIMARY KEY (id_sla);


--
-- TOC entry 5151 (class 2606 OID 68780)
-- Name: solucion_ticket solucion_ticket_id_ticket_key; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.solucion_ticket
    ADD CONSTRAINT solucion_ticket_id_ticket_key UNIQUE (id_ticket);


--
-- TOC entry 5153 (class 2606 OID 68782)
-- Name: solucion_ticket solucion_ticket_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.solucion_ticket
    ADD CONSTRAINT solucion_ticket_pkey PRIMARY KEY (id_solucion);


--
-- TOC entry 5155 (class 2606 OID 68784)
-- Name: ticket ticket_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT ticket_pkey PRIMARY KEY (id_ticket);


--
-- TOC entry 5137 (class 2606 OID 68786)
-- Name: categoria uk_35t4wyxqrevf09uwx9e9p6o75; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.categoria
    ADD CONSTRAINT uk_35t4wyxqrevf09uwx9e9p6o75 UNIQUE (nombre);


--
-- TOC entry 5147 (class 2606 OID 68788)
-- Name: prioridad uk_a578rljygcxqa65srjnxib9le; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.prioridad
    ADD CONSTRAINT uk_a578rljygcxqa65srjnxib9le UNIQUE (nombre);


--
-- TOC entry 5181 (class 2606 OID 69264)
-- Name: visita_tecnica visita_tecnica_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.visita_tecnica
    ADD CONSTRAINT visita_tecnica_pkey PRIMARY KEY (id_visita);


--
-- TOC entry 5157 (class 2606 OID 68790)
-- Name: persona persona_cedula_key; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.persona
    ADD CONSTRAINT persona_cedula_key UNIQUE (cedula);


--
-- TOC entry 5159 (class 2606 OID 68792)
-- Name: persona persona_id_usuario_key; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.persona
    ADD CONSTRAINT persona_id_usuario_key UNIQUE (id_usuario);


--
-- TOC entry 5161 (class 2606 OID 68794)
-- Name: persona persona_pkey; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.persona
    ADD CONSTRAINT persona_pkey PRIMARY KEY (id_persona);


--
-- TOC entry 5167 (class 2606 OID 68796)
-- Name: rol_bd rol_bd_nombre_key; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.rol_bd
    ADD CONSTRAINT rol_bd_nombre_key UNIQUE (nombre);


--
-- TOC entry 5169 (class 2606 OID 68798)
-- Name: rol_bd rol_bd_pkey; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.rol_bd
    ADD CONSTRAINT rol_bd_pkey PRIMARY KEY (id_rol_bd);


--
-- TOC entry 5163 (class 2606 OID 68800)
-- Name: rol rol_codigo_key; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.rol
    ADD CONSTRAINT rol_codigo_key UNIQUE (codigo);


--
-- TOC entry 5165 (class 2606 OID 68802)
-- Name: rol rol_pkey; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id_rol);


--
-- TOC entry 5171 (class 2606 OID 68804)
-- Name: usuario uk863n1y3x0jalatoir4325ehal; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT uk863n1y3x0jalatoir4325ehal UNIQUE (username);


--
-- TOC entry 5177 (class 2606 OID 68806)
-- Name: usuario_bd usuario_bd_nombre_key; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_bd
    ADD CONSTRAINT usuario_bd_nombre_key UNIQUE (nombre);


--
-- TOC entry 5179 (class 2606 OID 68808)
-- Name: usuario_bd usuario_bd_pkey; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_bd
    ADD CONSTRAINT usuario_bd_pkey PRIMARY KEY (id_usuario_bd);


--
-- TOC entry 5173 (class 2606 OID 68810)
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id_usuario);


--
-- TOC entry 5175 (class 2606 OID 68812)
-- Name: usuario usuario_username_key; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT usuario_username_key UNIQUE (username);


--
-- TOC entry 5133 (class 1259 OID 68813)
-- Name: uq_asignacion_activa; Type: INDEX; Schema: soporte; Owner: postgres
--

CREATE UNIQUE INDEX uq_asignacion_activa ON soporte.asignacion USING btree (id_ticket) WHERE (activo = true);


--
-- TOC entry 5182 (class 2606 OID 68814)
-- Name: auditoria_estado_ticket fk_aud_estado_ant; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_aud_estado_ant FOREIGN KEY (id_estado_anterior) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5190 (class 2606 OID 68819)
-- Name: auditoria_login fk_aud_login_usuario; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login
    ADD CONSTRAINT fk_aud_login_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 5188 (class 2606 OID 68824)
-- Name: auditoria_evento fk_auditoria_accion; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_evento
    ADD CONSTRAINT fk_auditoria_accion FOREIGN KEY (id_accion_item) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5183 (class 2606 OID 68829)
-- Name: auditoria_estado_ticket fk_auditoria_estado_ticket; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_auditoria_estado_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 5184 (class 2606 OID 68834)
-- Name: auditoria_estado_ticket fk_auditoria_estado_ticket_estado; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_auditoria_estado_ticket_estado FOREIGN KEY (id_estado_nuevo_item) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5185 (class 2606 OID 68839)
-- Name: auditoria_estado_ticket fk_auditoria_estado_ticket_evento; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_auditoria_estado_ticket_evento FOREIGN KEY (id_item_evento) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5186 (class 2606 OID 68844)
-- Name: auditoria_estado_ticket fk_auditoria_estado_ticket_ticket; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_auditoria_estado_ticket_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5187 (class 2606 OID 68849)
-- Name: auditoria_estado_ticket fk_auditoria_estado_ticket_usuario; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_auditoria_estado_ticket_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5193 (class 2606 OID 68854)
-- Name: auditoria_login_bd fk_auditoria_login_bd_evento; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd
    ADD CONSTRAINT fk_auditoria_login_bd_evento FOREIGN KEY (id_item_evento) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5194 (class 2606 OID 68859)
-- Name: auditoria_login_bd fk_auditoria_login_bd_usuario; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd
    ADD CONSTRAINT fk_auditoria_login_bd_usuario FOREIGN KEY (id_usuario_bd) REFERENCES usuarios.usuario_bd(id_usuario_bd) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5195 (class 2606 OID 68864)
-- Name: auditoria_login_bd fk_auditoria_login_bd_usuario_bd; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd
    ADD CONSTRAINT fk_auditoria_login_bd_usuario_bd FOREIGN KEY (id_usuario_bd) REFERENCES usuarios.usuario_bd(id_usuario_bd) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5191 (class 2606 OID 68869)
-- Name: auditoria_login fk_auditoria_login_evento; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login
    ADD CONSTRAINT fk_auditoria_login_evento FOREIGN KEY (id_item_evento) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5192 (class 2606 OID 68874)
-- Name: auditoria_login fk_auditoria_login_usuario; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login
    ADD CONSTRAINT fk_auditoria_login_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5189 (class 2606 OID 68879)
-- Name: auditoria_evento fk_auditoria_usuario; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_evento
    ADD CONSTRAINT fk_auditoria_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 5196 (class 2606 OID 68884)
-- Name: auditoria_login_bd fk_login_bd_evento; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd
    ADD CONSTRAINT fk_login_bd_evento FOREIGN KEY (id_item_evento) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5197 (class 2606 OID 68889)
-- Name: catalogo_item catalogo_item_id_catalogo_fkey; Type: FK CONSTRAINT; Schema: catalogos; Owner: postgres
--

ALTER TABLE ONLY catalogos.catalogo_item
    ADD CONSTRAINT catalogo_item_id_catalogo_fkey FOREIGN KEY (id_catalogo) REFERENCES catalogos.catalogo(id_catalogo);


--
-- TOC entry 5198 (class 2606 OID 68894)
-- Name: canton fk_canton_ciudad; Type: FK CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.canton
    ADD CONSTRAINT fk_canton_ciudad FOREIGN KEY (id_ciudad) REFERENCES clientes.ciudad(id_ciudad);


--
-- TOC entry 5199 (class 2606 OID 68899)
-- Name: ciudad fk_ciudad_pais; Type: FK CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.ciudad
    ADD CONSTRAINT fk_ciudad_pais FOREIGN KEY (id_pais) REFERENCES clientes.pais(id_pais);


--
-- TOC entry 5200 (class 2606 OID 68904)
-- Name: cliente fk_cliente_persona; Type: FK CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.cliente
    ADD CONSTRAINT fk_cliente_persona FOREIGN KEY (id_persona) REFERENCES usuarios.persona(id_persona) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5201 (class 2606 OID 68909)
-- Name: cliente fk_cliente_sucursal; Type: FK CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.cliente
    ADD CONSTRAINT fk_cliente_sucursal FOREIGN KEY (id_sucursal) REFERENCES empresa.sucursal(id_sucursal);


--
-- TOC entry 5202 (class 2606 OID 68914)
-- Name: documento_cliente fk_doc_cli_estado; Type: FK CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.documento_cliente
    ADD CONSTRAINT fk_doc_cli_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5203 (class 2606 OID 68919)
-- Name: documento_cliente fk_documento_cliente_cliente; Type: FK CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.documento_cliente
    ADD CONSTRAINT fk_documento_cliente_cliente FOREIGN KEY (id_cliente) REFERENCES clientes.cliente(id_cliente);


--
-- TOC entry 5204 (class 2606 OID 68924)
-- Name: documento_cliente fk_documento_tipo; Type: FK CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.documento_cliente
    ADD CONSTRAINT fk_documento_tipo FOREIGN KEY (id_tipo_documento) REFERENCES clientes.tipo_documento(id_tipo_documento);


--
-- TOC entry 5205 (class 2606 OID 68929)
-- Name: documento_empleado fk_doc_emp_estado; Type: FK CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.documento_empleado
    ADD CONSTRAINT fk_doc_emp_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5206 (class 2606 OID 68934)
-- Name: documento_empleado fk_doc_emp_tipo_documento; Type: FK CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.documento_empleado
    ADD CONSTRAINT fk_doc_emp_tipo_documento FOREIGN KEY (id_tipo_documento) REFERENCES clientes.tipo_documento(id_tipo_documento);


--
-- TOC entry 5207 (class 2606 OID 68939)
-- Name: documento_empleado fk_documento_empleado_empleado; Type: FK CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.documento_empleado
    ADD CONSTRAINT fk_documento_empleado_empleado FOREIGN KEY (id_empleado) REFERENCES empleados.empleado(id_empleado);


--
-- TOC entry 5208 (class 2606 OID 68944)
-- Name: empleado fk_empleado_area; Type: FK CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT fk_empleado_area FOREIGN KEY (id_area) REFERENCES empleados.area(id_area);


--
-- TOC entry 5209 (class 2606 OID 68949)
-- Name: empleado fk_empleado_cargo; Type: FK CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT fk_empleado_cargo FOREIGN KEY (id_cargo) REFERENCES empleados.cargo(id_cargo);


--
-- TOC entry 5210 (class 2606 OID 68954)
-- Name: empleado fk_empleado_persona; Type: FK CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT fk_empleado_persona FOREIGN KEY (id_persona) REFERENCES usuarios.persona(id_persona) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5211 (class 2606 OID 68959)
-- Name: empleado fk_empleado_sucursal; Type: FK CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT fk_empleado_sucursal FOREIGN KEY (id_sucursal) REFERENCES empresa.sucursal(id_sucursal);


--
-- TOC entry 5212 (class 2606 OID 68964)
-- Name: empleado fk_empleado_tipo_contrato_catalogo; Type: FK CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT fk_empleado_tipo_contrato_catalogo FOREIGN KEY (id_tipo_contrato) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5213 (class 2606 OID 68969)
-- Name: documento_empresa documento_empresa_id_empresa_fkey; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.documento_empresa
    ADD CONSTRAINT documento_empresa_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa);


--
-- TOC entry 5218 (class 2606 OID 68974)
-- Name: empresa_servicio fk4v8ptw3ao3v85rsfvpm19cjpx; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.empresa_servicio
    ADD CONSTRAINT fk4v8ptw3ao3v85rsfvpm19cjpx FOREIGN KEY (id_servicio) REFERENCES empresa.servicio(id_servicio);


--
-- TOC entry 5214 (class 2606 OID 68979)
-- Name: documento_empresa fk_doc_empresa_estado; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.documento_empresa
    ADD CONSTRAINT fk_doc_empresa_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5215 (class 2606 OID 68984)
-- Name: documento_empresa fk_documento_empresa_tipo_documento; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.documento_empresa
    ADD CONSTRAINT fk_documento_empresa_tipo_documento FOREIGN KEY (id_tipo_documento) REFERENCES clientes.tipo_documento(id_tipo_documento);


--
-- TOC entry 5216 (class 2606 OID 68989)
-- Name: empresa fk_empresa_estado; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.empresa
    ADD CONSTRAINT fk_empresa_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5217 (class 2606 OID 68994)
-- Name: empresa fk_empresa_tipo; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.empresa
    ADD CONSTRAINT fk_empresa_tipo FOREIGN KEY (id_catalogo_item_tipo_empresa) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5219 (class 2606 OID 68999)
-- Name: empresa_servicio fk_es_empresa; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.empresa_servicio
    ADD CONSTRAINT fk_es_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa);


--
-- TOC entry 5220 (class 2606 OID 69004)
-- Name: sucursal fk_sucursal_canton; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.sucursal
    ADD CONSTRAINT fk_sucursal_canton FOREIGN KEY (id_canton) REFERENCES clientes.canton(id_canton);


--
-- TOC entry 5221 (class 2606 OID 69009)
-- Name: sucursal fk_sucursal_ciudad; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.sucursal
    ADD CONSTRAINT fk_sucursal_ciudad FOREIGN KEY (id_ciudad) REFERENCES clientes.ciudad(id_ciudad);


--
-- TOC entry 5222 (class 2606 OID 69014)
-- Name: sucursal fk_sucursal_empresa; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.sucursal
    ADD CONSTRAINT fk_sucursal_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa);


--
-- TOC entry 5223 (class 2606 OID 69019)
-- Name: sucursal fk_sucursal_estado; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.sucursal
    ADD CONSTRAINT fk_sucursal_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5224 (class 2606 OID 69024)
-- Name: notificacion fk_notificacion_empresa; Type: FK CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.notificacion
    ADD CONSTRAINT fk_notificacion_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5225 (class 2606 OID 69029)
-- Name: notificacion fk_notificacion_ticket; Type: FK CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.notificacion
    ADD CONSTRAINT fk_notificacion_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 5226 (class 2606 OID 69034)
-- Name: notificacion fk_notificacion_tipo; Type: FK CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.notificacion
    ADD CONSTRAINT fk_notificacion_tipo FOREIGN KEY (id_tipo_notificacion) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5227 (class 2606 OID 69039)
-- Name: notificacion fk_notificacion_usuario; Type: FK CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.notificacion
    ADD CONSTRAINT fk_notificacion_usuario FOREIGN KEY (id_usuario_destino) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 5228 (class 2606 OID 69044)
-- Name: notificacion fk_notificacion_usuario_origen; Type: FK CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.notificacion
    ADD CONSTRAINT fk_notificacion_usuario_origen FOREIGN KEY (id_usuario_origen) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 5229 (class 2606 OID 69049)
-- Name: notificacion notificacion_id_canal_fkey; Type: FK CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.notificacion
    ADD CONSTRAINT notificacion_id_canal_fkey FOREIGN KEY (id_canal) REFERENCES notificaciones.canal_notificacion(id_canal);


--
-- TOC entry 5253 (class 2606 OID 69054)
-- Name: ticket fk81l25qsiooc520ve4sm69chsy; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk81l25qsiooc520ve4sm69chsy FOREIGN KEY (id_servicio) REFERENCES empresa.servicio(id_servicio);


--
-- TOC entry 5241 (class 2606 OID 69059)
-- Name: historial_estado fk86k65nur98avxs6ac5ue2sgj; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk86k65nur98avxs6ac5ue2sgj FOREIGN KEY (id_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5230 (class 2606 OID 69064)
-- Name: asignacion fk_asignacion_ticket; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.asignacion
    ADD CONSTRAINT fk_asignacion_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 5231 (class 2606 OID 69069)
-- Name: asignacion fk_asignacion_usuario; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.asignacion
    ADD CONSTRAINT fk_asignacion_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5233 (class 2606 OID 69074)
-- Name: comentario_ticket fk_com_estado; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket
    ADD CONSTRAINT fk_com_estado FOREIGN KEY (id_estado_item) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5234 (class 2606 OID 69079)
-- Name: comentario_ticket fk_com_ticket; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket
    ADD CONSTRAINT fk_com_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket) ON DELETE CASCADE;


--
-- TOC entry 5235 (class 2606 OID 69084)
-- Name: comentario_ticket fk_com_usuario; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket
    ADD CONSTRAINT fk_com_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 5237 (class 2606 OID 69089)
-- Name: documento_ticket fk_doc_estado; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.documento_ticket
    ADD CONSTRAINT fk_doc_estado FOREIGN KEY (id_estado_item) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5238 (class 2606 OID 69094)
-- Name: documento_ticket fk_doc_ticket; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.documento_ticket
    ADD CONSTRAINT fk_doc_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket) ON DELETE CASCADE;


--
-- TOC entry 5239 (class 2606 OID 69099)
-- Name: documento_ticket fk_doc_tipo; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.documento_ticket
    ADD CONSTRAINT fk_doc_tipo FOREIGN KEY (id_tipo_documento_item) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5240 (class 2606 OID 69104)
-- Name: documento_ticket fk_doc_usuario; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.documento_ticket
    ADD CONSTRAINT fk_doc_usuario FOREIGN KEY (id_usuario_subio) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 5242 (class 2606 OID 69109)
-- Name: historial_estado fk_hist_estado_anterior; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_hist_estado_anterior FOREIGN KEY (id_estado_anterior) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5243 (class 2606 OID 69114)
-- Name: historial_estado fk_hist_estado_nuevo; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_hist_estado_nuevo FOREIGN KEY (id_estado_nuevo) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5244 (class 2606 OID 69119)
-- Name: historial_estado fk_historial_estado_anterior; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_historial_estado_anterior FOREIGN KEY (id_estado_anterior) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5245 (class 2606 OID 69124)
-- Name: historial_estado fk_historial_estado_nuevo; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_historial_estado_nuevo FOREIGN KEY (id_estado_nuevo) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5246 (class 2606 OID 69129)
-- Name: historial_estado fk_historial_ticket; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_historial_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 5247 (class 2606 OID 69134)
-- Name: historial_estado fk_historial_usuario; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_historial_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5249 (class 2606 OID 69139)
-- Name: sla_ticket fk_sla_prioridad; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.sla_ticket
    ADD CONSTRAINT fk_sla_prioridad FOREIGN KEY (aplica_prioridad) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5254 (class 2606 OID 69144)
-- Name: ticket fk_ticket_categoria_item; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_categoria_item FOREIGN KEY (id_categoria_item) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5255 (class 2606 OID 69149)
-- Name: ticket fk_ticket_cliente; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_cliente FOREIGN KEY (id_cliente) REFERENCES clientes.cliente(id_cliente);


--
-- TOC entry 5256 (class 2606 OID 69154)
-- Name: ticket fk_ticket_estado_item; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_estado_item FOREIGN KEY (id_estado_item) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5257 (class 2606 OID 69159)
-- Name: ticket fk_ticket_prioridad_item; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_prioridad_item FOREIGN KEY (id_prioridad_item) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5258 (class 2606 OID 69164)
-- Name: ticket fk_ticket_sla; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_sla FOREIGN KEY (id_sla) REFERENCES soporte.sla_ticket(id_sla);


--
-- TOC entry 5259 (class 2606 OID 69169)
-- Name: ticket fk_ticket_sucursal; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_sucursal FOREIGN KEY (id_sucursal) REFERENCES empresa.sucursal(id_sucursal);


--
-- TOC entry 5260 (class 2606 OID 69174)
-- Name: ticket fk_ticket_usuario_asignado; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_usuario_asignado FOREIGN KEY (id_usuario_asignado) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 5261 (class 2606 OID 69179)
-- Name: ticket fk_ticket_usuario_creador; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_usuario_creador FOREIGN KEY (id_usuario_creador) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5270 (class 2606 OID 69280)
-- Name: visita_tecnica fk_visita_empresa; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.visita_tecnica
    ADD CONSTRAINT fk_visita_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa);


--
-- TOC entry 5271 (class 2606 OID 69275)
-- Name: visita_tecnica fk_visita_estado; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.visita_tecnica
    ADD CONSTRAINT fk_visita_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5272 (class 2606 OID 69270)
-- Name: visita_tecnica fk_visita_tecnico; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.visita_tecnica
    ADD CONSTRAINT fk_visita_tecnico FOREIGN KEY (id_usuario_tecnico) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 5273 (class 2606 OID 69265)
-- Name: visita_tecnica fk_visita_ticket; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.visita_tecnica
    ADD CONSTRAINT fk_visita_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 5236 (class 2606 OID 69184)
-- Name: comentario_ticket fkbv5gyaxos7jsns8fsucflndds; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket
    ADD CONSTRAINT fkbv5gyaxos7jsns8fsucflndds FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa);


--
-- TOC entry 5248 (class 2606 OID 69189)
-- Name: prioridad fkcnj24dfocilmvv1yyfjxf89gd; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.prioridad
    ADD CONSTRAINT fkcnj24dfocilmvv1yyfjxf89gd FOREIGN KEY (id_item) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5232 (class 2606 OID 69194)
-- Name: categoria fke27el05povf1kt0jl2811tm7r; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.categoria
    ADD CONSTRAINT fke27el05povf1kt0jl2811tm7r FOREIGN KEY (id_item) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5250 (class 2606 OID 69199)
-- Name: sla_ticket fkm9bsgtiqm9fcxfjnewil1mgdw; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.sla_ticket
    ADD CONSTRAINT fkm9bsgtiqm9fcxfjnewil1mgdw FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa);


--
-- TOC entry 5251 (class 2606 OID 69204)
-- Name: solucion_ticket solucion_ticket_id_ticket_fkey; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.solucion_ticket
    ADD CONSTRAINT solucion_ticket_id_ticket_fkey FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 5252 (class 2606 OID 69209)
-- Name: solucion_ticket solucion_ticket_id_usuario_tecnico_fkey; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.solucion_ticket
    ADD CONSTRAINT solucion_ticket_id_usuario_tecnico_fkey FOREIGN KEY (id_usuario_tecnico) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 5262 (class 2606 OID 69214)
-- Name: persona fk_persona_canton; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.persona
    ADD CONSTRAINT fk_persona_canton FOREIGN KEY (id_canton) REFERENCES clientes.canton(id_canton);


--
-- TOC entry 5263 (class 2606 OID 69219)
-- Name: persona fk_persona_usuario; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.persona
    ADD CONSTRAINT fk_persona_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 5267 (class 2606 OID 69224)
-- Name: usuario_bd fk_usuario_bd_rol; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_bd
    ADD CONSTRAINT fk_usuario_bd_rol FOREIGN KEY (id_rol_bd) REFERENCES usuarios.rol_bd(id_rol_bd);


--
-- TOC entry 5268 (class 2606 OID 69229)
-- Name: usuario_bd fk_usuario_bd_rol_bd; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_bd
    ADD CONSTRAINT fk_usuario_bd_rol_bd FOREIGN KEY (id_rol_bd) REFERENCES usuarios.rol_bd(id_rol_bd) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5269 (class 2606 OID 69234)
-- Name: usuario_bd fk_usuario_bd_usuario; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_bd
    ADD CONSTRAINT fk_usuario_bd_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON DELETE CASCADE;


--
-- TOC entry 5264 (class 2606 OID 69239)
-- Name: usuario fk_usuario_empresa; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT fk_usuario_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5265 (class 2606 OID 69244)
-- Name: usuario fk_usuario_estado; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT fk_usuario_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5266 (class 2606 OID 69249)
-- Name: usuario fk_usuario_rol; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT fk_usuario_rol FOREIGN KEY (id_rol) REFERENCES usuarios.rol(id_rol);


-- Completed on 2026-02-26 07:13:10

--
-- PostgreSQL database dump complete
--

