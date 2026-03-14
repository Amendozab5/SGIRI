--
-- PostgreSQL database dump
--

\restrict xw9g1IfeH5cpTbFZ0jcdjvfk2qwVgML8t1dsRI2uPuvyGhA7BCnHehkhbiEL2Ss

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

-- Started on 2026-03-13 19:32:00 -05

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

DROP DATABASE "SGIM2";
--
-- TOC entry 5288 (class 1262 OID 23484)
-- Name: SGIM2; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE "SGIM2" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'es_EC.utf8';


ALTER DATABASE "SGIM2" OWNER TO postgres;

\unrestrict xw9g1IfeH5cpTbFZ0jcdjvfk2qwVgML8t1dsRI2uPuvyGhA7BCnHehkhbiEL2Ss
\connect "SGIM2"
\restrict xw9g1IfeH5cpTbFZ0jcdjvfk2qwVgML8t1dsRI2uPuvyGhA7BCnHehkhbiEL2Ss

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
-- TOC entry 7 (class 2615 OID 23485)
-- Name: auditoria; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA auditoria;


ALTER SCHEMA auditoria OWNER TO postgres;

--
-- TOC entry 8 (class 2615 OID 23486)
-- Name: catalogos; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA catalogos;


ALTER SCHEMA catalogos OWNER TO postgres;

--
-- TOC entry 9 (class 2615 OID 23487)
-- Name: clientes; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA clientes;


ALTER SCHEMA clientes OWNER TO postgres;

--
-- TOC entry 10 (class 2615 OID 23488)
-- Name: empleados; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA empleados;


ALTER SCHEMA empleados OWNER TO postgres;

--
-- TOC entry 11 (class 2615 OID 23489)
-- Name: empresa; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA empresa;


ALTER SCHEMA empresa OWNER TO postgres;

--
-- TOC entry 12 (class 2615 OID 23490)
-- Name: notificaciones; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA notificaciones;


ALTER SCHEMA notificaciones OWNER TO postgres;

--
-- TOC entry 13 (class 2615 OID 23491)
-- Name: reportes; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA reportes;


ALTER SCHEMA reportes OWNER TO postgres;

--
-- TOC entry 5297 (class 0 OID 0)
-- Dependencies: 13
-- Name: SCHEMA reportes; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA reportes IS 'Esquema dedicado a la gestión de metadatos, configuraciones e historial de reportes del sistema.';


--
-- TOC entry 14 (class 2615 OID 23492)
-- Name: soporte; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA soporte;


ALTER SCHEMA soporte OWNER TO postgres;

--
-- TOC entry 15 (class 2615 OID 23493)
-- Name: usuarios; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA usuarios;


ALTER SCHEMA usuarios OWNER TO postgres;

--
-- TOC entry 2 (class 3079 OID 23494)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 5301 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 375 (class 1255 OID 23532)
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
-- TOC entry 378 (class 1255 OID 23533)
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
-- TOC entry 377 (class 1255 OID 23534)
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
-- TOC entry 376 (class 1255 OID 23535)
-- Name: fn_descontar_stock_inventario(); Type: FUNCTION; Schema: soporte; Owner: postgres
--

CREATE FUNCTION soporte.fn_descontar_stock_inventario() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update stock
    UPDATE soporte.inventario
    SET stock_actual = stock_actual - NEW.cantidad
    WHERE id_item_inventario = NEW.id_item_inventario;

    -- Validation
    IF (SELECT stock_actual FROM soporte.inventario WHERE id_item_inventario = NEW.id_item_inventario) < 0 THEN
        RAISE EXCEPTION 'Stock insuficiente para el Ã­tem ID %', NEW.id_item_inventario;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION soporte.fn_descontar_stock_inventario() OWNER TO postgres;

--
-- TOC entry 379 (class 1255 OID 23536)
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
-- TOC entry 381 (class 1255 OID 24789)
-- Name: fn_crear_usuario_cliente(character varying, integer, integer, integer, integer); Type: FUNCTION; Schema: usuarios; Owner: postgres
--

CREATE FUNCTION usuarios.fn_crear_usuario_cliente(p_cedula character varying, p_anio_nacimiento integer, p_id_rol integer, p_id_empresa integer, p_id_estado_item integer) RETURNS TABLE(r_id_usuario integer, r_username character varying, r_password_plano character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'usuarios', 'clientes', 'catalogos', 'public', 'pg_temp'
    AS $$
DECLARE
    v_username VARCHAR;
    v_password_hash TEXT;
    v_password_plano TEXT;
    v_id_usuario INTEGER;
    v_nombre_rol_bd TEXT;
    v_codigo_rol VARCHAR;
    v_nombre_bd TEXT;
BEGIN

    -- 1. Validar que cliente exista
    IF NOT EXISTS (
        SELECT 1 FROM clientes.cliente WHERE cedula = p_cedula
    ) THEN
        RAISE EXCEPTION 'El cliente con cédula % no existe en el sistema.', p_cedula;
    END IF;

    -- 2. Validar que usuario no exista (por username/cédula)
    IF EXISTS (
        SELECT 1 FROM usuarios.usuario WHERE username = p_cedula
    ) THEN
        RAISE EXCEPTION 'El usuario para la cédula % ya existe.', p_cedula;
    END IF;

    -- 3. Generar credenciales
    -- Retorna Record con username, password_plano, password_hash
    SELECT f.r_username, f.r_password_plano, f.r_password_hash
    INTO v_username, v_password_plano, v_password_hash
    FROM usuarios.fn_generar_credenciales(p_cedula, p_anio_nacimiento) f;

    -- 4. Obtener código del rol para rol físico
    SELECT codigo
    INTO v_codigo_rol
    FROM usuarios.rol
    WHERE id_rol = p_id_rol;

    IF v_codigo_rol IS NULL THEN
        RAISE EXCEPTION 'El rol aplicativo no existe.';
    END IF;

    v_nombre_rol_bd := 'rol_' || LOWER(v_codigo_rol);

    IF NOT EXISTS (
        SELECT 1
        FROM usuarios.rol_bd
        WHERE nombre = v_nombre_rol_bd
    ) THEN
        -- Si no existe un rol específico, intentamos con rol_cliente por defecto para seguridad
        v_nombre_rol_bd := 'rol_cliente';
        
        IF NOT EXISTS (SELECT 1 FROM usuarios.rol_bd WHERE nombre = 'rol_cliente') THEN
            RAISE EXCEPTION 'El rol BD asociado % no está registrado.', v_nombre_rol_bd;
        END IF;
    END IF;

    -- 5. Crear usuario aplicativo
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

    -- 6. Relacionar con cliente
    INSERT INTO usuarios.usuario_cliente (
        id_usuario,
        cedula_cliente,
        id_cliente
    )
    SELECT v_id_usuario, cedula, id_cliente
    FROM clientes.cliente
    WHERE cedula = p_cedula;

    -- 7. Crear usuario físico PostgreSQL
    -- Formato: cli_{cedula}_{id_usuario}
    v_nombre_bd := 'cli_' || p_cedula || '_' || v_id_usuario;

    EXECUTE format(
        'CREATE ROLE %I LOGIN PASSWORD %L',
        v_nombre_bd,
        v_password_plano
    );

    -- 8. Asignar rol físico
    EXECUTE format(
        'GRANT %I TO %I',
        v_nombre_rol_bd,
        v_nombre_bd
    );

    -- 9. Registrar usuario en tabla lógica usuario_bd
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

    -- 10. Conceder SET ROLE para sgiri_app
    EXECUTE format(
        'GRANT %I TO %I',
        v_nombre_bd,
        'sgiri_app'
    );

    -- 11. Retornar datos creados
    RETURN QUERY
    SELECT 
        v_id_usuario::integer, 
        v_username::character varying, 
        v_password_plano::character varying;
END;
$$;


ALTER FUNCTION usuarios.fn_crear_usuario_cliente(p_cedula character varying, p_anio_nacimiento integer, p_id_rol integer, p_id_empresa integer, p_id_estado_item integer) OWNER TO postgres;

--
-- TOC entry 380 (class 1255 OID 23538)
-- Name: fn_crear_usuario_empleado(character varying, integer, integer, integer, integer); Type: FUNCTION; Schema: usuarios; Owner: postgres
--

CREATE FUNCTION usuarios.fn_crear_usuario_empleado(p_cedula character varying, p_anio_nacimiento integer, p_id_rol integer, p_id_empresa integer, p_id_estado_item integer) RETURNS TABLE(r_id_usuario integer, r_username character varying, r_password_plano character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'usuarios', 'empleados', 'catalogos', 'public', 'pg_temp'
    AS $$
DECLARE
    v_id_persona INTEGER;
    v_username VARCHAR;
    v_password_hash TEXT;
    v_password_plano TEXT;
    v_id_usuario INTEGER;
    v_nombre_rol_bd TEXT;
    v_codigo_rol VARCHAR;
    v_nombre_bd TEXT;
BEGIN
    -- 1. Validar que la persona existe
    SELECT id_persona
    INTO v_id_persona
    FROM usuarios.persona
    WHERE cedula = p_cedula;

    IF v_id_persona IS NULL THEN
        RAISE EXCEPTION 'La persona con cédula % no existe en el sistema.', p_cedula;
    END IF;

    -- 2. Validar que el empleado existe
    IF NOT EXISTS (
        SELECT 1
        FROM empleados.empleado
        WHERE id_persona = v_id_persona
    ) THEN
        RAISE EXCEPTION 'No existe un registro de empleado para la persona con cédula %.', p_cedula;
    END IF;

    -- 3. Validar que no tenga ya un usuario asociado
    IF EXISTS (
        SELECT 1
        FROM usuarios.persona
        WHERE id_persona = v_id_persona
          AND id_usuario IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'La persona ya tiene un usuario de acceso asociado.';
    END IF;

    -- 4. Validar que tenga documento ACTIVO
    IF NOT EXISTS (
        SELECT 1 
        FROM empleados.documento_empleado d
        INNER JOIN catalogos.catalogo_item ci
            ON d.id_catalogo_item_estado = ci.id_item
        WHERE d.cedula_empleado = p_cedula
          AND ci.codigo = 'ACTIVO'
    ) THEN
        RAISE EXCEPTION 'El empleado no tiene documento validado (estado ACTIVO).';
    END IF;

    -- 5. Generar credenciales
    SELECT f.r_username, f.r_password_plano, f.r_password_hash
    INTO v_username, v_password_plano, v_password_hash
    FROM usuarios.fn_generar_credenciales(p_cedula, p_anio_nacimiento) f;

    -- 6. Obtener código del rol para rol físico
    SELECT codigo
    INTO v_codigo_rol
    FROM usuarios.rol
    WHERE id_rol = p_id_rol;

    IF v_codigo_rol IS NULL THEN
        RAISE EXCEPTION 'El rol aplicativo no existe.';
    END IF;

    v_nombre_rol_bd := 'rol_' || LOWER(v_codigo_rol);

    IF NOT EXISTS (
        SELECT 1
        FROM usuarios.rol_bd
        WHERE nombre = v_nombre_rol_bd
    ) THEN
        RAISE EXCEPTION 'El rol BD asociado % no está registrado en la tabla lógica.', v_nombre_rol_bd;
    END IF;

    -- 7. Crear usuario aplicativo
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

    -- 8. Relacionar persona -> usuario
    UPDATE usuarios.persona 
    SET id_usuario = v_id_usuario
    WHERE id_persona = v_id_persona;

    -- 9. Crear usuario físico PostgreSQL
    v_nombre_bd := 'emp_' || p_cedula || '_' || v_id_usuario;

    EXECUTE format(
        'CREATE ROLE %I LOGIN PASSWORD %L',
        v_nombre_bd,
        v_password_plano
    );

    -- 10. Asignar rol físico
    EXECUTE format(
        'GRANT %I TO %I',
        v_nombre_rol_bd,
        v_nombre_bd
    );

    -- 11. Registrar usuario en tabla lógica usuario_bd
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

    -- 12. Conceder SET ROLE para sgiri_app
    EXECUTE format(
        'GRANT %I TO %I',
        v_nombre_bd,
        'sgiri_app'
    );

    -- 13. Retornar datos creados con cast explícito para evitar error de tipos
    RETURN QUERY
    SELECT 
        v_id_usuario::integer, 
        v_username::character varying, 
        v_password_plano::character varying;
END;
$$;


ALTER FUNCTION usuarios.fn_crear_usuario_empleado(p_cedula character varying, p_anio_nacimiento integer, p_id_rol integer, p_id_empresa integer, p_id_estado_item integer) OWNER TO postgres;

--
-- TOC entry 382 (class 1255 OID 23539)
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
-- TOC entry 229 (class 1259 OID 23540)
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
-- TOC entry 230 (class 1259 OID 23548)
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
-- TOC entry 5311 (class 0 OID 0)
-- Dependencies: 230
-- Name: auditoria_estado_ticket_id_auditoria_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: postgres
--

ALTER SEQUENCE auditoria.auditoria_estado_ticket_id_auditoria_seq OWNED BY auditoria.auditoria_estado_ticket.id_auditoria;


--
-- TOC entry 231 (class 1259 OID 23549)
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
    id_accion_item integer NOT NULL,
    modulo character varying(50),
    valores_anteriores text,
    valores_nuevos text,
    ip_origen character varying(45),
    user_agent text,
    endpoint character varying(200),
    metodo_http character varying(10),
    exito boolean DEFAULT true NOT NULL,
    observacion text
);


ALTER TABLE auditoria.auditoria_evento OWNER TO postgres;

--
-- TOC entry 5313 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN auditoria_evento.modulo; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON COLUMN auditoria.auditoria_evento.modulo IS 'Área funcional del sistema: AUTH, TICKETS, USUARIOS, EMPLEADOS, DOCUMENTOS, VISITAS, PERFIL';


--
-- TOC entry 5314 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN auditoria_evento.valores_anteriores; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON COLUMN auditoria.auditoria_evento.valores_anteriores IS 'JSON con campos relevantes del registro ANTES del cambio. Null en INSERT.';


--
-- TOC entry 5315 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN auditoria_evento.valores_nuevos; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON COLUMN auditoria.auditoria_evento.valores_nuevos IS 'JSON con campos relevantes del registro DESPUÉS del cambio. Null en DELETE.';


--
-- TOC entry 5316 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN auditoria_evento.endpoint; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON COLUMN auditoria.auditoria_evento.endpoint IS 'URI del endpoint REST invocado, ej. /api/tickets/5/status';


--
-- TOC entry 5317 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN auditoria_evento.exito; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON COLUMN auditoria.auditoria_evento.exito IS 'TRUE si la operación fue exitosa; FALSE si fue un intento que falló.';


--
-- TOC entry 5318 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN auditoria_evento.observacion; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON COLUMN auditoria.auditoria_evento.observacion IS 'Observación adicional de contexto: mensaje de error, motivo de fallo, etc.';


--
-- TOC entry 232 (class 1259 OID 23565)
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
-- TOC entry 5320 (class 0 OID 0)
-- Dependencies: 232
-- Name: auditoria_evento_id_evento_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: postgres
--

ALTER SEQUENCE auditoria.auditoria_evento_id_evento_seq OWNED BY auditoria.auditoria_evento.id_evento;


--
-- TOC entry 233 (class 1259 OID 23566)
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
    id_item_evento integer,
    user_agent text,
    motivo_fallo character varying(200)
);


ALTER TABLE auditoria.auditoria_login OWNER TO postgres;

--
-- TOC entry 5322 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN auditoria_login.user_agent; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON COLUMN auditoria.auditoria_login.user_agent IS 'User-Agent HTTP del cliente que realizó el intento de login.';


--
-- TOC entry 5323 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN auditoria_login.motivo_fallo; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON COLUMN auditoria.auditoria_login.motivo_fallo IS 'Causa del intento fallido cuando exito=false. Ej: "Credenciales incorrectas".';


--
-- TOC entry 234 (class 1259 OID 23575)
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
-- TOC entry 235 (class 1259 OID 23585)
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
-- TOC entry 5326 (class 0 OID 0)
-- Dependencies: 235
-- Name: auditoria_login_bd_id_auditoria_login_bd_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: postgres
--

ALTER SEQUENCE auditoria.auditoria_login_bd_id_auditoria_login_bd_seq OWNED BY auditoria.auditoria_login_bd.id_auditoria_login_bd;


--
-- TOC entry 236 (class 1259 OID 23586)
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
-- TOC entry 5328 (class 0 OID 0)
-- Dependencies: 236
-- Name: auditoria_login_id_login_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: postgres
--

ALTER SEQUENCE auditoria.auditoria_login_id_login_seq OWNED BY auditoria.auditoria_login.id_login;


--
-- TOC entry 237 (class 1259 OID 23587)
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
-- TOC entry 238 (class 1259 OID 23594)
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
-- TOC entry 239 (class 1259 OID 23606)
-- Name: vw_timeline_administrativa; Type: VIEW; Schema: auditoria; Owner: postgres
--

CREATE VIEW auditoria.vw_timeline_administrativa AS
 SELECT ('EV-'::text || ae.id_evento) AS event_key,
    'EVENTO'::text AS tipo_entidad,
    ae.id_evento AS original_id,
    ae.fecha_evento AS fecha,
    ae.modulo,
    ci.codigo AS accion,
    ae.descripcion,
    ae.id_usuario,
    COALESCE(u.username, ae.usuario_bd, 'Sistema'::character varying) AS actor,
    ae.usuario_bd,
    ae.ip_origen,
    ae.exito,
    ae.tabla_afectada
   FROM ((auditoria.auditoria_evento ae
     LEFT JOIN catalogos.catalogo_item ci ON ((ae.id_accion_item = ci.id_item)))
     LEFT JOIN usuarios.usuario u ON ((u.id_usuario = ae.id_usuario)))
UNION ALL
 SELECT ('LG-'::text || al.id_login) AS event_key,
    'LOGIN'::text AS tipo_entidad,
    al.id_login AS original_id,
    al.fecha_login AS fecha,
    'AUTH'::character varying AS modulo,
    ci.codigo AS accion,
        CASE
            WHEN al.exito THEN 'Inicio de sesión exitoso'::text
            ELSE ('Fallo de login: '::text || (COALESCE(al.motivo_fallo, 'Desconocido'::character varying))::text)
        END AS descripcion,
    al.id_usuario,
    COALESCE(u.username, al.usuario_bd, 'Sistema / Cliente'::character varying) AS actor,
    al.usuario_bd,
    al.ip_origen,
    al.exito,
    NULL::character varying AS tabla_afectada
   FROM ((auditoria.auditoria_login al
     LEFT JOIN catalogos.catalogo_item ci ON ((al.id_item_evento = ci.id_item)))
     LEFT JOIN usuarios.usuario u ON ((u.id_usuario = al.id_usuario)))
UNION ALL
 SELECT ('TK-'::text || aet.id_auditoria) AS event_key,
    'ESTADO_TICKET'::text AS tipo_entidad,
    aet.id_auditoria AS original_id,
    aet.fecha_cambio AS fecha,
    'TICKETS'::character varying AS modulo,
    'CAMBIO_ESTADO'::character varying AS accion,
    ('Registro de auditoría por cambio de estado del ticket #'::text || aet.id_ticket) AS descripcion,
    aet.id_usuario,
    COALESCE(u.username, aet.usuario_bd, 'Sistema'::character varying) AS actor,
    aet.usuario_bd,
    NULL::character varying AS ip_origen,
    true AS exito,
    'ticket'::character varying AS tabla_afectada
   FROM (auditoria.auditoria_estado_ticket aet
     LEFT JOIN usuarios.usuario u ON ((u.id_usuario = aet.id_usuario)));


ALTER VIEW auditoria.vw_timeline_administrativa OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 23611)
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
-- TOC entry 241 (class 1259 OID 23619)
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
-- TOC entry 5334 (class 0 OID 0)
-- Dependencies: 241
-- Name: catalogo_id_catalogo_seq; Type: SEQUENCE OWNED BY; Schema: catalogos; Owner: postgres
--

ALTER SEQUENCE catalogos.catalogo_id_catalogo_seq OWNED BY catalogos.catalogo.id_catalogo;


--
-- TOC entry 242 (class 1259 OID 23620)
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
-- TOC entry 5336 (class 0 OID 0)
-- Dependencies: 242
-- Name: catalogo_item_id_item_seq; Type: SEQUENCE OWNED BY; Schema: catalogos; Owner: postgres
--

ALTER SEQUENCE catalogos.catalogo_item_id_item_seq OWNED BY catalogos.catalogo_item.id_item;


--
-- TOC entry 243 (class 1259 OID 23621)
-- Name: canton; Type: TABLE; Schema: clientes; Owner: postgres
--

CREATE TABLE clientes.canton (
    id_canton integer NOT NULL,
    nombre character varying(100) NOT NULL,
    id_ciudad integer NOT NULL
);


ALTER TABLE clientes.canton OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 23627)
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
-- TOC entry 5339 (class 0 OID 0)
-- Dependencies: 244
-- Name: canton_id_canton_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: postgres
--

ALTER SEQUENCE clientes.canton_id_canton_seq OWNED BY clientes.canton.id_canton;


--
-- TOC entry 245 (class 1259 OID 23628)
-- Name: ciudad; Type: TABLE; Schema: clientes; Owner: postgres
--

CREATE TABLE clientes.ciudad (
    id_ciudad integer NOT NULL,
    nombre character varying(100) NOT NULL,
    id_pais integer NOT NULL
);


ALTER TABLE clientes.ciudad OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 23634)
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
-- TOC entry 5342 (class 0 OID 0)
-- Dependencies: 246
-- Name: ciudad_id_ciudad_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: postgres
--

ALTER SEQUENCE clientes.ciudad_id_ciudad_seq OWNED BY clientes.ciudad.id_ciudad;


--
-- TOC entry 247 (class 1259 OID 23635)
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
-- TOC entry 248 (class 1259 OID 23642)
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
-- TOC entry 5345 (class 0 OID 0)
-- Dependencies: 248
-- Name: cliente_id_cliente_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: postgres
--

ALTER SEQUENCE clientes.cliente_id_cliente_seq OWNED BY clientes.cliente.id_cliente;


--
-- TOC entry 249 (class 1259 OID 23643)
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
-- TOC entry 250 (class 1259 OID 23654)
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
-- TOC entry 5348 (class 0 OID 0)
-- Dependencies: 250
-- Name: documento_cliente_id_documento_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: postgres
--

ALTER SEQUENCE clientes.documento_cliente_id_documento_seq OWNED BY clientes.documento_cliente.id_documento;


--
-- TOC entry 251 (class 1259 OID 23655)
-- Name: pais; Type: TABLE; Schema: clientes; Owner: postgres
--

CREATE TABLE clientes.pais (
    id_pais integer NOT NULL,
    nombre character varying(100) NOT NULL
);


ALTER TABLE clientes.pais OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 23660)
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
-- TOC entry 5351 (class 0 OID 0)
-- Dependencies: 252
-- Name: pais_id_pais_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: postgres
--

ALTER SEQUENCE clientes.pais_id_pais_seq OWNED BY clientes.pais.id_pais;


--
-- TOC entry 253 (class 1259 OID 23661)
-- Name: tipo_documento; Type: TABLE; Schema: clientes; Owner: postgres
--

CREATE TABLE clientes.tipo_documento (
    id_tipo_documento integer NOT NULL,
    codigo character varying(20) NOT NULL
);


ALTER TABLE clientes.tipo_documento OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 23666)
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
-- TOC entry 5354 (class 0 OID 0)
-- Dependencies: 254
-- Name: tipo_documento_id_tipo_documento_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: postgres
--

ALTER SEQUENCE clientes.tipo_documento_id_tipo_documento_seq OWNED BY clientes.tipo_documento.id_tipo_documento;


--
-- TOC entry 255 (class 1259 OID 23667)
-- Name: area; Type: TABLE; Schema: empleados; Owner: postgres
--

CREATE TABLE empleados.area (
    id_area integer NOT NULL,
    nombre character varying(100) NOT NULL
);


ALTER TABLE empleados.area OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 23672)
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
-- TOC entry 5357 (class 0 OID 0)
-- Dependencies: 256
-- Name: area_id_area_seq; Type: SEQUENCE OWNED BY; Schema: empleados; Owner: postgres
--

ALTER SEQUENCE empleados.area_id_area_seq OWNED BY empleados.area.id_area;


--
-- TOC entry 257 (class 1259 OID 23673)
-- Name: cargo; Type: TABLE; Schema: empleados; Owner: postgres
--

CREATE TABLE empleados.cargo (
    id_cargo integer NOT NULL,
    nombre character varying(100) NOT NULL
);


ALTER TABLE empleados.cargo OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 23678)
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
-- TOC entry 5360 (class 0 OID 0)
-- Dependencies: 258
-- Name: cargo_id_cargo_seq; Type: SEQUENCE OWNED BY; Schema: empleados; Owner: postgres
--

ALTER SEQUENCE empleados.cargo_id_cargo_seq OWNED BY empleados.cargo.id_cargo;


--
-- TOC entry 259 (class 1259 OID 23679)
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
-- TOC entry 260 (class 1259 OID 23690)
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
-- TOC entry 5363 (class 0 OID 0)
-- Dependencies: 260
-- Name: documento_empleado_id_documento_seq; Type: SEQUENCE OWNED BY; Schema: empleados; Owner: postgres
--

ALTER SEQUENCE empleados.documento_empleado_id_documento_seq OWNED BY empleados.documento_empleado.id_documento;


--
-- TOC entry 261 (class 1259 OID 23691)
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
-- TOC entry 262 (class 1259 OID 23692)
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
-- TOC entry 263 (class 1259 OID 23701)
-- Name: tipo_contrato; Type: TABLE; Schema: empleados; Owner: postgres
--

CREATE TABLE empleados.tipo_contrato (
    id_tipo_contrato integer NOT NULL,
    nombre character varying(100) NOT NULL
);


ALTER TABLE empleados.tipo_contrato OWNER TO postgres;

--
-- TOC entry 264 (class 1259 OID 23706)
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
-- TOC entry 5368 (class 0 OID 0)
-- Dependencies: 264
-- Name: tipo_contrato_id_tipo_contrato_seq; Type: SEQUENCE OWNED BY; Schema: empleados; Owner: postgres
--

ALTER SEQUENCE empleados.tipo_contrato_id_tipo_contrato_seq OWNED BY empleados.tipo_contrato.id_tipo_contrato;


--
-- TOC entry 265 (class 1259 OID 23707)
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
-- TOC entry 266 (class 1259 OID 23718)
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
-- TOC entry 5371 (class 0 OID 0)
-- Dependencies: 266
-- Name: documento_empresa_id_documento_seq; Type: SEQUENCE OWNED BY; Schema: empresa; Owner: postgres
--

ALTER SEQUENCE empresa.documento_empresa_id_documento_seq OWNED BY empresa.documento_empresa.id_documento;


--
-- TOC entry 267 (class 1259 OID 23719)
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
-- TOC entry 268 (class 1259 OID 23730)
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
-- TOC entry 5374 (class 0 OID 0)
-- Dependencies: 268
-- Name: empresa_id_empresa_seq; Type: SEQUENCE OWNED BY; Schema: empresa; Owner: postgres
--

ALTER SEQUENCE empresa.empresa_id_empresa_seq OWNED BY empresa.empresa.id_empresa;


--
-- TOC entry 269 (class 1259 OID 23731)
-- Name: empresa_servicio; Type: TABLE; Schema: empresa; Owner: postgres
--

CREATE TABLE empresa.empresa_servicio (
    id_empresa integer NOT NULL,
    id_servicio integer NOT NULL
);


ALTER TABLE empresa.empresa_servicio OWNER TO postgres;

--
-- TOC entry 270 (class 1259 OID 23736)
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
-- TOC entry 271 (class 1259 OID 23743)
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
-- TOC entry 5378 (class 0 OID 0)
-- Dependencies: 271
-- Name: servicio_id_servicio_seq; Type: SEQUENCE OWNED BY; Schema: empresa; Owner: postgres
--

ALTER SEQUENCE empresa.servicio_id_servicio_seq OWNED BY empresa.servicio.id_servicio;


--
-- TOC entry 272 (class 1259 OID 23744)
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
-- TOC entry 273 (class 1259 OID 23753)
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
-- TOC entry 5381 (class 0 OID 0)
-- Dependencies: 273
-- Name: sucursal_id_sucursal_seq; Type: SEQUENCE OWNED BY; Schema: empresa; Owner: postgres
--

ALTER SEQUENCE empresa.sucursal_id_sucursal_seq OWNED BY empresa.sucursal.id_sucursal;


--
-- TOC entry 274 (class 1259 OID 23754)
-- Name: cola_correo; Type: TABLE; Schema: notificaciones; Owner: postgres
--

CREATE TABLE notificaciones.cola_correo (
    id_correo integer NOT NULL,
    id_empresa integer NOT NULL,
    destinatario_correo character varying(150) NOT NULL,
    asunto character varying(200) NOT NULL,
    cuerpo_html text NOT NULL,
    enviado boolean DEFAULT false,
    intentos integer DEFAULT 0,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_envio timestamp without time zone,
    error_envio text,
    id_ticket integer
);


ALTER TABLE notificaciones.cola_correo OWNER TO postgres;

--
-- TOC entry 275 (class 1259 OID 23767)
-- Name: cola_correo_id_correo_seq; Type: SEQUENCE; Schema: notificaciones; Owner: postgres
--

CREATE SEQUENCE notificaciones.cola_correo_id_correo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE notificaciones.cola_correo_id_correo_seq OWNER TO postgres;

--
-- TOC entry 5384 (class 0 OID 0)
-- Dependencies: 275
-- Name: cola_correo_id_correo_seq; Type: SEQUENCE OWNED BY; Schema: notificaciones; Owner: postgres
--

ALTER SEQUENCE notificaciones.cola_correo_id_correo_seq OWNED BY notificaciones.cola_correo.id_correo;


--
-- TOC entry 276 (class 1259 OID 23768)
-- Name: notificacion_web; Type: TABLE; Schema: notificaciones; Owner: postgres
--

CREATE TABLE notificaciones.notificacion_web (
    id_notificacion integer NOT NULL,
    id_usuario_destino integer NOT NULL,
    id_empresa integer NOT NULL,
    titulo character varying(150) NOT NULL,
    mensaje text NOT NULL,
    ruta_redireccion character varying(255) NOT NULL,
    id_ticket integer,
    leida boolean DEFAULT false,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_lectura timestamp without time zone
);


ALTER TABLE notificaciones.notificacion_web OWNER TO postgres;

--
-- TOC entry 277 (class 1259 OID 23781)
-- Name: notificacion_web_id_notificacion_seq; Type: SEQUENCE; Schema: notificaciones; Owner: postgres
--

CREATE SEQUENCE notificaciones.notificacion_web_id_notificacion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE notificaciones.notificacion_web_id_notificacion_seq OWNER TO postgres;

--
-- TOC entry 5389 (class 0 OID 0)
-- Dependencies: 277
-- Name: notificacion_web_id_notificacion_seq; Type: SEQUENCE OWNED BY; Schema: notificaciones; Owner: postgres
--

ALTER SEQUENCE notificaciones.notificacion_web_id_notificacion_seq OWNED BY notificaciones.notificacion_web.id_notificacion;


--
-- TOC entry 278 (class 1259 OID 23782)
-- Name: configuracion_reporte; Type: TABLE; Schema: reportes; Owner: postgres
--

CREATE TABLE reportes.configuracion_reporte (
    id_reporte integer NOT NULL,
    nombre character varying(150) NOT NULL,
    descripcion text,
    codigo_unico character varying(50) NOT NULL,
    modulo character varying(50) NOT NULL,
    tipo_salida character varying(20) NOT NULL,
    es_activo boolean DEFAULT true,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE reportes.configuracion_reporte OWNER TO postgres;

--
-- TOC entry 279 (class 1259 OID 23794)
-- Name: configuracion_reporte_id_reporte_seq; Type: SEQUENCE; Schema: reportes; Owner: postgres
--

CREATE SEQUENCE reportes.configuracion_reporte_id_reporte_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE reportes.configuracion_reporte_id_reporte_seq OWNER TO postgres;

--
-- TOC entry 5392 (class 0 OID 0)
-- Dependencies: 279
-- Name: configuracion_reporte_id_reporte_seq; Type: SEQUENCE OWNED BY; Schema: reportes; Owner: postgres
--

ALTER SEQUENCE reportes.configuracion_reporte_id_reporte_seq OWNED BY reportes.configuracion_reporte.id_reporte;


--
-- TOC entry 280 (class 1259 OID 23795)
-- Name: historial_generacion; Type: TABLE; Schema: reportes; Owner: postgres
--

CREATE TABLE reportes.historial_generacion (
    id_generacion integer NOT NULL,
    id_reporte integer NOT NULL,
    id_usuario integer NOT NULL,
    parametros_json jsonb,
    ruta_archivo text,
    taza_exito boolean DEFAULT true,
    mensaje_error text,
    tiempo_ejecucion_ms integer,
    fecha_generacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE reportes.historial_generacion OWNER TO postgres;

--
-- TOC entry 281 (class 1259 OID 23805)
-- Name: historial_generacion_id_generacion_seq; Type: SEQUENCE; Schema: reportes; Owner: postgres
--

CREATE SEQUENCE reportes.historial_generacion_id_generacion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE reportes.historial_generacion_id_generacion_seq OWNER TO postgres;

--
-- TOC entry 5395 (class 0 OID 0)
-- Dependencies: 281
-- Name: historial_generacion_id_generacion_seq; Type: SEQUENCE OWNED BY; Schema: reportes; Owner: postgres
--

ALTER SEQUENCE reportes.historial_generacion_id_generacion_seq OWNED BY reportes.historial_generacion.id_generacion;


--
-- TOC entry 282 (class 1259 OID 23806)
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
    fecha_cierre timestamp without time zone,
    impacto integer,
    urgencia integer,
    puntaje_prioridad integer,
    calificacion_satisfaccion integer,
    comentario_calificacion text,
    id_problema integer
);


ALTER TABLE soporte.ticket OWNER TO postgres;

--
-- TOC entry 5397 (class 0 OID 0)
-- Dependencies: 282
-- Name: COLUMN ticket.impacto; Type: COMMENT; Schema: soporte; Owner: postgres
--

COMMENT ON COLUMN soporte.ticket.impacto IS 'Nivel de afectación al negocio (1: Bajo, 2: Medio, 3: Alto)';


--
-- TOC entry 5398 (class 0 OID 0)
-- Dependencies: 282
-- Name: COLUMN ticket.urgencia; Type: COMMENT; Schema: soporte; Owner: postgres
--

COMMENT ON COLUMN soporte.ticket.urgencia IS 'Qué tan rápido debe resolverse (1: Baja, 2: Media, 3: Alta)';


--
-- TOC entry 5399 (class 0 OID 0)
-- Dependencies: 282
-- Name: COLUMN ticket.puntaje_prioridad; Type: COMMENT; Schema: soporte; Owner: postgres
--

COMMENT ON COLUMN soporte.ticket.puntaje_prioridad IS 'Resultado de Impacto x Urgencia + Factor de Envejecimiento';


--
-- TOC entry 5400 (class 0 OID 0)
-- Dependencies: 282
-- Name: COLUMN ticket.calificacion_satisfaccion; Type: COMMENT; Schema: soporte; Owner: postgres
--

COMMENT ON COLUMN soporte.ticket.calificacion_satisfaccion IS 'Ponderación de satisfacción del usuario (1-5 estrellas) dada al cerrar el caso';


--
-- TOC entry 5401 (class 0 OID 0)
-- Dependencies: 282
-- Name: COLUMN ticket.comentario_calificacion; Type: COMMENT; Schema: soporte; Owner: postgres
--

COMMENT ON COLUMN soporte.ticket.comentario_calificacion IS 'Comentario opcional del usuario al calificar al técnico';


--
-- TOC entry 283 (class 1259 OID 23819)
-- Name: vw_csat_analisis; Type: VIEW; Schema: reportes; Owner: postgres
--

CREATE VIEW reportes.vw_csat_analisis AS
 SELECT (date_trunc('month'::text, fecha_creacion))::date AS mes,
    count(calificacion_satisfaccion) AS total_respuestas,
    round(avg(calificacion_satisfaccion), 2) AS puntaje_promedio,
    round((((count(*) FILTER (WHERE (calificacion_satisfaccion >= 4)))::numeric * 100.0) / (NULLIF(count(calificacion_satisfaccion), 0))::numeric), 2) AS tasa_positiva
   FROM soporte.ticket t
  WHERE (calificacion_satisfaccion IS NOT NULL)
  GROUP BY ((date_trunc('month'::text, fecha_creacion))::date);


ALTER VIEW reportes.vw_csat_analisis OWNER TO postgres;

--
-- TOC entry 284 (class 1259 OID 23824)
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
-- TOC entry 285 (class 1259 OID 23834)
-- Name: vw_csat_detalle; Type: VIEW; Schema: reportes; Owner: postgres
--

CREATE VIEW reportes.vw_csat_detalle AS
 SELECT t.id_ticket,
    t.asunto,
    t.fecha_creacion,
    t.fecha_cierre,
    t.calificacion_satisfaccion,
    t.comentario_calificacion,
    COALESCE((((p.nombre)::text || ' '::text) || (p.apellido)::text), ('Usuario #'::text || t.id_cliente)) AS cliente_nombre,
    COALESCE(ci_cat.nombre, 'General'::character varying) AS categoria
   FROM (((soporte.ticket t
     LEFT JOIN clientes.cliente c ON ((t.id_cliente = c.id_cliente)))
     LEFT JOIN usuarios.persona p ON ((c.id_persona = p.id_persona)))
     LEFT JOIN catalogos.catalogo_item ci_cat ON ((t.id_categoria_item = ci_cat.id_item)))
  WHERE (t.calificacion_satisfaccion IS NOT NULL);


ALTER VIEW reportes.vw_csat_detalle OWNER TO postgres;

--
-- TOC entry 286 (class 1259 OID 23839)
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
-- TOC entry 5413 (class 0 OID 0)
-- Dependencies: 286
-- Name: TABLE visita_tecnica; Type: COMMENT; Schema: soporte; Owner: postgres
--

COMMENT ON TABLE soporte.visita_tecnica IS 'Entidad que gestiona las citas presenciales vinculadas a un ticket de soporte';


--
-- TOC entry 287 (class 1259 OID 23852)
-- Name: vw_desempeño_tecnicos; Type: VIEW; Schema: reportes; Owner: postgres
--

CREATE VIEW reportes."vw_desempeño_tecnicos" AS
 SELECT v.id_usuario_tecnico,
    (((p.nombre)::text || ' '::text) || (p.apellido)::text) AS nombre_tecnico,
    count(v.id_visita) AS total_visitas,
    sum((v.hora_fin - v.hora_inicio)) AS tiempo_total_campo,
    avg((v.hora_fin - v.hora_inicio)) AS tiempo_promedio_visita
   FROM (soporte.visita_tecnica v
     JOIN usuarios.persona p ON ((v.id_usuario_tecnico = ( SELECT persona.id_persona
           FROM usuarios.persona
          WHERE (persona.id_usuario = v.id_usuario_tecnico)
         LIMIT 1))))
  GROUP BY v.id_usuario_tecnico, p.nombre, p.apellido;


ALTER VIEW reportes."vw_desempeño_tecnicos" OWNER TO postgres;

--
-- TOC entry 288 (class 1259 OID 23857)
-- Name: vw_resumen_tickets; Type: VIEW; Schema: reportes; Owner: postgres
--

CREATE VIEW reportes.vw_resumen_tickets AS
 SELECT t.id_ticket,
    t.asunto,
    t.fecha_creacion,
    t.fecha_cierre,
    ci_est.nombre AS estado,
    ci_est.codigo AS estado_codigo,
    ci_prio.nombre AS prioridad,
        CASE
            WHEN (t.fecha_cierre IS NOT NULL) THEN (t.fecha_cierre - t.fecha_creacion)
            ELSE NULL::interval
        END AS tiempo_resolucion,
    t.calificacion_satisfaccion,
    t.id_usuario_asignado,
    t.id_cliente,
    t.id_sucursal,
    t.id_categoria_item,
    ci_cat.nombre AS categoria
   FROM (((soporte.ticket t
     LEFT JOIN catalogos.catalogo_item ci_est ON ((t.id_estado_item = ci_est.id_item)))
     LEFT JOIN catalogos.catalogo_item ci_prio ON ((t.id_prioridad_item = ci_prio.id_item)))
     LEFT JOIN catalogos.catalogo_item ci_cat ON ((t.id_categoria_item = ci_cat.id_item)));


ALTER VIEW reportes.vw_resumen_tickets OWNER TO postgres;

--
-- TOC entry 289 (class 1259 OID 23862)
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
-- TOC entry 290 (class 1259 OID 23870)
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
-- TOC entry 5418 (class 0 OID 0)
-- Dependencies: 290
-- Name: asignacion_id_asignacion_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.asignacion_id_asignacion_seq OWNED BY soporte.asignacion.id_asignacion;


--
-- TOC entry 291 (class 1259 OID 23871)
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
-- TOC entry 292 (class 1259 OID 23879)
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
-- TOC entry 5421 (class 0 OID 0)
-- Dependencies: 292
-- Name: categoria_id_categoria_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.categoria_id_categoria_seq OWNED BY soporte.categoria.id_categoria;


--
-- TOC entry 293 (class 1259 OID 23880)
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
-- TOC entry 294 (class 1259 OID 23894)
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
-- TOC entry 5424 (class 0 OID 0)
-- Dependencies: 294
-- Name: comentario_ticket_id_comentario_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.comentario_ticket_id_comentario_seq OWNED BY soporte.comentario_ticket.id_comentario;


--
-- TOC entry 295 (class 1259 OID 23895)
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
-- TOC entry 296 (class 1259 OID 23908)
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
-- TOC entry 5427 (class 0 OID 0)
-- Dependencies: 296
-- Name: documento_ticket_id_documento_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.documento_ticket_id_documento_seq OWNED BY soporte.documento_ticket.id_documento;


--
-- TOC entry 297 (class 1259 OID 23909)
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
-- TOC entry 298 (class 1259 OID 23920)
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
-- TOC entry 5430 (class 0 OID 0)
-- Dependencies: 298
-- Name: historial_estado_id_historial_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.historial_estado_id_historial_seq OWNED BY soporte.historial_estado.id_historial;


--
-- TOC entry 299 (class 1259 OID 23921)
-- Name: informe_trabajo_tecnico; Type: TABLE; Schema: soporte; Owner: postgres
--

CREATE TABLE soporte.informe_trabajo_tecnico (
    id_informe integer NOT NULL,
    id_ticket integer NOT NULL,
    id_tecnico integer NOT NULL,
    resultado character varying(20) NOT NULL,
    implementos_usados text,
    problemas_encontrados text,
    solucion_aplicada text,
    pruebas_realizadas text,
    motivo_no_resolucion text,
    comentario_tecnico text,
    url_adjunto text,
    tiempo_trabajo_minutos integer,
    fecha_registro timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT informe_trabajo_tecnico_resultado_check CHECK (((resultado)::text = ANY (ARRAY[('RESUELTO'::character varying)::text, ('NO_RESUELTO'::character varying)::text])))
);


ALTER TABLE soporte.informe_trabajo_tecnico OWNER TO postgres;

--
-- TOC entry 5432 (class 0 OID 0)
-- Dependencies: 299
-- Name: TABLE informe_trabajo_tecnico; Type: COMMENT; Schema: soporte; Owner: postgres
--

COMMENT ON TABLE soporte.informe_trabajo_tecnico IS 'Informe técnico del trabajo realizado por el técnico al atender un ticket';


--
-- TOC entry 5433 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN informe_trabajo_tecnico.resultado; Type: COMMENT; Schema: soporte; Owner: postgres
--

COMMENT ON COLUMN soporte.informe_trabajo_tecnico.resultado IS 'RESUELTO o NO_RESUELTO';


--
-- TOC entry 5434 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN informe_trabajo_tecnico.implementos_usados; Type: COMMENT; Schema: soporte; Owner: postgres
--

COMMENT ON COLUMN soporte.informe_trabajo_tecnico.implementos_usados IS 'Lista de implementos/herramientas usados (texto libre o JSON)';


--
-- TOC entry 5435 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN informe_trabajo_tecnico.problemas_encontrados; Type: COMMENT; Schema: soporte; Owner: postgres
--

COMMENT ON COLUMN soporte.informe_trabajo_tecnico.problemas_encontrados IS 'Descripción de problemas encontrados durante el diagnóstico';


--
-- TOC entry 5436 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN informe_trabajo_tecnico.solucion_aplicada; Type: COMMENT; Schema: soporte; Owner: postgres
--

COMMENT ON COLUMN soporte.informe_trabajo_tecnico.solucion_aplicada IS 'Descripción de la solución aplicada';


--
-- TOC entry 5437 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN informe_trabajo_tecnico.pruebas_realizadas; Type: COMMENT; Schema: soporte; Owner: postgres
--

COMMENT ON COLUMN soporte.informe_trabajo_tecnico.pruebas_realizadas IS 'Descripción de pruebas realizadas para verificar la solución';


--
-- TOC entry 5438 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN informe_trabajo_tecnico.motivo_no_resolucion; Type: COMMENT; Schema: soporte; Owner: postgres
--

COMMENT ON COLUMN soporte.informe_trabajo_tecnico.motivo_no_resolucion IS 'Motivo por el cual no se pudo resolver (cuando resultado=NO_RESUELTO)';


--
-- TOC entry 5439 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN informe_trabajo_tecnico.url_adjunto; Type: COMMENT; Schema: soporte; Owner: postgres
--

COMMENT ON COLUMN soporte.informe_trabajo_tecnico.url_adjunto IS 'URL o ruta de archivo adjunto de evidencia';


--
-- TOC entry 5440 (class 0 OID 0)
-- Dependencies: 299
-- Name: COLUMN informe_trabajo_tecnico.tiempo_trabajo_minutos; Type: COMMENT; Schema: soporte; Owner: postgres
--

COMMENT ON COLUMN soporte.informe_trabajo_tecnico.tiempo_trabajo_minutos IS 'Tiempo total de trabajo en minutos';


--
-- TOC entry 300 (class 1259 OID 23933)
-- Name: informe_trabajo_tecnico_id_informe_seq; Type: SEQUENCE; Schema: soporte; Owner: postgres
--

CREATE SEQUENCE soporte.informe_trabajo_tecnico_id_informe_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE soporte.informe_trabajo_tecnico_id_informe_seq OWNER TO postgres;

--
-- TOC entry 5442 (class 0 OID 0)
-- Dependencies: 300
-- Name: informe_trabajo_tecnico_id_informe_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.informe_trabajo_tecnico_id_informe_seq OWNED BY soporte.informe_trabajo_tecnico.id_informe;


--
-- TOC entry 301 (class 1259 OID 23934)
-- Name: inventario; Type: TABLE; Schema: soporte; Owner: postgres
--

CREATE TABLE soporte.inventario (
    id_item_inventario integer NOT NULL,
    codigo character varying(50) NOT NULL,
    nombre character varying(150) NOT NULL,
    descripcion text,
    tipo character varying(50),
    stock_actual integer DEFAULT 0 NOT NULL,
    stock_minimo integer DEFAULT 0,
    ubicacion character varying(100),
    activo boolean DEFAULT true,
    fecha_creacion timestamp without time zone DEFAULT now(),
    id_empresa integer NOT NULL,
    id_catalogo_item_estado integer DEFAULT 1,
    id_usuario_registro integer
);


ALTER TABLE soporte.inventario OWNER TO postgres;

--
-- TOC entry 302 (class 1259 OID 23949)
-- Name: inventario_id_item_inventario_seq; Type: SEQUENCE; Schema: soporte; Owner: postgres
--

CREATE SEQUENCE soporte.inventario_id_item_inventario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE soporte.inventario_id_item_inventario_seq OWNER TO postgres;

--
-- TOC entry 5445 (class 0 OID 0)
-- Dependencies: 302
-- Name: inventario_id_item_inventario_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.inventario_id_item_inventario_seq OWNED BY soporte.inventario.id_item_inventario;


--
-- TOC entry 303 (class 1259 OID 23950)
-- Name: inventario_usado_ticket; Type: TABLE; Schema: soporte; Owner: postgres
--

CREATE TABLE soporte.inventario_usado_ticket (
    id_uso integer NOT NULL,
    id_ticket integer NOT NULL,
    id_item_inventario integer NOT NULL,
    cantidad integer NOT NULL,
    fecha_registro timestamp without time zone DEFAULT now(),
    id_usuario_tecnico integer
);


ALTER TABLE soporte.inventario_usado_ticket OWNER TO postgres;

--
-- TOC entry 304 (class 1259 OID 23958)
-- Name: inventario_usado_ticket_id_uso_seq; Type: SEQUENCE; Schema: soporte; Owner: postgres
--

CREATE SEQUENCE soporte.inventario_usado_ticket_id_uso_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE soporte.inventario_usado_ticket_id_uso_seq OWNER TO postgres;

--
-- TOC entry 5448 (class 0 OID 0)
-- Dependencies: 304
-- Name: inventario_usado_ticket_id_uso_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.inventario_usado_ticket_id_uso_seq OWNED BY soporte.inventario_usado_ticket.id_uso;


--
-- TOC entry 305 (class 1259 OID 23959)
-- Name: network_probe_result; Type: TABLE; Schema: soporte; Owner: postgres
--

CREATE TABLE soporte.network_probe_result (
    id_result integer NOT NULL,
    id_run integer NOT NULL,
    zone_type character varying(50) NOT NULL,
    zone_id integer NOT NULL,
    latency_ms double precision,
    packet_loss double precision,
    http_status integer,
    score integer,
    level character varying(50)
);


ALTER TABLE soporte.network_probe_result OWNER TO postgres;

--
-- TOC entry 306 (class 1259 OID 23966)
-- Name: network_probe_result_id_result_seq; Type: SEQUENCE; Schema: soporte; Owner: postgres
--

CREATE SEQUENCE soporte.network_probe_result_id_result_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE soporte.network_probe_result_id_result_seq OWNER TO postgres;

--
-- TOC entry 5451 (class 0 OID 0)
-- Dependencies: 306
-- Name: network_probe_result_id_result_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.network_probe_result_id_result_seq OWNED BY soporte.network_probe_result.id_result;


--
-- TOC entry 307 (class 1259 OID 23967)
-- Name: network_probe_run; Type: TABLE; Schema: soporte; Owner: postgres
--

CREATE TABLE soporte.network_probe_run (
    id_run integer NOT NULL,
    target character varying(255) NOT NULL,
    data_source character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    duration_ms bigint,
    tool character varying(50),
    probe_count integer,
    success boolean,
    error_message text
);


ALTER TABLE soporte.network_probe_run OWNER TO postgres;

--
-- TOC entry 308 (class 1259 OID 23976)
-- Name: network_probe_run_id_run_seq; Type: SEQUENCE; Schema: soporte; Owner: postgres
--

CREATE SEQUENCE soporte.network_probe_run_id_run_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE soporte.network_probe_run_id_run_seq OWNER TO postgres;

--
-- TOC entry 5454 (class 0 OID 0)
-- Dependencies: 308
-- Name: network_probe_run_id_run_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.network_probe_run_id_run_seq OWNED BY soporte.network_probe_run.id_run;


--
-- TOC entry 309 (class 1259 OID 23977)
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
-- TOC entry 310 (class 1259 OID 23985)
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
-- TOC entry 5457 (class 0 OID 0)
-- Dependencies: 310
-- Name: prioridad_id_prioridad_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.prioridad_id_prioridad_seq OWNED BY soporte.prioridad.id_prioridad;


--
-- TOC entry 311 (class 1259 OID 23986)
-- Name: problema; Type: TABLE; Schema: soporte; Owner: postgres
--

CREATE TABLE soporte.problema (
    id_problema integer NOT NULL,
    nombre character varying(150) NOT NULL,
    descripcion text,
    nivel_criticidad integer DEFAULT 1,
    activo boolean DEFAULT true,
    fecha_creacion timestamp without time zone DEFAULT now(),
    id_categoria integer,
    id_catalogo_item_estado integer DEFAULT 1,
    id_prioridad integer,
    id_empresa integer
);


ALTER TABLE soporte.problema OWNER TO postgres;

--
-- TOC entry 312 (class 1259 OID 23997)
-- Name: problema_id_problema_seq; Type: SEQUENCE; Schema: soporte; Owner: postgres
--

CREATE SEQUENCE soporte.problema_id_problema_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE soporte.problema_id_problema_seq OWNER TO postgres;

--
-- TOC entry 5460 (class 0 OID 0)
-- Dependencies: 312
-- Name: problema_id_problema_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.problema_id_problema_seq OWNED BY soporte.problema.id_problema;


--
-- TOC entry 313 (class 1259 OID 23998)
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
-- TOC entry 314 (class 1259 OID 24010)
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
-- TOC entry 5463 (class 0 OID 0)
-- Dependencies: 314
-- Name: sla_ticket_id_sla_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.sla_ticket_id_sla_seq OWNED BY soporte.sla_ticket.id_sla;


--
-- TOC entry 315 (class 1259 OID 24011)
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
-- TOC entry 316 (class 1259 OID 24022)
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
-- TOC entry 5466 (class 0 OID 0)
-- Dependencies: 316
-- Name: solucion_ticket_id_solucion_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.solucion_ticket_id_solucion_seq OWNED BY soporte.solucion_ticket.id_solucion;


--
-- TOC entry 317 (class 1259 OID 24023)
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
-- TOC entry 5468 (class 0 OID 0)
-- Dependencies: 317
-- Name: ticket_id_ticket_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.ticket_id_ticket_seq OWNED BY soporte.ticket.id_ticket;


--
-- TOC entry 318 (class 1259 OID 24024)
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
-- TOC entry 5470 (class 0 OID 0)
-- Dependencies: 318
-- Name: visita_tecnica_id_visita_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.visita_tecnica_id_visita_seq OWNED BY soporte.visita_tecnica.id_visita;


--
-- TOC entry 319 (class 1259 OID 24025)
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
-- TOC entry 5472 (class 0 OID 0)
-- Dependencies: 319
-- Name: persona_id_persona_seq; Type: SEQUENCE OWNED BY; Schema: usuarios; Owner: postgres
--

ALTER SEQUENCE usuarios.persona_id_persona_seq OWNED BY usuarios.persona.id_persona;


--
-- TOC entry 320 (class 1259 OID 24026)
-- Name: rol; Type: TABLE; Schema: usuarios; Owner: postgres
--

CREATE TABLE usuarios.rol (
    id_rol integer NOT NULL,
    codigo character varying(50) NOT NULL,
    descripcion text
);


ALTER TABLE usuarios.rol OWNER TO postgres;

--
-- TOC entry 321 (class 1259 OID 24033)
-- Name: rol_bd; Type: TABLE; Schema: usuarios; Owner: postgres
--

CREATE TABLE usuarios.rol_bd (
    id_rol_bd integer NOT NULL,
    nombre character varying(50) NOT NULL,
    descripcion text
);


ALTER TABLE usuarios.rol_bd OWNER TO postgres;

--
-- TOC entry 322 (class 1259 OID 24040)
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
-- TOC entry 5476 (class 0 OID 0)
-- Dependencies: 322
-- Name: rol_bd_id_rol_bd_seq; Type: SEQUENCE OWNED BY; Schema: usuarios; Owner: postgres
--

ALTER SEQUENCE usuarios.rol_bd_id_rol_bd_seq OWNED BY usuarios.rol_bd.id_rol_bd;


--
-- TOC entry 323 (class 1259 OID 24041)
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
-- TOC entry 5478 (class 0 OID 0)
-- Dependencies: 323
-- Name: rol_id_rol_seq; Type: SEQUENCE OWNED BY; Schema: usuarios; Owner: postgres
--

ALTER SEQUENCE usuarios.rol_id_rol_seq OWNED BY usuarios.rol.id_rol;


--
-- TOC entry 324 (class 1259 OID 24042)
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
-- TOC entry 325 (class 1259 OID 24050)
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
-- TOC entry 5481 (class 0 OID 0)
-- Dependencies: 325
-- Name: usuario_bd_id_usuario_bd_seq; Type: SEQUENCE OWNED BY; Schema: usuarios; Owner: postgres
--

ALTER SEQUENCE usuarios.usuario_bd_id_usuario_bd_seq OWNED BY usuarios.usuario_bd.id_usuario_bd;


--
-- TOC entry 326 (class 1259 OID 24051)
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
-- TOC entry 5483 (class 0 OID 0)
-- Dependencies: 326
-- Name: usuario_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: usuarios; Owner: postgres
--

ALTER SEQUENCE usuarios.usuario_id_usuario_seq OWNED BY usuarios.usuario.id_usuario;


--
-- TOC entry 4674 (class 2604 OID 24052)
-- Name: auditoria_estado_ticket id_auditoria; Type: DEFAULT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket ALTER COLUMN id_auditoria SET DEFAULT nextval('auditoria.auditoria_estado_ticket_id_auditoria_seq'::regclass);


--
-- TOC entry 4676 (class 2604 OID 24053)
-- Name: auditoria_evento id_evento; Type: DEFAULT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_evento ALTER COLUMN id_evento SET DEFAULT nextval('auditoria.auditoria_evento_id_evento_seq'::regclass);


--
-- TOC entry 4679 (class 2604 OID 24054)
-- Name: auditoria_login id_login; Type: DEFAULT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login ALTER COLUMN id_login SET DEFAULT nextval('auditoria.auditoria_login_id_login_seq'::regclass);


--
-- TOC entry 4681 (class 2604 OID 24055)
-- Name: auditoria_login_bd id_auditoria_login_bd; Type: DEFAULT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd ALTER COLUMN id_auditoria_login_bd SET DEFAULT nextval('auditoria.auditoria_login_bd_id_auditoria_login_bd_seq'::regclass);


--
-- TOC entry 4688 (class 2604 OID 24056)
-- Name: catalogo id_catalogo; Type: DEFAULT; Schema: catalogos; Owner: postgres
--

ALTER TABLE ONLY catalogos.catalogo ALTER COLUMN id_catalogo SET DEFAULT nextval('catalogos.catalogo_id_catalogo_seq'::regclass);


--
-- TOC entry 4683 (class 2604 OID 24057)
-- Name: catalogo_item id_item; Type: DEFAULT; Schema: catalogos; Owner: postgres
--

ALTER TABLE ONLY catalogos.catalogo_item ALTER COLUMN id_item SET DEFAULT nextval('catalogos.catalogo_item_id_item_seq'::regclass);


--
-- TOC entry 4690 (class 2604 OID 24058)
-- Name: canton id_canton; Type: DEFAULT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.canton ALTER COLUMN id_canton SET DEFAULT nextval('clientes.canton_id_canton_seq'::regclass);


--
-- TOC entry 4691 (class 2604 OID 24059)
-- Name: ciudad id_ciudad; Type: DEFAULT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.ciudad ALTER COLUMN id_ciudad SET DEFAULT nextval('clientes.ciudad_id_ciudad_seq'::regclass);


--
-- TOC entry 4692 (class 2604 OID 24060)
-- Name: cliente id_cliente; Type: DEFAULT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.cliente ALTER COLUMN id_cliente SET DEFAULT nextval('clientes.cliente_id_cliente_seq'::regclass);


--
-- TOC entry 4696 (class 2604 OID 24061)
-- Name: documento_cliente id_documento; Type: DEFAULT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.documento_cliente ALTER COLUMN id_documento SET DEFAULT nextval('clientes.documento_cliente_id_documento_seq'::regclass);


--
-- TOC entry 4698 (class 2604 OID 24062)
-- Name: pais id_pais; Type: DEFAULT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.pais ALTER COLUMN id_pais SET DEFAULT nextval('clientes.pais_id_pais_seq'::regclass);


--
-- TOC entry 4699 (class 2604 OID 24063)
-- Name: tipo_documento id_tipo_documento; Type: DEFAULT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.tipo_documento ALTER COLUMN id_tipo_documento SET DEFAULT nextval('clientes.tipo_documento_id_tipo_documento_seq'::regclass);


--
-- TOC entry 4700 (class 2604 OID 24064)
-- Name: area id_area; Type: DEFAULT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.area ALTER COLUMN id_area SET DEFAULT nextval('empleados.area_id_area_seq'::regclass);


--
-- TOC entry 4701 (class 2604 OID 24065)
-- Name: cargo id_cargo; Type: DEFAULT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.cargo ALTER COLUMN id_cargo SET DEFAULT nextval('empleados.cargo_id_cargo_seq'::regclass);


--
-- TOC entry 4702 (class 2604 OID 24066)
-- Name: documento_empleado id_documento; Type: DEFAULT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.documento_empleado ALTER COLUMN id_documento SET DEFAULT nextval('empleados.documento_empleado_id_documento_seq'::regclass);


--
-- TOC entry 4705 (class 2604 OID 24067)
-- Name: tipo_contrato id_tipo_contrato; Type: DEFAULT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.tipo_contrato ALTER COLUMN id_tipo_contrato SET DEFAULT nextval('empleados.tipo_contrato_id_tipo_contrato_seq'::regclass);


--
-- TOC entry 4706 (class 2604 OID 24068)
-- Name: documento_empresa id_documento; Type: DEFAULT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.documento_empresa ALTER COLUMN id_documento SET DEFAULT nextval('empresa.documento_empresa_id_documento_seq'::regclass);


--
-- TOC entry 4708 (class 2604 OID 24069)
-- Name: empresa id_empresa; Type: DEFAULT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.empresa ALTER COLUMN id_empresa SET DEFAULT nextval('empresa.empresa_id_empresa_seq'::regclass);


--
-- TOC entry 4710 (class 2604 OID 24070)
-- Name: servicio id_servicio; Type: DEFAULT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.servicio ALTER COLUMN id_servicio SET DEFAULT nextval('empresa.servicio_id_servicio_seq'::regclass);


--
-- TOC entry 4711 (class 2604 OID 24071)
-- Name: sucursal id_sucursal; Type: DEFAULT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.sucursal ALTER COLUMN id_sucursal SET DEFAULT nextval('empresa.sucursal_id_sucursal_seq'::regclass);


--
-- TOC entry 4712 (class 2604 OID 24072)
-- Name: cola_correo id_correo; Type: DEFAULT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.cola_correo ALTER COLUMN id_correo SET DEFAULT nextval('notificaciones.cola_correo_id_correo_seq'::regclass);


--
-- TOC entry 4716 (class 2604 OID 24073)
-- Name: notificacion_web id_notificacion; Type: DEFAULT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.notificacion_web ALTER COLUMN id_notificacion SET DEFAULT nextval('notificaciones.notificacion_web_id_notificacion_seq'::regclass);


--
-- TOC entry 4719 (class 2604 OID 24074)
-- Name: configuracion_reporte id_reporte; Type: DEFAULT; Schema: reportes; Owner: postgres
--

ALTER TABLE ONLY reportes.configuracion_reporte ALTER COLUMN id_reporte SET DEFAULT nextval('reportes.configuracion_reporte_id_reporte_seq'::regclass);


--
-- TOC entry 4722 (class 2604 OID 24075)
-- Name: historial_generacion id_generacion; Type: DEFAULT; Schema: reportes; Owner: postgres
--

ALTER TABLE ONLY reportes.historial_generacion ALTER COLUMN id_generacion SET DEFAULT nextval('reportes.historial_generacion_id_generacion_seq'::regclass);


--
-- TOC entry 4731 (class 2604 OID 24076)
-- Name: asignacion id_asignacion; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.asignacion ALTER COLUMN id_asignacion SET DEFAULT nextval('soporte.asignacion_id_asignacion_seq'::regclass);


--
-- TOC entry 4734 (class 2604 OID 24077)
-- Name: categoria id_categoria; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.categoria ALTER COLUMN id_categoria SET DEFAULT nextval('soporte.categoria_id_categoria_seq'::regclass);


--
-- TOC entry 4735 (class 2604 OID 24078)
-- Name: comentario_ticket id_comentario; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket ALTER COLUMN id_comentario SET DEFAULT nextval('soporte.comentario_ticket_id_comentario_seq'::regclass);


--
-- TOC entry 4738 (class 2604 OID 24079)
-- Name: documento_ticket id_documento; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.documento_ticket ALTER COLUMN id_documento SET DEFAULT nextval('soporte.documento_ticket_id_documento_seq'::regclass);


--
-- TOC entry 4740 (class 2604 OID 24080)
-- Name: historial_estado id_historial; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado ALTER COLUMN id_historial SET DEFAULT nextval('soporte.historial_estado_id_historial_seq'::regclass);


--
-- TOC entry 4742 (class 2604 OID 24081)
-- Name: informe_trabajo_tecnico id_informe; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.informe_trabajo_tecnico ALTER COLUMN id_informe SET DEFAULT nextval('soporte.informe_trabajo_tecnico_id_informe_seq'::regclass);


--
-- TOC entry 4744 (class 2604 OID 24082)
-- Name: inventario id_item_inventario; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.inventario ALTER COLUMN id_item_inventario SET DEFAULT nextval('soporte.inventario_id_item_inventario_seq'::regclass);


--
-- TOC entry 4750 (class 2604 OID 24083)
-- Name: inventario_usado_ticket id_uso; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.inventario_usado_ticket ALTER COLUMN id_uso SET DEFAULT nextval('soporte.inventario_usado_ticket_id_uso_seq'::regclass);


--
-- TOC entry 4752 (class 2604 OID 24084)
-- Name: network_probe_result id_result; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.network_probe_result ALTER COLUMN id_result SET DEFAULT nextval('soporte.network_probe_result_id_result_seq'::regclass);


--
-- TOC entry 4753 (class 2604 OID 24085)
-- Name: network_probe_run id_run; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.network_probe_run ALTER COLUMN id_run SET DEFAULT nextval('soporte.network_probe_run_id_run_seq'::regclass);


--
-- TOC entry 4755 (class 2604 OID 24086)
-- Name: prioridad id_prioridad; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.prioridad ALTER COLUMN id_prioridad SET DEFAULT nextval('soporte.prioridad_id_prioridad_seq'::regclass);


--
-- TOC entry 4756 (class 2604 OID 24087)
-- Name: problema id_problema; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.problema ALTER COLUMN id_problema SET DEFAULT nextval('soporte.problema_id_problema_seq'::regclass);


--
-- TOC entry 4761 (class 2604 OID 24088)
-- Name: sla_ticket id_sla; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.sla_ticket ALTER COLUMN id_sla SET DEFAULT nextval('soporte.sla_ticket_id_sla_seq'::regclass);


--
-- TOC entry 4764 (class 2604 OID 24089)
-- Name: solucion_ticket id_solucion; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.solucion_ticket ALTER COLUMN id_solucion SET DEFAULT nextval('soporte.solucion_ticket_id_solucion_seq'::regclass);


--
-- TOC entry 4725 (class 2604 OID 24090)
-- Name: ticket id_ticket; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket ALTER COLUMN id_ticket SET DEFAULT nextval('soporte.ticket_id_ticket_seq'::regclass);


--
-- TOC entry 4729 (class 2604 OID 24091)
-- Name: visita_tecnica id_visita; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.visita_tecnica ALTER COLUMN id_visita SET DEFAULT nextval('soporte.visita_tecnica_id_visita_seq'::regclass);


--
-- TOC entry 4727 (class 2604 OID 24092)
-- Name: persona id_persona; Type: DEFAULT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.persona ALTER COLUMN id_persona SET DEFAULT nextval('usuarios.persona_id_persona_seq'::regclass);


--
-- TOC entry 4766 (class 2604 OID 24093)
-- Name: rol id_rol; Type: DEFAULT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.rol ALTER COLUMN id_rol SET DEFAULT nextval('usuarios.rol_id_rol_seq'::regclass);


--
-- TOC entry 4767 (class 2604 OID 24094)
-- Name: rol_bd id_rol_bd; Type: DEFAULT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.rol_bd ALTER COLUMN id_rol_bd SET DEFAULT nextval('usuarios.rol_bd_id_rol_bd_seq'::regclass);


--
-- TOC entry 4685 (class 2604 OID 24095)
-- Name: usuario id_usuario; Type: DEFAULT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario ALTER COLUMN id_usuario SET DEFAULT nextval('usuarios.usuario_id_usuario_seq'::regclass);


--
-- TOC entry 4768 (class 2604 OID 24096)
-- Name: usuario_bd id_usuario_bd; Type: DEFAULT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_bd ALTER COLUMN id_usuario_bd SET DEFAULT nextval('usuarios.usuario_bd_id_usuario_bd_seq'::regclass);


--
-- TOC entry 5190 (class 0 OID 23540)
-- Dependencies: 229
-- Data for Name: auditoria_estado_ticket; Type: TABLE DATA; Schema: auditoria; Owner: postgres
--

COPY auditoria.auditoria_estado_ticket (id_auditoria, id_ticket, usuario_bd, fecha_cambio, id_estado_anterior, id_item_evento, id_usuario, id_estado_nuevo_item) FROM stdin;
1	22	emp_0503658749_22	2026-03-08 12:39:36.356521	4	34	22	5
2	22	emp_1203587489_21	2026-03-08 12:40:46.153841	5	34	21	6
3	22	emp_1203587489_21	2026-03-08 12:56:02.92424	5	34	21	6
4	22	emp_1203587489_21	2026-03-08 13:00:42.788371	6	34	21	45
5	16	emp_0503658749_22	2026-03-08 13:18:24.616074	4	34	22	5
6	16	emp_1203587489_21	2026-03-08 13:24:18.067151	5	34	21	6
10	9	tecnico01	2026-03-09 03:17:59.543593	5	34	7	6
11	6	tecnico01	2026-03-09 03:27:42.302801	5	34	7	6
12	7	tecnico01	2026-03-09 04:52:45.506853	5	34	7	6
13	7	tecnico01	2026-03-09 04:55:11.777511	6	34	7	4
14	11	tecnico01	2026-03-09 05:01:01.449289	5	34	7	6
15	11	tecnico01	2026-03-09 05:08:58.348791	6	34	7	4
16	9	tecnico01	2026-03-09 08:27:27.455917	6	34	7	4
17	9	tecnico01	2026-03-09 08:27:56.978565	6	34	7	4
18	11	tecnico01	2026-03-09 10:30:01.845804	6	34	7	4
19	11	tecnico01	2026-03-09 10:50:17.498155	4	34	7	6
20	7	tecnico01	2026-03-09 11:13:15.589979	6	34	7	4
21	7	tecnico01	2026-03-09 11:13:23.752427	4	34	7	6
22	26	emp_0503658749_22	2026-03-09 11:28:35.779201	4	34	22	5
23	26	tecnico01	2026-03-09 11:29:55.010969	5	34	7	6
24	27	emp_0503658749_22	2026-03-09 11:53:27.582075	4	34	22	5
25	27	tecnico01	2026-03-09 11:53:45.665565	5	34	7	6
26	27	tecnico01	2026-03-09 11:54:49.991997	6	34	7	4
27	27	tecnico01	2026-03-09 11:56:07.410534	4	34	7	6
28	28	emp_0503658749_22	2026-03-10 06:17:38.375321	4	34	22	5
29	28	emp_1203587489_21	2026-03-10 06:18:09.288364	5	34	21	6
30	29	emp_0503658749_22	2026-03-10 11:42:57.242673	4	34	22	5
31	30	emp_0503658749_22	2026-03-10 11:46:04.860752	4	34	22	5
32	30	emp_1203587489_21	2026-03-10 11:48:01.900823	5	34	21	6
33	30	emp_1203587489_21	2026-03-10 11:50:11.655862	6	34	21	4
\.


--
-- TOC entry 5192 (class 0 OID 23549)
-- Dependencies: 231
-- Data for Name: auditoria_evento; Type: TABLE DATA; Schema: auditoria; Owner: postgres
--

COPY auditoria.auditoria_evento (id_evento, esquema_afectado, tabla_afectada, id_registro, descripcion, usuario_bd, rol_bd, fecha_evento, id_usuario, id_notificacion, id_accion_item, modulo, valores_anteriores, valores_nuevos, ip_origen, user_agent, endpoint, metodo_http, exito, observacion) FROM stdin;
1	desconocido	desconocida	0	Cierre de sesión de usuario	emp_1203587489_21	ROLE_TECNICO	2026-03-08 11:40:25.69744	21	\N	58	AUTH	\N	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/auth/logout	POST	t	\N
2	desconocido	desconocida	0	Cierre de sesión de usuario	sgiri_app	ROLE_CLIENTE	2026-03-08 12:09:19.985768	4	\N	58	AUTH	\N	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/auth/logout	POST	t	\N
3	soporte	ticket	22	Creación inicial de ticket por el cliente	sgiri_app	ROLE_CLIENTE	2026-03-08 12:39:09.552955	4	\N	30	TICKETS	\N	{"id_cliente":1,"asunto":"Fallas con el Internet"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/tickets	POST	t	\N
4	soporte	ticket	22	Ticket asignado o reasignado al técnico: amendozab1	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 12:39:36.363239	22	\N	31	TICKETS	\N	{"idUsuarioAsignadoNuevo":21}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/tickets/22/assign	POST	t	\N
5	soporte	ticket	22	Cierre o resolución de ticket. Nota: Problema de internet solucionado	emp_1203587489_21	ROLE_TECNICO	2026-03-08 13:07:50.483392	21	\N	34	TICKETS	{"estado_anterior":"REQUIERE_VISITA"}	{"estado_final":"RESUELTO"}	0:0:0:0:0:0:0:1	curl/8.15.0	/api/tickets/22/status	PUT	t	\N
6	soporte	ticket	22	Cierre o resolución de ticket. Nota: Cerrando el ticket tras verificacion	emp_1203587489_21	ROLE_TECNICO	2026-03-08 13:10:13.897384	21	\N	34	TICKETS	{"estado_anterior":"RESUELTO"}	{"estado_final":"CERRADO"}	0:0:0:0:0:0:0:1	curl/8.15.0	/api/tickets/22/status	PUT	t	\N
7	soporte	ticket	16	Ticket asignado o reasignado al técnico: amendozab1	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 13:18:24.629502	22	\N	31	TICKETS	\N	{"idUsuarioAsignadoNuevo":21}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/tickets/16/assign	POST	t	\N
8	soporte	ticket	16	Cierre o resolución de ticket. Nota: problema resuelto	emp_1203587489_21	ROLE_TECNICO	2026-03-08 13:25:30.753591	21	\N	34	TICKETS	{"estado_anterior":"EN_PROCESO"}	{"estado_final":"RESUELTO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/tickets/16/status	PUT	t	\N
9	soporte	ticket	16	Cliente registró calificación de satisfacción	sgiri_app	ROLE_CLIENTE	2026-03-08 13:31:55.840066	4	\N	57	TICKETS	\N	{"puntuacion":5}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/tickets/16/rating	POST	t	\N
10	empleados	empleado	12	Registro inicial de datos laborales del empleado	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 16:07:52.520187	22	\N	30	EMPLEADOS	\N	{"id_cargo":4,"id_area":2,"cedula":"1206847596"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/personnel/empleados	POST	t	\N
11	empleados	documento_empleado	8	Carga de documento tipo: CONSTANCIA	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 16:08:16.324538	22	\N	54	DOCUMENTOS	\N	{"tipo_codigo":"CONSTANCIA","id_empleado":12,"id_estado":48}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/documents/empleado/12/upload	POST	t	\N
12	empleados	documento_empleado	8	Gestión administrativa de documento: ACTIVO	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 16:08:19.502079	22	\N	55	DOCUMENTOS	\N	{"nuevo_estado":"ACTIVO","id_empleado":12}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/documents/empleado/docs/8/estado	PUT	t	\N
13	usuarios	usuario	23	Activación de acceso y creación de rol físico SQL	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 16:08:33.759011	22	\N	52	USUARIOS	\N	{"id_empleado":12,"rol":"TECNICO","username":"azambranoy1"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/personnel/empleados/1206847596/activar-acceso	POST	t	\N
14	desconocido	desconocida	0	Cierre de sesión de usuario	sgiri_app	ROLE_CLIENTE	2026-03-08 16:11:12.74625	4	\N	58	AUTH	\N	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/auth/logout	POST	t	\N
15	soporte	visita_tecnica	8	Programación de visita técnica para el ticket: #21	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 16:18:05.891828	22	\N	30	VISITAS	\N	{"id_tecnico":21,"id_ticket":21,"fecha":"2026-03-19"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/visitas	POST	t	\N
16	soporte	visita_tecnica	9	Programación de visita técnica para el ticket: #21	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 16:18:46.25833	22	\N	30	VISITAS	\N	{"id_tecnico":21,"id_ticket":21,"fecha":"2026-03-19"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/visitas	POST	t	\N
17	empleados	empleado	13	Registro inicial de datos laborales del empleado	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 16:22:06.982968	22	\N	30	EMPLEADOS	\N	{"id_cargo":4,"id_area":2,"cedula":"1205874962"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/personnel/empleados	POST	t	\N
19	empleados	documento_empleado	9	Gestión administrativa de documento: ACTIVO	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 16:23:11.730544	22	\N	55	DOCUMENTOS	\N	{"nuevo_estado":"ACTIVO","id_empleado":13}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/documents/empleado/docs/9/estado	PUT	t	\N
18	empleados	documento_empleado	9	Carga de documento tipo: CONSTANCIA	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 16:22:42.456282	22	\N	54	DOCUMENTOS	\N	{"tipo_codigo":"CONSTANCIA","id_empleado":13,"id_estado":48}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/documents/empleado/13/upload	POST	t	\N
20	usuarios	usuario	24	Activación de acceso y creación de rol físico SQL	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 16:23:44.144378	22	\N	52	USUARIOS	\N	{"id_empleado":13,"rol":"TECNICO","username":"amendozam"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/personnel/empleados/1205874962/activar-acceso	POST	t	\N
21	desconocido	desconocida	0	Cierre de sesión de usuario	emp_1203587489_21	ROLE_TECNICO	2026-03-08 16:25:00.228433	21	\N	58	AUTH	\N	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/auth/logout	POST	t	\N
22	empleados	documento_empleado	6	Gestión administrativa de documento: RECHAZADO	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 16:39:26.986467	22	\N	55	DOCUMENTOS	\N	{"nuevo_estado":"RECHAZADO","id_empleado":10}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/documents/empleado/docs/6/estado	PUT	t	\N
23	empleados	documento_empleado	6	Gestión administrativa de documento: ACTIVO	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 16:42:05.342888	22	\N	55	DOCUMENTOS	\N	{"nuevo_estado":"ACTIVO","id_empleado":10}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/documents/empleado/docs/6/estado	PUT	t	\N
24	empleados	documento_empleado	6	Gestión administrativa de documento: RECHAZADO	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 16:42:20.940737	22	\N	55	DOCUMENTOS	\N	{"nuevo_estado":"RECHAZADO","id_empleado":10}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/documents/empleado/docs/6/estado	PUT	t	\N
25	empleados	documento_empleado	6	Gestión administrativa de documento: ACTIVO	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 16:55:18.061414	22	\N	55	DOCUMENTOS	\N	{"nuevo_estado":"ACTIVO","id_empleado":10}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/documents/empleado/docs/6/estado	PUT	t	\N
26	usuarios	usuario	21	Suspensión automática por documentos rechazados	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 16:55:21.937129	22	\N	34	USUARIOS	{"id_doc_causa":6}	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/documents/empleado/docs/6/estado	PUT	t	\N
27	empleados	documento_empleado	6	Gestión administrativa de documento: RECHAZADO	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 16:55:21.944221	22	\N	55	DOCUMENTOS	\N	{"nuevo_estado":"RECHAZADO","id_empleado":10}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/documents/empleado/docs/6/estado	PUT	t	\N
28	usuarios	usuario	21	Reactivación automática por validación de documento	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 16:56:06.456396	22	\N	34	USUARIOS	{"id_doc_validacion":6}	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/documents/empleado/docs/6/estado	PUT	t	\N
29	empleados	documento_empleado	6	Gestión administrativa de documento: ACTIVO	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 16:56:06.465058	22	\N	55	DOCUMENTOS	\N	{"nuevo_estado":"ACTIVO","id_empleado":10}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/documents/empleado/docs/6/estado	PUT	t	\N
30	usuarios	usuario	24	El usuario ha cambiado exitosamente su contraseña	emp_1205874962_24	ROLE_TECNICO	2026-03-08 16:59:28.869314	24	\N	50	AUTH	\N	{"credencial_actualizada":true}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/auth/change-password	POST	t	\N
31	usuarios	usuario	24	El usuario ha cambiado exitosamente su contraseña	emp_1205874962_24	ROLE_TECNICO	2026-03-08 17:08:34.714598	24	\N	50	AUTH	\N	{"credencial_actualizada":true}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/auth/change-password	POST	t	\N
32	empleados	empleado	14	Registro inicial de datos laborales del empleado	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 17:22:40.85916	22	\N	30	EMPLEADOS	\N	{"id_area":2,"id_cargo":4,"cedula":"1302547895"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/personnel/empleados	POST	t	\N
33	empleados	documento_empleado	10	Carga de documento tipo: CONSTANCIA	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 17:23:48.228821	22	\N	54	DOCUMENTOS	\N	{"id_estado":48,"id_empleado":14,"tipo_codigo":"CONSTANCIA"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/documents/empleado/14/upload	POST	t	\N
34	empleados	documento_empleado	10	Gestión administrativa de documento: ACTIVO	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 17:23:51.065318	22	\N	55	DOCUMENTOS	\N	{"nuevo_estado":"ACTIVO","id_empleado":14}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/documents/empleado/docs/10/estado	PUT	t	\N
35	usuarios	usuario	25	Activación de acceso y creación de rol físico SQL	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 17:35:10.635034	22	\N	52	USUARIOS	\N	{"username":"dbermellol","rol":"TECNICO","id_empleado":14}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/personnel/empleados/1302547895/activar-acceso	POST	t	\N
36	empleados	empleado	15	Registro inicial de datos laborales del empleado	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 17:40:11.831291	22	\N	30	EMPLEADOS	\N	{"cedula":"1305487956","id_area":2,"id_cargo":4}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/personnel/empleados	POST	t	\N
37	empleados	documento_empleado	11	Carga de documento tipo: CONSTANCIA	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 17:40:34.487878	22	\N	54	DOCUMENTOS	\N	{"id_estado":48,"id_empleado":15,"tipo_codigo":"CONSTANCIA"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/documents/empleado/15/upload	POST	t	\N
38	empleados	documento_empleado	11	Gestión administrativa de documento: ACTIVO	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 17:40:37.249469	22	\N	55	DOCUMENTOS	\N	{"id_empleado":15,"nuevo_estado":"ACTIVO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/documents/empleado/docs/11/estado	PUT	t	\N
39	usuarios	usuario	26	Activación de acceso y creación de rol físico SQL	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-08 17:40:49.399842	22	\N	52	USUARIOS	\N	{"username":"kzambranoy","rol":"TECNICO","id_empleado":15}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/personnel/empleados/1305487956/activar-acceso	POST	t	\N
40	soporte	comentario_ticket	60	Comentario visible al cliente agregado al ticket	sgiri_app	ROLE_TECNICO	2026-03-09 10:23:35.405385	7	\N	56	TICKETS	\N	{"es_interno":false,"id_ticket":9}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/9/comments	POST	t	\N
41	soporte	ticket	9	Cierre o resolución de ticket. Nota: Informe técnico registrado. Ticket resuelto.	sgiri_app	ROLE_TECNICO	2026-03-09 10:24:03.158024	7	\N	34	TICKETS	{"estado_anterior":"EN_PROCESO"}	{"estado_final":"RESUELTO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/9/informe	POST	t	\N
42	soporte	informe_trabajo_tecnico	17	Técnico registró informe de trabajo. Resultado: RESUELTO	sgiri_app	ROLE_TECNICO	2026-03-09 10:24:03.208004	7	\N	30	TICKETS	\N	{"resultado":"RESUELTO","id_ticket":9}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/9/informe	POST	t	\N
106	desconocido	desconocida	0	Cierre de sesión de usuario	sgiri_app	ROLE_CLIENTE	2026-03-13 11:30:02.137479	4	\N	58	AUTH	\N	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	/api/auth/logout	POST	t	\N
43	soporte	comentario_ticket	61	Comentario visible al cliente agregado al ticket	sgiri_app	ROLE_TECNICO	2026-03-09 10:26:21.06677	7	\N	56	TICKETS	\N	{"es_interno":false,"id_ticket":11}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/11/comments	POST	t	\N
44	soporte	comentario_ticket	62	Comentario visible al cliente agregado al ticket	sgiri_app	ROLE_TECNICO	2026-03-09 10:27:09.055283	7	\N	56	TICKETS	\N	{"es_interno":false,"id_ticket":11}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/11/comments	POST	t	\N
45	soporte	informe_trabajo_tecnico	18	Técnico registró informe de trabajo. Resultado: NO_RESUELTO	sgiri_app	ROLE_TECNICO	2026-03-09 10:30:01.892387	7	\N	30	TICKETS	\N	{"resultado":"NO_RESUELTO","id_ticket":11}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/11/informe	POST	t	\N
46	soporte	ticket	11	Cierre o resolución de ticket. Nota: 	sgiri_app	ROLE_TECNICO	2026-03-09 10:50:33.314006	7	\N	34	TICKETS	{"estado_anterior":"EN_PROCESO"}	{"estado_final":"CERRADO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/11/status	PUT	t	\N
47	soporte	comentario_ticket	63	Comentario visible al cliente agregado al ticket	sgiri_app	ROLE_TECNICO	2026-03-09 11:01:26.538639	7	\N	56	TICKETS	\N	{"id_ticket":7,"es_interno":false}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/7/comments	POST	t	\N
48	usuarios	usuario	26	Suspensión automática por documentos rechazados	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-09 11:07:38.283301	22	\N	34	USUARIOS	{"id_doc_causa":11}	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/documents/empleado/docs/11/estado	PUT	t	\N
49	empleados	documento_empleado	11	Gestión administrativa de documento: RECHAZADO	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-09 11:07:38.297048	22	\N	55	DOCUMENTOS	\N	{"nuevo_estado":"RECHAZADO","id_empleado":15}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/documents/empleado/docs/11/estado	PUT	t	\N
50	soporte	comentario_ticket	64	Comentario visible al cliente agregado al ticket	sgiri_app	ROLE_TECNICO	2026-03-09 11:11:18.750241	7	\N	56	TICKETS	\N	{"id_ticket":7,"es_interno":false}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/7/comments	POST	t	\N
51	soporte	informe_trabajo_tecnico	19	Técnico registró informe de trabajo. Resultado: NO_RESUELTO	sgiri_app	ROLE_TECNICO	2026-03-09 11:13:15.625132	7	\N	30	TICKETS	\N	{"id_ticket":7,"resultado":"NO_RESUELTO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/7/informe	POST	t	\N
52	soporte	ticket	7	Cierre o resolución de ticket. Nota: 	sgiri_app	ROLE_TECNICO	2026-03-09 11:13:31.47029	7	\N	34	TICKETS	{"estado_anterior":"EN_PROCESO"}	{"estado_final":"CERRADO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/7/status	PUT	t	\N
53	soporte	ticket	9	Cierre o resolución de ticket. Nota: 	sgiri_app	ROLE_TECNICO	2026-03-09 11:15:41.598366	7	\N	34	TICKETS	{"estado_anterior":"RESUELTO"}	{"estado_final":"CERRADO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/9/status	PUT	t	\N
54	soporte	ticket	6	Cierre o resolución de ticket. Nota: Informe técnico registrado. Ticket resuelto.	sgiri_app	ROLE_TECNICO	2026-03-09 11:16:03.391066	7	\N	34	TICKETS	{"estado_anterior":"EN_PROCESO"}	{"estado_final":"RESUELTO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/6/informe	POST	t	\N
55	soporte	informe_trabajo_tecnico	20	Técnico registró informe de trabajo. Resultado: RESUELTO	sgiri_app	ROLE_TECNICO	2026-03-09 11:16:03.409438	7	\N	30	TICKETS	\N	{"id_ticket":6,"resultado":"RESUELTO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/6/informe	POST	t	\N
56	soporte	ticket	6	Cierre o resolución de ticket. Nota: listo	sgiri_app	ROLE_TECNICO	2026-03-09 11:18:16.426605	7	\N	34	TICKETS	{"estado_anterior":"RESUELTO"}	{"estado_final":"CERRADO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/6/status	PUT	t	\N
57	soporte	ticket	26	Creación inicial de ticket por el cliente	sgiri_app	ROLE_CLIENTE	2026-03-09 11:23:27.728901	4	\N	30	TICKETS	\N	{"id_cliente":1,"asunto":"no funciona mi pc  o es el internet barato que contrate"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets	POST	t	\N
58	desconocido	desconocida	0	Cierre de sesión de usuario	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-09 11:27:25.641961	22	\N	58	AUTH	\N	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/auth/logout	POST	t	\N
59	soporte	ticket	26	Ticket asignado o reasignado al técnico: tecnico01	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-09 11:28:35.791727	22	\N	31	TICKETS	\N	{"idUsuarioAsignadoNuevo":7}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/26/assign	POST	t	\N
60	soporte	comentario_ticket	65	Comentario visible al cliente agregado al ticket	sgiri_app	ROLE_CLIENTE	2026-03-09 11:28:55.412013	4	\N	56	TICKETS	\N	{"id_ticket":26,"es_interno":false}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/26/comments	POST	t	\N
61	soporte	comentario_ticket	66	Comentario visible al cliente agregado al ticket	sgiri_app	ROLE_CLIENTE	2026-03-09 11:28:58.519284	4	\N	56	TICKETS	\N	{"id_ticket":26,"es_interno":false}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/26/comments	POST	t	\N
62	soporte	comentario_ticket	67	Comentario visible al cliente agregado al ticket	sgiri_app	ROLE_CLIENTE	2026-03-09 11:29:02.497387	4	\N	56	TICKETS	\N	{"id_ticket":26,"es_interno":false}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/26/comments	POST	t	\N
107	desconocido	desconocida	0	Cierre de sesión de usuario	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-13 11:54:48.218849	22	\N	58	AUTH	\N	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	/api/auth/logout	POST	t	\N
63	soporte	comentario_ticket	68	Comentario visible al cliente agregado al ticket	sgiri_app	ROLE_TECNICO	2026-03-09 11:29:27.165122	7	\N	56	TICKETS	\N	{"id_ticket":26,"es_interno":false}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/26/comments	POST	t	\N
64	soporte	comentario_ticket	69	Comentario visible al cliente agregado al ticket	sgiri_app	ROLE_TECNICO	2026-03-09 11:35:14.966459	7	\N	56	TICKETS	\N	{"id_ticket":26,"es_interno":false}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/26/comments	POST	t	\N
65	soporte	ticket	26	Cierre o resolución de ticket. Nota: Informe técnico registrado. Ticket resuelto.	sgiri_app	ROLE_TECNICO	2026-03-09 11:35:58.082217	7	\N	34	TICKETS	{"estado_anterior":"EN_PROCESO"}	{"estado_final":"RESUELTO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/26/informe	POST	t	\N
66	soporte	informe_trabajo_tecnico	21	Técnico registró informe de trabajo. Resultado: RESUELTO	sgiri_app	ROLE_TECNICO	2026-03-09 11:35:58.105597	7	\N	30	TICKETS	\N	{"id_ticket":26,"resultado":"RESUELTO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/26/informe	POST	t	\N
67	soporte	ticket	26	Cierre o resolución de ticket. Nota: pngame 10	sgiri_app	ROLE_TECNICO	2026-03-09 11:36:21.731332	7	\N	34	TICKETS	{"estado_anterior":"RESUELTO"}	{"estado_final":"CERRADO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/26/status	PUT	t	\N
68	soporte	ticket	26	Cliente registró calificación de satisfacción	sgiri_app	ROLE_CLIENTE	2026-03-09 11:36:42.574842	4	\N	57	TICKETS	{"puntuacion":"sin calificar","comentario":"n/a"}	{"puntuacion":3,"comentario":"tarda mucho"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/26/rating	POST	t	\N
69	soporte	ticket	27	Creación inicial de ticket por el cliente	sgiri_app	ROLE_CLIENTE	2026-03-09 11:53:11.965526	4	\N	30	TICKETS	\N	{"id_cliente":1,"asunto":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets	POST	t	\N
70	soporte	ticket	27	Ticket asignado o reasignado al técnico: tecnico01	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-09 11:53:27.59205	22	\N	31	TICKETS	\N	{"idUsuarioAsignadoNuevo":7}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/27/assign	POST	t	\N
71	soporte	informe_trabajo_tecnico	22	Técnico registró informe de trabajo. Resultado: NO_RESUELTO	sgiri_app	ROLE_TECNICO	2026-03-09 11:54:50.018956	7	\N	30	TICKETS	\N	{"id_ticket":27,"resultado":"NO_RESUELTO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/27/informe	POST	t	\N
72	soporte	ticket	27	Cierre o resolución de ticket. Nota: 	sgiri_app	ROLE_TECNICO	2026-03-09 11:56:27.522424	7	\N	34	TICKETS	{"estado_anterior":"EN_PROCESO"}	{"estado_final":"CERRADO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	/api/tickets/27/status	PUT	t	\N
73	catalogos	documento_cliente	1	Carga de foto de perfil (Cliente)	sgiri_app	ROLE_CLIENTE	2026-03-09 16:15:34.444791	4	\N	54	PERFIL	\N	{"unique_filename":"amendozab_47ae4552-f2b7-4daf-8389-f0b1e44d0808.jpeg"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/documents/upload-photo	POST	t	\N
74	soporte	ticket	17	Cierre o resolución de ticket. Nota: Informe técnico registrado. Ticket resuelto.	emp_1203587489_21	ROLE_TECNICO	2026-03-09 16:24:34.677453	21	\N	34	TICKETS	{"estado_anterior":"EN_PROCESO"}	{"estado_final":"RESUELTO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/tickets/17/informe	POST	t	\N
75	soporte	informe_trabajo_tecnico	24	Técnico registró informe de trabajo. Resultado: RESUELTO	emp_1203587489_21	ROLE_TECNICO	2026-03-09 16:24:34.691419	21	\N	30	TICKETS	\N	{"id_ticket":17,"resultado":"RESUELTO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/tickets/17/informe	POST	t	\N
76	usuarios	usuario	26	Reactivación automática por validación de documento	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-09 16:56:04.229487	22	\N	34	USUARIOS	{"id_doc_validacion":11}	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/documents/empleado/docs/11/estado	PUT	t	\N
77	empleados	documento_empleado	11	Gestión administrativa de documento: ACTIVO	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-09 16:56:04.262694	22	\N	55	DOCUMENTOS	\N	{"nuevo_estado":"ACTIVO","id_empleado":15}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/documents/empleado/docs/11/estado	PUT	t	\N
78	usuarios	usuario	26	Suspensión automática por documentos rechazados	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-09 16:56:57.050497	22	\N	34	USUARIOS	{"id_doc_causa":11}	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/documents/empleado/docs/11/estado	PUT	t	\N
79	empleados	documento_empleado	11	Gestión administrativa de documento: RECHAZADO	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-09 16:56:57.082248	22	\N	55	DOCUMENTOS	\N	{"nuevo_estado":"RECHAZADO","id_empleado":15}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/documents/empleado/docs/11/estado	PUT	t	\N
80	usuarios	usuario	7	Cambio administrativo de rol de usuario	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-09 21:17:00.26883	22	\N	31	USUARIOS	{"rol":"TECNICO"}	{"rol":"TECNICO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/admin/users/7	PUT	t	\N
81	usuarios	usuario	7	Cambio administrativo de rol de usuario	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-09 21:17:43.56821	22	\N	31	USUARIOS	{"rol":"TECNICO"}	{"rol":"TECNICO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/admin/users/7	PUT	t	\N
82	catalogos	documento_cliente	1	Carga de foto de perfil (Cliente)	sgiri_app	ROLE_CLIENTE	2026-03-10 06:06:26.693178	4	\N	54	PERFIL	\N	{"unique_filename":"amendozab_5982e601-aa77-4b76-86d9-2d3000847550.jpeg"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/documents/upload-photo	POST	t	\N
108	desconocido	desconocida	0	Cierre de sesión de usuario	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-13 11:55:37.753567	22	\N	58	AUTH	\N	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	/api/auth/logout	POST	t	\N
83	soporte	ticket	28	Creación inicial de ticket por el cliente	sgiri_app	ROLE_CLIENTE	2026-03-10 06:17:19.855479	4	\N	30	TICKETS	\N	{"id_cliente":1,"asunto":"Fallas con el router - No hay internet "}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/tickets	POST	t	\N
84	soporte	ticket	28	Ticket asignado o reasignado al técnico: amendozab1	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-10 06:17:38.385739	22	\N	31	TICKETS	\N	{"idUsuarioAsignadoNuevo":21}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/tickets/28/assign	POST	t	\N
85	soporte	comentario_ticket	70	Comentario visible al cliente agregado al ticket	emp_1203587489_21	ROLE_TECNICO	2026-03-10 06:18:50.689212	21	\N	56	TICKETS	\N	{"es_interno":false,"id_ticket":28}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/tickets/28/comments	POST	t	\N
86	soporte	comentario_ticket	71	Comentario visible al cliente agregado al ticket	sgiri_app	ROLE_CLIENTE	2026-03-10 06:23:33.16753	4	\N	56	TICKETS	\N	{"es_interno":false,"id_ticket":28}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/tickets/28/comments	POST	t	\N
87	soporte	comentario_ticket	72	Comentario visible al cliente agregado al ticket	emp_1203587489_21	ROLE_TECNICO	2026-03-10 06:23:52.090248	21	\N	56	TICKETS	\N	{"es_interno":false,"id_ticket":28}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/tickets/28/comments	POST	t	\N
88	soporte	comentario_ticket	73	Comentario visible al cliente agregado al ticket	sgiri_app	ROLE_CLIENTE	2026-03-10 07:27:59.679902	4	\N	56	TICKETS	\N	{"es_interno":false,"id_ticket":28}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/tickets/28/comments	POST	t	\N
89	soporte	comentario_ticket	74	Comentario visible al cliente agregado al ticket	emp_1203587489_21	ROLE_TECNICO	2026-03-10 07:32:24.820243	21	\N	56	TICKETS	\N	{"es_interno":false,"id_ticket":28}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/tickets/28/comments	POST	t	\N
90	desconocido	desconocida	0	Cierre de sesión de usuario	sgiri_app	ROLE_CLIENTE	2026-03-10 11:33:28.65308	4	\N	58	AUTH	\N	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/auth/logout	POST	t	\N
91	soporte	ticket	29	Creación inicial de ticket por el cliente	sgiri_app	ROLE_CLIENTE	2026-03-10 11:40:55.933256	4	\N	30	TICKETS	\N	{"id_cliente":1,"asunto":"Internet muy lento y con cortes frecuentes"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/tickets	POST	t	\N
92	soporte	ticket	29	Ticket asignado o reasignado al técnico: azambranoy1	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-10 11:42:57.251751	22	\N	31	TICKETS	\N	{"idUsuarioAsignadoNuevo":23}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/tickets/29/assign	POST	t	\N
93	soporte	ticket	30	Creación inicial de ticket por el cliente	sgiri_app	ROLE_CLIENTE	2026-03-10 11:45:40.656486	4	\N	30	TICKETS	\N	{"id_cliente":1,"asunto":"Internet muy lento y con cortes frecuentes"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/tickets	POST	t	\N
94	soporte	ticket	30	Ticket asignado o reasignado al técnico: amendozab1	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-10 11:46:04.867715	22	\N	31	TICKETS	\N	{"idUsuarioAsignadoNuevo":21}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/tickets/30/assign	POST	t	\N
95	soporte	comentario_ticket	75	Comentario visible al cliente agregado al ticket	sgiri_app	ROLE_CLIENTE	2026-03-10 11:48:27.745141	4	\N	56	TICKETS	\N	{"es_interno":false,"id_ticket":30}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/tickets/30/comments	POST	t	\N
96	soporte	informe_trabajo_tecnico	25	Técnico registró informe de trabajo. Resultado: NO_RESUELTO	emp_1203587489_21	ROLE_TECNICO	2026-03-10 11:50:11.669135	21	\N	30	TICKETS	\N	{"resultado":"NO_RESUELTO","id_ticket":30}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/tickets/30/informe	POST	t	\N
97	soporte	ticket	30	Cierre o resolución de ticket. Nota: 	emp_1203587489_21	ROLE_TECNICO	2026-03-10 11:50:25.211345	21	\N	34	TICKETS	{"estado_anterior":"ABIERTO"}	{"estado_final":"CERRADO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/tickets/30/status	PUT	t	\N
98	soporte	ticket	30	Cliente registró calificación de satisfacción	sgiri_app	ROLE_CLIENTE	2026-03-10 11:52:18.873767	4	\N	57	TICKETS	{"comentario":"n/a","puntuacion":"sin calificar"}	{"comentario":"","puntuacion":4}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/tickets/30/rating	POST	t	\N
99	desconocido	desconocida	0	Cierre de sesión de usuario	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-11 11:42:20.664423	22	\N	58	AUTH	\N	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/auth/logout	POST	t	\N
100	desconocido	desconocida	0	Cierre de sesión de usuario	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-11 12:44:10.474052	22	\N	58	AUTH	\N	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/auth/logout	POST	t	\N
101	desconocido	desconocida	0	Cierre de sesión de usuario	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-11 12:47:45.082966	22	\N	58	AUTH	\N	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/auth/logout	POST	t	\N
102	desconocido	desconocida	0	Cierre de sesión de usuario	emp_1203587489_21	ROLE_TECNICO	2026-03-11 12:48:33.894045	21	\N	58	AUTH	\N	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	/api/auth/logout	POST	t	\N
103	desconocido	desconocida	0	Cierre de sesión de usuario	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-13 11:20:59.53274	22	\N	58	AUTH	\N	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	/api/auth/logout	POST	t	\N
104	usuarios	usuario	4	El usuario ha cambiado exitosamente su contraseña	sgiri_app	ROLE_CLIENTE	2026-03-13 11:22:19.952034	4	\N	50	AUTH	\N	{"credencial_actualizada":true}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	/api/auth/change-password	POST	t	\N
105	catalogos	documento_cliente	1	Carga de foto de perfil (Cliente)	sgiri_app	ROLE_CLIENTE	2026-03-13 11:25:30.235521	4	\N	54	PERFIL	\N	{"unique_filename":"https://res.cloudinary.com/dcavi7awm/image/upload/v1773419129/sgiri_uploads/tzka3erallmia5hkygd8.jpg"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	/api/documents/upload-photo	POST	t	\N
109	usuarios	usuario	11	Suspensión o reactivación administrativa de cuenta	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-13 12:27:06.618415	22	\N	34	USUARIOS	{"estado":"ACTIVO"}	{"estado":"INACTIVO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	/api/admin/users/11/status	PUT	t	\N
110	usuarios	usuario	26	Suspensión o reactivación administrativa de cuenta	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-13 12:27:13.929362	22	\N	34	USUARIOS	{"estado":"INACTIVO"}	{"estado":"ACTIVO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	/api/admin/users/26/status	PUT	t	\N
111	empleados	documento_empleado	11	Gestión administrativa de documento: ACTIVO	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-13 12:28:24.17683	22	\N	55	DOCUMENTOS	\N	{"id_empleado":15,"nuevo_estado":"ACTIVO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	/api/documents/empleado/docs/11/estado	PUT	t	\N
112	usuarios	usuario	26	Suspensión automática por documentos rechazados	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-13 12:28:26.248452	22	\N	34	USUARIOS	{"id_doc_causa":11}	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	/api/documents/empleado/docs/11/estado	PUT	t	\N
113	empleados	documento_empleado	11	Gestión administrativa de documento: RECHAZADO	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-13 12:28:26.253459	22	\N	55	DOCUMENTOS	\N	{"id_empleado":15,"nuevo_estado":"RECHAZADO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	/api/documents/empleado/docs/11/estado	PUT	t	\N
114	desconocido	desconocida	0	Cierre de sesión de usuario	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-13 13:42:43.007564	22	\N	58	AUTH	\N	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	/api/auth/logout	POST	t	\N
115	empleados	empleado	16	Registro inicial de datos laborales del empleado	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-13 13:58:22.017675	22	\N	30	EMPLEADOS	\N	{"cedula":"0985547886","id_cargo":3,"id_area":7}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	/api/personnel/empleados	POST	t	\N
116	empleados	documento_empleado	12	Carga de documento tipo: CONSTANCIA	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-13 18:57:30.389341	22	\N	54	DOCUMENTOS	\N	{"id_estado":48,"tipo_codigo":"CONSTANCIA","id_empleado":16}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	/api/documents/empleado/16/upload	POST	t	\N
117	empleados	documento_empleado	12	Gestión administrativa de documento: ACTIVO	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-13 18:57:39.255255	22	\N	55	DOCUMENTOS	\N	{"id_empleado":16,"nuevo_estado":"ACTIVO"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	/api/documents/empleado/docs/12/estado	PUT	t	\N
118	usuarios	usuario	28	Activación de acceso y creación de rol físico SQL	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-13 19:27:47.042406	22	\N	52	USUARIOS	\N	{"id_empleado":16,"rol":"ADMIN_CONTRATOS","username":"gpalmab"}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	/api/personnel/empleados/0985547886/activar-acceso	POST	t	\N
119	desconocido	desconocida	0	Cierre de sesión de usuario	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-13 19:28:08.931372	22	\N	58	AUTH	\N	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	/api/auth/logout	POST	t	\N
120	usuarios	usuario	28	El usuario ha cambiado exitosamente su contraseña	emp_0985547886_28	ROLE_ADMIN_CONTRATOS	2026-03-13 19:28:23.026918	28	\N	50	AUTH	\N	{"credencial_actualizada":true}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	/api/auth/change-password	POST	t	\N
121	usuarios	usuario	28	El usuario ha cambiado exitosamente su contraseña	emp_0985547886_28	ROLE_ADMIN_CONTRATOS	2026-03-13 19:30:08.319355	28	\N	50	AUTH	\N	{"credencial_actualizada":true}	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	/api/auth/change-password	POST	t	\N
122	desconocido	desconocida	0	Cierre de sesión de usuario	emp_0985547886_28	ROLE_ADMIN_CONTRATOS	2026-03-13 19:30:22.093061	28	\N	58	AUTH	\N	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	/api/auth/logout	POST	t	\N
123	desconocido	desconocida	0	Cierre de sesión de usuario	emp_0503658749_22	ROLE_ADMIN_MASTER	2026-03-13 19:31:26.501741	22	\N	58	AUTH	\N	\N	0:0:0:0:0:0:0:1	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	/api/auth/logout	POST	t	\N
\.


--
-- TOC entry 5194 (class 0 OID 23566)
-- Dependencies: 233
-- Data for Name: auditoria_login; Type: TABLE DATA; Schema: auditoria; Owner: postgres
--

COPY auditoria.auditoria_login (id_login, usuario_app, usuario_bd, exito, ip_origen, fecha_login, id_usuario, id_item_evento, user_agent, motivo_fallo) FROM stdin;
1	amendozab1	emp_1203587489_21	t	0:0:0:0:0:0:0:1	2026-03-08 11:32:43.504042	21	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
2	amendozab1	emp_1203587489_21	t	0:0:0:0:0:0:0:1	2026-03-08 11:40:31.421785	21	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
3	amendozab	\N	f	0:0:0:0:0:0:0:1	2026-03-08 12:03:03.545671	\N	49	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	Credenciales incorrectas o cuenta no activada
4	amendozab	\N	f	0:0:0:0:0:0:0:1	2026-03-08 12:04:33.49415	\N	49	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	Credenciales incorrectas o cuenta no activada
5	amendozab	\N	f	0:0:0:0:0:0:0:1	2026-03-08 12:04:44.866288	\N	49	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	Credenciales incorrectas o cuenta no activada
6	amendozab	\N	t	0:0:0:0:0:0:0:1	2026-03-08 12:04:58.587328	4	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
7	eburgosc	\N	t	0:0:0:0:0:0:0:1	2026-03-08 12:08:51.424152	2	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
8	amendozab	\N	t	0:0:0:0:0:0:0:1	2026-03-08 12:09:52.966888	4	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
9	amendozab1	emp_1203587489_21	t	0:0:0:0:0:0:0:1	2026-03-08 16:24:28.081341	21	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
10	amendozam	emp_1205874962_24	t	0:0:0:0:0:0:0:1	2026-03-08 16:59:16.80869	24	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
11	rsosam	emp_0503658749_22	t	0:0:0:0:0:0:0:1	2026-03-09 02:00:28.212378	22	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
16	amendozab1	emp_1203587489_21	t	0:0:0:0:0:0:0:1	2026-03-09 02:04:36.770393	21	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
17	amendozab1	emp_1203587489_21	t	0:0:0:0:0:0:0:1	2026-03-09 02:05:07.866195	21	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
18	tecnico01	\N	t	0:0:0:0:0:0:0:1	2026-03-09 03:17:22.152332	7	33	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	\N
19	tecnico01	\N	t	0:0:0:0:0:0:0:1	2026-03-09 03:27:33.505385	7	33	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	\N
20	tecnico01	\N	t	0:0:0:0:0:0:0:1	2026-03-09 04:52:05.445275	7	33	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	\N
21	tecnico01	\N	t	0:0:0:0:0:0:0:1	2026-03-09 04:57:23.22012	7	33	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	\N
22	tecnico01	\N	t	0:0:0:0:0:0:0:1	2026-03-09 07:02:12.4531	7	33	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	\N
23	tecnico01	\N	t	0:0:0:0:0:0:0:1	2026-03-09 08:26:10.688519	7	33	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	\N
24	tecnico01	\N	t	0:0:0:0:0:0:0:1	2026-03-09 08:54:25.032214	7	33	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	\N
25	tecnico01	\N	t	0:0:0:0:0:0:0:1	2026-03-09 09:06:38.926638	7	33	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	\N
26	tecnico01	\N	t	0:0:0:0:0:0:0:1	2026-03-09 09:18:53.157847	7	33	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	\N
27	tecnico01	\N	t	127.0.0.1	2026-03-09 09:23:35.819631	7	33	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	\N
28	tecnico01	\N	t	0:0:0:0:0:0:0:1	2026-03-09 09:51:10.267201	7	33	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	\N
29	tecnico01	\N	t	0:0:0:0:0:0:0:1	2026-03-09 09:53:12.151145	7	33	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	\N
30	tecnico01	\N	t	0:0:0:0:0:0:0:1	2026-03-09 10:23:25.051593	7	33	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	\N
31	tecnico01	\N	t	0:0:0:0:0:0:0:1	2026-03-09 10:49:42.448788	7	33	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	\N
32	rsosam	emp_0503658749_22	t	0:0:0:0:0:0:0:1	2026-03-09 10:51:47.612782	22	33	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	\N
33	tecnico01	\N	f	0:0:0:0:0:0:0:1	2026-03-09 11:05:26.072628	\N	49	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	Credenciales incorrectas o cuenta no activada
34	amendozab	\N	t	0:0:0:0:0:0:0:1	2026-03-09 11:18:36.839509	4	33	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	\N
35	aza	\N	f	0:0:0:0:0:0:0:1	2026-03-09 11:20:27.882276	\N	49	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	Credenciales incorrectas o cuenta no activada
36	rsosam	emp_0503658749_22	t	0:0:0:0:0:0:0:1	2026-03-09 11:27:21.534904	22	33	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	\N
37	tecnico01	\N	t	0:0:0:0:0:0:0:1	2026-03-09 11:27:35.326593	7	33	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0	\N
38	rsosam	emp_0503658749_22	t	0:0:0:0:0:0:0:1	2026-03-09 15:31:47.664237	22	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
39	amendozab1	emp_1203587489_21	t	0:0:0:0:0:0:0:1	2026-03-09 15:55:19.983069	21	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
40	amendozab1	emp_1203587489_21	t	0:0:0:0:0:0:0:1	2026-03-09 15:55:45.383537	21	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
41	amendozab1	emp_1203587489_21	t	0:0:0:0:0:0:0:1	2026-03-09 16:01:56.545048	21	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
42	amendozab1	emp_1203587489_21	t	0:0:0:0:0:0:0:1	2026-03-09 16:03:52.682299	21	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
43	amendozab1	emp_1203587489_21	t	0:0:0:0:0:0:0:1	2026-03-09 16:06:05.84258	21	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
44	amendozab1	emp_1203587489_21	t	0:0:0:0:0:0:0:1	2026-03-09 16:08:24.674266	21	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
45	amendozab	\N	t	0:0:0:0:0:0:0:1	2026-03-09 16:15:23.11144	4	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
46	eburgosc	\N	t	0:0:0:0:0:0:0:1	2026-03-09 16:15:52.931255	2	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
47	rsosam	emp_0503658749_22	t	0:0:0:0:0:0:0:1	2026-03-09 16:52:45.427156	22	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
48	rsosam	emp_0503658749_22	t	0:0:0:0:0:0:0:1	2026-03-10 06:05:50.105926	22	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
49	amendozab1	emp_1203587489_21	t	0:0:0:0:0:0:0:1	2026-03-10 06:06:02.986273	21	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
50	amendozab	\N	t	0:0:0:0:0:0:0:1	2026-03-10 06:06:18.02997	4	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
51	amendozab	\N	t	0:0:0:0:0:0:0:1	2026-03-10 11:33:57.819524	4	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
52	azambranoy1	\N	f	0:0:0:0:0:0:0:1	2026-03-10 11:44:14.207556	\N	49	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	Credenciales incorrectas o cuenta no activada
53	amendozab1	emp_1203587489_21	t	0:0:0:0:0:0:0:1	2026-03-10 11:46:14.404384	21	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
54	rsosam	emp_0503658749_22	t	0:0:0:0:0:0:0:1	2026-03-11 11:42:15.599404	22	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
55	rsosam	emp_0503658749_22	t	0:0:0:0:0:0:0:1	2026-03-11 11:45:24.883988	22	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
56	rsosom	\N	f	0:0:0:0:0:0:0:1	2026-03-11 12:45:53.648062	\N	49	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	Credenciales incorrectas o cuenta no activada
57	rsosam	emp_0503658749_22	t	0:0:0:0:0:0:0:1	2026-03-11 12:46:09.211476	22	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
58	amendozab1	emp_1203587489_21	t	0:0:0:0:0:0:0:1	2026-03-11 12:47:55.84843	21	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
59	rsosam	emp_0503658749_22	t	0:0:0:0:0:0:0:1	2026-03-11 12:48:42.111279	22	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	\N
60	rsosam	emp_0503658749_22	t	0:0:0:0:0:0:0:1	2026-03-13 11:18:55.3514	22	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	\N
61	amendozab	\N	f	0:0:0:0:0:0:0:1	2026-03-13 11:21:10.012536	\N	49	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	Credenciales incorrectas o cuenta no activada
62	amendozab	\N	t	0:0:0:0:0:0:0:1	2026-03-13 11:21:35.484207	4	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	\N
63	rsosam	emp_0503658749_22	t	0:0:0:0:0:0:0:1	2026-03-13 11:30:07.617343	22	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	\N
64	rsosam	emp_0503658749_22	t	0:0:0:0:0:0:0:1	2026-03-13 11:55:31.322485	22	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	\N
65	rsosam	emp_0503658749_22	t	0:0:0:0:0:0:0:1	2026-03-13 12:26:31.280813	22	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	\N
66	rsosam	emp_0503658749_22	t	0:0:0:0:0:0:0:1	2026-03-13 13:42:52.139419	22	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	\N
67	rsosam	emp_0503658749_22	t	0:0:0:0:0:0:0:1	2026-03-13 18:55:11.908963	22	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	\N
68	gpalmab	emp_0985547886_28	t	0:0:0:0:0:0:0:1	2026-03-13 19:28:16.376204	28	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	\N
69	rsosam	emp_0503658749_22	t	0:0:0:0:0:0:0:1	2026-03-13 19:30:27.385287	22	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	\N
70	gpalmab	emp_0985547886_28	t	0:0:0:0:0:0:0:1	2026-03-13 19:31:36.600568	28	33	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	\N
\.


--
-- TOC entry 5195 (class 0 OID 23575)
-- Dependencies: 234
-- Data for Name: auditoria_login_bd; Type: TABLE DATA; Schema: auditoria; Owner: postgres
--

COPY auditoria.auditoria_login_bd (id_auditoria_login_bd, id_usuario_bd, id_item_evento, fecha_evento, ip_origen, observacion) FROM stdin;
\.


--
-- TOC entry 5200 (class 0 OID 23611)
-- Dependencies: 240
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
12	ESTADOS_GENERALES	Estados generales para empresas, sucursales y otros.	t
13	IMPLEMENTOS_TECNICOS	Catálogo de implementos o herramientas no inventariadas.	t
14	PROBLEMAS_TECNICOS	Catálogo de problemas encontrados.	t
15	SOLUCIONES_TECNICAS	Catálogo de soluciones aplicadas.	t
16	PRUEBAS_TECNICAS	Catálogo de pruebas realizadas.	t
17	MOTIVOS_NO_RESOLUCION_TECNICA	Catálogo de motivos por los que no se resolvió un ticket.	t
\.


--
-- TOC entry 5198 (class 0 OID 23587)
-- Dependencies: 237
-- Data for Name: catalogo_item; Type: TABLE DATA; Schema: catalogos; Owner: postgres
--

COPY catalogos.catalogo_item (id_item, id_catalogo, codigo, nombre, orden, activo) FROM stdin;
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
39	3	PRIORIDAD_ULTRA	ULTRA URGENTE	5	t
10	3	BAJA	Baja	1	t
3	1	BLOQUEADO	Bloqueado	3	t
1	1	ACTIVO	Activo	1	t
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
46	12	ACTIVO	Activo	1	t
47	12	INACTIVO	Inactivo	2	t
48	12	PENDIENTE	Pendiente / En Espera	3	t
2	1	INACTIVO	Inactivo	2	t
49	8	LOGIN_FALLIDO	Intento de login fallido	6	t
50	8	CAMBIO_PASSWORD	Cambio de contraseña	7	t
51	8	REGISTRO_USUARIO	Auto-registro de nuevo usuario cliente	8	t
52	8	ACTIVACION_ACCESO	Activación de acceso a empleado	9	t
53	8	REVOCACION_ACCESO	Eliminación o revocación de acceso de usuario	10	t
54	8	UPLOAD_DOCUMENTO	Carga de documento al sistema	11	t
55	8	CAMBIO_ESTADO_DOC	Cambio de estado de documento	12	t
56	8	COMENTARIO	Comentario añadido a un ticket	13	t
57	8	CALIFICACION	Calificación de servicio registrada por cliente	14	t
58	8	LOGOUT	Cierre de sesión manual	15	t
59	13	NO_APLICA	NO_APLICA	1	t
60	13	SIN_MATERIAL	SIN_MATERIAL	2	t
61	13	CABLE_HDMI	Cable HDMI	3	t
62	13	CABLE_DE_RED	Cable de red	4	t
63	13	ROUTER	Router	5	t
64	13	SWITCH	Switch	6	t
65	13	ADAPTADOR	Adaptador	7	t
66	13	FUENTE_DE_PODER	Fuente de poder	8	t
67	13	DISCO_DURO	Disco duro	9	t
68	13	MEMORIA_RAM	Memoria RAM	10	t
69	13	PATCH_CORD	Patch cord	11	t
70	13	CONVERTIDOR_USB	Convertidor USB	12	t
71	13	ANTENA_WIFI	Antena WiFi	13	t
72	13	LAPTOP_DE_PRUEBA	Laptop de prueba	14	t
73	14	NO_APLICA	NO_APLICA	1	t
74	14	CABLE_DANADO	Cable dañado	2	t
75	14	CONFIGURACION_INCORRECTA	Configuración incorrecta	3	t
76	14	HARDWARE_DEFECTUOSO	Hardware defectuoso	4	t
77	14	VIRUS_DETECTADO	Virus detectado	5	t
78	14	SISTEMA_DESACTUALIZADO	Sistema desactualizado	6	t
79	14	SENAL_DEBIL_WIFI	Señal débil WiFi	7	t
80	14	PUERTO_QUEMADO	Puerto quemado	8	t
81	14	FALTA_DE_DRIVERS	Falta de drivers	9	t
82	14	SOBRECALENTAMIENTO	Sobrecalentamiento	10	t
83	14	ERROR_DE_SOFTWARE	Error de software	11	t
84	14	SATURACION_DE_RED	Saturación de red	12	t
85	15	NO_APLICA	NO_APLICA	1	t
86	15	REEMPLAZO_DE_CABLE	Reemplazo de cable	2	t
87	15	RECONFIGURACION_DEL_SISTEMA	Reconfiguración del sistema	3	t
88	15	INSTALACION_DE_DRIVERS	Instalación de drivers	4	t
89	15	ELIMINACION_DE_VIRUS	Eliminación de virus	5	t
90	15	ACTUALIZACION_DEL_SISTEMA	Actualización del sistema	6	t
91	15	CAMBIO_DE_HARDWARE	Cambio de hardware	7	t
92	15	RESETEO_DE_ROUTER	Reseteo de router	8	t
93	15	OPTIMIZACION_DE_RED	Optimización de red	9	t
94	15	REINSTALACION_DE_SOFTWARE	Reinstalación de software	10	t
95	15	CAMBIO_DE_CONFIGURACION_IP	Cambio de configuración IP	11	t
96	15	LIMPIEZA_DE_EQUIPO	Limpieza de equipo	12	t
97	16	NO_APLICA	NO_APLICA	1	t
98	16	REINICIO_DEL_SISTEMA	Reinicio del sistema	2	t
99	16	PRUEBA_DE_CONEXION	Prueba de conexión	3	t
100	16	TEST_DE_VELOCIDAD	Test de velocidad	4	t
101	16	TEST_DE_HARDWARE	Test de hardware	5	t
102	16	PRUEBA_DE_PING	Prueba de ping	6	t
103	16	VERIFICACION_DE_PUERTOS	Verificación de puertos	7	t
104	16	MONITOREO_DE_RED	Monitoreo de red	8	t
105	16	PRUEBA_DE_APLICACION	Prueba de aplicación	9	t
106	16	TEST_DE_CARGA	Test de carga	10	t
107	17	FALTA_DE_REPUESTOS	Falta de repuestos	1	t
108	17	PROBLEMA_MAYOR_IDENTIFICADO	Problema mayor identificado	2	t
109	17	REQUIERE_ESPECIALISTA_EXTERNO	Requiere especialista externo	3	t
110	17	CLIENTE_NO_DISPONIBLE	Cliente no disponible	4	t
111	17	PROBLEMA_EXTERNO_AL_ISP	Problema externo al ISP	5	t
112	17	REQUIERE_VISITA_PRESENCIAL_ADICIONAL	Requiere visita presencial adicional	6	t
113	17	ESPERA_DE_AUTORIZACION	Espera de autorización	7	t
\.


--
-- TOC entry 5203 (class 0 OID 23621)
-- Dependencies: 243
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
-- TOC entry 5205 (class 0 OID 23628)
-- Dependencies: 245
-- Data for Name: ciudad; Type: TABLE DATA; Schema: clientes; Owner: postgres
--

COPY clientes.ciudad (id_ciudad, nombre, id_pais) FROM stdin;
1	Pichincha	1
2	Guayas	1
3	Azuay	1
4	Manabí	1
5	Tungurahua	1
6	Bolívar	1
7	Cañar	1
8	Carchi	1
9	Cotopaxi	1
10	Chimborazo	1
11	El Oro	1
12	Esmeraldas	1
13	Imbabura	1
14	Loja	1
15	Los Ríos	1
16	Morona Santiago	1
17	Napo	1
18	Pastaza	1
19	Zamora Chinchipe	1
20	Galápagos	1
21	Sucumbíos	1
22	Orellana	1
23	Santo Domingo de los Tsáchilas	1
24	Santa Elena	1
25	Zonas No Delimitadas	1
\.


--
-- TOC entry 5207 (class 0 OID 23635)
-- Dependencies: 247
-- Data for Name: cliente; Type: TABLE DATA; Schema: clientes; Owner: postgres
--

COPY clientes.cliente (id_cliente, id_sucursal, id_persona, fecha_inicio_contrato, fecha_fin_contrato, acceso_remoto, aprobacion_de_cambios, actualizaciones_automaticas) FROM stdin;
1	2	1	\N	\N	t	f	t
2	1	2	\N	\N	t	f	t
3	3	3	\N	\N	t	f	t
4	3	6	\N	\N	t	f	t
5	3	8	\N	\N	t	f	t
\.


--
-- TOC entry 5209 (class 0 OID 23643)
-- Dependencies: 249
-- Data for Name: documento_cliente; Type: TABLE DATA; Schema: clientes; Owner: postgres
--

COPY clientes.documento_cliente (id_documento, numero_documento, ruta_archivo, descripcion, fecha_subida, id_cliente, id_tipo_documento, id_catalogo_item_estado) FROM stdin;
2	1250062336	azambranoy_3bbd13fc-ca97-40e4-b886-5fb733ca3d51.png	Foto de perfil	2026-02-25 12:12:44.744385	4	1	\N
1	0503360398	https://res.cloudinary.com/dcavi7awm/image/upload/v1773419129/sgiri_uploads/tzka3erallmia5hkygd8.jpg	Foto de perfil	2026-02-22 19:47:08.801353	1	1	\N
\.


--
-- TOC entry 5211 (class 0 OID 23655)
-- Dependencies: 251
-- Data for Name: pais; Type: TABLE DATA; Schema: clientes; Owner: postgres
--

COPY clientes.pais (id_pais, nombre) FROM stdin;
1	Ecuador
\.


--
-- TOC entry 5213 (class 0 OID 23661)
-- Dependencies: 253
-- Data for Name: tipo_documento; Type: TABLE DATA; Schema: clientes; Owner: postgres
--

COPY clientes.tipo_documento (id_tipo_documento, codigo) FROM stdin;
1	FOTO
3	CONSTANCIA
4	CONTRATO
5	CERTIFICADO
6	ACUERDO
7	ANEXO
\.


--
-- TOC entry 5215 (class 0 OID 23667)
-- Dependencies: 255
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
-- TOC entry 5217 (class 0 OID 23673)
-- Dependencies: 257
-- Data for Name: cargo; Type: TABLE DATA; Schema: empleados; Owner: postgres
--

COPY empleados.cargo (id_cargo, nombre) FROM stdin;
1	Administrador Master
2	Administrador Técnicos
4	Técnico
5	Soporte Nivel 1
6	Soporte Nivel 2
7	Jefe de Sistemas
8	Analista de Sistemas
3	Administrador Contratos
\.


--
-- TOC entry 5219 (class 0 OID 23679)
-- Dependencies: 259
-- Data for Name: documento_empleado; Type: TABLE DATA; Schema: empleados; Owner: postgres
--

COPY empleados.documento_empleado (id_documento, numero_documento, ruta_archivo, descripcion, fecha_subida, id_empleado, id_tipo_documento, id_catalogo_item_estado, cedula_empleado) FROM stdin;
7		emp_doc_11_b6c03827-c227-41e4-8e3f-ea56007dc49f.pdf		2026-03-08 10:42:56.313682	11	3	27	0503658749
8		emp_doc_12_ba1feebf-eeb2-47dd-ac76-0f2f58e911bc.pdf		2026-03-08 16:08:16.320697	12	3	27	1206847596
9		emp_doc_13_b8a8a4d7-7bac-4363-83aa-624e63a88736.pdf		2026-03-08 16:22:42.454363	13	3	27	1205874962
6		emp_doc_10_896c0769-62e5-426f-bc74-321328570cce.pdf		2026-03-07 19:47:29.851698	10	3	27	1203587489
10		emp_doc_14_7b3ef556-88bf-43c4-ad8e-298f3aed0b2d.pdf		2026-03-08 17:23:48.221321	14	3	27	1302547895
11		emp_doc_15_8632d5bb-090f-4107-8087-5feb180f8fec.pdf		2026-03-08 17:40:34.481297	15	3	9	1305487956
12		https://res.cloudinary.com/dcavi7awm/image/upload/v1773446249/sgiri_uploads/zyjfuj0c1i3dy2vsqn30.pdf		2026-03-13 18:57:30.380579	16	3	27	0985547886
\.


--
-- TOC entry 5222 (class 0 OID 23692)
-- Dependencies: 262
-- Data for Name: empleado; Type: TABLE DATA; Schema: empleados; Owner: postgres
--

COPY empleados.empleado (fecha_ingreso, id_cargo, id_area, id_tipo_contrato, id_empleado, id_sucursal, id_persona) FROM stdin;
2026-03-14	4	2	2	10	\N	15
2026-03-08	1	1	1	11	\N	16
2026-03-08	4	2	2	12	\N	17
2026-03-10	4	2	2	13	\N	18
2026-03-08	4	2	2	14	\N	19
2026-03-15	4	2	1	15	\N	20
2026-03-13	3	7	1	16	\N	21
\.


--
-- TOC entry 5223 (class 0 OID 23701)
-- Dependencies: 263
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
-- TOC entry 5225 (class 0 OID 23707)
-- Dependencies: 265
-- Data for Name: documento_empresa; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.documento_empresa (id_documento, id_empresa, numero_documento, ruta_archivo, descripcion, fecha_subida, id_tipo_documento, id_catalogo_item_estado) FROM stdin;
\.


--
-- TOC entry 5227 (class 0 OID 23719)
-- Dependencies: 267
-- Data for Name: empresa; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.empresa (id_empresa, nombre_comercial, razon_social, ruc, tipo_empresa, correo_contacto, telefono_contacto, direccion_principal, fecha_creacion, id_catalogo_item_tipo_empresa, id_catalogo_item_estado) FROM stdin;
1	CNT	Corporación Nacional de Telecomunicaciones CNT EP	1768152560001	PUBLICA	\N	\N	\N	2026-02-22 10:54:48.394042	\N	1
2	Netlife	MEGADATOS S.A. (NETLIFE)	1792161037001	PRIVADA	\N	\N	\N	2026-02-22 10:54:48.394042	\N	1
3	Xtrim	TV CABLE / XTRIM	0990793664001	PRIVADA	\N	\N	\N	2026-02-22 10:54:48.394042	\N	1
\.


--
-- TOC entry 5229 (class 0 OID 23731)
-- Dependencies: 269
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
-- TOC entry 5230 (class 0 OID 23736)
-- Dependencies: 270
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
-- TOC entry 5232 (class 0 OID 23744)
-- Dependencies: 272
-- Data for Name: sucursal; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.sucursal (id_sucursal, id_empresa, nombre, direccion, telefono, id_ciudad, id_canton, id_catalogo_item_estado) FROM stdin;
1	1	Sucursal Matriz CNT	Dirección Principal de CNT	\N	1	1	1
2	2	Sucursal Matriz Netlife	Dirección Principal de Netlife	\N	2	4	1
3	3	Sucursal Matriz Xtrim	Dirección Principal de Xtrim	\N	3	7	1
\.


--
-- TOC entry 5234 (class 0 OID 23754)
-- Dependencies: 274
-- Data for Name: cola_correo; Type: TABLE DATA; Schema: notificaciones; Owner: postgres
--

COPY notificaciones.cola_correo (id_correo, id_empresa, destinatario_correo, asunto, cuerpo_html, enviado, intentos, fecha_creacion, fecha_envio, error_envio, id_ticket) FROM stdin;
1	1	elizabethanahisb@gmail.com	Actualización de Ticket #18 - Técnico Asignado	<h3>Hola Elizabeth Anahis Burgos Chilan</h3><p>Le informamos que su ticket <b>#18: HOLA PAPUCITO LINDO</b> ha sido asignado al técnico <b>aza</b>.</p><p>Puede seguir el progreso desde el aplicativo web.</p>	t	0	2026-03-08 02:52:57.340705	2026-03-08 02:53:47.459915	\N	18
2	1	elizabethanahisb@gmail.com	Ticket #18 - Actualización de Estado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Elizabeth Anahis Burgos Chilan</b>,</p><p>Te informamos que tu ticket <b>#18</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Resuelto</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>HOLA PAPUCITO LINDO</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"El cliente me confirmo que ya esta todo funcionando al 100%"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>aza</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/18' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 03:27:26.878694	2026-03-08 03:27:30.038079	\N	18
3	1	elizabethanahisb@gmail.com	Ticket #19 - Técnico Asignado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Asignación de Técnico</div>            <p>Hola <b>Elizabeth Anahis Burgos Chilan</b>,</p><p>Nuestro equipo ha procesado tu requerimiento y queremos informarte que ya ha sido asignado un especialista para su atención.</p><div class='info-box'>    <div class='info-item'><span class='label'>Ticket:</span> <span class='value'>#19</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>QUE TA CHENDO AYUDEME UWU</span></div>    <div class='info-item' style='margin-bottom: 0;'><span class='label'>Especialista:</span> <span class='value'>aza</span></div></div><p>Puedes realizar el seguimiento de tu incidencia en tiempo real y chatear con el técnico asignado a través de nuestra plataforma web.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/19' class='btn button'>Seguir Ticket en Línea</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 03:29:32.203163	2026-03-08 03:29:35.308609	\N	19
4	1	elizabethanahisb@gmail.com	Ticket #19 - Actualización de Estado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Elizabeth Anahis Burgos Chilan</b>,</p><p>Te informamos que tu ticket <b>#19</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>En proceso</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>QUE TA CHENDO AYUDEME UWU</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"En revisión, este pendiente."</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>aza</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/19' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 03:30:09.353082	2026-03-08 03:30:10.423828	\N	19
5	1	elizabethanahisb@gmail.com	Ticket #19 - Actualización de Estado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Elizabeth Anahis Burgos Chilan</b>,</p><p>Te informamos que tu ticket <b>#19</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Requiere Visita</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>QUE TA CHENDO AYUDEME UWU</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"No hubo solución remota.\n"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>aza</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/19' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 03:32:51.239436	2026-03-08 03:32:51.319387	\N	19
6	1	elizabethanahisb@gmail.com	Ticket #20 - Técnico Asignado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Asignación de Técnico</div>            <p>Hola <b>Elizabeth Anahis Burgos Chilan</b>,</p><p>Nuestro equipo ha procesado tu requerimiento y queremos informarte que ya ha sido asignado un especialista para su atención.</p><div class='info-box'>    <div class='info-item'><span class='label'>Ticket:</span> <span class='value'>#20</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Papu sale humo de mi router</span></div>    <div class='info-item' style='margin-bottom: 0;'><span class='label'>Especialista:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Puedes realizar el seguimiento de tu incidencia en tiempo real y chatear con el técnico asignado a través de nuestra plataforma web.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/20' class='btn button'>Seguir Ticket en Línea</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 04:03:30.312356	2026-03-08 04:03:33.474603	\N	20
7	1	elizabethanahisb@gmail.com	Ticket #20 - En proceso	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Elizabeth Anahis Burgos Chilan</b>,</p><p>Te informamos que tu ticket <b>#20</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>En proceso</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Papu sale humo de mi router</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"En revisión"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/20' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 04:04:13.289336	2026-03-08 04:04:13.559044	\N	20
8	1	elizabethanahisb@gmail.com	Ticket #20 - Requiere Visita	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Visita Técnica Requerida</div>            <p>Hola <b>Elizabeth Anahis Burgos Chilan</b>,</p><p>Nuestro equipo técnico ha revisado tu requerimiento y ha determinado que <b>es necesaria una visita presencial</b> para resolver la incidencia.</p><div class='info-box' style='border-left: 5px solid #ffc107;'>    <div class='info-item'><span class='label'>Ticket:</span> <span class='value'>#20</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Papu sale humo de mi router</span></div>    <div class='info-item'><span class='label'>Motivo de Visita:</span> <br><i style='color: #555;'>"No se encontro una solucion remota."</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Técnico que solicita:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>En breve, nuestro personal administrativo se pondrá en contacto contigo o agendará la cita directamente en tu calendario de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/20' class='btn button'>Revisar Agenda</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 04:06:11.173534	2026-03-08 04:06:14.046123	\N	20
9	1	elizabethanahisb@gmail.com	Ticket #20 - Cerrado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Elizabeth Anahis Burgos Chilan</b>,</p><p>Te informamos que tu ticket <b>#20</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Cerrado</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Papu sale humo de mi router</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"El caso fue resuelto correctamente"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/20' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 04:30:21.276638	2026-03-08 04:30:25.496572	\N	20
10	1	elizabethanahisb@gmail.com	Ticket #21 - Técnico Asignado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Asignación de Técnico</div>            <p>Hola <b>Elizabeth Anahis Burgos Chilan</b>,</p><p>Nuestro equipo ha procesado tu requerimiento y queremos informarte que ya ha sido asignado un especialista para su atención.</p><div class='info-box'>    <div class='info-item'><span class='label'>Ticket:</span> <span class='value'>#21</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Mi cable de la instalacion se ha dañado</span></div>    <div class='info-item' style='margin-bottom: 0;'><span class='label'>Especialista:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Puedes realizar el seguimiento de tu incidencia en tiempo real y chatear con el técnico asignado a través de nuestra plataforma web.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/21' class='btn button'>Seguir Ticket en Línea</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 04:30:38.96669	2026-03-08 04:30:40.545041	\N	21
11	1	elizabethanahisb@gmail.com	Ticket #21 - En proceso	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Elizabeth Anahis Burgos Chilan</b>,</p><p>Te informamos que tu ticket <b>#21</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>En proceso</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Mi cable de la instalacion se ha dañado</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"En revisión"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/21' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 04:31:19.481666	2026-03-08 04:31:20.61669	\N	21
12	1	elizabethanahisb@gmail.com	Ticket #21 - Requiere Visita	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Visita Técnica Requerida</div>            <p>Hola <b>Elizabeth Anahis Burgos Chilan</b>,</p><p>Nuestro equipo técnico ha revisado tu requerimiento y ha determinado que <b>es necesaria una visita presencial</b> para resolver la incidencia.</p><div class='info-box' style='border-left: 5px solid #ffc107;'>    <div class='info-item'><span class='label'>Ticket:</span> <span class='value'>#21</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Mi cable de la instalacion se ha dañado</span></div>    <div class='info-item'><span class='label'>Motivo de Visita:</span> <br><i style='color: #555;'>"El caso requiere una revision presencial urgente."</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Técnico que solicita:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>En breve, nuestro personal administrativo se pondrá en contacto contigo o agendará la cita directamente en tu calendario de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/21' class='btn button'>Revisar Agenda</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 04:31:38.081768	2026-03-08 04:31:40.657802	\N	21
13	1	elizabethanahisb@gmail.com	Cita Programada: Visita Técnica para Ticket #21	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Cita Programada Exitosamente</div>            <p>Hola <b>Elizabeth Anahis</b>,</p><p>¡Buenas noticias! Tu visita técnica ha sido programada. Nuestro especialista acudirá a tus instalaciones en el horario acordado.</p><div class='info-box' style='border-left: 5px solid #198754;'>    <div class='info-item'><span class='label'>Fecha de Visita:</span> <span class='value' style='color: #198754;'>2026-03-13</span></div>    <div class='info-item'><span class='label'>Horario:</span> <span class='value'>De 09:30 a 11:30</span></div>    <div class='info-item'><span class='label'>Ticket Asociado:</span> <span class='value'>#21 - Mi cable de la instalacion se ha dañado</span></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Técnico Responsable:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Por favor, asegúrate de que haya alguien disponible para recibir a nuestro personal. Si necesitas reprogramar, contáctanos lo antes posible.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/cliente/tickets/detalle/21' class='btn button'>Ver Mi Agenda</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 04:33:24.913311	2026-03-08 04:33:25.829013	\N	21
14	2	angellomendoza46@gmail.com	Ticket #2 - Requiere Visita	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Visita Técnica Requerida</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Nuestro equipo técnico ha revisado tu requerimiento y ha determinado que <b>es necesaria una visita presencial</b> para resolver la incidencia.</p><div class='info-box' style='border-left: 5px solid #ffc107;'>    <div class='info-item'><span class='label'>Ticket:</span> <span class='value'>#2</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>No tengo conexión a internet desde ayer en la noche</span></div>    <div class='info-item'><span class='label'>Motivo de Visita:</span> <br><i style='color: #555;'>"No hubo resolución remota "</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Técnico que solicita:</span> <span class='value'>tecnico01</span></div></div><p>En breve, nuestro personal administrativo se pondrá en contacto contigo o agendará la cita directamente en tu calendario de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/2' class='btn button'>Revisar Agenda</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 05:23:47.301831	2026-03-08 05:23:48.91925	\N	2
15	2	angellomendoza46@gmail.com	Ticket #2 - Cerrado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Te informamos que tu ticket <b>#2</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Cerrado</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>No tengo conexión a internet desde ayer en la noche</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Incidencia resuelta"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/2' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 05:25:19.952751	2026-03-08 05:25:23.944626	\N	2
16	3	azambranoy@uteq.edu.ec	Ticket #5 - Cerrado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angel Daniel Zambrano Yong</b>,</p><p>Te informamos que tu ticket <b>#5</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Cerrado</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>GONTE GONTE GONTE GONTE</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Incidencia resuelta"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/5' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 05:30:09.347997	2026-03-08 05:30:14.010697	\N	5
17	3	azambranoy@uteq.edu.ec	Ticket #8 - Cerrado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angel Daniel Zambrano Yong</b>,</p><p>Te informamos que tu ticket <b>#8</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Cerrado</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>HOLAAAAAAAAAA</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Incidencia resuelta"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/8' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 05:30:25.046875	2026-03-08 05:30:29.020863	\N	8
18	3	azambranoy@uteq.edu.ec	Ticket #4 - Resuelto	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angel Daniel Zambrano Yong</b>,</p><p>Te informamos que tu ticket <b>#4</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Resuelto</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>TENGO TENGO TENGO TENGO</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"El usuario notificó que se soluciono su problema "</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/4' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 05:30:51.925895	2026-03-08 05:30:54.057559	\N	4
19	3	azambranoy@uteq.edu.ec	Ticket #4 - Cerrado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angel Daniel Zambrano Yong</b>,</p><p>Te informamos que tu ticket <b>#4</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Cerrado</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>TENGO TENGO TENGO TENGO</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Incidencia resuelta"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/4' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 05:30:54.971786	2026-03-08 05:30:59.062438	\N	4
20	2	angellomendoza46@gmail.com	Ticket #13 - Cerrado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Te informamos que tu ticket <b>#13</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Cerrado</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Sin señal en el servicio de televisión</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Incidencia resuelta"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/13' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 05:31:13.348024	2026-03-08 05:31:14.071198	\N	13
21	2	angellomendoza46@gmail.com	Ticket #15 - Cerrado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Te informamos que tu ticket <b>#15</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Cerrado</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Problemas de Latencia de Red</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Incidencia resuelta"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/15' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 05:31:20.152515	2026-03-08 05:31:24.080363	\N	15
22	1	elizabethanahisb@gmail.com	Ticket #17 - En proceso	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Elizabeth Anahis Burgos Chilan</b>,</p><p>Te informamos que tu ticket <b>#17</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>En proceso</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Falla del servicio de internet</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Usted esta siendo atendido "</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/17' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 10:05:10.801589	2026-03-08 10:05:11.863892	\N	17
23	2	angellomendoza46@gmail.com	Ticket #22 - Técnico Asignado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Asignación de Técnico</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Nuestro equipo ha procesado tu requerimiento y queremos informarte que ya ha sido asignado un especialista para su atención.</p><div class='info-box'>    <div class='info-item'><span class='label'>Ticket:</span> <span class='value'>#22</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Fallas con el Internet</span></div>    <div class='info-item' style='margin-bottom: 0;'><span class='label'>Especialista:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Puedes realizar el seguimiento de tu incidencia en tiempo real y chatear con el técnico asignado a través de nuestra plataforma web.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/22' class='btn button'>Seguir Ticket en Línea</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 12:39:36.376085	2026-03-08 12:39:41.1319	\N	22
24	2	angellomendoza46@gmail.com	Ticket #22 - En proceso	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Te informamos que tu ticket <b>#22</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>En proceso</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Fallas con el Internet</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Atendiendo el problema de internet"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/22' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 12:56:02.940205	2026-03-08 12:56:07.102953	\N	22
25	2	angellomendoza46@gmail.com	Ticket #22 - Requiere Visita	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Visita Técnica Requerida</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Nuestro equipo técnico ha revisado tu requerimiento y ha determinado que <b>es necesaria una visita presencial</b> para resolver la incidencia.</p><div class='info-box' style='border-left: 5px solid #ffc107;'>    <div class='info-item'><span class='label'>Ticket:</span> <span class='value'>#22</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Fallas con el Internet</span></div>    <div class='info-item'><span class='label'>Motivo de Visita:</span> <br><i style='color: #555;'>"No hubo resolución remota "</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Técnico que solicita:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>En breve, nuestro personal administrativo se pondrá en contacto contigo o agendará la cita directamente en tu calendario de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/22' class='btn button'>Revisar Agenda</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 13:00:42.798805	2026-03-08 13:00:46.294729	\N	22
26	2	angellomendoza46@gmail.com	Ticket #22 - Resuelto	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Te informamos que tu ticket <b>#22</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Resuelto</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Fallas con el Internet</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Problema de internet solucionado"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/22' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 13:07:50.491503	2026-03-08 13:07:51.417219	\N	22
27	2	angellomendoza46@gmail.com	Ticket #22 - Cerrado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Te informamos que tu ticket <b>#22</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Cerrado</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Fallas con el Internet</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Cerrando el ticket tras verificacion"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/22' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 13:10:13.914452	2026-03-08 13:10:15.750077	\N	22
28	2	angellomendoza46@gmail.com	Ticket #16 - Técnico Asignado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Asignación de Técnico</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Nuestro equipo ha procesado tu requerimiento y queremos informarte que ya ha sido asignado un especialista para su atención.</p><div class='info-box'>    <div class='info-item'><span class='label'>Ticket:</span> <span class='value'>#16</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Falla del servicio de internet</span></div>    <div class='info-item' style='margin-bottom: 0;'><span class='label'>Especialista:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Puedes realizar el seguimiento de tu incidencia en tiempo real y chatear con el técnico asignado a través de nuestra plataforma web.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/16' class='btn button'>Seguir Ticket en Línea</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 13:18:24.657569	2026-03-08 13:18:28.679293	\N	16
29	2	angellomendoza46@gmail.com	Ticket #16 - En proceso	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Te informamos que tu ticket <b>#16</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>En proceso</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Falla del servicio de internet</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Yo seré su técnico asignado "</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/16' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 13:24:18.084654	2026-03-08 13:24:21.824899	\N	16
30	2	angellomendoza46@gmail.com	Ticket #16 - Resuelto	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Te informamos que tu ticket <b>#16</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Resuelto</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Falla del servicio de internet</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"problema resuelto"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/16' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 13:25:30.76557	2026-03-08 13:25:33.58831	\N	16
31	1	elizabethanahisb@gmail.com	Cita Programada: Visita Técnica para Ticket #21	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Cita Programada Exitosamente</div>            <p>Hola <b>Elizabeth Anahis</b>,</p><p>¡Buenas noticias! Tu visita técnica ha sido programada. Nuestro especialista acudirá a tus instalaciones en el horario acordado.</p><div class='info-box' style='border-left: 5px solid #198754;'>    <div class='info-item'><span class='label'>Fecha de Visita:</span> <span class='value' style='color: #198754;'>2026-03-19</span></div>    <div class='info-item'><span class='label'>Horario:</span> <span class='value'>De 19:20 a 23:20</span></div>    <div class='info-item'><span class='label'>Ticket Asociado:</span> <span class='value'>#21 - Mi cable de la instalacion se ha dañado</span></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Técnico Responsable:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Por favor, asegúrate de que haya alguien disponible para recibir a nuestro personal. Si necesitas reprogramar, contáctanos lo antes posible.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/cliente/tickets/detalle/21' class='btn button'>Ver Mi Agenda</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 16:18:05.890211	2026-03-08 16:18:11.893014	\N	21
32	1	elizabethanahisb@gmail.com	Cita Programada: Visita Técnica para Ticket #21	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Cita Programada Exitosamente</div>            <p>Hola <b>Elizabeth Anahis</b>,</p><p>¡Buenas noticias! Tu visita técnica ha sido programada. Nuestro especialista acudirá a tus instalaciones en el horario acordado.</p><div class='info-box' style='border-left: 5px solid #198754;'>    <div class='info-item'><span class='label'>Fecha de Visita:</span> <span class='value' style='color: #198754;'>2026-03-19</span></div>    <div class='info-item'><span class='label'>Horario:</span> <span class='value'>De 19:18 a 20:18</span></div>    <div class='info-item'><span class='label'>Ticket Asociado:</span> <span class='value'>#21 - Mi cable de la instalacion se ha dañado</span></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Técnico Responsable:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Por favor, asegúrate de que haya alguien disponible para recibir a nuestro personal. Si necesitas reprogramar, contáctanos lo antes posible.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/cliente/tickets/detalle/21' class='btn button'>Ver Mi Agenda</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-08 16:18:46.256957	2026-03-08 16:18:49.018772	\N	21
35	3	azambranoy@uteq.edu.ec	Ticket #9 - En proceso	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angel Daniel Zambrano Yong</b>,</p><p>Te informamos que tu ticket <b>#9</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>En proceso</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>INSIDENCIA SOBRE MI VAINA</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"HOLA\n"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/9' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 03:17:59.569559	2026-03-09 03:18:10.566104	\N	9
37	3	azambranoy@uteq.edu.ec	Ticket #7 - En proceso	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angel Daniel Zambrano Yong</b>,</p><p>Te informamos que tu ticket <b>#7</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>En proceso</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>TENGO MI FALLITO DE RED YA SABES</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"hola"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/7' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 04:52:45.529007	2026-03-09 04:52:54.896418	\N	7
36	3	azambranoy@uteq.edu.ec	Ticket #6 - En proceso	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angel Daniel Zambrano Yong</b>,</p><p>Te informamos que tu ticket <b>#6</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>En proceso</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>TENGO MI FALLITO DE RED YA SABES</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Sin observaciones adicionales"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/6' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 03:27:42.323786	2026-03-09 03:27:48.786993	\N	6
39	3	azambranoy@uteq.edu.ec	Ticket #11 - En proceso	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angel Daniel Zambrano Yong</b>,</p><p>Te informamos que tu ticket <b>#11</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>En proceso</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>PRUEBA PRUEBA PRUEBA PRUEBA PRUEBA PRUEBA PRUEBA PRUEBA</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"holi"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/11' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 05:01:01.477432	2026-03-09 05:01:11.897935	\N	11
43	3	azambranoy@uteq.edu.ec	Ticket #9 - Resuelto	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angel Daniel Zambrano Yong</b>,</p><p>Te informamos que tu ticket <b>#9</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Resuelto</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>INSIDENCIA SOBRE MI VAINA</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Informe técnico registrado. Ticket resuelto."</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/9' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 10:24:03.193135	2026-03-09 10:24:07.673198	\N	9
44	3	azambranoy@uteq.edu.ec	Ticket #11 - Abierto	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angel Daniel Zambrano Yong</b>,</p><p>Te informamos que tu ticket <b>#11</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Abierto</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>PRUEBA PRUEBA PRUEBA PRUEBA PRUEBA PRUEBA PRUEBA PRUEBA</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Técnico no pudo resolver: Falta de repuestos"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/11' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 10:30:01.868555	2026-03-09 10:30:05.481055	\N	11
45	3	azambranoy@uteq.edu.ec	Ticket #11 - En proceso	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angel Daniel Zambrano Yong</b>,</p><p>Te informamos que tu ticket <b>#11</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>En proceso</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>PRUEBA PRUEBA PRUEBA PRUEBA PRUEBA PRUEBA PRUEBA PRUEBA</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Sin observaciones adicionales"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/11' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 10:50:17.52635	2026-03-09 10:50:21.174709	\N	11
46	3	azambranoy@uteq.edu.ec	Ticket #11 - Cerrado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angel Daniel Zambrano Yong</b>,</p><p>Te informamos que tu ticket <b>#11</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Cerrado</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>PRUEBA PRUEBA PRUEBA PRUEBA PRUEBA PRUEBA PRUEBA PRUEBA</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Sin observaciones adicionales"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/11' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 10:50:33.350092	2026-03-09 10:50:38.397664	\N	11
47	3	azambranoy@uteq.edu.ec	Ticket #7 - Abierto	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angel Daniel Zambrano Yong</b>,</p><p>Te informamos que tu ticket <b>#7</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Abierto</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>TENGO MI FALLITO DE RED YA SABES</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Técnico no pudo resolver: Requiere especialista externo"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/7' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 11:13:15.61753	2026-03-09 11:13:19.219386	\N	7
48	3	azambranoy@uteq.edu.ec	Ticket #7 - En proceso	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angel Daniel Zambrano Yong</b>,</p><p>Te informamos que tu ticket <b>#7</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>En proceso</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>TENGO MI FALLITO DE RED YA SABES</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Sin observaciones adicionales"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/7' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 11:13:23.764459	2026-03-09 11:13:26.174896	\N	7
49	3	azambranoy@uteq.edu.ec	Ticket #7 - Cerrado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angel Daniel Zambrano Yong</b>,</p><p>Te informamos que tu ticket <b>#7</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Cerrado</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>TENGO MI FALLITO DE RED YA SABES</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Sin observaciones adicionales"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/7' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 11:13:31.48562	2026-03-09 11:13:38.108572	\N	7
50	3	azambranoy@uteq.edu.ec	Ticket #9 - Cerrado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angel Daniel Zambrano Yong</b>,</p><p>Te informamos que tu ticket <b>#9</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Cerrado</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>INSIDENCIA SOBRE MI VAINA</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Sin observaciones adicionales"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/9' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 11:15:41.61363	2026-03-09 11:15:45.353791	\N	9
51	3	azambranoy@uteq.edu.ec	Ticket #6 - Resuelto	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angel Daniel Zambrano Yong</b>,</p><p>Te informamos que tu ticket <b>#6</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Resuelto</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>TENGO MI FALLITO DE RED YA SABES</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Informe técnico registrado. Ticket resuelto."</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/6' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 11:16:03.405053	2026-03-09 11:16:07.81736	\N	6
52	3	azambranoy@uteq.edu.ec	Ticket #6 - Cerrado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angel Daniel Zambrano Yong</b>,</p><p>Te informamos que tu ticket <b>#6</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Cerrado</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>TENGO MI FALLITO DE RED YA SABES</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"listo"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/6' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 11:18:16.439788	2026-03-09 11:18:20.324792	\N	6
53	2	angellomendoza46@gmail.com	Ticket #26 - Técnico Asignado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Asignación de Técnico</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Nuestro equipo ha procesado tu requerimiento y queremos informarte que ya ha sido asignado un especialista para su atención.</p><div class='info-box'>    <div class='info-item'><span class='label'>Ticket:</span> <span class='value'>#26</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>no funciona mi pc  o es el internet barato que contrate</span></div>    <div class='info-item' style='margin-bottom: 0;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Puedes realizar el seguimiento de tu incidencia en tiempo real y chatear con el técnico asignado a través de nuestra plataforma web.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/26' class='btn button'>Seguir Ticket en Línea</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 11:28:35.817648	2026-03-09 11:28:45.341349	\N	26
54	2	angellomendoza46@gmail.com	Ticket #26 - En proceso	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Te informamos que tu ticket <b>#26</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>En proceso</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>no funciona mi pc  o es el internet barato que contrate</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"en camino al ticket"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/26' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 11:29:55.02226	2026-03-09 11:29:58.325148	\N	26
55	2	angellomendoza46@gmail.com	Ticket #26 - Resuelto	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Te informamos que tu ticket <b>#26</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Resuelto</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>no funciona mi pc  o es el internet barato que contrate</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Informe técnico registrado. Ticket resuelto."</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/26' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 11:35:58.097578	2026-03-09 11:36:01.831065	\N	26
56	2	angellomendoza46@gmail.com	Ticket #26 - Cerrado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Te informamos que tu ticket <b>#26</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Cerrado</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>no funciona mi pc  o es el internet barato que contrate</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"pngame 10"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/26' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 11:36:21.741598	2026-03-09 11:36:27.363302	\N	26
57	2	angellomendoza46@gmail.com	Ticket #27 - Técnico Asignado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Asignación de Técnico</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Nuestro equipo ha procesado tu requerimiento y queremos informarte que ya ha sido asignado un especialista para su atención.</p><div class='info-box'>    <div class='info-item'><span class='label'>Ticket:</span> <span class='value'>#27</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa</span></div>    <div class='info-item' style='margin-bottom: 0;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Puedes realizar el seguimiento de tu incidencia en tiempo real y chatear con el técnico asignado a través de nuestra plataforma web.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/27' class='btn button'>Seguir Ticket en Línea</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 11:53:27.616539	2026-03-09 11:53:32.336082	\N	27
58	2	angellomendoza46@gmail.com	Ticket #27 - En proceso	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Te informamos que tu ticket <b>#27</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>En proceso</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Sin observaciones adicionales"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/27' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 11:53:45.678906	2026-03-09 11:53:49.145439	\N	27
59	2	angellomendoza46@gmail.com	Ticket #27 - Abierto	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Te informamos que tu ticket <b>#27</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Abierto</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Técnico no pudo resolver: Falta de repuestos"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/27' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 11:54:50.013898	2026-03-09 11:54:56.11324	\N	27
60	2	angellomendoza46@gmail.com	Ticket #27 - En proceso	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Te informamos que tu ticket <b>#27</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>En proceso</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Sin observaciones adicionales"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/27' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 11:56:07.424639	2026-03-09 11:56:13.163113	\N	27
61	2	angellomendoza46@gmail.com	Ticket #27 - Cerrado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Te informamos que tu ticket <b>#27</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Cerrado</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Sin observaciones adicionales"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>tecnico01</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/27' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 11:56:27.536179	2026-03-09 11:56:29.92832	\N	27
62	1	elizabethanahisb@gmail.com	Ticket #17 - Resuelto	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Elizabeth Anahis Burgos Chilan</b>,</p><p>Te informamos que tu ticket <b>#17</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Resuelto</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Falla del servicio de internet</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Informe técnico registrado. Ticket resuelto."</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/17' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-09 16:24:34.68751	2026-03-09 16:24:40.149338	\N	17
68	2	angellomendoza46@gmail.com	Ticket #30 - Abierto	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Te informamos que tu ticket <b>#30</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Abierto</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Internet muy lento y con cortes frecuentes</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Técnico no pudo resolver: Problema mayor identificado"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/30' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	127	2026-03-10 11:50:11.666651	2026-03-10 12:32:11.640361	\N	30
63	2	angellomendoza46@gmail.com	Ticket #28 - Técnico Asignado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Asignación de Técnico</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Nuestro equipo ha procesado tu requerimiento y queremos informarte que ya ha sido asignado un especialista para su atención.</p><div class='info-box'>    <div class='info-item'><span class='label'>Ticket:</span> <span class='value'>#28</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Fallas con el router - No hay internet </span></div>    <div class='info-item' style='margin-bottom: 0;'><span class='label'>Especialista:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Puedes realizar el seguimiento de tu incidencia en tiempo real y chatear con el técnico asignado a través de nuestra plataforma web.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/28' class='btn button'>Seguir Ticket en Línea</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-10 06:17:38.39932	2026-03-10 06:17:42.213455	\N	28
69	2	angellomendoza46@gmail.com	Ticket #30 - Cerrado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Te informamos que tu ticket <b>#30</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>Cerrado</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Internet muy lento y con cortes frecuentes</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Sin observaciones adicionales"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/30' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	125	2026-03-10 11:50:25.219693	2026-03-10 12:32:13.994833	\N	30
64	2	angellomendoza46@gmail.com	Ticket #28 - En proceso	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Te informamos que tu ticket <b>#28</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>En proceso</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Fallas con el router - No hay internet </span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"Yo seré su técnico asignado "</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/28' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	0	2026-03-10 06:18:09.323037	2026-03-10 06:18:14.247981	\N	28
65	2	angellomendoza46@gmail.com	Ticket #29 - Técnico Asignado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Asignación de Técnico</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Nuestro equipo ha procesado tu requerimiento y queremos informarte que ya ha sido asignado un especialista para su atención.</p><div class='info-box'>    <div class='info-item'><span class='label'>Ticket:</span> <span class='value'>#29</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Internet muy lento y con cortes frecuentes</span></div>    <div class='info-item' style='margin-bottom: 0;'><span class='label'>Especialista:</span> <span class='value'>Angel Daniel Zambrano Yong</span></div></div><p>Puedes realizar el seguimiento de tu incidencia en tiempo real y chatear con el técnico asignado a través de nuestra plataforma web.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/29' class='btn button'>Seguir Ticket en Línea</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	214	2026-03-10 11:42:57.267333	2026-03-10 12:32:16.145764	\N	29
66	2	angellomendoza46@gmail.com	Ticket #30 - Técnico Asignado	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Asignación de Técnico</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Nuestro equipo ha procesado tu requerimiento y queremos informarte que ya ha sido asignado un especialista para su atención.</p><div class='info-box'>    <div class='info-item'><span class='label'>Ticket:</span> <span class='value'>#30</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Internet muy lento y con cortes frecuentes</span></div>    <div class='info-item' style='margin-bottom: 0;'><span class='label'>Especialista:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Puedes realizar el seguimiento de tu incidencia en tiempo real y chatear con el técnico asignado a través de nuestra plataforma web.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/30' class='btn button'>Seguir Ticket en Línea</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	177	2026-03-10 11:46:04.87764	2026-03-10 12:32:18.295794	\N	30
67	2	angellomendoza46@gmail.com	Ticket #30 - En proceso	<!DOCTYPE html><html><head>    <style>        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }        .content { padding: 40px; color: #444444; line-height: 1.7; }        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }        .button:hover { background-color: #0b5ed7; }        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }        .info-item { margin-bottom: 10px; font-size: 15px; }        .label { font-weight: 600; color: #6c757d; }        .value { color: #1a1a1a; font-weight: 600; }    </style></head><body>    <div class='container'>        <div class='header'>            <h1>SGIM</h1>            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>        </div>        <div class='content'>            <div class='greeting'>Actualización de Estado</div>            <p>Hola <b>Angello Agustin Mendoza Bermello</b>,</p><p>Te informamos que tu ticket <b>#30</b> ha tenido una actualización importante en su estado:</p><div class='info-box'>    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>En proceso</span></div>    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>Internet muy lento y con cortes frecuentes</span></div>    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>"nbnmnm"</i></div>    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>Angel Agosti Mendoza Bermello</span></div></div><p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>            <div style='text-align: center; margin-top: 20px;'><a href='http://localhost:4200/home/user/ticket/30' class='btn button'>Ver Detalles del Ticket</a></div>        </div>        <div class='footer'>            <strong>SGIM - Soluciones Tecnológicas</strong><br>            Este mensaje fue generado automáticamente por nuestro sistema.<br>            © 2026 Todos los derechos reservados.        </div>    </div></body></html>	t	153	2026-03-10 11:48:01.910012	2026-03-10 12:32:20.243202	\N	30
\.


--
-- TOC entry 5236 (class 0 OID 23768)
-- Dependencies: 276
-- Data for Name: notificacion_web; Type: TABLE DATA; Schema: notificaciones; Owner: postgres
--

COPY notificaciones.notificacion_web (id_notificacion, id_usuario_destino, id_empresa, titulo, mensaje, ruta_redireccion, id_ticket, leida, fecha_creacion, fecha_lectura) FROM stdin;
3	10	1	Nuevo Ticket Asignado: #18	Se le ha asignado el ticket: HOLA PAPUCITO LINDO	/tecnico/tickets/detalle/18	18	t	2026-03-08 02:52:57.331354	2026-03-08 03:21:11.660343
4	2	1	Su ticket #18 ha sido asignado	Su ticket ahora está siendo atendido por aza	/cliente/tickets/detalle/18	18	t	2026-03-08 02:52:57.336625	2026-03-08 03:21:33.913187
7	10	1	Nuevo Ticket Asignado: #19	Se le ha asignado el ticket: QUE TA CHENDO AYUDEME UWU	/home/user/ticket/19	19	t	2026-03-08 03:29:32.192981	2026-03-08 03:29:38.024192
9	2	1	Actualización del Ticket #19	El estado de su ticket ha cambiado a: En proceso	/home/user/ticket/19	19	t	2026-03-08 03:30:09.344008	2026-03-08 03:31:54.34484
8	2	1	Su ticket #19 ha sido asignado	Su ticket ahora está siendo atendido por aza	/home/user/ticket/19	19	t	2026-03-08 03:29:32.196574	2026-03-08 03:31:54.34484
6	2	1	Actualización del Ticket #18	El estado de su ticket ha cambiado a: Resuelto	/home/user/ticket/18	18	t	2026-03-08 03:27:26.871143	2026-03-08 03:31:54.34484
5	2	1	Actualización del Ticket #18	El estado de su ticket ha cambiado a: En proceso	/home/user/ticket/18	18	t	2026-03-08 03:22:26.053168	2026-03-08 03:31:54.34484
11	21	1	Nuevo Ticket Asignado: #20	Se le ha asignado el ticket: Papu sale humo de mi router	/home/user/ticket/20	20	t	2026-03-08 04:03:30.301675	2026-03-08 04:03:38.72609
42	21	1	Nueva Visita Programada: Ticket #21	Se le ha programado una visita para el 2026-03-19 a las 19:18	/home/agenda	21	t	2026-03-08 16:18:46.254628	2026-03-09 02:04:44.017294
14	2	1	Actualización del Ticket #20	El estado de su ticket ha cambiado a: Requiere Visita	/home/user/ticket/20	20	t	2026-03-08 04:06:11.165004	2026-03-08 04:27:48.715932
13	2	1	Actualización del Ticket #20	El estado de su ticket ha cambiado a: En proceso	/home/user/ticket/20	20	t	2026-03-08 04:04:13.277784	2026-03-08 04:27:48.715932
12	2	1	Su ticket #20 ha sido asignado	Su ticket ahora está siendo atendido por Angel Agosti Mendoza Bermello	/home/user/ticket/20	20	t	2026-03-08 04:03:30.306813	2026-03-08 04:27:48.715932
10	2	1	Actualización del Ticket #19	El estado de su ticket ha cambiado a: Requiere Visita	/home/user/ticket/19	19	t	2026-03-08 03:32:51.234893	2026-03-08 04:27:48.715932
41	21	1	Nueva Visita Programada: Ticket #21	Se le ha programado una visita para el 2026-03-19 a las 19:20	/home/agenda	21	t	2026-03-08 16:18:05.884608	2026-03-09 02:04:44.017327
17	21	1	Nuevo Ticket Asignado: #21	Se le ha asignado el ticket: Mi cable de la instalacion se ha dañado	/home/user/ticket/21	21	t	2026-03-08 04:30:38.95917	2026-03-08 04:31:08.22992
20	2	1	Actualización del Ticket #21	El estado de su ticket ha cambiado a: Requiere Visita	/home/user/ticket/21	21	t	2026-03-08 04:31:38.078689	2026-03-08 04:40:27.841722
21	21	1	Nueva Visita Programada: Ticket #21	Se le ha programado una visita para el 2026-03-13 a las 09:30	/home/agenda	21	t	2026-03-08 04:33:24.908297	2026-03-08 05:05:51.067106
15	21	1	Nueva Visita Programada: Ticket #20	Se le ha programado una visita para el 2026-03-10 a las 12:00	/home/agenda	20	t	2026-03-08 04:19:45.703277	2026-03-08 05:05:51.067125
22	4	2	Actualización del Ticket #2	El estado de su ticket ha cambiado a: Requiere Visita	/home/user/ticket/2	2	t	2026-03-08 05:23:47.297756	2026-03-08 05:24:00.424237
24	8	3	Actualización del Ticket #5	El estado de su ticket ha cambiado a: Cerrado	/home/user/ticket/5	5	f	2026-03-08 05:30:09.346531	\N
25	8	3	Actualización del Ticket #8	El estado de su ticket ha cambiado a: Cerrado	/home/user/ticket/8	8	f	2026-03-08 05:30:25.045531	\N
26	8	3	Actualización del Ticket #4	El estado de su ticket ha cambiado a: Resuelto	/home/user/ticket/4	4	f	2026-03-08 05:30:51.924748	\N
27	8	3	Actualización del Ticket #4	El estado de su ticket ha cambiado a: Cerrado	/home/user/ticket/4	4	f	2026-03-08 05:30:54.970465	\N
29	4	2	Actualización del Ticket #15	El estado de su ticket ha cambiado a: Cerrado	/home/user/ticket/15	15	t	2026-03-08 05:31:20.151171	2026-03-08 12:06:03.384576
28	4	2	Actualización del Ticket #13	El estado de su ticket ha cambiado a: Cerrado	/home/user/ticket/13	13	t	2026-03-08 05:31:13.346928	2026-03-08 12:06:03.384593
23	4	2	Actualización del Ticket #2	El estado de su ticket ha cambiado a: Cerrado	/home/user/ticket/2	2	t	2026-03-08 05:25:19.951574	2026-03-08 12:06:03.384595
30	2	1	Actualización del Ticket #17	El estado de su ticket ha cambiado a: En proceso	/home/user/ticket/17	17	t	2026-03-08 10:05:10.796986	2026-03-08 12:09:08.355093
19	2	1	Actualización del Ticket #21	El estado de su ticket ha cambiado a: En proceso	/home/user/ticket/21	21	t	2026-03-08 04:31:19.478589	2026-03-08 12:09:08.355108
18	2	1	Su ticket #21 ha sido asignado	Su ticket ahora está siendo atendido por Angel Agosti Mendoza Bermello	/home/user/ticket/21	21	t	2026-03-08 04:30:38.96418	2026-03-08 12:09:08.355111
16	2	1	Actualización del Ticket #20	El estado de su ticket ha cambiado a: Cerrado	/home/user/ticket/20	20	t	2026-03-08 04:30:21.26655	2026-03-08 12:09:08.355113
31	21	1	Nuevo Ticket Asignado: #22	Se le ha asignado el ticket: Fallas con el Internet	/home/user/ticket/22	22	t	2026-03-08 12:39:36.36863	2026-03-08 12:55:56.857024
34	4	2	Actualización del Ticket #22	El estado de su ticket ha cambiado a: Requiere Visita	/home/user/ticket/22	22	t	2026-03-08 13:00:42.794684	2026-03-08 13:00:50.372847
36	4	2	Actualización del Ticket #22	El estado de su ticket ha cambiado a: Cerrado	/home/user/ticket/22	22	t	2026-03-08 13:10:13.907681	2026-03-08 13:16:15.24677
35	4	2	Actualización del Ticket #22	El estado de su ticket ha cambiado a: Resuelto	/home/user/ticket/22	22	t	2026-03-08 13:07:50.489516	2026-03-08 13:16:16.937503
33	4	2	Actualización del Ticket #22	El estado de su ticket ha cambiado a: En proceso	/home/user/ticket/22	22	t	2026-03-08 12:56:02.934876	2026-03-08 13:16:16.93753
32	4	2	Su ticket #22 ha sido asignado	Su ticket ahora está siendo atendido por Angel Agosti Mendoza Bermello	/home/user/ticket/22	22	t	2026-03-08 12:39:36.371724	2026-03-08 13:16:16.937536
38	4	2	Su ticket #16 ha sido asignado	Su ticket ahora está siendo atendido por Angel Agosti Mendoza Bermello	/home/user/ticket/16	16	t	2026-03-08 13:18:24.6505	2026-03-08 13:19:24.286382
37	21	1	Nuevo Ticket Asignado: #16	Se le ha asignado el ticket: Falla del servicio de internet	/home/user/ticket/16	16	t	2026-03-08 13:18:24.642699	2026-03-08 13:23:50.925309
39	4	2	Actualización del Ticket #16	El estado de su ticket ha cambiado a: En proceso	/home/user/ticket/16	16	t	2026-03-08 13:24:18.078205	2026-03-08 13:25:04.119302
40	4	2	Actualización del Ticket #16	El estado de su ticket ha cambiado a: Resuelto	/home/user/ticket/16	16	t	2026-03-08 13:25:30.762861	2026-03-08 13:25:35.948208
47	8	3	Actualización del Ticket #9	El estado de su ticket ha cambiado a: En proceso	/home/user/ticket/9	9	f	2026-03-09 03:17:59.55709	\N
48	8	3	Actualización del Ticket #6	El estado de su ticket ha cambiado a: En proceso	/home/user/ticket/6	6	f	2026-03-09 03:27:42.317079	\N
49	8	3	Actualización del Ticket #7	El estado de su ticket ha cambiado a: En proceso	/home/user/ticket/7	7	f	2026-03-09 04:52:45.522286	\N
51	8	3	Actualización del Ticket #11	El estado de su ticket ha cambiado a: En proceso	/home/user/ticket/11	11	f	2026-03-09 05:01:01.464422	\N
55	8	3	Actualización del Ticket #9	El estado de su ticket ha cambiado a: Resuelto	/home/user/ticket/9	9	f	2026-03-09 10:24:03.174272	\N
56	8	3	Actualización del Ticket #11	El estado de su ticket ha cambiado a: Abierto	/home/user/ticket/11	11	f	2026-03-09 10:30:01.859952	\N
57	8	3	Actualización del Ticket #11	El estado de su ticket ha cambiado a: En proceso	/home/user/ticket/11	11	f	2026-03-09 10:50:17.514847	\N
58	8	3	Actualización del Ticket #11	El estado de su ticket ha cambiado a: Cerrado	/home/user/ticket/11	11	f	2026-03-09 10:50:33.34362	\N
59	8	3	Actualización del Ticket #7	El estado de su ticket ha cambiado a: Abierto	/home/user/ticket/7	7	f	2026-03-09 11:13:15.601663	\N
60	8	3	Actualización del Ticket #7	El estado de su ticket ha cambiado a: En proceso	/home/user/ticket/7	7	f	2026-03-09 11:13:23.760691	\N
61	8	3	Actualización del Ticket #7	El estado de su ticket ha cambiado a: Cerrado	/home/user/ticket/7	7	f	2026-03-09 11:13:31.480573	\N
62	8	3	Actualización del Ticket #9	El estado de su ticket ha cambiado a: Cerrado	/home/user/ticket/9	9	f	2026-03-09 11:15:41.608941	\N
63	8	3	Actualización del Ticket #6	El estado de su ticket ha cambiado a: Resuelto	/home/user/ticket/6	6	f	2026-03-09 11:16:03.399784	\N
64	8	3	Actualización del Ticket #6	El estado de su ticket ha cambiado a: Cerrado	/home/user/ticket/6	6	f	2026-03-09 11:18:16.436136	\N
66	4	2	Su ticket #26 ha sido asignado	Su ticket ahora está siendo atendido por tecnico01	/home/user/ticket/26	26	t	2026-03-09 11:28:35.811271	2026-03-09 11:28:49.585277
65	7	1	Nuevo Ticket Asignado: #26	Se le ha asignado el ticket: no funciona mi pc  o es el internet barato que contrate	/home/user/ticket/26	26	t	2026-03-09 11:28:35.801081	2026-03-09 11:29:18.626968
70	7	1	Nuevo Ticket Asignado: #27	Se le ha asignado el ticket: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa	/home/user/ticket/27	27	t	2026-03-09 11:53:27.600168	2026-03-09 11:53:37.039452
75	4	2	Actualización del Ticket #27	El estado de su ticket ha cambiado a: Cerrado	/home/user/ticket/27	27	t	2026-03-09 11:56:27.531229	2026-03-09 16:15:28.044564
74	4	2	Actualización del Ticket #27	El estado de su ticket ha cambiado a: En proceso	/home/user/ticket/27	27	t	2026-03-09 11:56:07.419957	2026-03-09 16:15:28.044583
73	4	2	Actualización del Ticket #27	El estado de su ticket ha cambiado a: Abierto	/home/user/ticket/27	27	t	2026-03-09 11:54:50.007055	2026-03-09 16:15:28.044587
72	4	2	Actualización del Ticket #27	El estado de su ticket ha cambiado a: En proceso	/home/user/ticket/27	27	t	2026-03-09 11:53:45.675046	2026-03-09 16:15:28.044592
71	4	2	Su ticket #27 ha sido asignado	Su ticket ahora está siendo atendido por tecnico01	/home/user/ticket/27	27	t	2026-03-09 11:53:27.611357	2026-03-09 16:15:28.044595
69	4	2	Actualización del Ticket #26	El estado de su ticket ha cambiado a: Cerrado	/home/user/ticket/26	26	t	2026-03-09 11:36:21.737282	2026-03-09 16:15:28.044598
68	4	2	Actualización del Ticket #26	El estado de su ticket ha cambiado a: Resuelto	/home/user/ticket/26	26	t	2026-03-09 11:35:58.089908	2026-03-09 16:15:28.0446
67	4	2	Actualización del Ticket #26	El estado de su ticket ha cambiado a: En proceso	/home/user/ticket/26	26	t	2026-03-09 11:29:55.016659	2026-03-09 16:15:28.044602
76	2	1	Actualización del Ticket #17	El estado de su ticket ha cambiado a: Resuelto	/home/user/ticket/17	17	t	2026-03-09 16:24:34.683476	2026-03-09 16:25:36.548059
77	21	1	Nuevo Ticket Asignado: #28	Se le ha asignado el ticket: Fallas con el router - No hay internet 	/home/user/ticket/28	28	t	2026-03-10 06:17:38.390782	2026-03-10 06:17:44.399422
79	4	2	Actualización del Ticket #28	El estado de su ticket ha cambiado a: En proceso	/home/user/ticket/28	28	t	2026-03-10 06:18:09.320995	2026-03-10 06:18:17.622307
78	4	2	Su ticket #28 ha sido asignado	Su ticket ahora está siendo atendido por Angel Agosti Mendoza Bermello	/home/user/ticket/28	28	t	2026-03-10 06:17:38.394043	2026-03-10 06:21:37.754407
80	23	1	Nuevo Ticket Asignado: #29	Se le ha asignado el ticket: Internet muy lento y con cortes frecuentes	/home/user/ticket/29	29	f	2026-03-10 11:42:57.25983	\N
82	21	1	Nuevo Ticket Asignado: #30	Se le ha asignado el ticket: Internet muy lento y con cortes frecuentes	/home/user/ticket/30	30	t	2026-03-10 11:46:04.873197	2026-03-10 11:46:19.906603
83	4	2	Su ticket #30 ha sido asignado	Su ticket ahora está siendo atendido por Angel Agosti Mendoza Bermello	/home/user/ticket/30	30	t	2026-03-10 11:46:04.876064	2026-03-10 11:48:21.120606
86	4	2	Actualización del Ticket #30	El estado de su ticket ha cambiado a: Cerrado	/home/user/ticket/30	30	t	2026-03-10 11:50:25.218334	2026-03-13 11:22:02.2814
85	4	2	Actualización del Ticket #30	El estado de su ticket ha cambiado a: Abierto	/home/user/ticket/30	30	t	2026-03-10 11:50:11.664077	2026-03-13 11:22:02.281417
84	4	2	Actualización del Ticket #30	El estado de su ticket ha cambiado a: En proceso	/home/user/ticket/30	30	t	2026-03-10 11:48:01.908684	2026-03-13 11:22:02.281421
81	4	2	Su ticket #29 ha sido asignado	Su ticket ahora está siendo atendido por Angel Daniel Zambrano Yong	/home/user/ticket/29	29	t	2026-03-10 11:42:57.26296	2026-03-13 11:22:02.281425
\.


--
-- TOC entry 5238 (class 0 OID 23782)
-- Dependencies: 278
-- Data for Name: configuracion_reporte; Type: TABLE DATA; Schema: reportes; Owner: postgres
--

COPY reportes.configuracion_reporte (id_reporte, nombre, descripcion, codigo_unico, modulo, tipo_salida, es_activo, fecha_creacion) FROM stdin;
1	Resumen Operativo de Tickets	Listado general con estados y prioridades.	TICKETS_RESUMEN	SOPORTE	TABLE	t	2026-03-09 00:19:49.11402
2	Cumplimiento de SLA por Técnico	Análisis de tiempos de respuesta y metas.	SLA_TECNICO	ADMIN	DASHBOARD	t	2026-03-09 00:19:49.11402
3	Satisfacción del Cliente (CSAT)	Resumen de valoraciones y tasa de felicidad.	CSAT_ANALISIS	CLIENTES	DASHBOARD	t	2026-03-09 00:19:49.11402
4	Gestión de Tickets	Volumen de incidencias, estados y tiempos.	TICKET_GESTION	SOPORTE	DASHBOARD	t	2026-03-09 00:19:49.11402
\.


--
-- TOC entry 5240 (class 0 OID 23795)
-- Dependencies: 280
-- Data for Name: historial_generacion; Type: TABLE DATA; Schema: reportes; Owner: postgres
--

COPY reportes.historial_generacion (id_generacion, id_reporte, id_usuario, parametros_json, ruta_archivo, taza_exito, mensaje_error, tiempo_ejecucion_ms, fecha_generacion) FROM stdin;
\.


--
-- TOC entry 5245 (class 0 OID 23862)
-- Dependencies: 289
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
13	1	2026-02-26 16:33:07.930072	t	10
14	6	2026-02-26 16:33:12.924993	t	7
15	7	2026-02-26 16:33:16.75218	t	7
16	11	2026-02-26 16:33:18.77501	t	7
17	12	2026-02-27 11:10:48.720388	t	7
18	13	2026-03-02 08:42:02.741025	t	7
19	15	2026-03-02 09:18:29.832199	t	7
20	14	2026-03-02 15:52:58.015058	t	7
21	17	2026-03-07 20:33:24.465813	t	21
32	18	2026-03-08 02:52:57.32027	t	10
33	19	2026-03-08 03:29:32.179685	t	10
34	20	2026-03-08 04:03:30.284551	t	21
35	21	2026-03-08 04:30:38.927071	t	21
36	22	2026-03-08 12:39:36.34766	t	21
37	16	2026-03-08 13:18:24.597933	t	21
40	26	2026-03-09 11:28:35.760425	t	7
45	27	2026-03-09 11:53:27.569891	t	7
47	28	2026-03-10 06:17:38.370693	t	21
48	29	2026-03-10 11:42:57.234911	t	23
49	30	2026-03-10 11:46:04.855338	t	21
\.


--
-- TOC entry 5247 (class 0 OID 23871)
-- Dependencies: 291
-- Data for Name: categoria; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.categoria (id_categoria, descripcion, nombre, id_item) FROM stdin;
1	Seed categoria: INSTALACION	Instalacion	17
2	Seed categoria: FACTURACION	Facturacion	15
3	Seed categoria: CONFIGURACION	Configuracion de equipo	16
4	Seed categoria: INTERNET	Problema de Internet	14
\.


--
-- TOC entry 5249 (class 0 OID 23880)
-- Dependencies: 293
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
18	2	4	hola	t	2026-02-26 14:23:12.562151	\N	6	hola	f	2
19	13	7	Muy buenas tardes, yo sere su tecnico asignado en esta sesiòn, por favor mantengase en disponibilidad 	t	2026-03-02 08:45:08.898975	\N	6	Muy buenas tardes, yo sere su tecnico asignado en esta sesiòn, por favor mantengase en disponibilidad 	f	1
20	13	4	Hola, que tal\nEstarè al pendiente 	t	2026-03-02 08:45:52.128057	\N	6	Hola, que tal\nEstarè al pendiente 	f	2
21	13	7	Perfecto, pruebo con esto.\n1. Inicie su television por administrador\n2. Luego ingrese la contraseña del proveedor\n3. Apague y encienda el dispositivo	t	2026-03-02 08:49:06.855076	\N	6	Perfecto, pruebo con esto.\n1. Inicie su television por administrador\n2. Luego ingrese la contraseña del proveedor\n3. Apague y encienda el dispositivo	f	1
22	13	4	Segui al pie de la letra todo eso y no funciono	t	2026-03-02 08:49:35.860676	\N	6	Segui al pie de la letra todo eso y no funciono	f	2
23	15	7	Hola papu	t	2026-03-02 09:20:24.553549	\N	6	Hola papu	f	1
24	15	4	hola	t	2026-03-02 09:20:34.128651	\N	6	hola	f	2
25	14	7	Hola muy buenas, yo estaré atendiendo su problema 	t	2026-03-04 05:10:53.952043	\N	6	Hola muy buenas, yo estaré atendiendo su problema 	f	1
26	14	4	Mucho gusto	t	2026-03-04 05:11:07.39551	\N	6	Mucho gusto	f	2
27	14	7	Listo, notifiqueme detalladamente cual es su problema 	t	2026-03-04 05:11:26.938054	\N	6	Listo, notifiqueme detalladamente cual es su problema 	f	1
28	14	4	Lo que pasa es que desde ayer en la noche mi internet ha estado fallando, en el router aparece una luz en color amarillo con un tono anaranjado 	t	2026-03-04 05:12:30.874975	\N	6	Lo que pasa es que desde ayer en la noche mi internet ha estado fallando, en el router aparece una luz en color amarillo con un tono anaranjado 	f	2
29	14	7	Listo, entonces siga estos pasos\n1. Mantenga presionado el botón de inicio/apagado por 3 segundos\n2. Suelte el botón y espere por 1 minuto \n3. Vuelva a encender el router 	t	2026-03-04 05:13:37.340851	\N	6	Listo, entonces siga estos pasos\n1. Mantenga presionado el botón de inicio/apagado por 3 segundos\n2. Suelte el botón y espere por 1 minuto \n3. Vuelva a encender el router 	f	1
30	14	4	Perfecto, ya me sale conectado a internet 	t	2026-03-04 05:14:07.638871	\N	6	Perfecto, ya me sale conectado a internet 	f	2
31	18	10	hola papucito	t	2026-03-08 03:22:34.4016	\N	6	hola papucito	f	1
60	9	7	a	t	2026-03-09 10:23:35.401738	\N	6	a	f	1
61	11	7	pila papu	t	2026-03-09 10:26:21.06677	\N	6	pila papu	f	1
62	11	7	simon simon	t	2026-03-09 10:27:09.054726	\N	6	simon simon	f	1
63	7	7	hola	t	2026-03-09 11:01:26.526845	\N	6	hola	f	1
64	7	7	pepe activa la wuea	t	2026-03-09 11:11:18.742686	\N	6	pepe activa la wuea	f	1
65	26	4	yaf resuelve	t	2026-03-09 11:28:55.4065	\N	5	yaf resuelve	f	2
66	26	4	hagale	t	2026-03-09 11:28:58.516694	\N	5	hagale	f	2
67	26	4	mueva	t	2026-03-09 11:29:02.492495	\N	5	mueva	f	2
68	26	7	ya voy nmms	t	2026-03-09 11:29:27.161237	\N	5	ya voy nmms	f	1
69	26	7	pilas ya termine	t	2026-03-09 11:35:14.960033	\N	6	pilas ya termine	f	1
70	28	21	Hola muy buenas, podría explicarme detalladamente su problema?	t	2026-03-10 06:18:50.685972	\N	6	Hola muy buenas, podría explicarme detalladamente su problema?	f	1
71	28	4	Mucho gusto	t	2026-03-10 06:23:33.166019	\N	6	Mucho gusto	f	2
72	28	21	Si...	t	2026-03-10 06:23:52.088711	\N	6	Si...	f	1
73	28	4	Si?	t	2026-03-10 07:27:59.676792	\N	6	Si?	f	2
74	28	21	SIp	t	2026-03-10 07:32:24.818732	\N	6	SIp	f	1
75	30	4	hola	t	2026-03-10 11:48:27.742651	\N	6	hola	f	2
\.


--
-- TOC entry 5251 (class 0 OID 23895)
-- Dependencies: 295
-- Data for Name: documento_ticket; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.documento_ticket (id_documento, id_ticket, id_tipo_documento_item, id_usuario_subio, nombre_archivo, ruta_archivo, descripcion, fecha_subida, id_estado_item) FROM stdin;
\.


--
-- TOC entry 5253 (class 0 OID 23909)
-- Dependencies: 297
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
26	11	azambranoy	2026-02-26 07:42:24.380721	Ticket creado por el cliente	\N	4	8	4
27	1	adminmaster	2026-02-26 16:33:07.980898	Ticket asignado a aza	4	5	6	5
28	6	adminmaster	2026-02-26 16:33:12.928415	Ticket asignado a tecnico01	4	5	6	5
29	7	adminmaster	2026-02-26 16:33:16.754515	Ticket asignado a tecnico01	4	5	6	5
30	11	adminmaster	2026-02-26 16:33:18.777587	Ticket asignado a tecnico01	4	5	6	5
31	12	amendozab	2026-02-27 10:49:04.334825	Ticket creado por el cliente	\N	4	4	4
32	12	adminmaster	2026-02-27 11:10:48.722894	Ticket asignado a tecnico01	4	5	6	5
33	13	amendozab	2026-03-02 08:28:23.963641	Ticket creado por el cliente	\N	4	4	4
34	14	amendozab	2026-03-02 08:40:50.604548	Ticket creado por el cliente	\N	4	4	4
35	13	adminmaster	2026-03-02 08:42:02.749615	Ticket asignado a tecnico01	4	5	6	5
36	13	tecnico01	2026-03-02 08:44:32.989404	Buenas tardes	5	6	7	6
37	13	tecnico01	2026-03-02 08:49:51.456938	Sin solucion remota	6	45	7	45
38	15	amendozab	2026-03-02 09:17:36.430123	Ticket creado por el cliente	\N	4	4	4
39	15	adminmaster	2026-03-02 09:18:29.834865	Ticket asignado a tecnico01	4	5	6	5
40	15	tecnico01	2026-03-02 09:19:22.144914	En proceso	5	6	7	6
41	15	tecnico01	2026-03-02 09:20:49.303969	Sin solucion remota	6	45	7	45
42	12	tecnico01	2026-03-02 15:46:22.842047	hola	5	6	7	6
43	12	tecnico01	2026-03-02 15:46:31.038298	resuelto	6	7	7	7
44	14	adminmaster	2026-03-02 15:52:58.020298	Ticket asignado a tecnico01	4	5	6	5
45	12	amendozab	2026-03-02 19:49:02.721738	Cliente calificó el servicio con 5 estrellas. 	7	8	4	8
46	14	tecnico01	2026-03-04 05:10:30.053613	Inicio de la incidencia	5	6	7	6
47	14	tecnico01	2026-03-04 05:14:37.82602	Cliente reporta una solución absoluta a su problema  	6	7	7	7
48	14	tecnico01	2026-03-04 05:14:51.949306	Cliente satisfecho 	7	8	7	8
49	16	amendozab	2026-03-07 20:29:59.035574	Ticket creado por el cliente	\N	4	4	4
50	17	eburgosc	2026-03-07 20:32:40.046378	Ticket creado por el cliente	\N	4	2	4
51	17	adminmaster	2026-03-07 20:33:24.470271	Ticket asignado a amendozab1	4	5	6	5
52	18	eburgosc	2026-03-08 02:36:56.13912	Ticket creado por el cliente	\N	4	2	4
62	18	adminmaster	2026-03-08 02:52:57.324092	Ticket asignado a aza	4	5	6	5
63	18	aza	2026-03-08 03:22:26.039506	En revision	5	6	10	6
64	18	aza	2026-03-08 03:27:26.858553	El cliente me confirmo que ya esta todo funcionando al 100%	6	7	10	7
65	19	eburgosc	2026-03-08 03:28:57.923144	Ticket creado por el cliente	\N	4	2	4
66	19	adminmaster	2026-03-08 03:29:32.186684	Ticket asignado a aza	4	5	6	5
67	19	aza	2026-03-08 03:30:09.327403	En revisión, este pendiente.	5	6	10	6
68	19	aza	2026-03-08 03:32:51.228857	No hubo solución remota.\n	6	45	10	45
69	20	eburgosc	2026-03-08 04:03:00.323702	Ticket creado por el cliente	\N	4	2	4
70	20	adminmaster	2026-03-08 04:03:30.293106	Ticket asignado a amendozab1	4	5	6	5
71	20	amendozab1	2026-03-08 04:04:13.269751	En revisión	5	6	21	6
72	20	amendozab1	2026-03-08 04:06:11.157439	No se encontro una solucion remota.	6	45	21	45
73	21	eburgosc	2026-03-08 04:28:55.53192	Ticket creado por el cliente	\N	4	2	4
74	20	amendozab1	2026-03-08 04:30:21.260018	El caso fue resuelto correctamente	45	8	21	8
75	21	adminmaster	2026-03-08 04:30:38.935611	Ticket asignado a amendozab1	4	5	6	5
76	21	amendozab1	2026-03-08 04:31:19.467659	En revisión	5	6	21	6
77	21	amendozab1	2026-03-08 04:31:38.067589	El caso requiere una revision presencial urgente.	6	45	21	45
78	2	tecnico01	2026-03-08 05:23:47.293337	No hubo resolución remota 	6	45	7	45
79	2	tecnico01	2026-03-08 05:25:19.949897	Incidencia resuelta	45	8	7	8
80	5	tecnico01	2026-03-08 05:30:09.343881	Incidencia resuelta	7	8	7	8
81	8	tecnico01	2026-03-08 05:30:25.043206	Incidencia resuelta	45	8	7	8
82	4	tecnico01	2026-03-08 05:30:51.922628	El usuario notificó que se soluciono su problema 	6	7	7	7
83	4	tecnico01	2026-03-08 05:30:54.967758	Incidencia resuelta	7	8	7	8
84	13	tecnico01	2026-03-08 05:31:13.344877	Incidencia resuelta	45	8	7	8
85	15	tecnico01	2026-03-08 05:31:20.148505	Incidencia resuelta	45	8	7	8
86	17	amendozab1	2026-03-08 10:05:10.784347	Usted esta siendo atendido 	5	6	21	6
87	22	amendozab	2026-03-08 12:39:09.549904	Ticket creado por el cliente	\N	4	4	4
88	22	emp_0503658749_22	2026-03-08 12:39:36.35186	Ticket asignado a amendozab1	4	5	22	5
90	22	emp_1203587489_21	2026-03-08 12:56:02.919952	Atendiendo el problema de internet	5	6	21	6
91	22	emp_1203587489_21	2026-03-08 13:00:42.778292	No hubo resolución remota 	6	45	21	45
92	22	emp_1203587489_21	2026-03-08 13:07:50.478254	Problema de internet solucionado	45	7	21	7
93	22	emp_1203587489_21	2026-03-08 13:10:13.891721	Cerrando el ticket tras verificacion	7	8	21	8
94	16	emp_0503658749_22	2026-03-08 13:18:24.606348	Ticket asignado a amendozab1	4	5	22	5
95	16	emp_1203587489_21	2026-03-08 13:24:18.062731	Yo seré su técnico asignado 	5	6	21	6
96	16	emp_1203587489_21	2026-03-08 13:25:30.751671	problema resuelto	6	7	21	7
103	9	tecnico01	2026-03-09 03:17:59.515193	HOLA\n	5	6	7	6
104	6	tecnico01	2026-03-09 03:27:42.283511		5	6	7	6
105	7	tecnico01	2026-03-09 04:52:45.477469	hola	5	6	7	6
108	11	tecnico01	2026-03-09 05:01:01.434559	holi	5	6	7	6
123	9	tecnico01	2026-03-09 10:24:03.148749	Informe técnico registrado. Ticket resuelto.	6	7	7	7
124	11	tecnico01	2026-03-09 10:30:01.835449	Técnico no pudo resolver: Falta de repuestos	6	4	7	4
125	11	tecnico01	2026-03-09 10:50:17.484189		4	6	7	6
126	11	tecnico01	2026-03-09 10:50:33.304359		6	8	7	8
127	7	tecnico01	2026-03-09 11:13:15.581535	Técnico no pudo resolver: Requiere especialista externo	6	4	7	4
128	7	tecnico01	2026-03-09 11:13:23.747906		4	6	7	6
129	7	tecnico01	2026-03-09 11:13:31.465159		6	8	7	8
130	9	tecnico01	2026-03-09 11:15:41.59417		7	8	7	8
131	6	tecnico01	2026-03-09 11:16:03.385964	Informe técnico registrado. Ticket resuelto.	6	7	7	7
132	6	tecnico01	2026-03-09 11:18:16.423535	listo	7	8	7	8
133	26	amendozab	2026-03-09 11:23:27.719836	Ticket creado por el cliente	\N	4	4	4
134	26	emp_0503658749_22	2026-03-09 11:28:35.77062	Ticket asignado a tecnico01	4	5	22	5
135	26	tecnico01	2026-03-09 11:29:55.005222	en camino al ticket	5	6	7	6
136	26	tecnico01	2026-03-09 11:35:58.076857	Informe técnico registrado. Ticket resuelto.	6	7	7	7
137	26	tecnico01	2026-03-09 11:36:21.727736	pngame 10	7	8	7	8
138	27	amendozab	2026-03-09 11:53:11.959955	Ticket creado por el cliente	\N	4	4	4
139	27	emp_0503658749_22	2026-03-09 11:53:27.576983	Ticket asignado a tecnico01	4	5	22	5
140	27	tecnico01	2026-03-09 11:53:45.660988		5	6	7	6
141	27	tecnico01	2026-03-09 11:54:49.984436	Técnico no pudo resolver: Falta de repuestos	6	4	7	4
142	27	tecnico01	2026-03-09 11:56:07.405495		4	6	7	6
143	27	tecnico01	2026-03-09 11:56:27.517871		6	8	7	8
144	17	emp_1203587489_21	2026-03-09 16:24:34.671645	Informe técnico registrado. Ticket resuelto.	6	7	21	7
145	28	amendozab	2026-03-10 06:17:19.852873	Ticket creado por el cliente	\N	4	4	4
146	28	emp_0503658749_22	2026-03-10 06:17:38.372877	Ticket asignado a amendozab1	4	5	22	5
147	28	emp_1203587489_21	2026-03-10 06:18:09.286084	Yo seré su técnico asignado 	5	6	21	6
148	29	amendozab	2026-03-10 11:40:55.930991	Ticket creado por el cliente	\N	4	4	4
149	29	emp_0503658749_22	2026-03-10 11:42:57.239364	Ticket asignado a azambranoy1	4	5	22	5
150	30	amendozab	2026-03-10 11:45:40.655317	Ticket creado por el cliente	\N	4	4	4
151	30	emp_0503658749_22	2026-03-10 11:46:04.858268	Ticket asignado a amendozab1	4	5	22	5
152	30	emp_1203587489_21	2026-03-10 11:48:01.899236	nbnmnm	5	6	21	6
153	30	emp_1203587489_21	2026-03-10 11:50:11.652781	Técnico no pudo resolver: Problema mayor identificado	6	4	21	4
154	30	emp_1203587489_21	2026-03-10 11:50:25.209707		4	8	21	8
\.


--
-- TOC entry 5255 (class 0 OID 23921)
-- Dependencies: 299
-- Data for Name: informe_trabajo_tecnico; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.informe_trabajo_tecnico (id_informe, id_ticket, id_tecnico, resultado, implementos_usados, problemas_encontrados, solucion_aplicada, pruebas_realizadas, motivo_no_resolucion, comentario_tecnico, url_adjunto, tiempo_trabajo_minutos, fecha_registro) FROM stdin;
17	9	7	RESUELTO	Router	Cable dañado	Reemplazo de cable	Reinicio del sistema	\N	sisisi	\N	30	2026-03-09 10:24:03.099141
18	11	7	NO_RESUELTO	Cable HDMI	Configuración incorrecta	Reconfiguración del sistema	Prueba de conexión	Falta de repuestos	no puede papu	\N	30	2026-03-09 10:30:01.808982
19	7	7	NO_RESUELTO	Cable HDMI	Cable dañado	Reemplazo de cable	Reinicio del sistema	Requiere especialista externo	no pude 	\N	30	2026-03-09 11:13:15.526973
20	6	7	RESUELTO	Cable HDMI	Configuración incorrecta	Reconfiguración del sistema	Prueba de conexión	\N		\N	30	2026-03-09 11:16:03.369008
21	26	7	RESUELTO	Patch cord	Configuración incorrecta	Reseteo de router	Reinicio del sistema	\N	se logro lo comoetido	\N	30	2026-03-09 11:35:58.047697
22	27	7	NO_RESUELTO	NO_APLICA	NO_APLICA	NO_APLICA	NO_APLICA	Falta de repuestos	no se	\N	30	2026-03-09 11:54:49.955233
24	17	21	RESUELTO	NO_APLICA	NO_APLICA	NO_APLICA	NO_APLICA	\N		\N	30	2026-03-09 16:24:34.662671
25	30	21	NO_RESUELTO	NO_APLICA	NO_APLICA	NO_APLICA	NO_APLICA	Problema mayor identificado		\N	30	2026-03-10 11:50:11.646624
\.


--
-- TOC entry 5257 (class 0 OID 23934)
-- Dependencies: 301
-- Data for Name: inventario; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.inventario (id_item_inventario, codigo, nombre, descripcion, tipo, stock_actual, stock_minimo, ubicacion, activo, fecha_creacion, id_empresa, id_catalogo_item_estado, id_usuario_registro) FROM stdin;
1	INV-999	NO APLICA	Elemento usado cuando la solución no requiere inventario	servicio	0	0	N/A	t	2026-03-09 03:30:20.933899	1	1	\N
3	INV-102	Router D-Link	Router doméstico	router	12	3	Bodega central	t	2026-03-09 03:30:41.442062	1	1	\N
4	INV-103	Switch 24 puertos	Switch red empresarial	switch	6	2	Bodega equipos	t	2026-03-09 03:30:41.442062	1	1	\N
5	INV-104	Switch 48 puertos	Switch red data center	switch	4	1	Bodega equipos	t	2026-03-09 03:30:41.442062	1	1	\N
7	INV-106	Cable UTP CAT7	Cable red alta velocidad	cable	200	40	Bodega cables	t	2026-03-09 03:30:41.442062	1	1	\N
8	INV-107	Conector RJ11	Conector telefonía	conector	150	40	Bodega cables	t	2026-03-09 03:30:41.442062	1	1	\N
9	INV-108	Conector fibra SC	Conector fibra óptica	conector	120	30	Bodega cables	t	2026-03-09 03:30:41.442062	1	1	\N
10	INV-109	Antena sectorial	Antena distribución señal	repuesto	20	5	Bodega repuestos	t	2026-03-09 03:30:41.442062	1	1	\N
12	INV-111	Tarjeta red gigabit	Tarjeta red ethernet	hardware	10	2	Bodega hardware	t	2026-03-09 03:30:41.442062	1	1	\N
14	INV-113	Patch panel 24 puertos	Panel conexiones rack	hardware	8	2	Bodega hardware	t	2026-03-09 03:30:41.442062	1	1	\N
15	INV-114	Rack de red	Gabinete para equipos	hardware	3	1	Bodega equipos	t	2026-03-09 03:30:41.442062	1	1	\N
16	INV-115	Convertidor fibra media	Conversor fibra a ethernet	hardware	7	2	Bodega hardware	t	2026-03-09 03:30:41.442062	1	1	\N
17	INV-116	Protector eléctrico	Protector contra picos	repuesto	25	5	Bodega repuestos	t	2026-03-09 03:30:41.442062	1	1	\N
18	INV-117	UPS 1000VA	UPS respaldo energía	hardware	6	2	Bodega equipos	t	2026-03-09 03:30:41.442062	1	1	\N
19	INV-118	Router portátil 4G	Router internet móvil	router	5	1	Bodega central	t	2026-03-09 03:30:41.442062	1	1	\N
20	INV-119	Tester cable profesional	Herramienta diagnóstico red	herramienta	3	1	Bodega herramientas	t	2026-03-09 03:30:41.442062	1	1	\N
21	INV-120	Crimpadora RJ45	Herramienta armado cables	herramienta	5	1	Bodega herramientas	t	2026-03-09 03:30:41.442062	1	1	\N
23	INV-002	Router Huawei	Router fibra óptica Huawei	router	10	3	Bodega central	t	2026-03-09 03:30:52.69505	1	1	\N
25	INV-004	Cable UTP CAT6	Cable red ethernet	cable	100	20	Bodega cables	t	2026-03-09 03:30:52.69505	1	1	\N
26	INV-005	Conector RJ45	Conector ethernet	conector	200	50	Bodega cables	t	2026-03-09 03:30:52.69505	1	1	\N
27	INV-006	Switch 8 Puertos	Switch red 8 puertos	switch	12	3	Bodega equipos	t	2026-03-09 03:30:52.69505	1	1	\N
28	INV-007	Tarjeta de red PCI	Tarjeta de red para PC	hardware	8	2	Bodega equipos	t	2026-03-09 03:30:52.69505	1	1	\N
29	INV-008	Fuente router	Fuente de poder router	repuesto	20	5	Bodega repuestos	t	2026-03-09 03:30:52.69505	1	1	\N
30	INV-009	Antena WiFi	Antena externa router	repuesto	18	4	Bodega repuestos	t	2026-03-09 03:30:52.69505	1	1	\N
32	INV-998	SIN_MATERIAL	Caso donde el técnico resuelve el problema sin usar inventario	servicio	0	0	N/A	t	2026-03-09 03:33:42.599081	1	1	\N
24	INV-003	Cable Fibra 10m	Cable fibra óptica 10 metros	cable	39	10	Bodega cables	t	2026-03-09 03:30:52.69505	1	1	\N
13	INV-112	Adaptador WiFi USB	Adaptador wifi portátil	hardware	0	4	Bodega hardware	t	2026-03-09 03:30:41.442062	1	1	\N
6	INV-105	Cable UTP CAT5e	Cable red ethernet	cable	299	50	Bodega cables	t	2026-03-09 03:30:41.442062	1	1	\N
11	INV-110	Antena direccional	Antena largo alcance	repuesto	12	3	Bodega repuestos	t	2026-03-09 03:30:41.442062	1	1	\N
2	INV-101	Router Asus AX3000	Router wifi alto rendimiento	router	9	3	Bodega central	t	2026-03-09 03:30:41.442062	1	1	\N
22	INV-001	Router TPLink	Router inalámbrico TPLink	router	14	5	Bodega central	t	2026-03-09 03:30:52.69505	1	1	\N
31	INV-010	Router Mikrotik	Router empresarial Mikrotik	router	5	2	Bodega central	t	2026-03-09 03:30:52.69505	1	1	\N
\.


--
-- TOC entry 5259 (class 0 OID 23950)
-- Dependencies: 303
-- Data for Name: inventario_usado_ticket; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.inventario_usado_ticket (id_uso, id_ticket, id_item_inventario, cantidad, fecha_registro, id_usuario_tecnico) FROM stdin;
2	1	8	1	2026-03-09 04:15:41.440926	\N
15	9	13	1	2026-03-09 10:24:03.112071	7
16	11	11	2	2026-03-09 10:30:01.816757	7
17	11	6	1	2026-03-09 10:30:01.82489	7
18	7	11	1	2026-03-09 11:13:15.543859	7
19	7	2	1	2026-03-09 11:13:15.561942	7
20	7	22	1	2026-03-09 11:13:15.566598	7
21	6	13	1	2026-03-09 11:16:03.375886	7
22	26	13	1	2026-03-09 11:35:58.059523	7
23	26	24	1	2026-03-09 11:35:58.067777	7
24	27	13	12	2026-03-09 11:54:49.964795	7
25	17	31	1	2026-03-09 16:24:34.664346	21
\.


--
-- TOC entry 5261 (class 0 OID 23959)
-- Dependencies: 305
-- Data for Name: network_probe_result; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.network_probe_result (id_result, id_run, zone_type, zone_id, latency_ms, packet_loss, http_status, score, level) FROM stdin;
1	2	COUNTRY	1	24.031	0	\N	100	GOOD
2	3	COUNTRY	1	24.199	0	\N	100	GOOD
3	4	COUNTRY	1	24.272	0	\N	100	GOOD
4	5	COUNTRY	1	24.059	0	\N	100	GOOD
5	6	COUNTRY	1	24.044	0	\N	100	GOOD
6	7	COUNTRY	1	24.115	0	\N	100	GOOD
7	8	COUNTRY	1	23.896	0	\N	100	GOOD
8	9	COUNTRY	1	24.039	0	\N	100	GOOD
9	10	COUNTRY	1	24.178	0	\N	100	GOOD
10	11	COUNTRY	1	24.388	0	\N	100	GOOD
11	12	COUNTRY	1	24.097	0	\N	100	GOOD
12	13	COUNTRY	1	23.912	0	\N	100	GOOD
13	14	COUNTRY	1	24.18	0	\N	100	GOOD
14	15	COUNTRY	1	24.19	0	\N	100	GOOD
15	16	COUNTRY	1	24.071	0	\N	100	GOOD
16	17	COUNTRY	1	23.979	0	\N	100	GOOD
17	18	COUNTRY	1	28.188	0	\N	100	GOOD
18	19	COUNTRY	1	28.188	0	\N	100	GOOD
19	20	COUNTRY	1	28.384	0	\N	100	GOOD
20	21	COUNTRY	1	28.317	0	\N	100	GOOD
21	22	COUNTRY	1	28.326	0	\N	100	GOOD
22	23	COUNTRY	1	28.652	0	\N	100	GOOD
23	24	COUNTRY	1	28.642	0	\N	100	GOOD
24	25	COUNTRY	1	28.844	0	\N	100	GOOD
25	26	COUNTRY	1	28.548	0	\N	100	GOOD
26	27	COUNTRY	1	28.655	0	\N	100	GOOD
27	28	COUNTRY	1	28.697	0	\N	100	GOOD
28	29	COUNTRY	1	28.353	0	\N	100	GOOD
29	30	COUNTRY	1	28.662	0	\N	100	GOOD
30	31	COUNTRY	1	28.245	0	\N	100	GOOD
31	32	COUNTRY	1	28.714	0	\N	100	GOOD
32	33	COUNTRY	1	28.725	0	\N	100	GOOD
33	34	COUNTRY	1	28.684	0	\N	100	GOOD
34	35	COUNTRY	1	28.668	0	\N	100	GOOD
35	36	COUNTRY	1	28.448	0	\N	100	GOOD
36	37	COUNTRY	1	28.668	0	\N	100	GOOD
37	38	COUNTRY	1	28.329	0	\N	100	GOOD
38	39	COUNTRY	1	28.756	0	\N	100	GOOD
39	40	COUNTRY	1	28.676	0	\N	100	GOOD
40	41	COUNTRY	1	30.643	0	\N	100	GOOD
41	42	COUNTRY	1	28.638	0	\N	100	GOOD
42	43	COUNTRY	1	28.41	0	\N	100	GOOD
43	44	COUNTRY	1	28.64	0	\N	100	GOOD
44	45	COUNTRY	1	69.562	0	\N	95	GOOD
45	46	COUNTRY	1	28.616	0	\N	100	GOOD
46	47	COUNTRY	1	26.325	0	\N	100	GOOD
47	48	COUNTRY	1	26.754	0	\N	100	GOOD
48	49	COUNTRY	1	26.181	0	\N	100	GOOD
49	50	COUNTRY	1	25.959	0	\N	100	GOOD
50	51	COUNTRY	1	26.322	0	\N	100	GOOD
51	52	COUNTRY	1	26.251	0	\N	100	GOOD
52	53	COUNTRY	1	26.286	0	\N	100	GOOD
53	54	COUNTRY	1	26.265	0	\N	100	GOOD
54	55	COUNTRY	1	26.113	0	\N	100	GOOD
55	56	COUNTRY	1	26.159	0	\N	100	GOOD
56	57	COUNTRY	1	27.464	0	\N	100	GOOD
57	58	COUNTRY	1	29.7725	0	\N	100	GOOD
58	59	COUNTRY	1	25.645	0	\N	100	GOOD
59	60	COUNTRY	1	26.063	0	\N	100	GOOD
60	61	COUNTRY	1	26.358	0	\N	100	GOOD
61	62	COUNTRY	1	26.221	0	\N	100	GOOD
62	63	COUNTRY	1	26.311	0	\N	100	GOOD
63	64	COUNTRY	1	21.85	0	\N	100	GOOD
64	65	COUNTRY	1	21.7	0	\N	100	GOOD
65	66	COUNTRY	1	21.811	0	\N	100	GOOD
66	67	COUNTRY	1	21.806	0	\N	100	GOOD
67	68	COUNTRY	1	21.765	0	\N	100	GOOD
68	69	COUNTRY	1	21.818	0	\N	100	GOOD
69	70	COUNTRY	1	21.813	0	\N	100	GOOD
70	71	COUNTRY	1	21.921	0	\N	100	GOOD
71	72	COUNTRY	1	21.773	0	\N	100	GOOD
72	73	COUNTRY	1	21.76	0	\N	100	GOOD
73	74	COUNTRY	1	21.863	0	\N	100	GOOD
74	75	COUNTRY	1	21.748	0	\N	100	GOOD
75	76	COUNTRY	1	21.783	0	\N	100	GOOD
76	77	COUNTRY	1	21.751	0	\N	100	GOOD
77	78	COUNTRY	1	21.794	0	\N	100	GOOD
78	79	COUNTRY	1	21.744	0	\N	100	GOOD
79	80	COUNTRY	1	21.793	0	\N	100	GOOD
80	81	COUNTRY	1	21.839	0	\N	100	GOOD
81	82	COUNTRY	1	21.871	0	\N	100	GOOD
82	83	COUNTRY	1	21.779	0	\N	100	GOOD
83	84	COUNTRY	1	21.844	0	\N	100	GOOD
84	85	COUNTRY	1	21.87	0	\N	100	GOOD
85	86	COUNTRY	1	22.088	0	\N	100	GOOD
86	87	COUNTRY	1	21.868	0	\N	100	GOOD
87	88	COUNTRY	1	21.847	0	\N	100	GOOD
88	89	COUNTRY	1	25.241	0	\N	100	GOOD
89	90	COUNTRY	1	24.986	0	\N	100	GOOD
90	91	COUNTRY	1	22.362	0	\N	100	GOOD
91	92	COUNTRY	1	22.117	0	\N	100	GOOD
92	93	COUNTRY	1	22.086	0	\N	100	GOOD
93	94	COUNTRY	1	22.347	0	\N	100	GOOD
94	95	COUNTRY	1	21.954	0	\N	100	GOOD
95	96	COUNTRY	1	22.041	0	\N	100	GOOD
96	97	COUNTRY	1	21.992	0	\N	100	GOOD
97	98	COUNTRY	1	21.974	0	\N	100	GOOD
98	99	COUNTRY	1	22.361	0	\N	100	GOOD
99	100	COUNTRY	1	22.227	0	\N	100	GOOD
100	101	COUNTRY	1	22.015	0	\N	100	GOOD
101	102	COUNTRY	1	22.052	0	\N	100	GOOD
102	103	COUNTRY	1	21.971	0	\N	100	GOOD
103	104	COUNTRY	1	22.226	0	\N	100	GOOD
104	105	COUNTRY	1	21.912	0	\N	100	GOOD
105	106	COUNTRY	1	22.136	0	\N	100	GOOD
106	107	COUNTRY	1	21.925	0	\N	100	GOOD
107	108	COUNTRY	1	22.056	0	\N	100	GOOD
108	109	COUNTRY	1	21.982	0	\N	100	GOOD
109	110	COUNTRY	1	22.143	0	\N	100	GOOD
110	111	COUNTRY	1	22.072	0	\N	100	GOOD
111	112	COUNTRY	1	21.794	0	\N	100	GOOD
112	113	COUNTRY	1	21.486	0	\N	100	GOOD
113	114	COUNTRY	1	21.44	0	\N	100	GOOD
114	115	COUNTRY	1	21.462	0	\N	100	GOOD
115	116	COUNTRY	1	21.46	0	\N	100	GOOD
116	117	COUNTRY	1	21.182	0	\N	100	GOOD
117	118	COUNTRY	1	21.45	0	\N	100	GOOD
118	119	COUNTRY	1	21.489	0	\N	100	GOOD
119	120	COUNTRY	1	21.456	0	\N	100	GOOD
120	121	COUNTRY	1	21.46	0	\N	100	GOOD
121	122	COUNTRY	1	21.542	0	\N	100	GOOD
122	123	COUNTRY	1	21.542	0	\N	100	GOOD
123	124	COUNTRY	1	29.273	0	\N	100	GOOD
124	125	COUNTRY	1	29.066	0	\N	100	GOOD
125	126	COUNTRY	1	29.284	0	\N	100	GOOD
126	127	COUNTRY	1	29.174	0	\N	100	GOOD
127	128	COUNTRY	1	29.209	0	\N	100	GOOD
128	129	COUNTRY	1	28.783	0	\N	100	GOOD
129	130	COUNTRY	1	26.102	0	\N	100	GOOD
130	131	COUNTRY	1	26.304	0	\N	100	GOOD
131	132	COUNTRY	1	26.204	0	\N	100	GOOD
132	133	COUNTRY	1	26.053	0	\N	100	GOOD
133	134	COUNTRY	1	26.358	0	\N	100	GOOD
134	135	COUNTRY	1	26.266	0	\N	100	GOOD
135	136	COUNTRY	1	26.08	0	\N	100	GOOD
136	137	COUNTRY	1	26.262	0	\N	100	GOOD
137	138	COUNTRY	1	26.322	0	\N	100	GOOD
138	139	COUNTRY	1	26.04	0	\N	100	GOOD
139	140	COUNTRY	1	26.29	0	\N	100	GOOD
140	141	COUNTRY	1	26.064	0	\N	100	GOOD
141	142	COUNTRY	1	26.211	0	\N	100	GOOD
142	143	COUNTRY	1	25.893	0	\N	100	GOOD
143	144	COUNTRY	1	26.33	0	\N	100	GOOD
144	145	COUNTRY	1	26.372	0	\N	100	GOOD
145	146	COUNTRY	1	26.274	0	\N	100	GOOD
146	147	COUNTRY	1	26.368	0	\N	100	GOOD
147	148	COUNTRY	1	26.12	0	\N	100	GOOD
148	149	COUNTRY	1	26.357	0	\N	100	GOOD
149	150	COUNTRY	1	26.249	0	\N	100	GOOD
150	151	COUNTRY	1	26.311	0	\N	100	GOOD
151	152	COUNTRY	1	26.166	0	\N	100	GOOD
152	153	COUNTRY	1	26.318	0	\N	100	GOOD
153	154	COUNTRY	1	26.323	0	\N	100	GOOD
154	155	COUNTRY	1	26.322	0	\N	100	GOOD
155	156	COUNTRY	1	26.25	0	\N	100	GOOD
156	157	COUNTRY	1	26.074	0	\N	100	GOOD
157	158	COUNTRY	1	26.125	0	\N	100	GOOD
158	159	COUNTRY	1	26.358	0	\N	100	GOOD
159	160	COUNTRY	1	26.383	0	\N	100	GOOD
160	161	COUNTRY	1	26.325	0	\N	100	GOOD
161	162	COUNTRY	1	26.32	0	\N	100	GOOD
162	163	COUNTRY	1	26.301	0	\N	100	GOOD
163	164	COUNTRY	1	21.856	0	\N	100	GOOD
164	165	COUNTRY	1	26.578	0	\N	100	GOOD
165	166	COUNTRY	1	26.388	0	\N	100	GOOD
166	167	COUNTRY	1	26.388	0	\N	100	GOOD
167	168	COUNTRY	1	26.388	0	\N	100	GOOD
168	169	COUNTRY	1	26.388	0	\N	100	GOOD
169	170	COUNTRY	1	26.388	0	\N	100	GOOD
170	171	COUNTRY	1	26.388	0	\N	100	GOOD
171	172	COUNTRY	1	26.388	0	\N	100	GOOD
172	173	COUNTRY	1	26.069	0	\N	100	GOOD
173	174	COUNTRY	1	25.848	0	\N	100	GOOD
174	175	COUNTRY	1	25.881	0	\N	100	GOOD
175	176	COUNTRY	1	26.129	0	\N	100	GOOD
176	177	COUNTRY	1	26.078	0	\N	100	GOOD
177	178	COUNTRY	1	25.927	0	\N	100	GOOD
178	179	COUNTRY	1	26.245	0	\N	100	GOOD
179	180	COUNTRY	1	26.281	0	\N	100	GOOD
180	181	COUNTRY	1	23.764	0	\N	100	GOOD
181	182	COUNTRY	1	23.592	0	\N	100	GOOD
182	183	COUNTRY	1	23.625	0	\N	100	GOOD
183	184	COUNTRY	1	24.418	0	\N	100	GOOD
184	185	COUNTRY	1	23.604	0	\N	100	GOOD
185	186	COUNTRY	1	23.785	0	\N	100	GOOD
186	187	COUNTRY	1	23.974	0	\N	100	GOOD
187	188	COUNTRY	1	23.866	0	\N	100	GOOD
188	189	COUNTRY	1	23.726	0	\N	100	GOOD
189	190	COUNTRY	1	23.864	0	\N	100	GOOD
190	191	COUNTRY	1	23.864	0	\N	100	GOOD
191	192	COUNTRY	1	24.309	0	\N	100	GOOD
192	193	COUNTRY	1	24.184	0	\N	100	GOOD
193	194	COUNTRY	1	24.219	0	\N	100	GOOD
194	195	COUNTRY	1	24.204	0	\N	100	GOOD
195	196	COUNTRY	1	24.083	0	\N	100	GOOD
196	197	COUNTRY	1	24.011	0	\N	100	GOOD
197	198	COUNTRY	1	24.011	0	\N	100	GOOD
198	199	COUNTRY	1	23.798	0	\N	100	GOOD
199	200	COUNTRY	1	24.675	0	\N	100	GOOD
200	201	COUNTRY	1	24.061	0	\N	100	GOOD
201	202	COUNTRY	1	24.017	0	\N	100	GOOD
202	203	COUNTRY	1	24.057	0	\N	100	GOOD
203	204	COUNTRY	1	24.055	0	\N	100	GOOD
204	205	COUNTRY	1	24.121	0	\N	100	GOOD
205	206	COUNTRY	1	23.959	0	\N	100	GOOD
206	207	COUNTRY	1	24.051	0	\N	100	GOOD
207	208	COUNTRY	1	24.062	0	\N	100	GOOD
208	209	COUNTRY	1	23.873	0	\N	100	GOOD
209	210	COUNTRY	1	24.029	0	\N	100	GOOD
210	211	COUNTRY	1	24.017	0	\N	100	GOOD
211	212	COUNTRY	1	24.076	0	\N	100	GOOD
212	213	COUNTRY	1	23.937	0	\N	100	GOOD
213	214	COUNTRY	1	24.263	0	\N	100	GOOD
214	215	COUNTRY	1	23.998	0	\N	100	GOOD
215	216	COUNTRY	1	25.143	0	\N	100	GOOD
216	217	COUNTRY	1	24.266	0	\N	100	GOOD
217	218	COUNTRY	1	24.532	0	\N	100	GOOD
218	219	COUNTRY	1	24.418	0	\N	100	GOOD
219	220	COUNTRY	1	24.288	0	\N	100	GOOD
220	221	COUNTRY	1	24.342	0	\N	100	GOOD
221	222	COUNTRY	1	24.235	0	\N	100	GOOD
222	223	COUNTRY	1	24.32	0	\N	100	GOOD
223	224	COUNTRY	1	24.298	0	\N	100	GOOD
224	225	COUNTRY	1	24.38	0	\N	100	GOOD
225	226	COUNTRY	1	24.385	0	\N	100	GOOD
226	227	COUNTRY	1	24.522	0	\N	100	GOOD
227	228	COUNTRY	1	24.255	0	\N	100	GOOD
228	229	COUNTRY	1	24.436	0	\N	100	GOOD
229	230	COUNTRY	1	22.938	0	\N	100	GOOD
230	231	COUNTRY	1	23.108	0	\N	100	GOOD
231	232	COUNTRY	1	24.764	0	\N	100	GOOD
232	233	COUNTRY	1	24.34	0	\N	100	GOOD
233	234	COUNTRY	1	24.807	0	\N	100	GOOD
234	235	COUNTRY	1	24.55	0	\N	100	GOOD
235	236	COUNTRY	1	24.414	0	\N	100	GOOD
236	237	COUNTRY	1	24.632	0	\N	100	GOOD
237	238	COUNTRY	1	24.545	0	\N	100	GOOD
238	239	COUNTRY	1	24.562	0	\N	100	GOOD
239	240	COUNTRY	1	24.523	0	\N	100	GOOD
240	241	COUNTRY	1	24.353	0	\N	100	GOOD
241	242	COUNTRY	1	24.632	0	\N	100	GOOD
242	243	COUNTRY	1	24.635	0	\N	100	GOOD
243	244	COUNTRY	1	25.06	0	\N	100	GOOD
244	245	COUNTRY	1	24.533	0	\N	100	GOOD
245	246	COUNTRY	1	24.669	0	\N	100	GOOD
246	247	COUNTRY	1	24.443	0	\N	100	GOOD
247	248	COUNTRY	1	24.481	0	\N	100	GOOD
248	249	COUNTRY	1	24.799	0	\N	100	GOOD
249	250	COUNTRY	1	25.024	0	\N	100	GOOD
250	251	COUNTRY	1	25.244	0	\N	100	GOOD
251	252	COUNTRY	1	24.606	0	\N	100	GOOD
252	253	COUNTRY	1	24.531	0	\N	100	GOOD
253	254	COUNTRY	1	24.584	0	\N	100	GOOD
254	255	COUNTRY	1	24.701	0	\N	100	GOOD
255	256	COUNTRY	1	24.475	0	\N	100	GOOD
256	257	COUNTRY	1	24.298	0	\N	100	GOOD
257	258	COUNTRY	1	24.726	0	\N	100	GOOD
258	259	COUNTRY	1	24.616	0	\N	100	GOOD
259	260	COUNTRY	1	24.23	0	\N	100	GOOD
260	261	COUNTRY	1	24.323	0	\N	100	GOOD
261	262	COUNTRY	1	24.447	0	\N	100	GOOD
262	263	COUNTRY	1	24.344	0	\N	100	GOOD
263	264	COUNTRY	1	24.405	0	\N	100	GOOD
264	265	COUNTRY	1	24.409	0	\N	100	GOOD
265	266	COUNTRY	1	24.389	0	\N	100	GOOD
266	267	COUNTRY	1	24.277	0	\N	100	GOOD
267	268	COUNTRY	1	24.276	0	\N	100	GOOD
268	269	COUNTRY	1	24.433	0	\N	100	GOOD
269	270	COUNTRY	1	24.242	0	\N	100	GOOD
270	271	COUNTRY	1	24.419	0	\N	100	GOOD
271	272	COUNTRY	1	24.21	0	\N	100	GOOD
272	273	COUNTRY	1	24.251	0	\N	100	GOOD
273	274	COUNTRY	1	24.253	0	\N	100	GOOD
274	275	COUNTRY	1	24.294	0	\N	100	GOOD
275	276	COUNTRY	1	24.183	0	\N	100	GOOD
276	277	COUNTRY	1	24.22	0	\N	100	GOOD
277	278	COUNTRY	1	24.256	0	\N	100	GOOD
278	279	COUNTRY	1	24.369	0	\N	100	GOOD
279	280	COUNTRY	1	24.192	0	\N	100	GOOD
280	281	COUNTRY	1	24.193	0	\N	100	GOOD
281	282	COUNTRY	1	24.27	0	\N	100	GOOD
282	283	COUNTRY	1	24.193	0	\N	100	GOOD
283	284	COUNTRY	1	24.288	0	\N	100	GOOD
284	285	COUNTRY	1	24.277	0	\N	100	GOOD
285	286	COUNTRY	1	24.184	0	\N	100	GOOD
286	287	COUNTRY	1	24.28	0	\N	100	GOOD
287	288	COUNTRY	1	24.386	0	\N	100	GOOD
288	289	COUNTRY	1	24.193	0	\N	100	GOOD
289	290	COUNTRY	1	24.265	0	\N	100	GOOD
290	291	COUNTRY	1	24.226	0	\N	100	GOOD
291	292	COUNTRY	1	24.242	0	\N	100	GOOD
292	293	COUNTRY	1	24.222	0	\N	100	GOOD
293	294	COUNTRY	1	24.238	0	\N	100	GOOD
294	295	COUNTRY	1	24.174	0	\N	100	GOOD
295	296	COUNTRY	1	24.32	0	\N	100	GOOD
296	297	COUNTRY	1	24.174	0	\N	100	GOOD
297	298	COUNTRY	1	24.244	0	\N	100	GOOD
298	299	COUNTRY	1	24.361	0	\N	100	GOOD
299	300	COUNTRY	1	24.223	0	\N	100	GOOD
300	301	COUNTRY	1	24.252	0	\N	100	GOOD
301	302	COUNTRY	1	24.201	0	\N	100	GOOD
302	303	COUNTRY	1	24.268	0	\N	100	GOOD
303	304	COUNTRY	1	24.241	0	\N	100	GOOD
304	305	COUNTRY	1	24.274	0	\N	100	GOOD
305	306	COUNTRY	1	24.228	0	\N	100	GOOD
306	307	COUNTRY	1	24.226	0	\N	100	GOOD
307	308	COUNTRY	1	24.251	0	\N	100	GOOD
308	309	COUNTRY	1	24.244	0	\N	100	GOOD
309	310	COUNTRY	1	24.193	0	\N	100	GOOD
310	311	COUNTRY	1	24.258	0	\N	100	GOOD
311	312	COUNTRY	1	24.243	0	\N	100	GOOD
312	313	COUNTRY	1	24.422	0	\N	100	GOOD
313	314	COUNTRY	1	24.289	0	\N	100	GOOD
314	315	COUNTRY	1	24.287	0	\N	100	GOOD
315	316	COUNTRY	1	24.415	0	\N	100	GOOD
316	317	COUNTRY	1	24.419	0	\N	100	GOOD
317	318	COUNTRY	1	24.452	0	\N	100	GOOD
318	319	COUNTRY	1	24.236	0	\N	100	GOOD
319	320	COUNTRY	1	24.299	0	\N	100	GOOD
320	321	COUNTRY	1	24.346	0	\N	100	GOOD
321	322	COUNTRY	1	24.244	0	\N	100	GOOD
322	323	COUNTRY	1	24.358	0	\N	100	GOOD
323	324	COUNTRY	1	24.385	0	\N	100	GOOD
324	325	COUNTRY	1	24.381	0	\N	100	GOOD
325	326	COUNTRY	1	24.271	0	\N	100	GOOD
326	327	COUNTRY	1	24.266	0	\N	100	GOOD
327	328	COUNTRY	1	24.408	0	\N	100	GOOD
328	329	COUNTRY	1	24.412	0	\N	100	GOOD
329	330	COUNTRY	1	24.259	0	\N	100	GOOD
330	331	COUNTRY	1	24.386	0	\N	100	GOOD
331	332	COUNTRY	1	24.3	0	\N	100	GOOD
332	333	COUNTRY	1	24.229	0	\N	100	GOOD
333	334	COUNTRY	1	24.327	0	\N	100	GOOD
334	335	COUNTRY	1	24.395	0	\N	100	GOOD
335	336	COUNTRY	1	24.34	0	\N	100	GOOD
336	337	COUNTRY	1	24.351	0	\N	100	GOOD
337	338	COUNTRY	1	24.748	0	\N	100	GOOD
338	339	COUNTRY	1	24.311	0	\N	100	GOOD
339	340	COUNTRY	1	24.294	0	\N	100	GOOD
340	341	COUNTRY	1	24.534	0	\N	100	GOOD
341	342	COUNTRY	1	24.424	0	\N	100	GOOD
342	343	COUNTRY	1	24.425	0	\N	100	GOOD
343	344	COUNTRY	1	24.834	0	\N	100	GOOD
344	345	COUNTRY	1	24.444	0	\N	100	GOOD
345	346	COUNTRY	1	24.364	0	\N	100	GOOD
346	347	COUNTRY	1	24.245	0	\N	100	GOOD
347	348	COUNTRY	1	24.603	0	\N	100	GOOD
348	349	COUNTRY	1	24.339	0	\N	100	GOOD
349	350	COUNTRY	1	24.293	0	\N	100	GOOD
350	351	COUNTRY	1	24.401	0	\N	100	GOOD
351	352	COUNTRY	1	24.324	0	\N	100	GOOD
352	353	COUNTRY	1	24.312	0	\N	100	GOOD
353	354	COUNTRY	1	24.351	0	\N	100	GOOD
354	355	COUNTRY	1	24.357	0	\N	100	GOOD
355	356	COUNTRY	1	24.411	0	\N	100	GOOD
356	357	COUNTRY	1	24.286	0	\N	100	GOOD
357	358	COUNTRY	1	24.321	0	\N	100	GOOD
358	359	COUNTRY	1	24.242	0	\N	100	GOOD
359	360	COUNTRY	1	24.272	0	\N	100	GOOD
360	361	COUNTRY	1	24.287	0	\N	100	GOOD
361	362	COUNTRY	1	24.229	0	\N	100	GOOD
362	363	COUNTRY	1	24.24	0	\N	100	GOOD
363	364	COUNTRY	1	24.355	0	\N	100	GOOD
364	365	COUNTRY	1	24.295	0	\N	100	GOOD
365	366	COUNTRY	1	24.26	0	\N	100	GOOD
366	367	COUNTRY	1	24.356	0	\N	100	GOOD
367	368	COUNTRY	1	24.233	0	\N	100	GOOD
368	369	COUNTRY	1	24.353	0	\N	100	GOOD
369	370	COUNTRY	1	24.224	0	\N	100	GOOD
370	371	COUNTRY	1	23.9	0	\N	100	GOOD
371	372	COUNTRY	1	23.815	0	\N	100	GOOD
372	373	COUNTRY	1	23.975	0	\N	100	GOOD
373	374	COUNTRY	1	23.847	0	\N	100	GOOD
374	375	COUNTRY	1	24.071	0	\N	100	GOOD
375	376	COUNTRY	1	23.914	0	\N	100	GOOD
376	377	COUNTRY	1	24.027	0	\N	100	GOOD
377	378	COUNTRY	1	23.841	0	\N	100	GOOD
378	379	COUNTRY	1	24.126	0	\N	100	GOOD
379	380	COUNTRY	1	24.05	0	\N	100	GOOD
380	381	COUNTRY	1	24.041	0	\N	100	GOOD
381	382	COUNTRY	1	23.931	0	\N	100	GOOD
382	383	COUNTRY	1	23.952	0	\N	100	GOOD
383	384	COUNTRY	1	23.822	0	\N	100	GOOD
384	385	COUNTRY	1	24.056	0	\N	100	GOOD
385	386	COUNTRY	1	23.954	0	\N	100	GOOD
386	387	COUNTRY	1	23.897	0	\N	100	GOOD
387	388	COUNTRY	1	23.862	0	\N	100	GOOD
388	389	COUNTRY	1	24.14	0	\N	100	GOOD
389	390	COUNTRY	1	23.942	0	\N	100	GOOD
390	391	COUNTRY	1	23.943	0	\N	100	GOOD
407	408	COUNTRY	1	23.854	0	\N	100	GOOD
408	409	COUNTRY	1	23.804	0	\N	100	GOOD
409	410	COUNTRY	1	23.835	0	\N	100	GOOD
410	411	COUNTRY	1	23.875	0	\N	100	GOOD
411	412	COUNTRY	1	23.849	0	\N	100	GOOD
412	413	COUNTRY	1	23.827	0	\N	100	GOOD
413	414	COUNTRY	1	23.815	0	\N	100	GOOD
414	415	COUNTRY	1	24.058	0	\N	100	GOOD
415	416	COUNTRY	1	23.799	0	\N	100	GOOD
416	417	COUNTRY	1	23.848	0	\N	100	GOOD
417	418	COUNTRY	1	23.832	0	\N	100	GOOD
418	419	COUNTRY	1	23.878	0	\N	100	GOOD
419	420	COUNTRY	1	23.902	0	\N	100	GOOD
420	421	COUNTRY	1	23.844	0	\N	100	GOOD
421	422	COUNTRY	1	23.888	0	\N	100	GOOD
422	423	COUNTRY	1	23.829	0	\N	100	GOOD
423	424	COUNTRY	1	23.774	0	\N	100	GOOD
424	425	COUNTRY	1	23.806	0	\N	100	GOOD
425	426	COUNTRY	1	23.814	0	\N	100	GOOD
426	427	COUNTRY	1	24.056	0	\N	100	GOOD
427	428	COUNTRY	1	23.833	0	\N	100	GOOD
428	429	COUNTRY	1	23.872	0	\N	100	GOOD
429	430	COUNTRY	1	23.897	0	\N	100	GOOD
430	431	COUNTRY	1	23.831	0	\N	100	GOOD
431	432	COUNTRY	1	23.833	0	\N	100	GOOD
432	433	COUNTRY	1	23.777	0	\N	100	GOOD
433	434	COUNTRY	1	23.98	0	\N	100	GOOD
434	435	COUNTRY	1	23.895	0	\N	100	GOOD
435	436	COUNTRY	1	24.014	0	\N	100	GOOD
436	437	COUNTRY	1	23.839	0	\N	100	GOOD
437	438	COUNTRY	1	23.965	0	\N	100	GOOD
438	439	COUNTRY	1	24.054	0	\N	100	GOOD
439	440	COUNTRY	1	24.015	0	\N	100	GOOD
440	441	COUNTRY	1	23.849	0	\N	100	GOOD
441	442	COUNTRY	1	23.849	0	\N	100	GOOD
442	443	COUNTRY	1	23.933	0	\N	100	GOOD
443	444	COUNTRY	1	24.037	0	\N	100	GOOD
444	445	COUNTRY	1	23.785	0	\N	100	GOOD
445	446	COUNTRY	1	23.808	0	\N	100	GOOD
446	447	COUNTRY	1	24.02	0	\N	100	GOOD
447	448	COUNTRY	1	23.799	0	\N	100	GOOD
448	449	COUNTRY	1	23.879	0	\N	100	GOOD
449	450	COUNTRY	1	23.966	0	\N	100	GOOD
450	451	COUNTRY	1	23.806	0	\N	100	GOOD
451	452	COUNTRY	1	23.84	0	\N	100	GOOD
452	453	COUNTRY	1	23.895	0	\N	100	GOOD
453	454	COUNTRY	1	23.879	0	\N	100	GOOD
454	455	COUNTRY	1	23.891	0	\N	100	GOOD
455	456	COUNTRY	1	23.962	0	\N	100	GOOD
456	457	COUNTRY	1	23.941	0	\N	100	GOOD
457	458	COUNTRY	1	24.302	0	\N	100	GOOD
458	459	COUNTRY	1	23.867	0	\N	100	GOOD
459	460	COUNTRY	1	24.164	0	\N	100	GOOD
460	461	COUNTRY	1	23.826	0	\N	100	GOOD
461	462	COUNTRY	1	24.002	0	\N	100	GOOD
462	463	COUNTRY	1	23.933	0	\N	100	GOOD
463	464	COUNTRY	1	23.963	0	\N	100	GOOD
464	465	COUNTRY	1	23.883	0	\N	100	GOOD
465	466	COUNTRY	1	24.227	0	\N	100	GOOD
466	467	COUNTRY	1	24.089	0	\N	100	GOOD
467	468	COUNTRY	1	23.924	0	\N	100	GOOD
468	469	COUNTRY	1	24.097	0	\N	100	GOOD
469	470	COUNTRY	1	23.98	0	\N	100	GOOD
470	471	COUNTRY	1	23.873	0	\N	100	GOOD
471	472	COUNTRY	1	24.107	0	\N	100	GOOD
472	473	COUNTRY	1	23.989	0	\N	100	GOOD
473	474	COUNTRY	1	23.956	0	\N	100	GOOD
474	475	COUNTRY	1	24.071	0	\N	100	GOOD
475	476	COUNTRY	1	23.967	0	\N	100	GOOD
476	477	COUNTRY	1	25.345	0	\N	100	GOOD
477	478	COUNTRY	1	23.922	0	\N	100	GOOD
478	479	COUNTRY	1	24.575	0	\N	100	GOOD
479	480	COUNTRY	1	24.093	0	\N	100	GOOD
480	481	COUNTRY	1	24.281	0	\N	100	GOOD
481	482	COUNTRY	1	24.241	0	\N	100	GOOD
482	483	COUNTRY	1	24.211	0	\N	100	GOOD
483	484	COUNTRY	1	24.127	0	\N	100	GOOD
484	485	COUNTRY	1	24.08	0	\N	100	GOOD
485	486	COUNTRY	1	24.116	0	\N	100	GOOD
486	487	COUNTRY	1	24.159	0	\N	100	GOOD
487	488	COUNTRY	1	24.136	0	\N	100	GOOD
488	489	COUNTRY	1	23.994	0	\N	100	GOOD
489	490	COUNTRY	1	24.023	0	\N	100	GOOD
490	491	COUNTRY	1	23.988	0	\N	100	GOOD
491	492	COUNTRY	1	24.085	0	\N	100	GOOD
492	493	COUNTRY	1	24.207	0	\N	100	GOOD
493	494	COUNTRY	1	24.026	0	\N	100	GOOD
494	495	COUNTRY	1	24.025	0	\N	100	GOOD
495	496	COUNTRY	1	23.837	0	\N	100	GOOD
496	497	COUNTRY	1	23.815	0	\N	100	GOOD
497	498	COUNTRY	1	23.849	0	\N	100	GOOD
498	499	COUNTRY	1	23.869	0	\N	100	GOOD
499	500	COUNTRY	1	23.869	0	\N	100	GOOD
500	501	COUNTRY	1	23.869	0	\N	100	GOOD
501	502	COUNTRY	1	23.869	0	\N	100	GOOD
502	503	COUNTRY	1	23.869	0	\N	100	GOOD
503	504	COUNTRY	1	10.5958	0	\N	100	GOOD
504	505	COUNTRY	1	21.555	0	\N	100	GOOD
505	506	COUNTRY	1	21.431	0	\N	100	GOOD
506	507	COUNTRY	1	21.38	0	\N	100	GOOD
507	508	COUNTRY	1	21.527	0	\N	100	GOOD
508	509	COUNTRY	1	21.392	0	\N	100	GOOD
509	510	COUNTRY	1	21.49	0	\N	100	GOOD
510	511	COUNTRY	1	3.867	0	\N	100	GOOD
511	512	COUNTRY	1	1.222	0	\N	100	GOOD
512	513	COUNTRY	1	17.4098	0	\N	100	GOOD
513	514	COUNTRY	1	21.771	0	\N	100	GOOD
514	515	COUNTRY	1	21.844	0	\N	100	GOOD
515	516	COUNTRY	1	21.739	0	\N	100	GOOD
516	517	COUNTRY	1	21.371	0	\N	100	GOOD
517	518	COUNTRY	1	21.5	0	\N	100	GOOD
518	519	COUNTRY	1	21.397	0	\N	100	GOOD
519	520	COUNTRY	1	21.4	0	\N	100	GOOD
520	521	COUNTRY	1	21.4	0	\N	100	GOOD
521	522	COUNTRY	1	21.4	0	\N	100	GOOD
522	523	COUNTRY	1	21.4	0	\N	100	GOOD
523	524	COUNTRY	1	21.4	0	\N	100	GOOD
524	525	COUNTRY	1	21.4	0	\N	100	GOOD
525	526	COUNTRY	1	21.4	0	\N	100	GOOD
526	527	COUNTRY	1	21.4	0	\N	100	GOOD
527	528	COUNTRY	1	21.4	0	\N	100	GOOD
528	529	COUNTRY	1	21.4	0	\N	100	GOOD
529	530	COUNTRY	1	97.474	0	\N	86	GOOD
530	531	COUNTRY	1	21.661	0	\N	100	GOOD
531	532	COUNTRY	1	21.492	0	\N	100	GOOD
532	533	COUNTRY	1	84.719	0	\N	90	GOOD
533	534	COUNTRY	1	21.625	0	\N	100	GOOD
534	535	COUNTRY	1	21.373	0	\N	100	GOOD
535	536	COUNTRY	1	21.636	0	\N	100	GOOD
536	537	COUNTRY	1	21.599	0	\N	100	GOOD
537	538	COUNTRY	1	21.677	0	\N	100	GOOD
538	539	COUNTRY	1	73.828	0	\N	93	GOOD
539	540	COUNTRY	1	109.691	0	\N	83	GOOD
540	541	COUNTRY	1	24.2	0	\N	100	GOOD
541	542	COUNTRY	1	23.136	0	\N	100	GOOD
542	543	COUNTRY	1	24.114	0	\N	100	GOOD
\.


--
-- TOC entry 5263 (class 0 OID 23967)
-- Dependencies: 307
-- Data for Name: network_probe_run; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.network_probe_run (id_run, target, data_source, created_at, duration_ms, tool, probe_count, success, error_message) FROM stdin;
1	8.8.8.8	FALLBACK	2026-02-28 09:04:56.086115	1935	ping	5	f	422 Unprocessable Entity: "{<EOL>  "error": {<EOL>    "type": "no_probes_found",<EOL>    "message": "No matching IPv4 probes available."<EOL>  },<EOL>  "links": {<EOL>    "documentation": "https://globalping.io/docs/api.globalping.io#post-/v1/measurements"<EOL>  }<EOL>}"
2	2001:4860:4860::8888	REAL	2026-02-28 09:17:44.672106	105910	ping	1	t	\N
3	2001:4860:4860::8888	REAL	2026-02-28 09:31:02.247332	3513	ping	1	t	\N
4	2001:4860:4860::8888	REAL	2026-02-28 09:46:02.056381	3323	ping	1	t	\N
5	2001:4860:4860::8888	REAL	2026-02-28 10:01:02.144916	3411	ping	1	t	\N
6	2001:4860:4860::8888	REAL	2026-02-28 10:16:02.656518	3923	ping	1	t	\N
7	2001:4860:4860::8888	REAL	2026-02-28 10:31:02.246798	3513	ping	1	t	\N
8	2001:4860:4860::8888	REAL	2026-02-28 10:46:02.036308	3303	ping	1	t	\N
9	2001:4860:4860::8888	REAL	2026-02-28 11:01:02.348455	3615	ping	1	t	\N
10	2001:4860:4860::8888	REAL	2026-02-28 11:07:12.026429	3736	ping	1	t	\N
11	2001:4860:4860::8888	REAL	2026-02-28 11:22:12.308146	4037	ping	1	t	\N
12	2001:4860:4860::8888	REAL	2026-02-28 11:37:12.763501	4494	ping	1	t	\N
13	2001:4860:4860::8888	REAL	2026-02-28 11:52:11.692506	3422	ping	1	t	\N
14	2001:4860:4860::8888	REAL	2026-02-28 12:07:11.468167	3196	ping	1	t	\N
15	2001:4860:4860::8888	REAL	2026-02-28 12:22:11.455162	3185	ping	1	t	\N
16	2001:4860:4860::8888	REAL	2026-02-28 12:37:11.517175	3247	ping	1	t	\N
17	2001:4860:4860::8888	REAL	2026-02-28 12:52:37.554944	4707	ping	1	t	\N
18	8.8.8.8	REAL	2026-02-28 13:07:35.635073	2844	ping	1	t	\N
19	8.8.8.8	REAL	2026-02-28 14:08:00.272253	3274	ping	1	t	\N
20	8.8.8.8	REAL	2026-02-28 14:22:59.875181	2895	ping	1	t	\N
21	8.8.8.8	REAL	2026-02-28 14:26:45.266635	3035	ping	1	t	\N
22	8.8.8.8	REAL	2026-02-28 14:41:45.079863	2862	ping	1	t	\N
23	8.8.8.8	REAL	2026-02-28 15:09:52.22669	2973	ping	1	t	\N
24	8.8.8.8	REAL	2026-02-28 15:24:52.651833	3398	ping	1	t	\N
25	8.8.8.8	REAL	2026-02-28 15:39:52.635221	3381	ping	1	t	\N
26	8.8.8.8	REAL	2026-02-28 16:25:30.526401	3749	ping	1	t	\N
27	8.8.8.8	REAL	2026-02-28 16:40:30.122047	3344	ping	1	t	\N
28	8.8.8.8	REAL	2026-02-28 17:27:06.247416	4436	ping	1	t	\N
29	8.8.8.8	REAL	2026-02-28 17:42:05.03258	3215	ping	1	t	\N
30	8.8.8.8	REAL	2026-02-28 17:57:04.65798	2847	ping	1	t	\N
31	8.8.8.8	REAL	2026-02-28 18:12:04.646754	2835	ping	1	t	\N
32	8.8.8.8	REAL	2026-02-28 18:27:04.785147	2973	ping	1	t	\N
33	8.8.8.8	REAL	2026-02-28 18:42:04.65253	2841	ping	1	t	\N
34	8.8.8.8	REAL	2026-02-28 18:57:04.954876	3143	ping	1	t	\N
35	8.8.8.8	REAL	2026-02-28 19:12:05.252985	3442	ping	1	t	\N
36	8.8.8.8	REAL	2026-02-28 19:27:04.753904	2941	ping	1	t	\N
37	8.8.8.8	REAL	2026-02-28 19:42:05.436383	3622	ping	1	t	\N
38	8.8.8.8	REAL	2026-02-28 20:05:43.007842	2882	ping	1	t	\N
39	8.8.8.8	REAL	2026-02-28 20:20:43.072796	2949	ping	1	t	\N
40	8.8.8.8	REAL	2026-02-28 20:35:42.968064	2844	ping	1	t	\N
41	8.8.8.8	REAL	2026-02-28 20:50:42.978891	2855	ping	1	t	\N
42	8.8.8.8	REAL	2026-02-28 21:11:30.086252	2932	ping	1	t	\N
43	8.8.8.8	REAL	2026-02-28 21:26:29.982203	2827	ping	1	t	\N
44	8.8.8.8	REAL	2026-02-28 21:42:00.071619	2857	ping	1	t	\N
45	8.8.8.8	REAL	2026-02-28 21:57:00.054675	2839	ping	1	t	\N
46	8.8.8.8	REAL	2026-02-28 22:12:00.092254	2878	ping	1	t	\N
47	8.8.8.8	REAL	2026-02-28 22:37:29.987948	2852	ping	1	t	\N
48	8.8.8.8	REAL	2026-02-28 22:52:29.985858	2849	ping	1	t	\N
49	8.8.8.8	REAL	2026-02-28 23:11:57.028643	2850	ping	1	t	\N
50	8.8.8.8	REAL	2026-02-28 23:36:58.708756	2950	ping	1	t	\N
51	8.8.8.8	REAL	2026-02-28 23:51:58.631165	2871	ping	1	t	\N
52	8.8.8.8	REAL	2026-03-01 00:06:58.609321	2849	ping	1	t	\N
53	8.8.8.8	REAL	2026-03-01 00:21:58.661973	2902	ping	1	t	\N
54	8.8.8.8	REAL	2026-03-01 00:36:59.328591	3568	ping	1	t	\N
55	8.8.8.8	REAL	2026-03-01 00:51:58.632803	2874	ping	1	t	\N
56	8.8.8.8	REAL	2026-03-01 01:06:58.590342	2832	ping	1	t	\N
57	8.8.8.8	REAL	2026-03-01 01:21:58.629884	2870	ping	1	t	\N
58	2001:4860:4860::8888	REAL	2026-03-01 01:36:58.899867	3141	ping	2	t	\N
59	8.8.8.8	REAL	2026-03-01 01:51:58.618722	2859	ping	1	t	\N
60	8.8.8.8	REAL	2026-03-01 02:06:58.600041	2842	ping	1	t	\N
61	8.8.8.8	REAL	2026-03-01 02:21:58.618215	2860	ping	1	t	\N
62	8.8.8.8	REAL	2026-03-01 02:36:58.593425	2835	ping	1	t	\N
63	8.8.8.8	REAL	2026-03-01 02:51:58.593048	2835	ping	1	t	\N
64	2001:4860:4860::8888	REAL	2026-03-01 03:06:58.860757	3101	ping	1	t	\N
65	2001:4860:4860::8888	REAL	2026-03-01 03:21:59.392417	3634	ping	1	t	\N
66	2001:4860:4860::8888	REAL	2026-03-01 03:36:58.822354	3064	ping	1	t	\N
67	2001:4860:4860::8888	REAL	2026-03-01 03:51:59.39044	3631	ping	1	t	\N
68	2001:4860:4860::8888	REAL	2026-03-01 04:06:58.815732	3056	ping	1	t	\N
69	2001:4860:4860::8888	REAL	2026-03-01 04:21:58.934063	3176	ping	1	t	\N
70	2001:4860:4860::8888	REAL	2026-03-01 04:36:58.823365	3064	ping	1	t	\N
71	2001:4860:4860::8888	REAL	2026-03-01 04:51:58.823377	3064	ping	1	t	\N
72	2001:4860:4860::8888	REAL	2026-03-01 05:06:58.786466	3027	ping	1	t	\N
73	2001:4860:4860::8888	REAL	2026-03-01 05:21:58.82406	3066	ping	1	t	\N
74	2001:4860:4860::8888	REAL	2026-03-01 05:36:58.818106	3060	ping	1	t	\N
75	2001:4860:4860::8888	REAL	2026-03-01 05:51:58.852526	3093	ping	1	t	\N
76	2001:4860:4860::8888	REAL	2026-03-01 06:06:58.807766	3050	ping	1	t	\N
77	2001:4860:4860::8888	REAL	2026-03-01 06:21:58.871098	3113	ping	1	t	\N
78	2001:4860:4860::8888	REAL	2026-03-01 06:36:58.843227	3084	ping	1	t	\N
79	2001:4860:4860::8888	REAL	2026-03-01 06:51:59.044168	3285	ping	1	t	\N
80	2001:4860:4860::8888	REAL	2026-03-01 07:08:28.223079	3400	ping	1	t	\N
81	2001:4860:4860::8888	REAL	2026-03-01 07:23:27.973533	3165	ping	1	t	\N
82	2001:4860:4860::8888	REAL	2026-03-01 07:38:27.963325	3165	ping	1	t	\N
83	2001:4860:4860::8888	REAL	2026-03-01 07:53:27.8632	3065	ping	1	t	\N
84	2001:4860:4860::8888	REAL	2026-03-01 08:08:27.858157	3063	ping	1	t	\N
85	2001:4860:4860::8888	REAL	2026-03-01 08:23:27.873214	3078	ping	1	t	\N
86	2001:4860:4860::8888	REAL	2026-03-01 08:38:27.852306	3056	ping	1	t	\N
87	2001:4860:4860::8888	REAL	2026-03-01 08:47:10.547759	3394	ping	1	t	\N
88	2001:4860:4860::8888	REAL	2026-03-01 09:02:11.086082	3995	ping	1	t	\N
89	2001:4860:4860::8888	REAL	2026-03-01 17:30:11.585435	3678	ping	1	t	\N
90	2001:4860:4860::8888	REAL	2026-03-01 17:45:11.536524	3650	ping	1	t	\N
91	2001:4860:4860::8888	REAL	2026-03-01 18:00:11.541685	3652	ping	1	t	\N
92	2001:4860:4860::8888	REAL	2026-03-01 18:15:12.045961	4158	ping	1	t	\N
93	2001:4860:4860::8888	REAL	2026-03-01 18:54:01.660314	4056	ping	1	t	\N
94	2001:4860:4860::8888	REAL	2026-03-01 19:09:01.055285	3454	ping	1	t	\N
95	2001:4860:4860::8888	REAL	2026-03-01 19:24:01.142117	3541	ping	1	t	\N
96	2001:4860:4860::8888	REAL	2026-03-01 19:39:01.040346	3439	ping	1	t	\N
97	2001:4860:4860::8888	REAL	2026-03-01 19:54:01.242149	3641	ping	1	t	\N
98	2001:4860:4860::8888	REAL	2026-03-01 20:09:01.046312	3440	ping	1	t	\N
99	2001:4860:4860::8888	REAL	2026-03-01 20:24:01.234273	3632	ping	1	t	\N
100	2001:4860:4860::8888	REAL	2026-03-01 21:10:28.189437	4151	ping	1	t	\N
101	2001:4860:4860::8888	REAL	2026-03-01 21:25:27.25838	3220	ping	1	t	\N
102	2001:4860:4860::8888	REAL	2026-03-01 21:40:27.794259	3756	ping	1	t	\N
103	2001:4860:4860::8888	REAL	2026-03-01 21:55:27.149253	3111	ping	1	t	\N
104	2001:4860:4860::8888	REAL	2026-03-01 22:10:27.090801	3053	ping	1	t	\N
105	2001:4860:4860::8888	REAL	2026-03-01 22:25:27.219148	3182	ping	1	t	\N
106	2001:4860:4860::8888	REAL	2026-03-01 22:40:27.653285	3605	ping	1	t	\N
107	2001:4860:4860::8888	REAL	2026-03-01 23:16:00.66893	3251	ping	1	t	\N
108	2001:4860:4860::8888	REAL	2026-03-01 23:31:01.020052	3620	ping	1	t	\N
109	2001:4860:4860::8888	REAL	2026-03-01 23:46:00.458848	3061	ping	1	t	\N
110	2001:4860:4860::8888	REAL	2026-03-02 00:01:00.611919	3190	ping	1	t	\N
111	2001:4860:4860::8888	REAL	2026-03-02 07:34:50.13762	4222	ping	1	t	\N
112	2001:4860:4860::8888	REAL	2026-03-02 07:52:39.060376	3991	ping	1	t	\N
113	2001:4860:4860::8888	REAL	2026-03-02 08:07:38.537678	3468	ping	1	t	\N
114	2001:4860:4860::8888	REAL	2026-03-02 08:22:38.531094	3461	ping	1	t	\N
115	2001:4860:4860::8888	REAL	2026-03-02 08:37:38.635684	3566	ping	1	t	\N
116	2001:4860:4860::8888	REAL	2026-03-02 08:40:39.006426	3760	ping	1	t	\N
117	2001:4860:4860::8888	REAL	2026-03-02 08:55:38.651994	3459	ping	1	t	\N
118	2001:4860:4860::8888	REAL	2026-03-02 09:10:38.33712	3145	ping	1	t	\N
119	2001:4860:4860::8888	REAL	2026-03-02 09:25:38.648938	3455	ping	1	t	\N
120	2001:4860:4860::8888	REAL	2026-03-02 09:40:38.953806	3761	ping	1	t	\N
121	2001:4860:4860::8888	REAL	2026-03-02 10:18:36.25767	3705	ping	1	t	\N
122	2001:4860:4860::8888	REAL	2026-03-02 10:33:35.722016	3185	ping	1	t	\N
123	FALLBACK	FALLBACK	2026-03-02 11:43:33.195155	140076	ping	0	f	I/O error on POST request for "https://api.globalping.io/v1/measurements": api.globalping.io
124	8.8.8.8	REAL	2026-03-02 15:44:32.957979	3408	ping	1	t	\N
125	8.8.8.8	REAL	2026-03-02 15:59:32.336235	2821	ping	1	t	\N
126	8.8.8.8	REAL	2026-03-02 16:14:32.313884	2795	ping	1	t	\N
127	8.8.8.8	REAL	2026-03-02 16:29:33.013819	3498	ping	1	t	\N
128	8.8.8.8	REAL	2026-03-02 16:44:32.332376	2816	ping	1	t	\N
129	8.8.8.8	REAL	2026-03-02 16:59:32.722137	3206	ping	1	t	\N
130	8.8.8.8	REAL	2026-03-02 19:48:32.807467	3769	ping	1	t	\N
131	8.8.8.8	REAL	2026-03-02 20:03:31.852983	2832	ping	1	t	\N
132	8.8.8.8	REAL	2026-03-02 20:18:31.946996	2925	ping	1	t	\N
133	8.8.8.8	REAL	2026-03-02 20:33:31.93429	2913	ping	1	t	\N
134	8.8.8.8	REAL	2026-03-02 20:48:32.489606	3468	ping	1	t	\N
135	8.8.8.8	REAL	2026-03-02 21:03:32.107332	3085	ping	1	t	\N
136	8.8.8.8	REAL	2026-03-02 21:18:31.972333	2951	ping	1	t	\N
137	8.8.8.8	REAL	2026-03-02 21:33:31.872174	2850	ping	1	t	\N
138	8.8.8.8	REAL	2026-03-02 21:48:31.873078	2852	ping	1	t	\N
139	8.8.8.8	REAL	2026-03-02 22:03:31.865803	2844	ping	1	t	\N
140	8.8.8.8	REAL	2026-03-02 22:18:31.88842	2867	ping	1	t	\N
141	8.8.8.8	REAL	2026-03-02 22:33:32.15618	3135	ping	1	t	\N
142	8.8.8.8	REAL	2026-03-02 22:48:32.094192	3073	ping	1	t	\N
143	8.8.8.8	REAL	2026-03-02 23:03:31.856339	2835	ping	1	t	\N
144	8.8.8.8	REAL	2026-03-02 23:18:35.049106	6028	ping	1	t	\N
145	8.8.8.8	REAL	2026-03-02 23:33:32.090005	3069	ping	1	t	\N
146	8.8.8.8	REAL	2026-03-02 23:48:31.855981	2835	ping	1	t	\N
147	8.8.8.8	REAL	2026-03-03 00:03:31.861346	2840	ping	1	t	\N
148	8.8.8.8	REAL	2026-03-03 00:18:47.509431	18488	ping	1	t	\N
149	8.8.8.8	REAL	2026-03-03 00:35:42.6025	3624	ping	1	t	\N
150	8.8.8.8	REAL	2026-03-03 00:50:42.419526	3459	ping	1	t	\N
151	8.8.8.8	REAL	2026-03-03 01:05:42.046272	3086	ping	1	t	\N
152	8.8.8.8	REAL	2026-03-03 01:20:41.865285	2905	ping	1	t	\N
153	8.8.8.8	REAL	2026-03-03 01:35:41.878692	2918	ping	1	t	\N
154	8.8.8.8	REAL	2026-03-03 01:50:41.789377	2829	ping	1	t	\N
155	8.8.8.8	REAL	2026-03-03 02:05:41.745875	2786	ping	1	t	\N
156	8.8.8.8	REAL	2026-03-03 02:20:41.764298	2804	ping	1	t	\N
157	8.8.8.8	REAL	2026-03-03 02:35:41.768834	2808	ping	1	t	\N
158	8.8.8.8	REAL	2026-03-03 02:50:42.812252	3852	ping	1	t	\N
159	8.8.8.8	REAL	2026-03-03 03:05:42.400194	3440	ping	1	t	\N
160	8.8.8.8	REAL	2026-03-03 04:47:04.642832	3006	ping	1	t	\N
161	8.8.8.8	REAL	2026-03-03 05:02:34.582829	2789	ping	1	t	\N
162	8.8.8.8	REAL	2026-03-03 05:17:34.622397	2829	ping	1	t	\N
163	8.8.8.8	REAL	2026-03-03 06:05:37.66233	2882	ping	1	t	\N
164	2001:4860:4860::8888	REAL	2026-03-03 06:20:37.791852	3011	ping	1	t	\N
165	8.8.8.8	REAL	2026-03-03 06:35:37.555341	2775	ping	1	t	\N
166	8.8.8.8	REAL	2026-03-03 06:50:37.555643	2775	ping	1	t	\N
167	FALLBACK	FALLBACK	2026-03-03 07:25:37.843105	25	ping	0	f	I/O error on POST request for "https://api.globalping.io/v1/measurements": api.globalping.io
168	FALLBACK	FALLBACK	2026-03-03 07:40:37.822296	5	ping	0	f	I/O error on POST request for "https://api.globalping.io/v1/measurements": api.globalping.io
169	FALLBACK	FALLBACK	2026-03-03 07:57:20.546596	5	ping	0	f	I/O error on POST request for "https://api.globalping.io/v1/measurements": api.globalping.io
170	FALLBACK	FALLBACK	2026-03-03 08:12:20.546569	5	ping	0	f	I/O error on POST request for "https://api.globalping.io/v1/measurements": api.globalping.io
171	FALLBACK	FALLBACK	2026-03-03 08:27:20.546383	5	ping	0	f	I/O error on POST request for "https://api.globalping.io/v1/measurements": api.globalping.io
172	FALLBACK	FALLBACK	2026-03-03 08:42:20.545944	5	ping	0	f	I/O error on POST request for "https://api.globalping.io/v1/measurements": api.globalping.io
173	8.8.8.8	REAL	2026-03-03 08:57:23.864463	3323	ping	1	t	\N
174	8.8.8.8	REAL	2026-03-03 09:12:23.654975	3115	ping	1	t	\N
175	8.8.8.8	REAL	2026-03-03 09:27:23.549041	3008	ping	1	t	\N
176	8.8.8.8	REAL	2026-03-03 09:42:23.545301	3005	ping	1	t	\N
177	8.8.8.8	REAL	2026-03-03 09:57:24.160887	3621	ping	1	t	\N
178	8.8.8.8	REAL	2026-03-03 10:12:23.505979	2965	ping	1	t	\N
179	8.8.8.8	REAL	2026-03-03 10:27:23.607833	3067	ping	1	t	\N
180	8.8.8.8	REAL	2026-03-03 10:44:27.094379	3033	ping	1	t	\N
181	2001:4860:4860::8888	REAL	2026-03-04 05:07:35.779636	3425	ping	1	t	\N
182	2001:4860:4860::8888	REAL	2026-03-04 05:22:35.878739	3548	ping	1	t	\N
183	2001:4860:4860::8888	REAL	2026-03-04 05:37:35.55875	3228	ping	1	t	\N
184	2001:4860:4860::8888	REAL	2026-03-04 05:52:36.587574	4257	ping	1	t	\N
185	2001:4860:4860::8888	REAL	2026-03-04 06:07:35.392916	3060	ping	1	t	\N
186	2001:4860:4860::8888	REAL	2026-03-04 06:22:35.387963	3057	ping	1	t	\N
187	2001:4860:4860::8888	REAL	2026-03-04 08:35:43.178583	4003	ping	1	t	\N
188	2001:4860:4860::8888	REAL	2026-03-04 08:50:42.657453	3482	ping	1	t	\N
189	2001:4860:4860::8888	REAL	2026-03-04 09:05:43.064973	3890	ping	1	t	\N
190	2001:4860:4860::8888	REAL	2026-03-04 09:20:42.441483	3265	ping	1	t	\N
191	FALLBACK	FALLBACK	2026-03-04 16:14:09.460986	32	ping	0	f	I/O error on POST request for "https://api.globalping.io/v1/measurements": api.globalping.io
192	2001:4860:4860::8888	REAL	2026-03-04 16:53:14.417204	3055	ping	1	t	\N
193	2001:4860:4860::8888	REAL	2026-03-04 17:49:26.306795	3017	ping	1	t	\N
194	2001:4860:4860::8888	REAL	2026-03-04 18:04:28.990543	5701	ping	1	t	\N
195	2001:4860:4860::8888	REAL	2026-03-04 18:19:27.040911	3026	ping	1	t	\N
196	2001:4860:4860::8888	REAL	2026-03-07 07:03:55.504894	4531	ping	1	t	\N
197	2001:4860:4860::8888	REAL	2026-03-07 07:18:54.371212	3401	ping	1	t	\N
198	2001:4860:4860::8888	REAL	2026-03-07 07:33:55.089867	4134	ping	1	t	\N
199	2001:4860:4860::8888	REAL	2026-03-07 07:48:54.570902	3600	ping	1	t	\N
200	2001:4860:4860::8888	REAL	2026-03-07 08:03:54.565497	3609	ping	1	t	\N
201	2001:4860:4860::8888	REAL	2026-03-07 08:18:55.487377	4532	ping	1	t	\N
202	2001:4860:4860::8888	REAL	2026-03-07 08:33:54.461448	3506	ping	1	t	\N
203	2001:4860:4860::8888	REAL	2026-03-07 08:48:55.075594	4120	ping	1	t	\N
204	2001:4860:4860::8888	REAL	2026-03-07 09:06:49.989013	3602	ping	1	t	\N
205	2001:4860:4860::8888	REAL	2026-03-07 09:08:22.792137	3840	ping	1	t	\N
206	2001:4860:4860::8888	REAL	2026-03-07 09:23:23.159296	4279	ping	1	t	\N
207	2001:4860:4860::8888	REAL	2026-03-07 11:26:41.745835	3226	ping	1	t	\N
208	2001:4860:4860::8888	REAL	2026-03-07 11:41:41.738855	3236	ping	1	t	\N
209	2001:4860:4860::8888	REAL	2026-03-07 11:56:41.506895	3004	ping	1	t	\N
210	2001:4860:4860::8888	REAL	2026-03-07 12:11:41.513212	3010	ping	1	t	\N
211	2001:4860:4860::8888	REAL	2026-03-07 12:26:41.545388	3043	ping	1	t	\N
212	2001:4860:4860::8888	REAL	2026-03-07 12:41:41.53882	3036	ping	1	t	\N
213	2001:4860:4860::8888	REAL	2026-03-07 12:45:04.120048	3165	ping	1	t	\N
214	2001:4860:4860::8888	REAL	2026-03-07 13:00:04.314836	3382	ping	1	t	\N
215	2001:4860:4860::8888	REAL	2026-03-07 13:15:03.971786	3038	ping	1	t	\N
216	2001:4860:4860::8888	REAL	2026-03-07 13:30:03.965943	3033	ping	1	t	\N
217	2001:4860:4860::8888	REAL	2026-03-07 13:45:03.97005	3037	ping	1	t	\N
218	2001:4860:4860::8888	REAL	2026-03-07 15:03:14.16887	3280	ping	1	t	\N
219	2001:4860:4860::8888	REAL	2026-03-07 15:18:13.871031	3007	ping	1	t	\N
220	2001:4860:4860::8888	REAL	2026-03-07 15:28:05.09938	3752	ping	1	t	\N
221	2001:4860:4860::8888	REAL	2026-03-07 15:43:04.979759	3684	ping	1	t	\N
222	2001:4860:4860::8888	REAL	2026-03-07 15:55:47.948516	3304	ping	1	t	\N
223	2001:4860:4860::8888	REAL	2026-03-07 16:10:48.242321	3614	ping	1	t	\N
224	2001:4860:4860::8888	REAL	2026-03-07 16:25:47.65824	3030	ping	1	t	\N
225	2001:4860:4860::8888	REAL	2026-03-07 16:40:47.629528	3001	ping	1	t	\N
226	2001:4860:4860::8888	REAL	2026-03-07 16:55:47.629123	3001	ping	1	t	\N
227	2001:4860:4860::8888	REAL	2026-03-07 17:10:47.633751	3005	ping	1	t	\N
228	2001:4860:4860::8888	REAL	2026-03-07 17:11:13.432264	3188	ping	1	t	\N
229	2001:4860:4860::8888	REAL	2026-03-07 17:23:13.598964	3170	ping	1	t	\N
230	2001:4860:4860::8888	REAL	2026-03-07 17:33:30.522556	3162	ping	1	t	\N
231	2001:4860:4860::8888	REAL	2026-03-07 17:34:32.543099	3154	ping	1	t	\N
232	2001:4860:4860::8888	REAL	2026-03-07 17:49:32.383469	3015	ping	1	t	\N
233	2001:4860:4860::8888	REAL	2026-03-07 17:50:38.903673	3194	ping	1	t	\N
234	2001:4860:4860::8888	REAL	2026-03-07 18:05:39.139704	3450	ping	1	t	\N
235	2001:4860:4860::8888	REAL	2026-03-07 18:20:39.33446	3646	ping	1	t	\N
236	2001:4860:4860::8888	REAL	2026-03-07 18:22:55.023248	3166	ping	1	t	\N
237	2001:4860:4860::8888	REAL	2026-03-07 18:37:55.276088	3436	ping	1	t	\N
238	2001:4860:4860::8888	REAL	2026-03-07 18:52:54.878574	3038	ping	1	t	\N
239	2001:4860:4860::8888	REAL	2026-03-07 19:07:54.855034	3015	ping	1	t	\N
240	2001:4860:4860::8888	REAL	2026-03-07 19:22:54.913716	3073	ping	1	t	\N
241	2001:4860:4860::8888	REAL	2026-03-07 19:37:55.015194	3174	ping	1	t	\N
242	2001:4860:4860::8888	REAL	2026-03-07 19:46:25.209726	3176	ping	1	t	\N
243	2001:4860:4860::8888	REAL	2026-03-07 20:01:25.070144	3046	ping	1	t	\N
244	2001:4860:4860::8888	REAL	2026-03-07 20:15:44.696127	3306	ping	1	t	\N
245	2001:4860:4860::8888	REAL	2026-03-07 20:17:06.326547	3437	ping	1	t	\N
246	2001:4860:4860::8888	REAL	2026-03-07 20:19:23.663859	3220	ping	1	t	\N
247	2001:4860:4860::8888	REAL	2026-03-07 20:22:47.99461	3758	ping	1	t	\N
248	2001:4860:4860::8888	REAL	2026-03-07 20:23:26.720433	3177	ping	1	t	\N
249	2001:4860:4860::8888	REAL	2026-03-07 20:26:11.246297	3183	ping	1	t	\N
250	2001:4860:4860::8888	REAL	2026-03-07 20:41:11.612143	3557	ping	1	t	\N
251	2001:4860:4860::8888	REAL	2026-03-07 20:56:04.410829	3740	ping	1	t	\N
252	2001:4860:4860::8888	REAL	2026-03-07 21:42:05.55201	3755	ping	1	t	\N
253	2001:4860:4860::8888	REAL	2026-03-07 21:57:05.44881	3681	ping	1	t	\N
254	2001:4860:4860::8888	REAL	2026-03-07 22:12:04.771766	3010	ping	1	t	\N
255	2001:4860:4860::8888	REAL	2026-03-07 22:27:05.775858	4009	ping	1	t	\N
256	2001:4860:4860::8888	REAL	2026-03-07 22:42:05.336133	3579	ping	1	t	\N
257	2001:4860:4860::8888	REAL	2026-03-07 22:57:04.854069	3083	ping	1	t	\N
258	2001:4860:4860::8888	REAL	2026-03-07 23:12:05.697201	3932	ping	1	t	\N
259	2001:4860:4860::8888	REAL	2026-03-07 23:27:04.813513	3053	ping	1	t	\N
260	2001:4860:4860::8888	REAL	2026-03-07 23:42:04.839876	3068	ping	1	t	\N
261	2001:4860:4860::8888	REAL	2026-03-07 23:57:04.857975	3098	ping	1	t	\N
262	2001:4860:4860::8888	REAL	2026-03-08 00:12:04.918342	3148	ping	1	t	\N
263	2001:4860:4860::8888	REAL	2026-03-08 00:27:04.893339	3118	ping	1	t	\N
264	2001:4860:4860::8888	REAL	2026-03-08 00:42:04.891047	3132	ping	1	t	\N
265	2001:4860:4860::8888	REAL	2026-03-08 00:57:04.844047	3081	ping	1	t	\N
266	2001:4860:4860::8888	REAL	2026-03-08 01:12:04.833692	3074	ping	1	t	\N
267	2001:4860:4860::8888	REAL	2026-03-08 01:27:05.57202	3779	ping	1	t	\N
268	2001:4860:4860::8888	REAL	2026-03-08 01:42:05.098493	3341	ping	1	t	\N
269	2001:4860:4860::8888	REAL	2026-03-08 01:57:05.013546	3246	ping	1	t	\N
270	2001:4860:4860::8888	REAL	2026-03-08 02:12:04.90441	3132	ping	1	t	\N
271	2001:4860:4860::8888	REAL	2026-03-08 02:27:05.098873	3341	ping	1	t	\N
272	2001:4860:4860::8888	REAL	2026-03-08 02:42:04.82009	3062	ping	1	t	\N
273	2001:4860:4860::8888	REAL	2026-03-08 02:49:40.592529	3299	ping	1	t	\N
274	2001:4860:4860::8888	REAL	2026-03-08 02:50:57.307021	4495	ping	1	t	\N
275	2001:4860:4860::8888	REAL	2026-03-08 02:52:00.514795	3085	ping	1	t	\N
276	2001:4860:4860::8888	REAL	2026-03-08 02:57:36.277581	3952	ping	1	t	\N
277	2001:4860:4860::8888	REAL	2026-03-08 02:59:43.003993	2981	ping	1	t	\N
278	2001:4860:4860::8888	REAL	2026-03-08 03:14:16.986714	3106	ping	1	t	\N
279	2001:4860:4860::8888	REAL	2026-03-08 03:18:04.508863	3737	ping	1	t	\N
280	2001:4860:4860::8888	REAL	2026-03-08 03:19:42.763067	3508	ping	1	t	\N
281	2001:4860:4860::8888	REAL	2026-03-08 03:21:14.1687	3150	ping	1	t	\N
282	2001:4860:4860::8888	REAL	2026-03-08 03:21:51.296075	3050	ping	1	t	\N
283	2001:4860:4860::8888	REAL	2026-03-08 03:23:56.434606	3031	ping	1	t	\N
284	2001:4860:4860::8888	REAL	2026-03-08 03:26:48.963668	3568	ping	1	t	\N
285	2001:4860:4860::8888	REAL	2026-03-08 03:27:04.980894	3044	ping	1	t	\N
286	2001:4860:4860::8888	REAL	2026-03-08 03:36:00.224919	3024	ping	1	t	\N
287	2001:4860:4860::8888	REAL	2026-03-08 03:36:46.213606	3022	ping	1	t	\N
288	2001:4860:4860::8888	REAL	2026-03-08 03:51:46.81111	3626	ping	1	t	\N
289	2001:4860:4860::8888	REAL	2026-03-08 03:52:29.981092	3310	ping	1	t	\N
290	2001:4860:4860::8888	REAL	2026-03-08 03:53:30.905168	3778	ping	1	t	\N
291	2001:4860:4860::8888	REAL	2026-03-08 03:57:48.624155	3312	ping	1	t	\N
292	2001:4860:4860::8888	REAL	2026-03-08 04:00:18.863672	3057	ping	1	t	\N
293	2001:4860:4860::8888	REAL	2026-03-08 04:01:13.059156	3307	ping	1	t	\N
294	2001:4860:4860::8888	REAL	2026-03-08 04:10:53.180877	3224	ping	1	t	\N
295	2001:4860:4860::8888	REAL	2026-03-08 04:12:12.34256	4334	ping	1	t	\N
296	2001:4860:4860::8888	REAL	2026-03-08 04:19:05.435327	4221	ping	1	t	\N
297	2001:4860:4860::8888	REAL	2026-03-08 04:21:35.790548	3028	ping	1	t	\N
298	2001:4860:4860::8888	REAL	2026-03-08 04:22:03.547299	3627	ping	1	t	\N
299	2001:4860:4860::8888	REAL	2026-03-08 04:37:03.046206	3123	ping	1	t	\N
300	2001:4860:4860::8888	REAL	2026-03-08 05:04:03.603991	3365	ping	1	t	\N
301	2001:4860:4860::8888	REAL	2026-03-08 05:19:03.278629	3055	ping	1	t	\N
302	2001:4860:4860::8888	REAL	2026-03-08 05:34:03.238929	3015	ping	1	t	\N
303	2001:4860:4860::8888	REAL	2026-03-08 05:49:03.828199	3605	ping	1	t	\N
304	2001:4860:4860::8888	REAL	2026-03-08 06:02:56.236335	3608	ping	1	t	\N
305	2001:4860:4860::8888	REAL	2026-03-08 06:03:41.304571	3572	ping	1	t	\N
306	2001:4860:4860::8888	REAL	2026-03-08 06:03:58.935768	3018	ping	1	t	\N
307	2001:4860:4860::8888	REAL	2026-03-08 06:04:24.302832	2989	ping	1	t	\N
308	2001:4860:4860::8888	REAL	2026-03-08 06:05:52.527868	2993	ping	1	t	\N
309	2001:4860:4860::8888	REAL	2026-03-08 06:08:28.120333	3019	ping	1	t	\N
310	2001:4860:4860::8888	REAL	2026-03-08 06:09:19.779768	3543	ping	1	t	\N
311	2001:4860:4860::8888	REAL	2026-03-08 06:19:06.97088	3047	ping	1	t	\N
312	2001:4860:4860::8888	REAL	2026-03-08 06:19:40.567762	3021	ping	1	t	\N
313	2001:4860:4860::8888	REAL	2026-03-08 06:34:40.555434	3012	ping	1	t	\N
314	2001:4860:4860::8888	REAL	2026-03-08 06:58:22.509628	3010	ping	1	t	\N
315	2001:4860:4860::8888	REAL	2026-03-08 07:13:22.55884	3059	ping	1	t	\N
316	2001:4860:4860::8888	REAL	2026-03-08 07:25:44.722409	3634	ping	1	t	\N
317	2001:4860:4860::8888	REAL	2026-03-08 07:31:40.636986	3000	ping	1	t	\N
318	2001:4860:4860::8888	REAL	2026-03-08 09:06:18.008745	3974	ping	1	t	\N
319	2001:4860:4860::8888	REAL	2026-03-08 09:20:16.93422	3017	ping	1	t	\N
320	2001:4860:4860::8888	REAL	2026-03-08 09:20:42.744262	3030	ping	1	t	\N
321	2001:4860:4860::8888	REAL	2026-03-08 09:23:09.345073	3013	ping	1	t	\N
322	2001:4860:4860::8888	REAL	2026-03-08 09:38:09.354374	3023	ping	1	t	\N
323	2001:4860:4860::8888	REAL	2026-03-08 09:44:34.767466	3012	ping	1	t	\N
324	2001:4860:4860::8888	REAL	2026-03-08 09:46:04.650606	3040	ping	1	t	\N
325	2001:4860:4860::8888	REAL	2026-03-08 09:46:21.971628	2999	ping	1	t	\N
326	2001:4860:4860::8888	REAL	2026-03-08 09:49:43.589542	3009	ping	1	t	\N
327	2001:4860:4860::8888	REAL	2026-03-08 09:50:13.938695	3010	ping	1	t	\N
328	2001:4860:4860::8888	REAL	2026-03-08 09:50:28.686126	3010	ping	1	t	\N
329	2001:4860:4860::8888	REAL	2026-03-08 09:51:11.784084	3276	ping	1	t	\N
330	2001:4860:4860::8888	REAL	2026-03-08 09:58:08.881528	3193	ping	1	t	\N
331	2001:4860:4860::8888	REAL	2026-03-08 10:01:16.750942	3181	ping	1	t	\N
332	2001:4860:4860::8888	REAL	2026-03-08 10:14:57.390194	3818	ping	1	t	\N
333	2001:4860:4860::8888	REAL	2026-03-08 10:15:24.55395	3011	ping	1	t	\N
334	2001:4860:4860::8888	REAL	2026-03-08 10:21:24.934242	3135	ping	1	t	\N
335	2001:4860:4860::8888	REAL	2026-03-08 10:30:20.652082	3326	ping	1	t	\N
336	2001:4860:4860::8888	REAL	2026-03-08 10:39:10.980206	3191	ping	1	t	\N
337	2001:4860:4860::8888	REAL	2026-03-08 10:51:24.951489	3244	ping	1	t	\N
338	2001:4860:4860::8888	REAL	2026-03-08 10:51:55.015097	3235	ping	1	t	\N
339	2001:4860:4860::8888	REAL	2026-03-08 10:53:33.955979	5511	ping	1	t	\N
340	2001:4860:4860::8888	REAL	2026-03-08 10:58:41.400173	3138	ping	1	t	\N
341	2001:4860:4860::8888	REAL	2026-03-08 11:13:41.251645	2998	ping	1	t	\N
342	2001:4860:4860::8888	REAL	2026-03-08 11:28:41.268917	3016	ping	1	t	\N
343	2001:4860:4860::8888	REAL	2026-03-08 11:37:50.31923	3651	ping	1	t	\N
344	2001:4860:4860::8888	REAL	2026-03-08 11:52:49.678836	3011	ping	1	t	\N
345	2001:4860:4860::8888	REAL	2026-03-08 12:07:49.672598	3004	ping	1	t	\N
346	2001:4860:4860::8888	REAL	2026-03-08 12:22:49.673542	3005	ping	1	t	\N
347	2001:4860:4860::8888	REAL	2026-03-08 12:37:50.291073	3623	ping	1	t	\N
348	2001:4860:4860::8888	REAL	2026-03-08 12:52:49.675486	3006	ping	1	t	\N
349	2001:4860:4860::8888	REAL	2026-03-08 12:56:07.088078	2998	ping	1	t	\N
350	2001:4860:4860::8888	REAL	2026-03-08 12:58:26.216626	3238	ping	1	t	\N
351	2001:4860:4860::8888	REAL	2026-03-08 13:10:09.09896	3010	ping	1	t	\N
352	2001:4860:4860::8888	REAL	2026-03-08 13:18:11.818242	3282	ping	1	t	\N
353	2001:4860:4860::8888	REAL	2026-03-08 13:20:35.236681	3033	ping	1	t	\N
354	2001:4860:4860::8888	REAL	2026-03-08 13:20:49.975327	3021	ping	1	t	\N
355	2001:4860:4860::8888	REAL	2026-03-08 13:35:49.981255	3028	ping	1	t	\N
356	2001:4860:4860::8888	REAL	2026-03-08 13:36:23.18743	3031	ping	1	t	\N
357	2001:4860:4860::8888	REAL	2026-03-08 13:49:49.972468	3000	ping	1	t	\N
358	2001:4860:4860::8888	REAL	2026-03-08 13:53:10.562609	3228	ping	1	t	\N
359	2001:4860:4860::8888	REAL	2026-03-08 13:55:25.620692	4697	ping	1	t	\N
360	2001:4860:4860::8888	REAL	2026-03-08 13:57:43.679886	3004	ping	1	t	\N
361	2001:4860:4860::8888	REAL	2026-03-08 13:58:44.655453	3190	ping	1	t	\N
362	2001:4860:4860::8888	REAL	2026-03-08 14:00:50.299255	3019	ping	1	t	\N
363	2001:4860:4860::8888	REAL	2026-03-08 14:02:06.961807	3040	ping	1	t	\N
364	2001:4860:4860::8888	REAL	2026-03-08 14:04:24.428264	3010	ping	1	t	\N
365	2001:4860:4860::8888	REAL	2026-03-08 14:19:24.430008	3012	ping	1	t	\N
366	2001:4860:4860::8888	REAL	2026-03-08 14:34:24.433919	3008	ping	1	t	\N
367	2001:4860:4860::8888	REAL	2026-03-08 14:49:24.430585	3013	ping	1	t	\N
368	2001:4860:4860::8888	REAL	2026-03-08 15:04:24.553303	3135	ping	1	t	\N
369	2001:4860:4860::8888	REAL	2026-03-08 15:19:24.96375	3545	ping	1	t	\N
370	2001:4860:4860::8888	REAL	2026-03-08 15:34:24.457943	3039	ping	1	t	\N
371	2001:4860:4860::8888	REAL	2026-03-08 15:49:24.544608	3126	ping	1	t	\N
372	2001:4860:4860::8888	REAL	2026-03-08 16:04:24.496183	3079	ping	1	t	\N
373	2001:4860:4860::8888	REAL	2026-03-08 16:19:24.464525	3047	ping	1	t	\N
374	2001:4860:4860::8888	REAL	2026-03-08 16:34:24.541473	3124	ping	1	t	\N
375	2001:4860:4860::8888	REAL	2026-03-08 16:49:24.540509	3122	ping	1	t	\N
376	2001:4860:4860::8888	REAL	2026-03-08 16:50:40.057936	3677	ping	1	t	\N
377	2001:4860:4860::8888	REAL	2026-03-08 16:51:02.747243	3815	ping	1	t	\N
378	2001:4860:4860::8888	REAL	2026-03-08 16:51:17.982404	3061	ping	1	t	\N
379	2001:4860:4860::8888	REAL	2026-03-08 16:54:49.478526	3459	ping	1	t	\N
380	2001:4860:4860::8888	REAL	2026-03-08 17:08:38.289643	3780	ping	1	t	\N
381	2001:4860:4860::8888	REAL	2026-03-08 17:14:40.275507	3110	ping	1	t	\N
382	2001:4860:4860::8888	REAL	2026-03-08 17:29:40.382749	3217	ping	1	t	\N
383	2001:4860:4860::8888	REAL	2026-03-08 17:30:17.745923	3033	ping	1	t	\N
384	2001:4860:4860::8888	REAL	2026-03-08 17:32:21.120352	3966	ping	1	t	\N
385	2001:4860:4860::8888	REAL	2026-03-08 17:47:20.325345	3201	ping	1	t	\N
386	2001:4860:4860::8888	REAL	2026-03-08 18:02:20.168233	3043	ping	1	t	\N
387	2001:4860:4860::8888	REAL	2026-03-08 18:17:20.364363	3241	ping	1	t	\N
388	2001:4860:4860::8888	REAL	2026-03-08 18:32:20.159243	3036	ping	1	t	\N
389	2001:4860:4860::8888	REAL	2026-03-08 18:47:20.152545	3029	ping	1	t	\N
390	2001:4860:4860::8888	REAL	2026-03-08 19:02:20.143667	3017	ping	1	t	\N
391	2001:4860:4860::8888	REAL	2026-03-09 01:59:16.550028	4395	ping	1	t	\N
408	2001:4860:4860::8888	REAL	2026-03-09 02:07:32.794671	3493	ping	1	t	\N
409	2001:4860:4860::8888	REAL	2026-03-09 02:22:32.340454	3058	ping	1	t	\N
410	2001:4860:4860::8888	REAL	2026-03-09 02:37:32.30352	3021	ping	1	t	\N
411	2001:4860:4860::8888	REAL	2026-03-09 02:52:32.30478	3021	ping	1	t	\N
412	2001:4860:4860::8888	REAL	2026-03-09 03:07:32.881038	3590	ping	1	t	\N
413	2001:4860:4860::8888	REAL	2026-03-09 03:22:47.053299	3220	ping	1	t	\N
414	2001:4860:4860::8888	REAL	2026-03-09 03:37:46.889118	3046	ping	1	t	\N
415	2001:4860:4860::8888	REAL	2026-03-09 03:52:47.819178	3977	ping	1	t	\N
416	2001:4860:4860::8888	REAL	2026-03-09 04:07:47.523329	3688	ping	1	t	\N
417	2001:4860:4860::8888	REAL	2026-03-09 04:22:45.670464	3023	ping	1	t	\N
418	2001:4860:4860::8888	REAL	2026-03-09 04:23:15.756021	3775	ping	1	t	\N
419	2001:4860:4860::8888	REAL	2026-03-09 04:23:47.736385	3514	ping	1	t	\N
420	2001:4860:4860::8888	REAL	2026-03-09 04:24:43.986594	3074	ping	1	t	\N
421	2001:4860:4860::8888	REAL	2026-03-09 04:25:26.860788	4086	ping	1	t	\N
422	2001:4860:4860::8888	REAL	2026-03-09 04:25:57.604583	3043	ping	1	t	\N
423	2001:4860:4860::8888	REAL	2026-03-09 04:33:41.749346	3074	ping	1	t	\N
424	2001:4860:4860::8888	REAL	2026-03-09 04:34:46.456942	3048	ping	1	t	\N
425	2001:4860:4860::8888	REAL	2026-03-09 04:40:00.208233	4126	ping	1	t	\N
426	2001:4860:4860::8888	REAL	2026-03-09 04:40:22.084761	3090	ping	1	t	\N
427	2001:4860:4860::8888	REAL	2026-03-09 04:49:22.283281	3727	ping	1	t	\N
428	2001:4860:4860::8888	REAL	2026-03-09 05:04:22.418533	3915	ping	1	t	\N
429	2001:4860:4860::8888	REAL	2026-03-09 05:19:22.124488	3619	ping	1	t	\N
430	2001:4860:4860::8888	REAL	2026-03-09 05:34:21.579897	3070	ping	1	t	\N
431	2001:4860:4860::8888	REAL	2026-03-09 05:49:21.740874	3234	ping	1	t	\N
432	2001:4860:4860::8888	REAL	2026-03-09 06:04:21.575761	3062	ping	1	t	\N
433	2001:4860:4860::8888	REAL	2026-03-09 06:19:22.601316	4096	ping	1	t	\N
434	2001:4860:4860::8888	REAL	2026-03-09 06:34:21.919927	3406	ping	1	t	\N
435	2001:4860:4860::8888	REAL	2026-03-09 06:34:54.493098	3310	ping	1	t	\N
436	2001:4860:4860::8888	REAL	2026-03-09 06:35:14.077355	3068	ping	1	t	\N
437	2001:4860:4860::8888	REAL	2026-03-09 06:35:45.906217	3035	ping	1	t	\N
438	2001:4860:4860::8888	REAL	2026-03-09 06:47:24.028014	3046	ping	1	t	\N
439	2001:4860:4860::8888	REAL	2026-03-09 07:01:06.542241	3720	ping	1	t	\N
440	2001:4860:4860::8888	REAL	2026-03-09 07:35:50.84194	3845	ping	1	t	\N
441	2001:4860:4860::8888	REAL	2026-03-09 07:42:34.769657	3321	ping	1	t	\N
442	2001:4860:4860::8888	REAL	2026-03-09 08:20:36.959947	4000	ping	1	t	\N
443	2001:4860:4860::8888	REAL	2026-03-09 08:35:36.523161	3561	ping	1	t	\N
444	2001:4860:4860::8888	REAL	2026-03-09 08:49:30.328926	3068	ping	1	t	\N
445	2001:4860:4860::8888	REAL	2026-03-09 08:51:35.786196	3049	ping	1	t	\N
446	2001:4860:4860::8888	REAL	2026-03-09 08:53:21.90649	3074	ping	1	t	\N
447	2001:4860:4860::8888	REAL	2026-03-09 09:05:45.841196	3234	ping	1	t	\N
448	2001:4860:4860::8888	REAL	2026-03-09 09:12:56.240342	3024	ping	1	t	\N
449	2001:4860:4860::8888	REAL	2026-03-09 09:17:33.190679	3064	ping	1	t	\N
450	2001:4860:4860::8888	REAL	2026-03-09 09:21:33.785778	4010	ping	1	t	\N
451	2001:4860:4860::8888	REAL	2026-03-09 09:29:58.982484	3049	ping	1	t	\N
452	2001:4860:4860::8888	REAL	2026-03-09 09:32:18.103378	3513	ping	1	t	\N
453	2001:4860:4860::8888	REAL	2026-03-09 09:33:27.455382	3634	ping	1	t	\N
454	2001:4860:4860::8888	REAL	2026-03-09 09:50:40.98172	3661	ping	1	t	\N
455	2001:4860:4860::8888	REAL	2026-03-09 10:16:03.628586	3751	ping	1	t	\N
456	2001:4860:4860::8888	REAL	2026-03-09 10:49:18.310205	4464	ping	1	t	\N
457	2001:4860:4860::8888	REAL	2026-03-09 11:04:20.790055	4268	ping	1	t	\N
458	2001:4860:4860::8888	REAL	2026-03-09 11:19:19.588547	3052	ping	1	t	\N
459	2001:4860:4860::8888	REAL	2026-03-09 11:34:19.575425	3050	ping	1	t	\N
460	2001:4860:4860::8888	REAL	2026-03-09 11:49:19.614657	3088	ping	1	t	\N
461	2001:4860:4860::8888	REAL	2026-03-09 12:04:19.580468	3055	ping	1	t	\N
462	2001:4860:4860::8888	REAL	2026-03-09 12:19:19.539474	3006	ping	1	t	\N
463	2001:4860:4860::8888	REAL	2026-03-09 12:34:19.718726	3190	ping	1	t	\N
464	2001:4860:4860::8888	REAL	2026-03-09 14:12:21.022137	3872	ping	1	t	\N
465	2001:4860:4860::8888	REAL	2026-03-09 15:17:22.332285	3283	ping	1	t	\N
466	2001:4860:4860::8888	REAL	2026-03-09 15:21:31.548298	3170	ping	1	t	\N
467	2001:4860:4860::8888	REAL	2026-03-09 15:28:23.898294	3931	ping	1	t	\N
468	2001:4860:4860::8888	REAL	2026-03-09 15:31:26.052155	3838	ping	1	t	\N
469	2001:4860:4860::8888	REAL	2026-03-09 15:46:25.384199	3488	ping	1	t	\N
470	2001:4860:4860::8888	REAL	2026-03-09 16:02:03.110038	3759	ping	1	t	\N
471	2001:4860:4860::8888	REAL	2026-03-09 16:03:47.924071	3234	ping	1	t	\N
472	2001:4860:4860::8888	REAL	2026-03-09 16:08:28.001536	3192	ping	1	t	\N
473	2001:4860:4860::8888	REAL	2026-03-09 16:23:27.77938	2971	ping	1	t	\N
474	2001:4860:4860::8888	REAL	2026-03-09 16:38:27.825069	2990	ping	1	t	\N
475	2001:4860:4860::8888	REAL	2026-03-09 16:53:28.193082	3386	ping	1	t	\N
476	2001:4860:4860::8888	REAL	2026-03-09 17:08:27.955061	3147	ping	1	t	\N
477	2001:4860:4860::8888	REAL	2026-03-09 17:23:27.807209	3000	ping	1	t	\N
478	2001:4860:4860::8888	REAL	2026-03-09 19:47:33.35797	3058	ping	1	t	\N
479	2001:4860:4860::8888	REAL	2026-03-09 20:02:33.291399	2995	ping	1	t	\N
480	2001:4860:4860::8888	REAL	2026-03-09 20:17:33.300035	3004	ping	1	t	\N
481	2001:4860:4860::8888	REAL	2026-03-09 20:32:33.337442	3042	ping	1	t	\N
482	2001:4860:4860::8888	REAL	2026-03-09 20:47:33.83647	3540	ping	1	t	\N
483	2001:4860:4860::8888	REAL	2026-03-09 21:02:33.308329	3011	ping	1	t	\N
484	2001:4860:4860::8888	REAL	2026-03-09 21:17:33.716296	3420	ping	1	t	\N
485	2001:4860:4860::8888	REAL	2026-03-10 06:05:49.470281	3213	ping	1	t	\N
486	2001:4860:4860::8888	REAL	2026-03-10 06:20:50.215507	3971	ping	1	t	\N
487	2001:4860:4860::8888	REAL	2026-03-10 07:27:20.933117	3595	ping	1	t	\N
488	2001:4860:4860::8888	REAL	2026-03-10 07:42:20.575589	3209	ping	1	t	\N
489	2001:4860:4860::8888	REAL	2026-03-10 07:57:20.983966	3644	ping	1	t	\N
490	2001:4860:4860::8888	REAL	2026-03-10 08:12:20.670804	3332	ping	1	t	\N
491	2001:4860:4860::8888	REAL	2026-03-10 08:27:20.813967	3476	ping	1	t	\N
492	2001:4860:4860::8888	REAL	2026-03-10 08:42:20.979298	3641	ping	1	t	\N
493	2001:4860:4860::8888	REAL	2026-03-10 08:57:21.038931	3679	ping	1	t	\N
494	2001:4860:4860::8888	REAL	2026-03-10 09:12:21.085854	3739	ping	1	t	\N
495	2001:4860:4860::8888	REAL	2026-03-10 09:27:20.560823	3219	ping	1	t	\N
496	2001:4860:4860::8888	REAL	2026-03-10 09:42:20.868092	3527	ping	1	t	\N
497	2001:4860:4860::8888	REAL	2026-03-10 09:57:20.775435	3436	ping	1	t	\N
498	2001:4860:4860::8888	REAL	2026-03-10 10:12:20.705756	3364	ping	1	t	\N
499	2001:4860:4860::8888	REAL	2026-03-10 10:27:21.262912	3921	ping	1	t	\N
500	FALLBACK	FALLBACK	2026-03-10 11:40:38.087202	56	ping	0	f	I/O error on POST request for "https://api.globalping.io/v1/measurements": api.globalping.io
501	FALLBACK	FALLBACK	2026-03-10 11:55:38.032012	3	ping	0	f	I/O error on POST request for "https://api.globalping.io/v1/measurements": api.globalping.io
502	FALLBACK	FALLBACK	2026-03-11 11:41:21.540321	342	ping	0	f	I/O error on POST request for "https://api.globalping.io/v1/measurements": La red es inaccesible
503	FALLBACK	FALLBACK	2026-03-11 12:40:29.43809	8	ping	0	f	I/O error on POST request for "https://api.globalping.io/v1/measurements": api.globalping.io
504	8.8.8.8	REAL_REGIONAL	2026-03-13 10:30:05.604434	53772	ping	5	t	\N
505	8.8.8.8	REAL	2026-03-13 10:44:23.981042	12183	ping	1	t	\N
506	8.8.8.8	REAL	2026-03-13 11:18:04.268556	4118	ping	1	t	\N
507	8.8.8.8	REAL	2026-03-13 11:19:34.610085	4275	ping	1	t	\N
508	8.8.8.8	REAL	2026-03-13 11:20:25.119961	3259	ping	1	t	\N
509	8.8.8.8	REAL	2026-03-13 11:25:17.527803	35905	ping	1	t	\N
510	8.8.8.8	REAL	2026-03-13 11:25:36.928223	8359	ping	1	t	\N
511	8.8.8.8	REAL_REGIONAL	2026-03-13 11:41:18.071358	49500	ping	2	t	\N
512	8.8.8.8	REAL_REGIONAL	2026-03-13 11:56:13.479954	44908	ping	1	t	\N
513	8.8.8.8	REAL_REGIONAL	2026-03-13 11:57:44.618241	19399	ping	5	t	\N
514	8.8.8.8	REAL	2026-03-13 12:12:36.523158	11305	ping	1	t	\N
515	8.8.8.8	REAL	2026-03-13 12:26:15.744221	4579	ping	1	t	\N
516	8.8.8.8	REAL	2026-03-13 12:41:17.668684	6521	ping	1	t	\N
517	8.8.8.8	REAL	2026-03-13 12:57:39.750033	4152	ping	1	t	\N
518	8.8.8.8	REAL	2026-03-13 13:51:50.550428	7656	ping	1	t	\N
519	8.8.8.8	REAL	2026-03-13 13:57:50.268666	4558	ping	1	t	\N
520	8.8.8.8	REAL	2026-03-13 14:12:49.945273	4243	ping	1	t	\N
521	FALLBACK	FALLBACK	2026-03-13 14:30:05.858152	140128	ping	0	f	I/O error on POST request for "https://api.globalping.io/v1/measurements": api.globalping.io
522	FALLBACK	FALLBACK	2026-03-13 14:45:05.825109	140123	ping	0	f	I/O error on POST request for "https://api.globalping.io/v1/measurements": api.globalping.io
523	FALLBACK	FALLBACK	2026-03-13 15:00:05.739103	140037	ping	0	f	I/O error on POST request for "https://api.globalping.io/v1/measurements": api.globalping.io
524	FALLBACK	FALLBACK	2026-03-13 15:15:05.825103	140123	ping	0	f	I/O error on POST request for "https://api.globalping.io/v1/measurements": api.globalping.io
525	FALLBACK	FALLBACK	2026-03-13 15:29:45.793552	120091	ping	0	f	I/O error on POST request for "https://api.globalping.io/v1/measurements": api.globalping.io
526	FALLBACK	FALLBACK	2026-03-13 15:45:05.818096	140116	ping	0	f	I/O error on POST request for "https://api.globalping.io/v1/measurements": api.globalping.io
527	FALLBACK	FALLBACK	2026-03-13 16:00:05.825029	140123	ping	0	f	I/O error on POST request for "https://api.globalping.io/v1/measurements": api.globalping.io
528	FALLBACK	FALLBACK	2026-03-13 16:15:05.820699	140118	ping	0	f	I/O error on POST request for "https://api.globalping.io/v1/measurements": api.globalping.io
529	FALLBACK	FALLBACK	2026-03-13 16:27:45.705036	3	ping	0	f	I/O error on POST request for "https://api.globalping.io/v1/measurements": api.globalping.io
530	8.8.8.8	REAL	2026-03-13 16:42:49.081079	3379	ping	1	t	\N
531	8.8.8.8	REAL	2026-03-13 16:57:49.902272	4200	ping	1	t	\N
532	8.8.8.8	REAL	2026-03-13 17:12:49.070426	3368	ping	1	t	\N
533	8.8.8.8	REAL	2026-03-13 17:27:49.589549	3887	ping	1	t	\N
534	8.8.8.8	REAL	2026-03-13 17:42:49.17919	3477	ping	1	t	\N
535	8.8.8.8	REAL	2026-03-13 17:57:49.286478	3583	ping	1	t	\N
536	8.8.8.8	REAL	2026-03-13 18:12:49.077445	3374	ping	1	t	\N
537	8.8.8.8	REAL	2026-03-13 18:27:48.964228	3262	ping	1	t	\N
538	8.8.8.8	REAL	2026-03-13 18:42:49.278171	3576	ping	1	t	\N
539	8.8.8.8	REAL	2026-03-13 18:57:48.756718	3054	ping	1	t	\N
540	8.8.8.8	REAL	2026-03-13 19:02:42.759715	2994	ping	1	t	\N
541	8.8.8.8	REAL	2026-03-13 19:05:14.852482	3470	ping	1	t	\N
542	8.8.8.8	REAL	2026-03-13 19:20:14.251499	2922	ping	1	t	\N
543	8.8.8.8	REAL	2026-03-13 19:25:56.269609	3347	ping	1	t	\N
\.


--
-- TOC entry 5265 (class 0 OID 23977)
-- Dependencies: 309
-- Data for Name: prioridad; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.prioridad (id_prioridad, descripcion, nombre, id_item) FROM stdin;
1	Seed prioridad: MEDIA	Media	11
2	Seed prioridad: PRIORIDAD_ULTRA	ULTRA URGENTE	39
3	Seed prioridad: ALTA	Alta	12
4	Seed prioridad: BAJA	Baja	10
5	Seed prioridad: CRITICA	Crítica	13
\.


--
-- TOC entry 5267 (class 0 OID 23986)
-- Dependencies: 311
-- Data for Name: problema; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.problema (id_problema, nombre, descripcion, nivel_criticidad, activo, fecha_creacion, id_categoria, id_catalogo_item_estado, id_prioridad, id_empresa) FROM stdin;
21	Sin conexión a internet	El cliente no tiene acceso a internet	3	t	2026-03-09 03:31:27.764978	1	1	1	1
22	Internet lento	Velocidad de internet inferior a lo contratado	2	t	2026-03-09 03:31:27.764978	1	1	2	1
23	Cortes intermitentes	El internet se cae constantemente	2	t	2026-03-09 03:31:27.764978	1	1	2	1
24	Router no enciende	El router no prende o no recibe energía	3	t	2026-03-09 03:31:27.764978	2	1	1	1
25	Router quemado	Equipo presenta humo o daño físico	3	t	2026-03-09 03:31:27.764978	2	1	1	1
26	Configuración incorrecta	Router mal configurado	2	t	2026-03-09 03:31:27.764978	3	1	2	1
27	WiFi hackeado	Usuarios desconocidos conectados a la red	3	t	2026-03-09 03:31:27.764978	3	1	1	1
28	Dispositivo no conecta	Laptop o celular no detecta la red	2	t	2026-03-09 03:31:27.764978	4	1	2	1
29	Problema de cableado	Cable dañado o desconectado	3	t	2026-03-09 03:31:27.764978	1	1	1	1
30	Actualización firmware router	Router necesita actualización	1	t	2026-03-09 03:31:27.764978	2	1	3	1
31	Pérdida de paquetes	La conexión presenta pérdida de paquetes en pruebas de red	2	t	2026-03-09 03:31:37.462729	1	1	2	1
32	Latencia alta	El tiempo de respuesta de la red es muy alto	2	t	2026-03-09 03:31:37.462729	1	1	2	1
33	Red saturada por dispositivos	Demasiados dispositivos conectados al router	2	t	2026-03-09 03:31:37.462729	1	1	2	1
34	IP en conflicto	Dos dispositivos usan la misma dirección IP	2	t	2026-03-09 03:31:37.462729	3	1	2	1
35	DNS no responde	Servidor DNS no responde correctamente	2	t	2026-03-09 03:31:37.462729	3	1	2	1
36	Router reinicia solo	El equipo se reinicia constantemente	3	t	2026-03-09 03:31:37.462729	2	1	1	1
37	Sobrecalentamiento router	Router se calienta demasiado y falla	3	t	2026-03-09 03:31:37.462729	2	1	1	1
38	Puerto LAN sin señal	Puerto ethernet no transmite datos	2	t	2026-03-09 03:31:37.462729	1	1	2	1
39	Cable de red suelto	Cable de red mal conectado	1	t	2026-03-09 03:31:37.462729	1	1	3	1
40	Cable ethernet dañado	Cable ethernet roto o defectuoso	2	t	2026-03-09 03:31:37.462729	1	1	2	1
41	Interferencia señal WiFi	Otros dispositivos interfieren con señal	2	t	2026-03-09 03:31:37.462729	1	1	2	1
42	Configuración NAT incorrecta	Problema en traducción de direcciones	2	t	2026-03-09 03:31:37.462729	3	1	2	1
43	Problema con DHCP	Servidor DHCP no asigna direcciones IP	2	t	2026-03-09 03:31:37.462729	3	1	2	1
44	Red WiFi oculta	Red no visible para dispositivos	1	t	2026-03-09 03:31:37.462729	3	1	3	1
45	Bloqueo por control parental	Restricciones bloquean acceso	1	t	2026-03-09 03:31:37.462729	2	1	3	1
46	Puerto bloqueado	Puerto necesario para aplicación bloqueado	2	t	2026-03-09 03:31:37.462729	3	1	2	1
47	Problema en switch	Switch no transmite paquetes correctamente	3	t	2026-03-09 03:31:37.462729	1	1	1	1
48	Switch sobrecargado	Demasiados dispositivos conectados al switch	2	t	2026-03-09 03:31:37.462729	1	1	2	1
49	Firmware corrupto	Firmware del router dañado	3	t	2026-03-09 03:31:37.462729	2	1	1	1
50	Actualización fallida	Error durante actualización del equipo	2	t	2026-03-09 03:31:37.462729	2	1	2	1
51	Error autenticación WiFi	Contraseña incorrecta o error autenticación	2	t	2026-03-09 03:31:37.462729	1	1	2	1
52	Red no obtiene IP	Dispositivo no recibe IP automáticamente	2	t	2026-03-09 03:31:37.462729	3	1	2	1
53	Puerto WAN sin conexión	Router no detecta conexión del proveedor	3	t	2026-03-09 03:31:37.462729	1	1	1	1
54	Problema firewall router	Firewall bloquea tráfico legítimo	2	t	2026-03-09 03:31:37.462729	3	1	2	1
55	Problema VLAN	Configuración VLAN incorrecta	2	t	2026-03-09 03:31:37.462729	3	1	2	1
56	Router sin firmware	Router perdió sistema interno	3	t	2026-03-09 03:31:37.462729	2	1	1	1
57	Error en autenticación PPPoE	Router no autentica con proveedor	3	t	2026-03-09 03:31:37.462729	1	1	1	1
58	Problema balanceo carga	Balanceo de red incorrecto	2	t	2026-03-09 03:31:37.462729	3	1	2	1
59	Configuración proxy incorrecta	Proxy mal configurado	2	t	2026-03-09 03:31:37.462729	3	1	2	1
60	Problema red mesh	Red mesh no sincroniza nodos	2	t	2026-03-09 03:31:37.462729	1	1	2	1
\.


--
-- TOC entry 5269 (class 0 OID 23998)
-- Dependencies: 313
-- Data for Name: sla_ticket; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.sla_ticket (id_sla, nombre, descripcion, tiempo_respuesta_min, tiempo_solucion_min, aplica_prioridad, activo, fecha_creacion, id_empresa) FROM stdin;
1	SLA Estándar	Resp 2h / Sol 24h	120	1440	\N	t	2026-02-28 22:07:09.921828	1
\.


--
-- TOC entry 5271 (class 0 OID 24011)
-- Dependencies: 315
-- Data for Name: solucion_ticket; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.solucion_ticket (id_solucion, id_ticket, descripcion_solucion, fue_resuelto, fecha_solucion, id_usuario_tecnico) FROM stdin;
\.


--
-- TOC entry 5242 (class 0 OID 23806)
-- Dependencies: 282
-- Data for Name: ticket; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.ticket (id_ticket, asunto, descripcion, fecha_creacion, fecha_actualizacion, id_servicio, id_sucursal, id_sla, id_estado_item, id_prioridad_item, id_categoria_item, id_usuario_creador, id_usuario_asignado, id_cliente, fecha_cierre, impacto, urgencia, puntaje_prioridad, calificacion_satisfaccion, comentario_calificacion, id_problema) FROM stdin;
12	Sin señal en el servicio de televisión	Desde el día de hoy en la mañana el servicio de televisión no presenta señal. En la pantalla aparece el mensaje “Sin señal” y no se visualiza ningún canal.\n\nEl internet funciona con normalidad, pero el decodificador parece no recibir señal. Verifiqué que los cables HDMI y coaxial estén correctamente conectados y reinicié tanto el televisor como el decodificador, pero el problema continúa.\n\nSolicito por favor la revisión del equipo o validación del estado del servicio para restablecer la señal lo antes posible.	2026-02-27 10:49:04.316933	2026-03-02 19:49:02.725448	5	2	1	8	10	16	4	7	1	2026-03-02 19:49:02.721195	\N	\N	\N	5	\N	\N
3	TENGO TENGO TENGO TENGO	TENGO TENGOTENGO TENGOTENGO TENGOTENGO TENGOTENGO TENGO	2026-02-25 12:23:45.421804	2026-02-25 12:30:36.858663	4	3	1	5	11	14	8	10	4	\N	\N	\N	\N	\N	\N	\N
10	INSIDENCIA SOBRE MI VAINA	asdasdsadasdasdasdasdasda	2026-02-25 18:09:24.948352	2026-02-25 18:16:24.828277	1	1	1	8	10	14	2	7	2	2026-02-25 18:16:24.825773	\N	\N	\N	\N	\N	\N
1	Falla total de internet - Luz roja parpadeando	Desde hace dos horas el módem tiene la luz de LOS en color rojo. Ya intenté desconectarlo de la corriente y volverlo a conectar pero el problema persiste. No tengo navegación en ningún dispositivo.	2026-02-23 08:40:46.369847	2026-02-26 16:33:07.99939	2	2	1	5	10	14	4	10	1	\N	\N	\N	\N	\N	\N	\N
14	No tengo conexión a internet desde ayer en la noche	Tengo un pequeño problema al querer ver la TV y es que me sale que no tengo señal	2026-03-02 08:40:50.597389	2026-03-04 05:17:06.526991	5	2	\N	8	10	14	4	7	1	2026-03-04 05:14:51.949151	\N	\N	\N	5	Un excelente servicio	\N
18	HOLA PAPUCITO LINDO	PAPUCITO NO TENGO INTERNET AYUDAME PORFAVOR PIPIPI	2026-03-08 02:36:56.132534	2026-03-08 03:27:26.881239	1	1	\N	7	10	14	2	10	2	2026-03-08 03:27:26.853005	\N	\N	\N	\N	\N	\N
19	QUE TA CHENDO AYUDEME UWU	PAPU NO PUEDO VER VIDEOS EN YT ME MENCIONA QUE TENGO BLOQUEADO EL ACCESO PIPIPI	2026-03-08 03:28:57.914337	2026-03-08 03:32:51.241976	1	1	\N	45	10	14	2	10	2	\N	\N	\N	\N	\N	\N	\N
20	Papu sale humo de mi router	papu el hamster de mi router se murio y ahora sale humo pipipipi	2026-03-08 04:03:00.317021	2026-03-08 04:30:21.288705	1	1	\N	8	10	14	2	21	2	2026-03-08 04:30:21.256489	\N	\N	\N	\N	\N	\N
21	Mi cable de la instalacion se ha dañado	el cable que viene desde afuera se ha dañado y está colgando	2026-03-08 04:28:55.526345	2026-03-08 04:31:38.082779	1	1	\N	45	10	17	2	21	2	\N	\N	\N	\N	\N	\N	\N
2	No tengo conexión a internet desde ayer en la noche	Desde el día de ayer (21/02/2026) aproximadamente a las 21:30 no tengo conexión a internet.\nEl módem está encendido, pero la luz de "Internet" está en rojo y parpadeando constantemente.	2026-02-23 09:09:49.326989	2026-03-08 05:25:19.953658	2	2	1	8	13	14	4	7	1	2026-03-08 05:25:19.949339	\N	\N	\N	\N	\N	\N
5	GONTE GONTE GONTE GONTE	GONTE GONTE GONTE GONTE GONTE GONTE	2026-02-25 12:24:32.932886	2026-03-08 05:30:09.34904	4	3	1	8	10	14	8	7	4	2026-03-08 05:30:09.343234	\N	\N	\N	\N	\N	\N
8	HOLAAAAAAAAAA	HOLAAAAAAAAAA HOLAAAAAAAAAAHOLAAAAAAAAAAHOLAAAAAAAAAA	2026-02-25 14:37:55.420797	2026-03-08 05:30:25.048437	4	3	1	8	10	14	8	7	4	2026-03-08 05:30:25.042643	\N	\N	\N	\N	\N	\N
22	Fallas con el Internet	El problema empezó desde hace 2 días y sigue persistiendo  	2026-03-08 12:39:09.544955	2026-03-08 13:10:13.916727	2	2	\N	8	10	14	4	21	1	2026-03-08 13:10:13.889841	\N	\N	\N	\N	\N	\N
4	TENGO TENGO TENGO TENGO	TENGO TENGOTENGO TENGOTENGO TENGOTENGO TENGOTENGO TENGO	2026-02-25 12:23:47.203748	2026-03-08 05:30:54.972837	4	3	1	8	10	14	8	7	4	2026-03-08 05:30:54.967183	\N	\N	\N	\N	\N	\N
13	Sin señal en el servicio de televisión	Tengo un pequeño problema al querer ver la TV y es que me sale que no tengo señal	2026-03-02 08:28:23.955139	2026-03-08 05:31:13.348791	5	2	\N	8	10	14	4	7	1	2026-03-08 05:31:13.343996	\N	\N	\N	\N	\N	\N
15	Problemas de Latencia de Red	Tengo problemas de latencia de red cada 30 min	2026-03-02 09:17:36.425626	2026-03-08 05:31:20.153627	5	2	\N	8	10	14	4	7	1	2026-03-08 05:31:20.147763	\N	\N	\N	\N	\N	\N
16	Falla del servicio de internet	He vuelto a tener otro inconveniente con la red	2026-03-07 20:29:59.030573	2026-03-08 13:31:55.843811	2	2	\N	7	10	14	4	21	1	2026-03-08 13:25:30.750956	\N	\N	\N	5	Una resolución excelente	\N
27	aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa	aaaaaaaaaaaaaaaaaaaaaaaaaaaa	2026-03-09 11:53:11.948271	2026-03-09 11:56:27.540694	2	2	\N	8	10	14	4	7	1	2026-03-09 11:56:27.516326	\N	\N	\N	\N	\N	\N
6	TENGO MI FALLITO DE RED YA SABES	TENGO MI FALLITO DE RED YA SABESTENGO MI FALLITO DE RED YA SABESTENGO MI FALLITO DE RED YA SABES	2026-02-25 14:36:52.408091	2026-03-09 11:18:16.459621	4	3	1	8	10	14	8	7	4	2026-03-09 11:18:16.421367	\N	\N	\N	\N	\N	\N
11	PRUEBA PRUEBA PRUEBA PRUEBA PRUEBA PRUEBA PRUEBA PRUEBA	PRUEBA PRUEBAPRUEBA PRUEBAPRUEBA PRUEBA	2026-02-26 07:42:24.342737	2026-03-09 10:50:33.356666	4	3	1	8	10	14	8	7	4	2026-03-09 10:50:33.29764	\N	\N	\N	\N	\N	\N
26	no funciona mi pc  o es el internet barato que contrate	nocunfionaddddddddddds	2026-03-09 11:23:27.706118	2026-03-09 11:36:42.580182	5	2	\N	8	10	14	4	7	1	2026-03-09 11:36:21.725734	\N	\N	\N	3	tarda mucho	\N
7	TENGO MI FALLITO DE RED YA SABES	TENGO MI FALLITO DE RED YA SABESTENGO MI FALLITO DE RED YA SABESTENGO MI FALLITO DE RED YA SABES	2026-02-25 14:36:53.743848	2026-03-09 11:13:31.498854	4	3	1	8	10	14	8	7	4	2026-03-09 11:13:31.46416	\N	\N	\N	\N	\N	\N
9	INSIDENCIA SOBRE MI VAINA	asdasdasdsadasdasdasdasd	2026-02-25 18:08:55.147609	2026-03-09 11:15:41.618688	4	3	1	8	10	14	8	7	4	2026-03-09 11:15:41.592177	\N	\N	\N	\N	\N	\N
17	Falla del servicio de internet	He vuelto a tener problemas con la conexion 	2026-03-07 20:32:40.042876	2026-03-09 16:24:34.695126	1	1	\N	7	10	14	2	21	2	2026-03-09 16:24:34.670616	\N	\N	\N	\N	\N	\N
28	Fallas con el router - No hay internet 	Tengo problemas al tratar de conectarme a la red	2026-03-10 06:17:19.849493	2026-03-10 06:18:09.324362	2	2	\N	6	10	14	4	21	1	\N	\N	\N	\N	\N	\N	\N
29	Internet muy lento y con cortes frecuentes	tengo problemas con la conexion 	2026-03-10 11:40:55.92795	2026-03-10 11:42:57.270155	5	2	\N	5	10	14	4	23	1	\N	\N	\N	\N	\N	\N	\N
30	Internet muy lento y con cortes frecuentes	Problemas con la conexion	2026-03-10 11:45:40.653442	2026-03-10 11:52:18.877279	2	2	\N	8	10	14	4	21	1	2026-03-10 11:50:25.209111	\N	\N	\N	4	\N	\N
\.


--
-- TOC entry 5244 (class 0 OID 23839)
-- Dependencies: 286
-- Data for Name: visita_tecnica; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.visita_tecnica (id_visita, id_ticket, id_usuario_tecnico, id_empresa, fecha_visita, hora_inicio, hora_fin, id_catalogo_item_estado, reporte_visita, fecha_creacion, fecha_actualizacion) FROM stdin;
1	8	11	1	2026-02-26	18:40:00	19:40:00	41	\N	2026-02-25 15:34:48.079159	\N
3	10	11	1	2026-02-28	19:20:00	21:20:00	40	Hola soy angello	2026-02-25 18:15:11.22517	\N
4	8	11	1	2026-03-01	19:20:00	20:20:00	42	\N	2026-02-25 18:18:51.618675	\N
5	8	11	1	2026-03-01	13:10:00	16:25:00	40	Cambiar fibra òptica	2026-02-26 14:04:34.120704	2026-02-27 10:38:10.053633
6	20	21	1	2026-03-10	12:00:00	15:00:00	40	Revision exhaustiva de la instalación.	2026-03-08 04:19:45.695331	\N
7	21	21	1	2026-03-13	09:30:00	11:30:00	40	revision presencial.	2026-03-08 04:33:24.899725	\N
8	21	21	1	2026-03-19	19:20:00	23:20:00	40	Agendado	2026-03-08 16:18:05.872946	\N
9	21	21	1	2026-03-19	19:18:00	20:18:00	40	agenda	2026-03-08 16:18:46.25366	\N
\.


--
-- TOC entry 5243 (class 0 OID 23824)
-- Dependencies: 284
-- Data for Name: persona; Type: TABLE DATA; Schema: usuarios; Owner: postgres
--

COPY usuarios.persona (id_persona, cedula, nombre, apellido, celular, correo, fecha_nacimiento, direccion, id_canton, fecha_creacion, fecha_actualizacion, id_usuario, ruta_foto) FROM stdin;
2	1207445154	Elizabeth Anahis	Burgos Chilan	\N	elizabethanahisb@gmail.com	\N	\N	\N	2026-02-22 10:54:48.394042	2026-02-22 12:30:37.862134	2	\N
5	9999999999	Super	Administrador	0999999999	admin@sgim.com	\N	\N	\N	2026-02-22 20:31:01.463502	\N	6	\N
6	1250062336	Angel Daniel	Zambrano Yong	0995220227	azambranoy@uteq.edu.ec	\N	\N	\N	2026-02-25 12:08:45.194564	2026-02-25 12:13:04.427962	8	\N
8	1250062310	Manuel Manolo	Cruz Medrano	\N	zambranoyong1010@gmail.com	\N	\N	\N	2026-02-26 08:38:09.487756	2026-02-26 08:39:07.864473	12	\N
3	1207910165	Justyn Keith	Cruz Perez	\N	justyncruzperez@gmail.com	\N	\N	\N	2026-02-22 10:54:48.394042	2026-03-01 22:23:49.445955	13	\N
15	1203587489	Angel Agosti	Mendoza Bermello	0958745126	angelagosti1999@gmail.com	\N	\N	\N	2026-03-07 19:47:07.962033	\N	21	\N
16	0503658749	Roberto Carlos	Sosa Mendez	0958746512	amendozab5@uteq.edu.ec	\N	\N	\N	2026-03-08 10:42:18.694663	\N	22	\N
17	1206847596	Angel Daniel	Zambrano Yong	0987452168	azambranoy@uteq.edu.ec	\N	\N	\N	2026-03-08 16:07:52.501344	\N	23	\N
18	1205874962	Andy Emanuel	Mendoza Moreira	0985216487	zambranomourad@gmail.com	\N	\N	\N	2026-03-08 16:22:06.976011	\N	24	\N
19	1302547895	DIgna LIliana	Bermello Leones	0956487215	dignaliliana10@gmail.com	\N	\N	\N	2026-03-08 17:22:40.837353	\N	25	\N
20	1305487956	Kevin Patricio	Zambrano Yong	0958746215	agustinbermello799@gmail.com	\N	\N	\N	2026-03-08 17:40:11.809964	\N	26	\N
1	0503360398	Angello Agustin	Mendoza Bermello	0963136286	angellomendoza46@gmail.com	\N	\N	\N	2026-02-22 10:54:48.394042	2026-02-22 20:03:32.504119	4	\N
21	0985547886	Gregorio Alexander	Palma Bermello	0958822451	losesobrad2.1@gmail.com	\N	\N	\N	2026-03-13 13:58:21.998995	\N	28	\N
\.


--
-- TOC entry 5276 (class 0 OID 24026)
-- Dependencies: 320
-- Data for Name: rol; Type: TABLE DATA; Schema: usuarios; Owner: postgres
--

COPY usuarios.rol (id_rol, codigo, descripcion) FROM stdin;
1	CLIENTE	Usuario cliente del sistema
2	TECNICO	Empleado técnico
3	ADMIN_TECNICOS	Administrador de técnicos
4	ADMIN_MASTER	Administrador general del sistema
5	ADMIN_CONTRATOS	Administrador de contratos y acceso de empleados
\.


--
-- TOC entry 5277 (class 0 OID 24033)
-- Dependencies: 321
-- Data for Name: rol_bd; Type: TABLE DATA; Schema: usuarios; Owner: postgres
--

COPY usuarios.rol_bd (id_rol_bd, nombre, descripcion) FROM stdin;
1	rol_cliente	Rol base de datos clientes
2	rol_tecnico	Rol base de datos técnicos
3	rol_admin_tecnicos	Rol BD administrador técnicos
4	rol_admin_master	Rol BD administrador master
5	rol_admin_contratos	Rol BD administrador contratos
\.


--
-- TOC entry 5199 (class 0 OID 23594)
-- Dependencies: 238
-- Data for Name: usuario; Type: TABLE DATA; Schema: usuarios; Owner: postgres
--

COPY usuarios.usuario (id_usuario, username, password_hash, primer_login, id_rol, fecha_creacion, fecha_actualizacion, id_empresa, id_catalogo_item_estado) FROM stdin;
10	aza	$2a$10$31ZZkoaZ9stog.hZ90NVMu3f67IZ7UQxch8pJtTJtGWjNO5FYKu/O	f	2	2026-02-25 12:29:53.929094	2026-02-25 12:30:13.940889	1	27
7	tecnico01	$2a$10$1WnPLfhgkNoQ29Caq9hwDu0iGm186wUyw7lonDkVZP/xZ2/PQvycS	f	2	2026-02-23 08:58:54.4776	2026-02-23 09:00:35.768315	1	27
2	eburgosc	$2a$10$PEbYXTN/uQaNKujO/o9Hx.I9SmZQDrxrvcdm/iYptWou1XeDthNzO	f	1	2026-02-22 12:30:37.808543	2026-02-26 07:47:52.544445	1	27
8	azambranoy	$2a$10$3dXvEbYOQNDOneJwRArYyejwrXbMn5Lp0FzqKpm.hqbHsiWQY5QvC	f	1	2026-02-25 12:11:27.164129	2026-02-26 07:54:53.857384	3	27
12	mcruzm	$2a$06$QFU4YWd6R9Wri0rhSNvV9OXlOKsKvkm1qDSquuD0mLw2CfXEG9Tjq	t	1	2026-02-26 08:39:07.853471	\N	3	27
13	jcruzp	$2a$06$9HeyG2ua.oPLUGLnStIEP.uGkLyPVLhgWfvDSNhRDsjXlJmsTKStq	t	1	2026-03-01 22:23:49.419828	\N	3	27
22	rsosam	$2a$10$SfmUl2GjU6pfcKrvuvV9q.xu43QVAC56Mgh8JPohvQE2GOYndAnUK	f	4	2026-03-08 10:43:18.588152	2026-03-08 11:00:16.659255	1	27
6	adminmaster_legacy_desactivado	$2a$06$KUSBFI.E1d/PpaKW/rDozumKoIcoyV4E.44mcuxmnCgMkoiwuoQYe	f	4	2026-02-22 20:31:01.463502	\N	1	2
23	azambranoy1	$2a$06$s2iwIyXVDneymqdFo.dwnOO4K0W2ltVNtkb8v62l8pWKDgo6ajYd6	t	2	2026-03-08 16:08:31.537191	\N	1	27
21	amendozab1	$2a$10$8QT5t14mjoIsBrFzq3g.se7XMPzw5uBfpUyRtWQs7nMZ/kzf5j2Nm	f	2	2026-03-07 19:56:34.756305	2026-03-08 16:56:06.471148	1	27
24	amendozam	$2a$10$nhlvrr82SakVOjViJhZt6OgJzox5rEkczD1lBht87V0O3Fut5qSGG	f	2	2026-03-08 16:23:42.229409	2026-03-08 17:08:34.741846	1	27
25	dbermellol	$2a$06$UCctNN0C36Jj0auJR9zXYuTFOlT.vcA/RORipZc4kVQO66WL3PoLC	t	2	2026-03-08 17:35:08.285084	\N	2	27
4	amendozab	$2a$10$yAQza49q8rWFip0um/dYEO3DNbjjZtE2vV0xQcfFlsHv36M9cQ9Wq	f	1	2026-02-22 19:45:13.203058	2026-03-13 11:22:19.961377	2	27
11	tecnicoadmin	$2a$10$pKe5IhDOMug5X0dd.syqaONl4BBz3n/ZEjKgntyUu8hcq.7vZbTh2	f	3	2026-02-25 14:16:34.950027	2026-03-13 12:27:06.627129	1	47
26	kzambranoy	$2a$06$uB84f2HJ6X4xPpBY9MWEieM9672Dmkd4qmNtQ0mND6/Q3cF3gGYpK	t	2	2026-03-08 17:40:47.370827	2026-03-13 12:28:26.257803	3	47
28	gpalmab	$2a$10$7ddU/dMkQVAiVibvqqcfhe0KJInpDWf9SntfqVs5JXqe5oMv.G0u6	f	5	2026-03-13 19:27:44.606846	2026-03-13 19:30:08.329607	\N	27
\.


--
-- TOC entry 5280 (class 0 OID 24042)
-- Dependencies: 324
-- Data for Name: usuario_bd; Type: TABLE DATA; Schema: usuarios; Owner: postgres
--

COPY usuarios.usuario_bd (id_usuario_bd, nombre, id_rol_bd, fecha_creacion, id_usuario) FROM stdin;
9	emp_1203587489_21	2	2026-03-08 10:25:02.160516	21
10	emp_0503658749_22	4	2026-03-08 10:43:18.588152	22
11	emp_1206847596_23	2	2026-03-08 16:08:31.537191	23
12	emp_1205874962_24	2	2026-03-08 16:23:42.229409	24
13	emp_1302547895_25	2	2026-03-08 17:35:08.285084	25
14	emp_1305487956_26	2	2026-03-08 17:40:47.370827	26
15	emp_0985547886_28	5	2026-03-13 19:27:44.606846	28
\.


--
-- TOC entry 5485 (class 0 OID 0)
-- Dependencies: 230
-- Name: auditoria_estado_ticket_id_auditoria_seq; Type: SEQUENCE SET; Schema: auditoria; Owner: postgres
--

SELECT pg_catalog.setval('auditoria.auditoria_estado_ticket_id_auditoria_seq', 33, true);


--
-- TOC entry 5486 (class 0 OID 0)
-- Dependencies: 232
-- Name: auditoria_evento_id_evento_seq; Type: SEQUENCE SET; Schema: auditoria; Owner: postgres
--

SELECT pg_catalog.setval('auditoria.auditoria_evento_id_evento_seq', 123, true);


--
-- TOC entry 5487 (class 0 OID 0)
-- Dependencies: 235
-- Name: auditoria_login_bd_id_auditoria_login_bd_seq; Type: SEQUENCE SET; Schema: auditoria; Owner: postgres
--

SELECT pg_catalog.setval('auditoria.auditoria_login_bd_id_auditoria_login_bd_seq', 1, false);


--
-- TOC entry 5488 (class 0 OID 0)
-- Dependencies: 236
-- Name: auditoria_login_id_login_seq; Type: SEQUENCE SET; Schema: auditoria; Owner: postgres
--

SELECT pg_catalog.setval('auditoria.auditoria_login_id_login_seq', 70, true);


--
-- TOC entry 5489 (class 0 OID 0)
-- Dependencies: 241
-- Name: catalogo_id_catalogo_seq; Type: SEQUENCE SET; Schema: catalogos; Owner: postgres
--

SELECT pg_catalog.setval('catalogos.catalogo_id_catalogo_seq', 17, true);


--
-- TOC entry 5490 (class 0 OID 0)
-- Dependencies: 242
-- Name: catalogo_item_id_item_seq; Type: SEQUENCE SET; Schema: catalogos; Owner: postgres
--

SELECT pg_catalog.setval('catalogos.catalogo_item_id_item_seq', 113, true);


--
-- TOC entry 5491 (class 0 OID 0)
-- Dependencies: 244
-- Name: canton_id_canton_seq; Type: SEQUENCE SET; Schema: clientes; Owner: postgres
--

SELECT pg_catalog.setval('clientes.canton_id_canton_seq', 1, false);


--
-- TOC entry 5492 (class 0 OID 0)
-- Dependencies: 246
-- Name: ciudad_id_ciudad_seq; Type: SEQUENCE SET; Schema: clientes; Owner: postgres
--

SELECT pg_catalog.setval('clientes.ciudad_id_ciudad_seq', 25, true);


--
-- TOC entry 5493 (class 0 OID 0)
-- Dependencies: 248
-- Name: cliente_id_cliente_seq; Type: SEQUENCE SET; Schema: clientes; Owner: postgres
--

SELECT pg_catalog.setval('clientes.cliente_id_cliente_seq', 5, true);


--
-- TOC entry 5494 (class 0 OID 0)
-- Dependencies: 250
-- Name: documento_cliente_id_documento_seq; Type: SEQUENCE SET; Schema: clientes; Owner: postgres
--

SELECT pg_catalog.setval('clientes.documento_cliente_id_documento_seq', 2, true);


--
-- TOC entry 5495 (class 0 OID 0)
-- Dependencies: 252
-- Name: pais_id_pais_seq; Type: SEQUENCE SET; Schema: clientes; Owner: postgres
--

SELECT pg_catalog.setval('clientes.pais_id_pais_seq', 1, false);


--
-- TOC entry 5496 (class 0 OID 0)
-- Dependencies: 254
-- Name: tipo_documento_id_tipo_documento_seq; Type: SEQUENCE SET; Schema: clientes; Owner: postgres
--

SELECT pg_catalog.setval('clientes.tipo_documento_id_tipo_documento_seq', 7, true);


--
-- TOC entry 5497 (class 0 OID 0)
-- Dependencies: 256
-- Name: area_id_area_seq; Type: SEQUENCE SET; Schema: empleados; Owner: postgres
--

SELECT pg_catalog.setval('empleados.area_id_area_seq', 7, true);


--
-- TOC entry 5498 (class 0 OID 0)
-- Dependencies: 258
-- Name: cargo_id_cargo_seq; Type: SEQUENCE SET; Schema: empleados; Owner: postgres
--

SELECT pg_catalog.setval('empleados.cargo_id_cargo_seq', 8, true);


--
-- TOC entry 5499 (class 0 OID 0)
-- Dependencies: 260
-- Name: documento_empleado_id_documento_seq; Type: SEQUENCE SET; Schema: empleados; Owner: postgres
--

SELECT pg_catalog.setval('empleados.documento_empleado_id_documento_seq', 12, true);


--
-- TOC entry 5500 (class 0 OID 0)
-- Dependencies: 261
-- Name: empleado_id_empleado_seq; Type: SEQUENCE SET; Schema: empleados; Owner: postgres
--

SELECT pg_catalog.setval('empleados.empleado_id_empleado_seq', 16, true);


--
-- TOC entry 5501 (class 0 OID 0)
-- Dependencies: 264
-- Name: tipo_contrato_id_tipo_contrato_seq; Type: SEQUENCE SET; Schema: empleados; Owner: postgres
--

SELECT pg_catalog.setval('empleados.tipo_contrato_id_tipo_contrato_seq', 5, true);


--
-- TOC entry 5502 (class 0 OID 0)
-- Dependencies: 266
-- Name: documento_empresa_id_documento_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.documento_empresa_id_documento_seq', 1, true);


--
-- TOC entry 5503 (class 0 OID 0)
-- Dependencies: 268
-- Name: empresa_id_empresa_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.empresa_id_empresa_seq', 5, true);


--
-- TOC entry 5504 (class 0 OID 0)
-- Dependencies: 271
-- Name: servicio_id_servicio_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.servicio_id_servicio_seq', 5, true);


--
-- TOC entry 5505 (class 0 OID 0)
-- Dependencies: 273
-- Name: sucursal_id_sucursal_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.sucursal_id_sucursal_seq', 3, true);


--
-- TOC entry 5506 (class 0 OID 0)
-- Dependencies: 275
-- Name: cola_correo_id_correo_seq; Type: SEQUENCE SET; Schema: notificaciones; Owner: postgres
--

SELECT pg_catalog.setval('notificaciones.cola_correo_id_correo_seq', 69, true);


--
-- TOC entry 5507 (class 0 OID 0)
-- Dependencies: 277
-- Name: notificacion_web_id_notificacion_seq; Type: SEQUENCE SET; Schema: notificaciones; Owner: postgres
--

SELECT pg_catalog.setval('notificaciones.notificacion_web_id_notificacion_seq', 86, true);


--
-- TOC entry 5508 (class 0 OID 0)
-- Dependencies: 279
-- Name: configuracion_reporte_id_reporte_seq; Type: SEQUENCE SET; Schema: reportes; Owner: postgres
--

SELECT pg_catalog.setval('reportes.configuracion_reporte_id_reporte_seq', 1, true);


--
-- TOC entry 5509 (class 0 OID 0)
-- Dependencies: 281
-- Name: historial_generacion_id_generacion_seq; Type: SEQUENCE SET; Schema: reportes; Owner: postgres
--

SELECT pg_catalog.setval('reportes.historial_generacion_id_generacion_seq', 1, false);


--
-- TOC entry 5510 (class 0 OID 0)
-- Dependencies: 290
-- Name: asignacion_id_asignacion_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.asignacion_id_asignacion_seq', 49, true);


--
-- TOC entry 5511 (class 0 OID 0)
-- Dependencies: 292
-- Name: categoria_id_categoria_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.categoria_id_categoria_seq', 4, true);


--
-- TOC entry 5512 (class 0 OID 0)
-- Dependencies: 294
-- Name: comentario_ticket_id_comentario_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.comentario_ticket_id_comentario_seq', 75, true);


--
-- TOC entry 5513 (class 0 OID 0)
-- Dependencies: 296
-- Name: documento_ticket_id_documento_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.documento_ticket_id_documento_seq', 1, false);


--
-- TOC entry 5514 (class 0 OID 0)
-- Dependencies: 298
-- Name: historial_estado_id_historial_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.historial_estado_id_historial_seq', 154, true);


--
-- TOC entry 5515 (class 0 OID 0)
-- Dependencies: 300
-- Name: informe_trabajo_tecnico_id_informe_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.informe_trabajo_tecnico_id_informe_seq', 25, true);


--
-- TOC entry 5516 (class 0 OID 0)
-- Dependencies: 302
-- Name: inventario_id_item_inventario_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.inventario_id_item_inventario_seq', 32, true);


--
-- TOC entry 5517 (class 0 OID 0)
-- Dependencies: 304
-- Name: inventario_usado_ticket_id_uso_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.inventario_usado_ticket_id_uso_seq', 25, true);


--
-- TOC entry 5518 (class 0 OID 0)
-- Dependencies: 306
-- Name: network_probe_result_id_result_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.network_probe_result_id_result_seq', 542, true);


--
-- TOC entry 5519 (class 0 OID 0)
-- Dependencies: 308
-- Name: network_probe_run_id_run_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.network_probe_run_id_run_seq', 543, true);


--
-- TOC entry 5520 (class 0 OID 0)
-- Dependencies: 310
-- Name: prioridad_id_prioridad_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.prioridad_id_prioridad_seq', 5, true);


--
-- TOC entry 5521 (class 0 OID 0)
-- Dependencies: 312
-- Name: problema_id_problema_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.problema_id_problema_seq', 60, true);


--
-- TOC entry 5522 (class 0 OID 0)
-- Dependencies: 314
-- Name: sla_ticket_id_sla_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.sla_ticket_id_sla_seq', 1, true);


--
-- TOC entry 5523 (class 0 OID 0)
-- Dependencies: 316
-- Name: solucion_ticket_id_solucion_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.solucion_ticket_id_solucion_seq', 1, false);


--
-- TOC entry 5524 (class 0 OID 0)
-- Dependencies: 317
-- Name: ticket_id_ticket_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.ticket_id_ticket_seq', 30, true);


--
-- TOC entry 5525 (class 0 OID 0)
-- Dependencies: 318
-- Name: visita_tecnica_id_visita_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.visita_tecnica_id_visita_seq', 8, true);


--
-- TOC entry 5526 (class 0 OID 0)
-- Dependencies: 319
-- Name: persona_id_persona_seq; Type: SEQUENCE SET; Schema: usuarios; Owner: postgres
--

SELECT pg_catalog.setval('usuarios.persona_id_persona_seq', 21, true);


--
-- TOC entry 5527 (class 0 OID 0)
-- Dependencies: 322
-- Name: rol_bd_id_rol_bd_seq; Type: SEQUENCE SET; Schema: usuarios; Owner: postgres
--

SELECT pg_catalog.setval('usuarios.rol_bd_id_rol_bd_seq', 5, true);


--
-- TOC entry 5528 (class 0 OID 0)
-- Dependencies: 323
-- Name: rol_id_rol_seq; Type: SEQUENCE SET; Schema: usuarios; Owner: postgres
--

SELECT pg_catalog.setval('usuarios.rol_id_rol_seq', 5, true);


--
-- TOC entry 5529 (class 0 OID 0)
-- Dependencies: 325
-- Name: usuario_bd_id_usuario_bd_seq; Type: SEQUENCE SET; Schema: usuarios; Owner: postgres
--

SELECT pg_catalog.setval('usuarios.usuario_bd_id_usuario_bd_seq', 15, true);


--
-- TOC entry 5530 (class 0 OID 0)
-- Dependencies: 326
-- Name: usuario_id_usuario_seq; Type: SEQUENCE SET; Schema: usuarios; Owner: postgres
--

SELECT pg_catalog.setval('usuarios.usuario_id_usuario_seq', 28, true);


--
-- TOC entry 4772 (class 2606 OID 24098)
-- Name: auditoria_estado_ticket auditoria_estado_ticket_pkey; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT auditoria_estado_ticket_pkey PRIMARY KEY (id_auditoria);


--
-- TOC entry 4776 (class 2606 OID 24100)
-- Name: auditoria_evento auditoria_evento_pkey; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_evento
    ADD CONSTRAINT auditoria_evento_pkey PRIMARY KEY (id_evento);


--
-- TOC entry 4789 (class 2606 OID 24102)
-- Name: auditoria_login_bd auditoria_login_bd_pkey; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd
    ADD CONSTRAINT auditoria_login_bd_pkey PRIMARY KEY (id_auditoria_login_bd);


--
-- TOC entry 4784 (class 2606 OID 24104)
-- Name: auditoria_login auditoria_login_pkey; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login
    ADD CONSTRAINT auditoria_login_pkey PRIMARY KEY (id_login);


--
-- TOC entry 4791 (class 2606 OID 24106)
-- Name: catalogo_item catalogo_item_pkey; Type: CONSTRAINT; Schema: catalogos; Owner: postgres
--

ALTER TABLE ONLY catalogos.catalogo_item
    ADD CONSTRAINT catalogo_item_pkey PRIMARY KEY (id_item);


--
-- TOC entry 4799 (class 2606 OID 24108)
-- Name: catalogo catalogo_nombre_key; Type: CONSTRAINT; Schema: catalogos; Owner: postgres
--

ALTER TABLE ONLY catalogos.catalogo
    ADD CONSTRAINT catalogo_nombre_key UNIQUE (nombre);


--
-- TOC entry 4801 (class 2606 OID 24110)
-- Name: catalogo catalogo_pkey; Type: CONSTRAINT; Schema: catalogos; Owner: postgres
--

ALTER TABLE ONLY catalogos.catalogo
    ADD CONSTRAINT catalogo_pkey PRIMARY KEY (id_catalogo);


--
-- TOC entry 4803 (class 2606 OID 24112)
-- Name: canton canton_pkey; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.canton
    ADD CONSTRAINT canton_pkey PRIMARY KEY (id_canton);


--
-- TOC entry 4805 (class 2606 OID 24114)
-- Name: ciudad ciudad_pkey; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.ciudad
    ADD CONSTRAINT ciudad_pkey PRIMARY KEY (id_ciudad);


--
-- TOC entry 4813 (class 2606 OID 24116)
-- Name: documento_cliente documento_cliente_pkey; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.documento_cliente
    ADD CONSTRAINT documento_cliente_pkey PRIMARY KEY (id_documento);


--
-- TOC entry 4817 (class 2606 OID 24118)
-- Name: pais pais_nombre_key; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.pais
    ADD CONSTRAINT pais_nombre_key UNIQUE (nombre);


--
-- TOC entry 4819 (class 2606 OID 24120)
-- Name: pais pais_pkey; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.pais
    ADD CONSTRAINT pais_pkey PRIMARY KEY (id_pais);


--
-- TOC entry 4807 (class 2606 OID 24122)
-- Name: cliente pk_cliente; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.cliente
    ADD CONSTRAINT pk_cliente PRIMARY KEY (id_cliente);


--
-- TOC entry 4821 (class 2606 OID 24124)
-- Name: tipo_documento tipo_documento_codigo_key; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.tipo_documento
    ADD CONSTRAINT tipo_documento_codigo_key UNIQUE (codigo);


--
-- TOC entry 4823 (class 2606 OID 24126)
-- Name: tipo_documento tipo_documento_pkey; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.tipo_documento
    ADD CONSTRAINT tipo_documento_pkey PRIMARY KEY (id_tipo_documento);


--
-- TOC entry 4809 (class 2606 OID 24128)
-- Name: cliente uq_cliente_id_cliente; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.cliente
    ADD CONSTRAINT uq_cliente_id_cliente UNIQUE (id_cliente);


--
-- TOC entry 4811 (class 2606 OID 24130)
-- Name: cliente uq_cliente_persona; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.cliente
    ADD CONSTRAINT uq_cliente_persona UNIQUE (id_persona);


--
-- TOC entry 4815 (class 2606 OID 24132)
-- Name: documento_cliente uq_documento_cliente; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.documento_cliente
    ADD CONSTRAINT uq_documento_cliente UNIQUE (id_tipo_documento, numero_documento);


--
-- TOC entry 4825 (class 2606 OID 24134)
-- Name: area area_nombre_key; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.area
    ADD CONSTRAINT area_nombre_key UNIQUE (nombre);


--
-- TOC entry 4827 (class 2606 OID 24136)
-- Name: area area_pkey; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.area
    ADD CONSTRAINT area_pkey PRIMARY KEY (id_area);


--
-- TOC entry 4829 (class 2606 OID 24138)
-- Name: cargo cargo_nombre_key; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.cargo
    ADD CONSTRAINT cargo_nombre_key UNIQUE (nombre);


--
-- TOC entry 4831 (class 2606 OID 24140)
-- Name: cargo cargo_pkey; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.cargo
    ADD CONSTRAINT cargo_pkey PRIMARY KEY (id_cargo);


--
-- TOC entry 4833 (class 2606 OID 24142)
-- Name: documento_empleado documento_empleado_pkey; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.documento_empleado
    ADD CONSTRAINT documento_empleado_pkey PRIMARY KEY (id_documento);


--
-- TOC entry 4835 (class 2606 OID 24144)
-- Name: empleado pk_empleado; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT pk_empleado PRIMARY KEY (id_empleado);


--
-- TOC entry 4841 (class 2606 OID 24146)
-- Name: tipo_contrato tipo_contrato_nombre_key; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.tipo_contrato
    ADD CONSTRAINT tipo_contrato_nombre_key UNIQUE (nombre);


--
-- TOC entry 4843 (class 2606 OID 24148)
-- Name: tipo_contrato tipo_contrato_pkey; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.tipo_contrato
    ADD CONSTRAINT tipo_contrato_pkey PRIMARY KEY (id_tipo_contrato);


--
-- TOC entry 4837 (class 2606 OID 24150)
-- Name: empleado uq_empleado_id_empleado; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT uq_empleado_id_empleado UNIQUE (id_empleado);


--
-- TOC entry 4839 (class 2606 OID 24152)
-- Name: empleado uq_empleado_persona; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT uq_empleado_persona UNIQUE (id_persona);


--
-- TOC entry 4845 (class 2606 OID 24154)
-- Name: documento_empresa documento_empresa_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.documento_empresa
    ADD CONSTRAINT documento_empresa_pkey PRIMARY KEY (id_documento);


--
-- TOC entry 4849 (class 2606 OID 24156)
-- Name: empresa empresa_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.empresa
    ADD CONSTRAINT empresa_pkey PRIMARY KEY (id_empresa);


--
-- TOC entry 4851 (class 2606 OID 24158)
-- Name: empresa empresa_ruc_key; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.empresa
    ADD CONSTRAINT empresa_ruc_key UNIQUE (ruc);


--
-- TOC entry 4853 (class 2606 OID 24160)
-- Name: empresa_servicio empresa_servicio_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.empresa_servicio
    ADD CONSTRAINT empresa_servicio_pkey PRIMARY KEY (id_empresa, id_servicio);


--
-- TOC entry 4855 (class 2606 OID 24162)
-- Name: servicio servicio_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.servicio
    ADD CONSTRAINT servicio_pkey PRIMARY KEY (id_servicio);


--
-- TOC entry 4859 (class 2606 OID 24164)
-- Name: sucursal sucursal_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.sucursal
    ADD CONSTRAINT sucursal_pkey PRIMARY KEY (id_sucursal);


--
-- TOC entry 4857 (class 2606 OID 24166)
-- Name: servicio uk_5sp1r1csf8w09psuq7p8fatbs; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.servicio
    ADD CONSTRAINT uk_5sp1r1csf8w09psuq7p8fatbs UNIQUE (nombre);


--
-- TOC entry 4847 (class 2606 OID 24168)
-- Name: documento_empresa uq_documento_empresa; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.documento_empresa
    ADD CONSTRAINT uq_documento_empresa UNIQUE (id_tipo_documento, numero_documento);


--
-- TOC entry 4861 (class 2606 OID 24170)
-- Name: cola_correo cola_correo_pkey; Type: CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.cola_correo
    ADD CONSTRAINT cola_correo_pkey PRIMARY KEY (id_correo);


--
-- TOC entry 4865 (class 2606 OID 24172)
-- Name: notificacion_web notificacion_web_pkey; Type: CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.notificacion_web
    ADD CONSTRAINT notificacion_web_pkey PRIMARY KEY (id_notificacion);


--
-- TOC entry 4867 (class 2606 OID 24174)
-- Name: configuracion_reporte configuracion_reporte_codigo_unico_key; Type: CONSTRAINT; Schema: reportes; Owner: postgres
--

ALTER TABLE ONLY reportes.configuracion_reporte
    ADD CONSTRAINT configuracion_reporte_codigo_unico_key UNIQUE (codigo_unico);


--
-- TOC entry 4869 (class 2606 OID 24176)
-- Name: configuracion_reporte configuracion_reporte_pkey; Type: CONSTRAINT; Schema: reportes; Owner: postgres
--

ALTER TABLE ONLY reportes.configuracion_reporte
    ADD CONSTRAINT configuracion_reporte_pkey PRIMARY KEY (id_reporte);


--
-- TOC entry 4871 (class 2606 OID 24178)
-- Name: historial_generacion historial_generacion_pkey; Type: CONSTRAINT; Schema: reportes; Owner: postgres
--

ALTER TABLE ONLY reportes.historial_generacion
    ADD CONSTRAINT historial_generacion_pkey PRIMARY KEY (id_generacion);


--
-- TOC entry 4883 (class 2606 OID 24180)
-- Name: asignacion asignacion_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.asignacion
    ADD CONSTRAINT asignacion_pkey PRIMARY KEY (id_asignacion);


--
-- TOC entry 4886 (class 2606 OID 24182)
-- Name: categoria categoria_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.categoria
    ADD CONSTRAINT categoria_pkey PRIMARY KEY (id_categoria);


--
-- TOC entry 4890 (class 2606 OID 24184)
-- Name: comentario_ticket comentario_ticket_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket
    ADD CONSTRAINT comentario_ticket_pkey PRIMARY KEY (id_comentario);


--
-- TOC entry 4892 (class 2606 OID 24186)
-- Name: documento_ticket documento_ticket_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.documento_ticket
    ADD CONSTRAINT documento_ticket_pkey PRIMARY KEY (id_documento);


--
-- TOC entry 4894 (class 2606 OID 24188)
-- Name: historial_estado historial_estado_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT historial_estado_pkey PRIMARY KEY (id_historial);


--
-- TOC entry 4896 (class 2606 OID 24190)
-- Name: informe_trabajo_tecnico informe_trabajo_tecnico_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.informe_trabajo_tecnico
    ADD CONSTRAINT informe_trabajo_tecnico_pkey PRIMARY KEY (id_informe);


--
-- TOC entry 4898 (class 2606 OID 24192)
-- Name: inventario inventario_codigo_key; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.inventario
    ADD CONSTRAINT inventario_codigo_key UNIQUE (codigo);


--
-- TOC entry 4900 (class 2606 OID 24194)
-- Name: inventario inventario_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.inventario
    ADD CONSTRAINT inventario_pkey PRIMARY KEY (id_item_inventario);


--
-- TOC entry 4902 (class 2606 OID 24196)
-- Name: inventario_usado_ticket inventario_usado_ticket_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.inventario_usado_ticket
    ADD CONSTRAINT inventario_usado_ticket_pkey PRIMARY KEY (id_uso);


--
-- TOC entry 4904 (class 2606 OID 24198)
-- Name: network_probe_result network_probe_result_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.network_probe_result
    ADD CONSTRAINT network_probe_result_pkey PRIMARY KEY (id_result);


--
-- TOC entry 4906 (class 2606 OID 24200)
-- Name: network_probe_run network_probe_run_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.network_probe_run
    ADD CONSTRAINT network_probe_run_pkey PRIMARY KEY (id_run);


--
-- TOC entry 4908 (class 2606 OID 24202)
-- Name: prioridad prioridad_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.prioridad
    ADD CONSTRAINT prioridad_pkey PRIMARY KEY (id_prioridad);


--
-- TOC entry 4912 (class 2606 OID 24204)
-- Name: problema problema_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.problema
    ADD CONSTRAINT problema_pkey PRIMARY KEY (id_problema);


--
-- TOC entry 4914 (class 2606 OID 24206)
-- Name: sla_ticket sla_ticket_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.sla_ticket
    ADD CONSTRAINT sla_ticket_pkey PRIMARY KEY (id_sla);


--
-- TOC entry 4916 (class 2606 OID 24208)
-- Name: solucion_ticket solucion_ticket_id_ticket_key; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.solucion_ticket
    ADD CONSTRAINT solucion_ticket_id_ticket_key UNIQUE (id_ticket);


--
-- TOC entry 4918 (class 2606 OID 24210)
-- Name: solucion_ticket solucion_ticket_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.solucion_ticket
    ADD CONSTRAINT solucion_ticket_pkey PRIMARY KEY (id_solucion);


--
-- TOC entry 4873 (class 2606 OID 24212)
-- Name: ticket ticket_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT ticket_pkey PRIMARY KEY (id_ticket);


--
-- TOC entry 4888 (class 2606 OID 24214)
-- Name: categoria uk_35t4wyxqrevf09uwx9e9p6o75; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.categoria
    ADD CONSTRAINT uk_35t4wyxqrevf09uwx9e9p6o75 UNIQUE (nombre);


--
-- TOC entry 4910 (class 2606 OID 24216)
-- Name: prioridad uk_a578rljygcxqa65srjnxib9le; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.prioridad
    ADD CONSTRAINT uk_a578rljygcxqa65srjnxib9le UNIQUE (nombre);


--
-- TOC entry 4881 (class 2606 OID 24218)
-- Name: visita_tecnica visita_tecnica_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.visita_tecnica
    ADD CONSTRAINT visita_tecnica_pkey PRIMARY KEY (id_visita);


--
-- TOC entry 4875 (class 2606 OID 24220)
-- Name: persona persona_cedula_key; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.persona
    ADD CONSTRAINT persona_cedula_key UNIQUE (cedula);


--
-- TOC entry 4877 (class 2606 OID 24222)
-- Name: persona persona_id_usuario_key; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.persona
    ADD CONSTRAINT persona_id_usuario_key UNIQUE (id_usuario);


--
-- TOC entry 4879 (class 2606 OID 24224)
-- Name: persona persona_pkey; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.persona
    ADD CONSTRAINT persona_pkey PRIMARY KEY (id_persona);


--
-- TOC entry 4924 (class 2606 OID 24226)
-- Name: rol_bd rol_bd_nombre_key; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.rol_bd
    ADD CONSTRAINT rol_bd_nombre_key UNIQUE (nombre);


--
-- TOC entry 4926 (class 2606 OID 24228)
-- Name: rol_bd rol_bd_pkey; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.rol_bd
    ADD CONSTRAINT rol_bd_pkey PRIMARY KEY (id_rol_bd);


--
-- TOC entry 4920 (class 2606 OID 24230)
-- Name: rol rol_codigo_key; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.rol
    ADD CONSTRAINT rol_codigo_key UNIQUE (codigo);


--
-- TOC entry 4922 (class 2606 OID 24232)
-- Name: rol rol_pkey; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id_rol);


--
-- TOC entry 4793 (class 2606 OID 24234)
-- Name: usuario uk863n1y3x0jalatoir4325ehal; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT uk863n1y3x0jalatoir4325ehal UNIQUE (username);


--
-- TOC entry 4928 (class 2606 OID 24236)
-- Name: usuario_bd usuario_bd_nombre_key; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_bd
    ADD CONSTRAINT usuario_bd_nombre_key UNIQUE (nombre);


--
-- TOC entry 4930 (class 2606 OID 24238)
-- Name: usuario_bd usuario_bd_pkey; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_bd
    ADD CONSTRAINT usuario_bd_pkey PRIMARY KEY (id_usuario_bd);


--
-- TOC entry 4795 (class 2606 OID 24240)
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id_usuario);


--
-- TOC entry 4797 (class 2606 OID 24242)
-- Name: usuario usuario_username_key; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT usuario_username_key UNIQUE (username);


--
-- TOC entry 4773 (class 1259 OID 24243)
-- Name: idx_audit_estado_ticket_fecha; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_audit_estado_ticket_fecha ON auditoria.auditoria_estado_ticket USING btree (fecha_cambio DESC);


--
-- TOC entry 4774 (class 1259 OID 24244)
-- Name: idx_audit_estado_ticket_id; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_audit_estado_ticket_id ON auditoria.auditoria_estado_ticket USING btree (id_ticket);


--
-- TOC entry 4777 (class 1259 OID 24245)
-- Name: idx_audit_evento_accion; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_audit_evento_accion ON auditoria.auditoria_evento USING btree (id_accion_item);


--
-- TOC entry 4778 (class 1259 OID 24246)
-- Name: idx_audit_evento_exito; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_audit_evento_exito ON auditoria.auditoria_evento USING btree (exito);


--
-- TOC entry 4779 (class 1259 OID 24247)
-- Name: idx_audit_evento_fecha; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_audit_evento_fecha ON auditoria.auditoria_evento USING btree (fecha_evento DESC);


--
-- TOC entry 4780 (class 1259 OID 24248)
-- Name: idx_audit_evento_modulo; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_audit_evento_modulo ON auditoria.auditoria_evento USING btree (modulo);


--
-- TOC entry 4781 (class 1259 OID 24249)
-- Name: idx_audit_evento_registro; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_audit_evento_registro ON auditoria.auditoria_evento USING btree (tabla_afectada, id_registro);


--
-- TOC entry 4782 (class 1259 OID 24250)
-- Name: idx_audit_evento_usuario; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_audit_evento_usuario ON auditoria.auditoria_evento USING btree (id_usuario);


--
-- TOC entry 4785 (class 1259 OID 24251)
-- Name: idx_audit_login_exito; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_audit_login_exito ON auditoria.auditoria_login USING btree (exito);


--
-- TOC entry 4786 (class 1259 OID 24252)
-- Name: idx_audit_login_fecha; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_audit_login_fecha ON auditoria.auditoria_login USING btree (fecha_login DESC);


--
-- TOC entry 4787 (class 1259 OID 24253)
-- Name: idx_audit_login_usuario; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_audit_login_usuario ON auditoria.auditoria_login USING btree (id_usuario);


--
-- TOC entry 4862 (class 1259 OID 24254)
-- Name: idx_cola_correo_pendientes; Type: INDEX; Schema: notificaciones; Owner: postgres
--

CREATE INDEX idx_cola_correo_pendientes ON notificaciones.cola_correo USING btree (enviado) WHERE (enviado = false);


--
-- TOC entry 4863 (class 1259 OID 24255)
-- Name: idx_notificacion_web_usuario; Type: INDEX; Schema: notificaciones; Owner: postgres
--

CREATE INDEX idx_notificacion_web_usuario ON notificaciones.notificacion_web USING btree (id_usuario_destino, leida);


--
-- TOC entry 4884 (class 1259 OID 24256)
-- Name: uq_asignacion_activa; Type: INDEX; Schema: soporte; Owner: postgres
--

CREATE UNIQUE INDEX uq_asignacion_activa ON soporte.asignacion USING btree (id_ticket) WHERE (activo = true);


--
-- TOC entry 5037 (class 2620 OID 24257)
-- Name: inventario_usado_ticket trg_descontar_stock_inventario; Type: TRIGGER; Schema: soporte; Owner: postgres
--

CREATE TRIGGER trg_descontar_stock_inventario AFTER INSERT ON soporte.inventario_usado_ticket FOR EACH ROW EXECUTE FUNCTION soporte.fn_descontar_stock_inventario();


--
-- TOC entry 4931 (class 2606 OID 24258)
-- Name: auditoria_estado_ticket fk_aud_estado_ant; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_aud_estado_ant FOREIGN KEY (id_estado_anterior) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 4939 (class 2606 OID 24263)
-- Name: auditoria_login fk_aud_login_usuario; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login
    ADD CONSTRAINT fk_aud_login_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 4937 (class 2606 OID 24268)
-- Name: auditoria_evento fk_auditoria_accion; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_evento
    ADD CONSTRAINT fk_auditoria_accion FOREIGN KEY (id_accion_item) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 4932 (class 2606 OID 24273)
-- Name: auditoria_estado_ticket fk_auditoria_estado_ticket; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_auditoria_estado_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 4933 (class 2606 OID 24278)
-- Name: auditoria_estado_ticket fk_auditoria_estado_ticket_estado; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_auditoria_estado_ticket_estado FOREIGN KEY (id_estado_nuevo_item) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4934 (class 2606 OID 24283)
-- Name: auditoria_estado_ticket fk_auditoria_estado_ticket_evento; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_auditoria_estado_ticket_evento FOREIGN KEY (id_item_evento) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4935 (class 2606 OID 24288)
-- Name: auditoria_estado_ticket fk_auditoria_estado_ticket_ticket; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_auditoria_estado_ticket_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4936 (class 2606 OID 24293)
-- Name: auditoria_estado_ticket fk_auditoria_estado_ticket_usuario; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_auditoria_estado_ticket_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4942 (class 2606 OID 24298)
-- Name: auditoria_login_bd fk_auditoria_login_bd_evento; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd
    ADD CONSTRAINT fk_auditoria_login_bd_evento FOREIGN KEY (id_item_evento) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4943 (class 2606 OID 24303)
-- Name: auditoria_login_bd fk_auditoria_login_bd_usuario; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd
    ADD CONSTRAINT fk_auditoria_login_bd_usuario FOREIGN KEY (id_usuario_bd) REFERENCES usuarios.usuario_bd(id_usuario_bd) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4944 (class 2606 OID 24308)
-- Name: auditoria_login_bd fk_auditoria_login_bd_usuario_bd; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd
    ADD CONSTRAINT fk_auditoria_login_bd_usuario_bd FOREIGN KEY (id_usuario_bd) REFERENCES usuarios.usuario_bd(id_usuario_bd) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4940 (class 2606 OID 24313)
-- Name: auditoria_login fk_auditoria_login_evento; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login
    ADD CONSTRAINT fk_auditoria_login_evento FOREIGN KEY (id_item_evento) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4941 (class 2606 OID 24318)
-- Name: auditoria_login fk_auditoria_login_usuario; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login
    ADD CONSTRAINT fk_auditoria_login_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4938 (class 2606 OID 24323)
-- Name: auditoria_evento fk_auditoria_usuario; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_evento
    ADD CONSTRAINT fk_auditoria_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 4945 (class 2606 OID 24328)
-- Name: auditoria_login_bd fk_login_bd_evento; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd
    ADD CONSTRAINT fk_login_bd_evento FOREIGN KEY (id_item_evento) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4946 (class 2606 OID 24333)
-- Name: catalogo_item catalogo_item_id_catalogo_fkey; Type: FK CONSTRAINT; Schema: catalogos; Owner: postgres
--

ALTER TABLE ONLY catalogos.catalogo_item
    ADD CONSTRAINT catalogo_item_id_catalogo_fkey FOREIGN KEY (id_catalogo) REFERENCES catalogos.catalogo(id_catalogo);


--
-- TOC entry 4950 (class 2606 OID 24338)
-- Name: canton fk_canton_ciudad; Type: FK CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.canton
    ADD CONSTRAINT fk_canton_ciudad FOREIGN KEY (id_ciudad) REFERENCES clientes.ciudad(id_ciudad);


--
-- TOC entry 4951 (class 2606 OID 24343)
-- Name: ciudad fk_ciudad_pais; Type: FK CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.ciudad
    ADD CONSTRAINT fk_ciudad_pais FOREIGN KEY (id_pais) REFERENCES clientes.pais(id_pais);


--
-- TOC entry 4952 (class 2606 OID 24348)
-- Name: cliente fk_cliente_persona; Type: FK CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.cliente
    ADD CONSTRAINT fk_cliente_persona FOREIGN KEY (id_persona) REFERENCES usuarios.persona(id_persona) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4953 (class 2606 OID 24353)
-- Name: cliente fk_cliente_sucursal; Type: FK CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.cliente
    ADD CONSTRAINT fk_cliente_sucursal FOREIGN KEY (id_sucursal) REFERENCES empresa.sucursal(id_sucursal);


--
-- TOC entry 4954 (class 2606 OID 24358)
-- Name: documento_cliente fk_doc_cli_estado; Type: FK CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.documento_cliente
    ADD CONSTRAINT fk_doc_cli_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 4955 (class 2606 OID 24363)
-- Name: documento_cliente fk_documento_cliente_cliente; Type: FK CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.documento_cliente
    ADD CONSTRAINT fk_documento_cliente_cliente FOREIGN KEY (id_cliente) REFERENCES clientes.cliente(id_cliente);


--
-- TOC entry 4956 (class 2606 OID 24368)
-- Name: documento_cliente fk_documento_tipo; Type: FK CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.documento_cliente
    ADD CONSTRAINT fk_documento_tipo FOREIGN KEY (id_tipo_documento) REFERENCES clientes.tipo_documento(id_tipo_documento);


--
-- TOC entry 4957 (class 2606 OID 24373)
-- Name: documento_empleado fk_doc_emp_estado; Type: FK CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.documento_empleado
    ADD CONSTRAINT fk_doc_emp_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 4958 (class 2606 OID 24378)
-- Name: documento_empleado fk_doc_emp_tipo_documento; Type: FK CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.documento_empleado
    ADD CONSTRAINT fk_doc_emp_tipo_documento FOREIGN KEY (id_tipo_documento) REFERENCES clientes.tipo_documento(id_tipo_documento);


--
-- TOC entry 4959 (class 2606 OID 24383)
-- Name: documento_empleado fk_documento_empleado_empleado; Type: FK CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.documento_empleado
    ADD CONSTRAINT fk_documento_empleado_empleado FOREIGN KEY (id_empleado) REFERENCES empleados.empleado(id_empleado);


--
-- TOC entry 4960 (class 2606 OID 24388)
-- Name: empleado fk_empleado_area; Type: FK CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT fk_empleado_area FOREIGN KEY (id_area) REFERENCES empleados.area(id_area);


--
-- TOC entry 4961 (class 2606 OID 24393)
-- Name: empleado fk_empleado_cargo; Type: FK CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT fk_empleado_cargo FOREIGN KEY (id_cargo) REFERENCES empleados.cargo(id_cargo);


--
-- TOC entry 4962 (class 2606 OID 24398)
-- Name: empleado fk_empleado_persona; Type: FK CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT fk_empleado_persona FOREIGN KEY (id_persona) REFERENCES usuarios.persona(id_persona) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4963 (class 2606 OID 24403)
-- Name: empleado fk_empleado_sucursal; Type: FK CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT fk_empleado_sucursal FOREIGN KEY (id_sucursal) REFERENCES empresa.sucursal(id_sucursal);


--
-- TOC entry 4964 (class 2606 OID 24408)
-- Name: empleado fk_empleado_tipo_contrato_catalogo; Type: FK CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT fk_empleado_tipo_contrato_catalogo FOREIGN KEY (id_tipo_contrato) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4965 (class 2606 OID 24413)
-- Name: documento_empresa documento_empresa_id_empresa_fkey; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.documento_empresa
    ADD CONSTRAINT documento_empresa_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa);


--
-- TOC entry 4970 (class 2606 OID 24418)
-- Name: empresa_servicio fk4v8ptw3ao3v85rsfvpm19cjpx; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.empresa_servicio
    ADD CONSTRAINT fk4v8ptw3ao3v85rsfvpm19cjpx FOREIGN KEY (id_servicio) REFERENCES empresa.servicio(id_servicio);


--
-- TOC entry 4966 (class 2606 OID 24423)
-- Name: documento_empresa fk_doc_empresa_estado; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.documento_empresa
    ADD CONSTRAINT fk_doc_empresa_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 4967 (class 2606 OID 24428)
-- Name: documento_empresa fk_documento_empresa_tipo_documento; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.documento_empresa
    ADD CONSTRAINT fk_documento_empresa_tipo_documento FOREIGN KEY (id_tipo_documento) REFERENCES clientes.tipo_documento(id_tipo_documento);


--
-- TOC entry 4968 (class 2606 OID 24433)
-- Name: empresa fk_empresa_estado; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.empresa
    ADD CONSTRAINT fk_empresa_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 4969 (class 2606 OID 24438)
-- Name: empresa fk_empresa_tipo; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.empresa
    ADD CONSTRAINT fk_empresa_tipo FOREIGN KEY (id_catalogo_item_tipo_empresa) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 4971 (class 2606 OID 24443)
-- Name: empresa_servicio fk_es_empresa; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.empresa_servicio
    ADD CONSTRAINT fk_es_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa);


--
-- TOC entry 4972 (class 2606 OID 24448)
-- Name: sucursal fk_sucursal_canton; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.sucursal
    ADD CONSTRAINT fk_sucursal_canton FOREIGN KEY (id_canton) REFERENCES clientes.canton(id_canton);


--
-- TOC entry 4973 (class 2606 OID 24453)
-- Name: sucursal fk_sucursal_ciudad; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.sucursal
    ADD CONSTRAINT fk_sucursal_ciudad FOREIGN KEY (id_ciudad) REFERENCES clientes.ciudad(id_ciudad);


--
-- TOC entry 4974 (class 2606 OID 24458)
-- Name: sucursal fk_sucursal_empresa; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.sucursal
    ADD CONSTRAINT fk_sucursal_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa);


--
-- TOC entry 4975 (class 2606 OID 24463)
-- Name: sucursal fk_sucursal_estado; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.sucursal
    ADD CONSTRAINT fk_sucursal_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 4976 (class 2606 OID 24468)
-- Name: cola_correo fk_correo_empresa; Type: FK CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.cola_correo
    ADD CONSTRAINT fk_correo_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa) ON DELETE CASCADE;


--
-- TOC entry 4977 (class 2606 OID 24473)
-- Name: cola_correo fk_correo_ticket; Type: FK CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.cola_correo
    ADD CONSTRAINT fk_correo_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket) ON DELETE SET NULL;


--
-- TOC entry 4978 (class 2606 OID 24478)
-- Name: notificacion_web fk_noti_web_empresa; Type: FK CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.notificacion_web
    ADD CONSTRAINT fk_noti_web_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa) ON DELETE CASCADE;


--
-- TOC entry 4979 (class 2606 OID 24483)
-- Name: notificacion_web fk_noti_web_ticket; Type: FK CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.notificacion_web
    ADD CONSTRAINT fk_noti_web_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket) ON DELETE CASCADE;


--
-- TOC entry 4980 (class 2606 OID 24488)
-- Name: notificacion_web fk_noti_web_usuario; Type: FK CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.notificacion_web
    ADD CONSTRAINT fk_noti_web_usuario FOREIGN KEY (id_usuario_destino) REFERENCES usuarios.usuario(id_usuario) ON DELETE CASCADE;


--
-- TOC entry 4981 (class 2606 OID 24493)
-- Name: historial_generacion historial_generacion_id_reporte_fkey; Type: FK CONSTRAINT; Schema: reportes; Owner: postgres
--

ALTER TABLE ONLY reportes.historial_generacion
    ADD CONSTRAINT historial_generacion_id_reporte_fkey FOREIGN KEY (id_reporte) REFERENCES reportes.configuracion_reporte(id_reporte);


--
-- TOC entry 4982 (class 2606 OID 24498)
-- Name: ticket fk81l25qsiooc520ve4sm69chsy; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk81l25qsiooc520ve4sm69chsy FOREIGN KEY (id_servicio) REFERENCES empresa.servicio(id_servicio);


--
-- TOC entry 5009 (class 2606 OID 24503)
-- Name: historial_estado fk86k65nur98avxs6ac5ue2sgj; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk86k65nur98avxs6ac5ue2sgj FOREIGN KEY (id_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 4998 (class 2606 OID 24508)
-- Name: asignacion fk_asignacion_ticket; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.asignacion
    ADD CONSTRAINT fk_asignacion_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 4999 (class 2606 OID 24513)
-- Name: asignacion fk_asignacion_usuario; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.asignacion
    ADD CONSTRAINT fk_asignacion_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5001 (class 2606 OID 24518)
-- Name: comentario_ticket fk_com_estado; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket
    ADD CONSTRAINT fk_com_estado FOREIGN KEY (id_estado_item) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5002 (class 2606 OID 24523)
-- Name: comentario_ticket fk_com_ticket; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket
    ADD CONSTRAINT fk_com_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket) ON DELETE CASCADE;


--
-- TOC entry 5003 (class 2606 OID 24528)
-- Name: comentario_ticket fk_com_usuario; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket
    ADD CONSTRAINT fk_com_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 5005 (class 2606 OID 24533)
-- Name: documento_ticket fk_doc_estado; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.documento_ticket
    ADD CONSTRAINT fk_doc_estado FOREIGN KEY (id_estado_item) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5006 (class 2606 OID 24538)
-- Name: documento_ticket fk_doc_ticket; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.documento_ticket
    ADD CONSTRAINT fk_doc_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket) ON DELETE CASCADE;


--
-- TOC entry 5007 (class 2606 OID 24543)
-- Name: documento_ticket fk_doc_tipo; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.documento_ticket
    ADD CONSTRAINT fk_doc_tipo FOREIGN KEY (id_tipo_documento_item) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5008 (class 2606 OID 24548)
-- Name: documento_ticket fk_doc_usuario; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.documento_ticket
    ADD CONSTRAINT fk_doc_usuario FOREIGN KEY (id_usuario_subio) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 5010 (class 2606 OID 24553)
-- Name: historial_estado fk_hist_estado_anterior; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_hist_estado_anterior FOREIGN KEY (id_estado_anterior) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5011 (class 2606 OID 24558)
-- Name: historial_estado fk_hist_estado_nuevo; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_hist_estado_nuevo FOREIGN KEY (id_estado_nuevo) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5012 (class 2606 OID 24563)
-- Name: historial_estado fk_historial_estado_anterior; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_historial_estado_anterior FOREIGN KEY (id_estado_anterior) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5013 (class 2606 OID 24568)
-- Name: historial_estado fk_historial_estado_nuevo; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_historial_estado_nuevo FOREIGN KEY (id_estado_nuevo) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5014 (class 2606 OID 24573)
-- Name: historial_estado fk_historial_ticket; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_historial_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 5015 (class 2606 OID 24578)
-- Name: historial_estado fk_historial_usuario; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_historial_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5018 (class 2606 OID 24583)
-- Name: inventario fk_inventario_empresa; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.inventario
    ADD CONSTRAINT fk_inventario_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa);


--
-- TOC entry 5019 (class 2606 OID 24588)
-- Name: inventario fk_inventario_estado; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.inventario
    ADD CONSTRAINT fk_inventario_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5020 (class 2606 OID 24593)
-- Name: inventario fk_inventario_usuario; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.inventario
    ADD CONSTRAINT fk_inventario_usuario FOREIGN KEY (id_usuario_registro) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 5026 (class 2606 OID 24598)
-- Name: problema fk_problema_categoria; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.problema
    ADD CONSTRAINT fk_problema_categoria FOREIGN KEY (id_categoria) REFERENCES soporte.categoria(id_categoria);


--
-- TOC entry 5027 (class 2606 OID 24603)
-- Name: problema fk_problema_empresa; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.problema
    ADD CONSTRAINT fk_problema_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa);


--
-- TOC entry 5028 (class 2606 OID 24608)
-- Name: problema fk_problema_estado; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.problema
    ADD CONSTRAINT fk_problema_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5029 (class 2606 OID 24613)
-- Name: problema fk_problema_prioridad; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.problema
    ADD CONSTRAINT fk_problema_prioridad FOREIGN KEY (id_prioridad) REFERENCES soporte.prioridad(id_prioridad);


--
-- TOC entry 5030 (class 2606 OID 24618)
-- Name: sla_ticket fk_sla_prioridad; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.sla_ticket
    ADD CONSTRAINT fk_sla_prioridad FOREIGN KEY (aplica_prioridad) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4983 (class 2606 OID 24623)
-- Name: ticket fk_ticket_categoria_item; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_categoria_item FOREIGN KEY (id_categoria_item) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4984 (class 2606 OID 24628)
-- Name: ticket fk_ticket_cliente; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_cliente FOREIGN KEY (id_cliente) REFERENCES clientes.cliente(id_cliente);


--
-- TOC entry 4985 (class 2606 OID 24633)
-- Name: ticket fk_ticket_estado_item; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_estado_item FOREIGN KEY (id_estado_item) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4986 (class 2606 OID 24638)
-- Name: ticket fk_ticket_prioridad_item; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_prioridad_item FOREIGN KEY (id_prioridad_item) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4987 (class 2606 OID 24643)
-- Name: ticket fk_ticket_problema; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_problema FOREIGN KEY (id_problema) REFERENCES soporte.problema(id_problema);


--
-- TOC entry 4988 (class 2606 OID 24648)
-- Name: ticket fk_ticket_sla; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_sla FOREIGN KEY (id_sla) REFERENCES soporte.sla_ticket(id_sla);


--
-- TOC entry 4989 (class 2606 OID 24653)
-- Name: ticket fk_ticket_sucursal; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_sucursal FOREIGN KEY (id_sucursal) REFERENCES empresa.sucursal(id_sucursal);


--
-- TOC entry 4990 (class 2606 OID 24658)
-- Name: ticket fk_ticket_usuario_asignado; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_usuario_asignado FOREIGN KEY (id_usuario_asignado) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4991 (class 2606 OID 24663)
-- Name: ticket fk_ticket_usuario_creador; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_usuario_creador FOREIGN KEY (id_usuario_creador) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5021 (class 2606 OID 24668)
-- Name: inventario_usado_ticket fk_uso_inventario; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.inventario_usado_ticket
    ADD CONSTRAINT fk_uso_inventario FOREIGN KEY (id_item_inventario) REFERENCES soporte.inventario(id_item_inventario);


--
-- TOC entry 5022 (class 2606 OID 24673)
-- Name: inventario_usado_ticket fk_uso_tecnico; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.inventario_usado_ticket
    ADD CONSTRAINT fk_uso_tecnico FOREIGN KEY (id_usuario_tecnico) REFERENCES usuarios.usuario(id_usuario) ON DELETE SET NULL;


--
-- TOC entry 5023 (class 2606 OID 24678)
-- Name: inventario_usado_ticket fk_uso_ticket; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.inventario_usado_ticket
    ADD CONSTRAINT fk_uso_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 4994 (class 2606 OID 24683)
-- Name: visita_tecnica fk_visita_empresa; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.visita_tecnica
    ADD CONSTRAINT fk_visita_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa);


--
-- TOC entry 4995 (class 2606 OID 24688)
-- Name: visita_tecnica fk_visita_estado; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.visita_tecnica
    ADD CONSTRAINT fk_visita_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 4996 (class 2606 OID 24693)
-- Name: visita_tecnica fk_visita_tecnico; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.visita_tecnica
    ADD CONSTRAINT fk_visita_tecnico FOREIGN KEY (id_usuario_tecnico) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 4997 (class 2606 OID 24698)
-- Name: visita_tecnica fk_visita_ticket; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.visita_tecnica
    ADD CONSTRAINT fk_visita_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 5004 (class 2606 OID 24703)
-- Name: comentario_ticket fkbv5gyaxos7jsns8fsucflndds; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket
    ADD CONSTRAINT fkbv5gyaxos7jsns8fsucflndds FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa);


--
-- TOC entry 5025 (class 2606 OID 24708)
-- Name: prioridad fkcnj24dfocilmvv1yyfjxf89gd; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.prioridad
    ADD CONSTRAINT fkcnj24dfocilmvv1yyfjxf89gd FOREIGN KEY (id_item) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5000 (class 2606 OID 24713)
-- Name: categoria fke27el05povf1kt0jl2811tm7r; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.categoria
    ADD CONSTRAINT fke27el05povf1kt0jl2811tm7r FOREIGN KEY (id_item) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5031 (class 2606 OID 24718)
-- Name: sla_ticket fkm9bsgtiqm9fcxfjnewil1mgdw; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.sla_ticket
    ADD CONSTRAINT fkm9bsgtiqm9fcxfjnewil1mgdw FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa);


--
-- TOC entry 5016 (class 2606 OID 24723)
-- Name: informe_trabajo_tecnico informe_trabajo_tecnico_id_tecnico_fkey; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.informe_trabajo_tecnico
    ADD CONSTRAINT informe_trabajo_tecnico_id_tecnico_fkey FOREIGN KEY (id_tecnico) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 5017 (class 2606 OID 24728)
-- Name: informe_trabajo_tecnico informe_trabajo_tecnico_id_ticket_fkey; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.informe_trabajo_tecnico
    ADD CONSTRAINT informe_trabajo_tecnico_id_ticket_fkey FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 5024 (class 2606 OID 24733)
-- Name: network_probe_result network_probe_result_id_run_fkey; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.network_probe_result
    ADD CONSTRAINT network_probe_result_id_run_fkey FOREIGN KEY (id_run) REFERENCES soporte.network_probe_run(id_run) ON DELETE CASCADE;


--
-- TOC entry 5032 (class 2606 OID 24738)
-- Name: solucion_ticket solucion_ticket_id_ticket_fkey; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.solucion_ticket
    ADD CONSTRAINT solucion_ticket_id_ticket_fkey FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 5033 (class 2606 OID 24743)
-- Name: solucion_ticket solucion_ticket_id_usuario_tecnico_fkey; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.solucion_ticket
    ADD CONSTRAINT solucion_ticket_id_usuario_tecnico_fkey FOREIGN KEY (id_usuario_tecnico) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 4992 (class 2606 OID 24748)
-- Name: persona fk_persona_canton; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.persona
    ADD CONSTRAINT fk_persona_canton FOREIGN KEY (id_canton) REFERENCES clientes.canton(id_canton);


--
-- TOC entry 4993 (class 2606 OID 24753)
-- Name: persona fk_persona_usuario; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.persona
    ADD CONSTRAINT fk_persona_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 5034 (class 2606 OID 24758)
-- Name: usuario_bd fk_usuario_bd_rol; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_bd
    ADD CONSTRAINT fk_usuario_bd_rol FOREIGN KEY (id_rol_bd) REFERENCES usuarios.rol_bd(id_rol_bd);


--
-- TOC entry 5035 (class 2606 OID 24763)
-- Name: usuario_bd fk_usuario_bd_rol_bd; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_bd
    ADD CONSTRAINT fk_usuario_bd_rol_bd FOREIGN KEY (id_rol_bd) REFERENCES usuarios.rol_bd(id_rol_bd) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5036 (class 2606 OID 24768)
-- Name: usuario_bd fk_usuario_bd_usuario; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_bd
    ADD CONSTRAINT fk_usuario_bd_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON DELETE CASCADE;


--
-- TOC entry 4947 (class 2606 OID 24773)
-- Name: usuario fk_usuario_empresa; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT fk_usuario_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 4948 (class 2606 OID 24778)
-- Name: usuario fk_usuario_estado; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT fk_usuario_estado FOREIGN KEY (id_catalogo_item_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 4949 (class 2606 OID 24783)
-- Name: usuario fk_usuario_rol; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT fk_usuario_rol FOREIGN KEY (id_rol) REFERENCES usuarios.rol(id_rol);


--
-- TOC entry 5289 (class 0 OID 0)
-- Dependencies: 5288
-- Name: DATABASE "SGIM2"; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON DATABASE "SGIM2" TO sgiri_app;


--
-- TOC entry 5290 (class 0 OID 0)
-- Dependencies: 7
-- Name: SCHEMA auditoria; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA auditoria TO sgiri_app;
GRANT ALL ON SCHEMA auditoria TO emp_1203587489_21;
GRANT USAGE ON SCHEMA auditoria TO rol_tecnico;
GRANT USAGE ON SCHEMA auditoria TO rol_admin_tecnicos;
GRANT USAGE ON SCHEMA auditoria TO rol_admin_master;
GRANT USAGE ON SCHEMA auditoria TO rol_cliente;
GRANT USAGE ON SCHEMA auditoria TO rol_admin_visual;
GRANT USAGE ON SCHEMA auditoria TO rol_admin_contratos;


--
-- TOC entry 5291 (class 0 OID 0)
-- Dependencies: 8
-- Name: SCHEMA catalogos; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA catalogos TO sgiri_app;
GRANT USAGE ON SCHEMA catalogos TO rol_cliente;
GRANT USAGE ON SCHEMA catalogos TO rol_tecnico;
GRANT USAGE ON SCHEMA catalogos TO rol_admin_tecnicos;
GRANT USAGE ON SCHEMA catalogos TO rol_admin_master;
GRANT USAGE ON SCHEMA catalogos TO rol_admin_visual;
GRANT USAGE ON SCHEMA catalogos TO rol_admin_contratos;


--
-- TOC entry 5292 (class 0 OID 0)
-- Dependencies: 9
-- Name: SCHEMA clientes; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA clientes TO sgiri_app;
GRANT USAGE ON SCHEMA clientes TO rol_cliente;
GRANT USAGE ON SCHEMA clientes TO rol_tecnico;
GRANT USAGE ON SCHEMA clientes TO rol_admin_tecnicos;
GRANT USAGE ON SCHEMA clientes TO rol_admin_master;
GRANT USAGE ON SCHEMA clientes TO rol_admin_visual;
GRANT USAGE ON SCHEMA clientes TO rol_admin_contratos;


--
-- TOC entry 5293 (class 0 OID 0)
-- Dependencies: 10
-- Name: SCHEMA empleados; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA empleados TO sgiri_app;
GRANT USAGE ON SCHEMA empleados TO rol_cliente;
GRANT USAGE ON SCHEMA empleados TO rol_tecnico;
GRANT USAGE ON SCHEMA empleados TO rol_admin_tecnicos;
GRANT USAGE ON SCHEMA empleados TO rol_admin_master;
GRANT USAGE ON SCHEMA empleados TO rol_admin_visual;
GRANT USAGE ON SCHEMA empleados TO rol_admin_contratos;


--
-- TOC entry 5294 (class 0 OID 0)
-- Dependencies: 11
-- Name: SCHEMA empresa; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA empresa TO sgiri_app;
GRANT USAGE ON SCHEMA empresa TO rol_cliente;
GRANT USAGE ON SCHEMA empresa TO rol_tecnico;
GRANT USAGE ON SCHEMA empresa TO rol_admin_tecnicos;
GRANT USAGE ON SCHEMA empresa TO rol_admin_master;
GRANT USAGE ON SCHEMA empresa TO rol_admin_visual;
GRANT USAGE ON SCHEMA empresa TO rol_admin_contratos;


--
-- TOC entry 5295 (class 0 OID 0)
-- Dependencies: 12
-- Name: SCHEMA notificaciones; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA notificaciones TO sgiri_app;
GRANT USAGE ON SCHEMA notificaciones TO rol_cliente;
GRANT USAGE ON SCHEMA notificaciones TO rol_tecnico;
GRANT USAGE ON SCHEMA notificaciones TO rol_admin_tecnicos;
GRANT USAGE ON SCHEMA notificaciones TO rol_admin_master;
GRANT USAGE ON SCHEMA notificaciones TO rol_admin_visual;
GRANT USAGE ON SCHEMA notificaciones TO rol_admin_contratos;


--
-- TOC entry 5296 (class 0 OID 0)
-- Dependencies: 6
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO sgiri_app;


--
-- TOC entry 5298 (class 0 OID 0)
-- Dependencies: 13
-- Name: SCHEMA reportes; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA reportes TO rol_cliente;
GRANT USAGE ON SCHEMA reportes TO rol_tecnico;
GRANT USAGE ON SCHEMA reportes TO rol_admin_tecnicos;
GRANT USAGE ON SCHEMA reportes TO rol_admin_master;
GRANT USAGE ON SCHEMA reportes TO rol_admin_visual;
GRANT USAGE ON SCHEMA reportes TO rol_admin_contratos;


--
-- TOC entry 5299 (class 0 OID 0)
-- Dependencies: 14
-- Name: SCHEMA soporte; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA soporte TO sgiri_app;
GRANT USAGE ON SCHEMA soporte TO rol_cliente;
GRANT USAGE ON SCHEMA soporte TO rol_tecnico;
GRANT USAGE ON SCHEMA soporte TO rol_admin_tecnicos;
GRANT USAGE ON SCHEMA soporte TO rol_admin_master;
GRANT USAGE ON SCHEMA soporte TO rol_admin_visual;
GRANT USAGE ON SCHEMA soporte TO rol_admin_contratos;


--
-- TOC entry 5300 (class 0 OID 0)
-- Dependencies: 15
-- Name: SCHEMA usuarios; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA usuarios TO sgiri_app;
GRANT USAGE ON SCHEMA usuarios TO emp_1203587489_21;
GRANT USAGE ON SCHEMA usuarios TO rol_cliente;
GRANT USAGE ON SCHEMA usuarios TO rol_tecnico;
GRANT USAGE ON SCHEMA usuarios TO rol_admin_tecnicos;
GRANT USAGE ON SCHEMA usuarios TO rol_admin_master;
GRANT USAGE ON SCHEMA usuarios TO rol_admin_visual;
GRANT USAGE ON SCHEMA usuarios TO rol_admin_contratos;


--
-- TOC entry 5302 (class 0 OID 0)
-- Dependencies: 375
-- Name: FUNCTION fn_upsert_catalogo_item(p_nombre_catalogo character varying, p_descripcion_catalogo text, p_codigo_item character varying, p_nombre_item character varying, p_orden integer); Type: ACL; Schema: catalogos; Owner: postgres
--

GRANT ALL ON FUNCTION catalogos.fn_upsert_catalogo_item(p_nombre_catalogo character varying, p_descripcion_catalogo text, p_codigo_item character varying, p_nombre_item character varying, p_orden integer) TO sgiri_app;


--
-- TOC entry 5303 (class 0 OID 0)
-- Dependencies: 378
-- Name: FUNCTION fn_crear_empleado(p_cedula character varying, p_nombre character varying, p_apellido character varying, p_celular character varying, p_correo_personal character varying, p_fecha_nacimiento date, p_fecha_ingreso date, p_id_cargo integer, p_id_area integer, p_id_tipo_contrato integer); Type: ACL; Schema: empleados; Owner: postgres
--

GRANT ALL ON FUNCTION empleados.fn_crear_empleado(p_cedula character varying, p_nombre character varying, p_apellido character varying, p_celular character varying, p_correo_personal character varying, p_fecha_nacimiento date, p_fecha_ingreso date, p_id_cargo integer, p_id_area integer, p_id_tipo_contrato integer) TO sgiri_app;


--
-- TOC entry 5304 (class 0 OID 0)
-- Dependencies: 377
-- Name: FUNCTION fn_subir_documento(p_cedula character varying, p_tipo_documento character varying, p_ruta_archivo text, p_descripcion text); Type: ACL; Schema: empleados; Owner: postgres
--

GRANT ALL ON FUNCTION empleados.fn_subir_documento(p_cedula character varying, p_tipo_documento character varying, p_ruta_archivo text, p_descripcion text) TO sgiri_app;


--
-- TOC entry 5305 (class 0 OID 0)
-- Dependencies: 376
-- Name: FUNCTION fn_descontar_stock_inventario(); Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON FUNCTION soporte.fn_descontar_stock_inventario() TO sgiri_app;


--
-- TOC entry 5306 (class 0 OID 0)
-- Dependencies: 379
-- Name: FUNCTION fn_cambiar_credenciales(p_id_usuario integer, p_nuevo_username character varying, p_nueva_password text); Type: ACL; Schema: usuarios; Owner: postgres
--

GRANT ALL ON FUNCTION usuarios.fn_cambiar_credenciales(p_id_usuario integer, p_nuevo_username character varying, p_nueva_password text) TO sgiri_app;


--
-- TOC entry 5307 (class 0 OID 0)
-- Dependencies: 381
-- Name: FUNCTION fn_crear_usuario_cliente(p_cedula character varying, p_anio_nacimiento integer, p_id_rol integer, p_id_empresa integer, p_id_estado_item integer); Type: ACL; Schema: usuarios; Owner: postgres
--

GRANT ALL ON FUNCTION usuarios.fn_crear_usuario_cliente(p_cedula character varying, p_anio_nacimiento integer, p_id_rol integer, p_id_empresa integer, p_id_estado_item integer) TO sgiri_app;


--
-- TOC entry 5308 (class 0 OID 0)
-- Dependencies: 380
-- Name: FUNCTION fn_crear_usuario_empleado(p_cedula character varying, p_anio_nacimiento integer, p_id_rol integer, p_id_empresa integer, p_id_estado_item integer); Type: ACL; Schema: usuarios; Owner: postgres
--

GRANT ALL ON FUNCTION usuarios.fn_crear_usuario_empleado(p_cedula character varying, p_anio_nacimiento integer, p_id_rol integer, p_id_empresa integer, p_id_estado_item integer) TO sgiri_app;
GRANT ALL ON FUNCTION usuarios.fn_crear_usuario_empleado(p_cedula character varying, p_anio_nacimiento integer, p_id_rol integer, p_id_empresa integer, p_id_estado_item integer) TO rol_admin_contratos;


--
-- TOC entry 5309 (class 0 OID 0)
-- Dependencies: 382
-- Name: FUNCTION fn_generar_credenciales(p_cedula character varying, p_anio_nacimiento integer); Type: ACL; Schema: usuarios; Owner: postgres
--

GRANT ALL ON FUNCTION usuarios.fn_generar_credenciales(p_cedula character varying, p_anio_nacimiento integer) TO sgiri_app;
GRANT ALL ON FUNCTION usuarios.fn_generar_credenciales(p_cedula character varying, p_anio_nacimiento integer) TO rol_admin_contratos;


--
-- TOC entry 5310 (class 0 OID 0)
-- Dependencies: 229
-- Name: TABLE auditoria_estado_ticket; Type: ACL; Schema: auditoria; Owner: postgres
--

GRANT ALL ON TABLE auditoria.auditoria_estado_ticket TO sgiri_app;
GRANT SELECT ON TABLE auditoria.auditoria_estado_ticket TO emp_1203587489_21;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_estado_ticket TO rol_tecnico;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_estado_ticket TO rol_admin_tecnicos;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_estado_ticket TO rol_admin_master;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_estado_ticket TO rol_cliente;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_estado_ticket TO rol_admin_visual;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_estado_ticket TO rol_admin_contratos;


--
-- TOC entry 5312 (class 0 OID 0)
-- Dependencies: 230
-- Name: SEQUENCE auditoria_estado_ticket_id_auditoria_seq; Type: ACL; Schema: auditoria; Owner: postgres
--

GRANT ALL ON SEQUENCE auditoria.auditoria_estado_ticket_id_auditoria_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_estado_ticket_id_auditoria_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_estado_ticket_id_auditoria_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_estado_ticket_id_auditoria_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_estado_ticket_id_auditoria_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_estado_ticket_id_auditoria_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_estado_ticket_id_auditoria_seq TO rol_admin_contratos;


--
-- TOC entry 5319 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE auditoria_evento; Type: ACL; Schema: auditoria; Owner: postgres
--

GRANT ALL ON TABLE auditoria.auditoria_evento TO sgiri_app;
GRANT SELECT ON TABLE auditoria.auditoria_evento TO emp_1203587489_21;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_evento TO rol_tecnico;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_evento TO rol_admin_tecnicos;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_evento TO rol_admin_master;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_evento TO rol_cliente;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_evento TO rol_admin_visual;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_evento TO rol_admin_contratos;


--
-- TOC entry 5321 (class 0 OID 0)
-- Dependencies: 232
-- Name: SEQUENCE auditoria_evento_id_evento_seq; Type: ACL; Schema: auditoria; Owner: postgres
--

GRANT ALL ON SEQUENCE auditoria.auditoria_evento_id_evento_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_evento_id_evento_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_evento_id_evento_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_evento_id_evento_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_evento_id_evento_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_evento_id_evento_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_evento_id_evento_seq TO rol_admin_contratos;


--
-- TOC entry 5324 (class 0 OID 0)
-- Dependencies: 233
-- Name: TABLE auditoria_login; Type: ACL; Schema: auditoria; Owner: postgres
--

GRANT ALL ON TABLE auditoria.auditoria_login TO sgiri_app;
GRANT SELECT ON TABLE auditoria.auditoria_login TO emp_1203587489_21;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_login TO rol_tecnico;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_login TO rol_admin_tecnicos;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_login TO rol_admin_master;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_login TO rol_cliente;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_login TO rol_admin_visual;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_login TO rol_admin_contratos;


--
-- TOC entry 5325 (class 0 OID 0)
-- Dependencies: 234
-- Name: TABLE auditoria_login_bd; Type: ACL; Schema: auditoria; Owner: postgres
--

GRANT ALL ON TABLE auditoria.auditoria_login_bd TO sgiri_app;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_login_bd TO emp_1203587489_21;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_login_bd TO rol_tecnico;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_login_bd TO rol_admin_tecnicos;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_login_bd TO rol_admin_master;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_login_bd TO rol_cliente;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_login_bd TO rol_admin_visual;
GRANT SELECT,INSERT ON TABLE auditoria.auditoria_login_bd TO rol_admin_contratos;


--
-- TOC entry 5327 (class 0 OID 0)
-- Dependencies: 235
-- Name: SEQUENCE auditoria_login_bd_id_auditoria_login_bd_seq; Type: ACL; Schema: auditoria; Owner: postgres
--

GRANT ALL ON SEQUENCE auditoria.auditoria_login_bd_id_auditoria_login_bd_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_login_bd_id_auditoria_login_bd_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_login_bd_id_auditoria_login_bd_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_login_bd_id_auditoria_login_bd_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_login_bd_id_auditoria_login_bd_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_login_bd_id_auditoria_login_bd_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_login_bd_id_auditoria_login_bd_seq TO rol_admin_contratos;


--
-- TOC entry 5329 (class 0 OID 0)
-- Dependencies: 236
-- Name: SEQUENCE auditoria_login_id_login_seq; Type: ACL; Schema: auditoria; Owner: postgres
--

GRANT ALL ON SEQUENCE auditoria.auditoria_login_id_login_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_login_id_login_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_login_id_login_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_login_id_login_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_login_id_login_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_login_id_login_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE auditoria.auditoria_login_id_login_seq TO rol_admin_contratos;


--
-- TOC entry 5330 (class 0 OID 0)
-- Dependencies: 237
-- Name: TABLE catalogo_item; Type: ACL; Schema: catalogos; Owner: postgres
--

GRANT ALL ON TABLE catalogos.catalogo_item TO sgiri_app;
GRANT SELECT ON TABLE catalogos.catalogo_item TO rol_cliente;
GRANT SELECT ON TABLE catalogos.catalogo_item TO rol_tecnico;
GRANT SELECT ON TABLE catalogos.catalogo_item TO rol_admin_tecnicos;
GRANT SELECT ON TABLE catalogos.catalogo_item TO rol_admin_master;
GRANT SELECT ON TABLE catalogos.catalogo_item TO rol_admin_visual;
GRANT SELECT ON TABLE catalogos.catalogo_item TO rol_admin_contratos;


--
-- TOC entry 5331 (class 0 OID 0)
-- Dependencies: 238
-- Name: TABLE usuario; Type: ACL; Schema: usuarios; Owner: postgres
--

GRANT ALL ON TABLE usuarios.usuario TO sgiri_app;
GRANT SELECT ON TABLE usuarios.usuario TO emp_1203587489_21;
GRANT ALL ON TABLE usuarios.usuario TO rol_admin_master;
GRANT SELECT ON TABLE usuarios.usuario TO rol_tecnico;
GRANT SELECT ON TABLE usuarios.usuario TO rol_admin_tecnicos;
GRANT SELECT ON TABLE usuarios.usuario TO rol_cliente;
GRANT SELECT ON TABLE usuarios.usuario TO rol_admin_visual;
GRANT SELECT,INSERT,UPDATE ON TABLE usuarios.usuario TO rol_admin_contratos;


--
-- TOC entry 5332 (class 0 OID 0)
-- Dependencies: 239
-- Name: TABLE vw_timeline_administrativa; Type: ACL; Schema: auditoria; Owner: postgres
--

GRANT ALL ON TABLE auditoria.vw_timeline_administrativa TO sgiri_app;
GRANT SELECT,INSERT ON TABLE auditoria.vw_timeline_administrativa TO rol_tecnico;
GRANT SELECT,INSERT ON TABLE auditoria.vw_timeline_administrativa TO rol_admin_tecnicos;
GRANT SELECT,INSERT ON TABLE auditoria.vw_timeline_administrativa TO rol_admin_master;
GRANT SELECT,INSERT ON TABLE auditoria.vw_timeline_administrativa TO rol_cliente;
GRANT SELECT,INSERT ON TABLE auditoria.vw_timeline_administrativa TO rol_admin_visual;
GRANT SELECT,INSERT ON TABLE auditoria.vw_timeline_administrativa TO rol_admin_contratos;


--
-- TOC entry 5333 (class 0 OID 0)
-- Dependencies: 240
-- Name: TABLE catalogo; Type: ACL; Schema: catalogos; Owner: postgres
--

GRANT ALL ON TABLE catalogos.catalogo TO sgiri_app;
GRANT SELECT ON TABLE catalogos.catalogo TO rol_cliente;
GRANT SELECT ON TABLE catalogos.catalogo TO rol_tecnico;
GRANT SELECT ON TABLE catalogos.catalogo TO rol_admin_tecnicos;
GRANT SELECT ON TABLE catalogos.catalogo TO rol_admin_master;
GRANT SELECT ON TABLE catalogos.catalogo TO rol_admin_visual;
GRANT SELECT ON TABLE catalogos.catalogo TO rol_admin_contratos;


--
-- TOC entry 5335 (class 0 OID 0)
-- Dependencies: 241
-- Name: SEQUENCE catalogo_id_catalogo_seq; Type: ACL; Schema: catalogos; Owner: postgres
--

GRANT ALL ON SEQUENCE catalogos.catalogo_id_catalogo_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE catalogos.catalogo_id_catalogo_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE catalogos.catalogo_id_catalogo_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE catalogos.catalogo_id_catalogo_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE catalogos.catalogo_id_catalogo_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE catalogos.catalogo_id_catalogo_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE catalogos.catalogo_id_catalogo_seq TO rol_admin_contratos;


--
-- TOC entry 5337 (class 0 OID 0)
-- Dependencies: 242
-- Name: SEQUENCE catalogo_item_id_item_seq; Type: ACL; Schema: catalogos; Owner: postgres
--

GRANT ALL ON SEQUENCE catalogos.catalogo_item_id_item_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE catalogos.catalogo_item_id_item_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE catalogos.catalogo_item_id_item_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE catalogos.catalogo_item_id_item_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE catalogos.catalogo_item_id_item_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE catalogos.catalogo_item_id_item_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE catalogos.catalogo_item_id_item_seq TO rol_admin_contratos;


--
-- TOC entry 5338 (class 0 OID 0)
-- Dependencies: 243
-- Name: TABLE canton; Type: ACL; Schema: clientes; Owner: postgres
--

GRANT ALL ON TABLE clientes.canton TO sgiri_app;
GRANT SELECT ON TABLE clientes.canton TO rol_cliente;
GRANT SELECT ON TABLE clientes.canton TO rol_tecnico;
GRANT SELECT ON TABLE clientes.canton TO rol_admin_tecnicos;
GRANT SELECT ON TABLE clientes.canton TO rol_admin_master;
GRANT SELECT ON TABLE clientes.canton TO rol_admin_visual;
GRANT SELECT ON TABLE clientes.canton TO rol_admin_contratos;


--
-- TOC entry 5340 (class 0 OID 0)
-- Dependencies: 244
-- Name: SEQUENCE canton_id_canton_seq; Type: ACL; Schema: clientes; Owner: postgres
--

GRANT ALL ON SEQUENCE clientes.canton_id_canton_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE clientes.canton_id_canton_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE clientes.canton_id_canton_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE clientes.canton_id_canton_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE clientes.canton_id_canton_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE clientes.canton_id_canton_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE clientes.canton_id_canton_seq TO rol_admin_contratos;


--
-- TOC entry 5341 (class 0 OID 0)
-- Dependencies: 245
-- Name: TABLE ciudad; Type: ACL; Schema: clientes; Owner: postgres
--

GRANT ALL ON TABLE clientes.ciudad TO sgiri_app;
GRANT SELECT ON TABLE clientes.ciudad TO rol_cliente;
GRANT SELECT ON TABLE clientes.ciudad TO rol_tecnico;
GRANT SELECT ON TABLE clientes.ciudad TO rol_admin_tecnicos;
GRANT SELECT ON TABLE clientes.ciudad TO rol_admin_master;
GRANT SELECT ON TABLE clientes.ciudad TO rol_admin_visual;
GRANT SELECT ON TABLE clientes.ciudad TO rol_admin_contratos;


--
-- TOC entry 5343 (class 0 OID 0)
-- Dependencies: 246
-- Name: SEQUENCE ciudad_id_ciudad_seq; Type: ACL; Schema: clientes; Owner: postgres
--

GRANT ALL ON SEQUENCE clientes.ciudad_id_ciudad_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE clientes.ciudad_id_ciudad_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE clientes.ciudad_id_ciudad_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE clientes.ciudad_id_ciudad_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE clientes.ciudad_id_ciudad_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE clientes.ciudad_id_ciudad_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE clientes.ciudad_id_ciudad_seq TO rol_admin_contratos;


--
-- TOC entry 5344 (class 0 OID 0)
-- Dependencies: 247
-- Name: TABLE cliente; Type: ACL; Schema: clientes; Owner: postgres
--

GRANT ALL ON TABLE clientes.cliente TO sgiri_app;
GRANT SELECT ON TABLE clientes.cliente TO rol_cliente;
GRANT SELECT ON TABLE clientes.cliente TO rol_tecnico;
GRANT SELECT ON TABLE clientes.cliente TO rol_admin_tecnicos;
GRANT SELECT ON TABLE clientes.cliente TO rol_admin_master;
GRANT SELECT ON TABLE clientes.cliente TO rol_admin_visual;
GRANT SELECT ON TABLE clientes.cliente TO rol_admin_contratos;


--
-- TOC entry 5346 (class 0 OID 0)
-- Dependencies: 248
-- Name: SEQUENCE cliente_id_cliente_seq; Type: ACL; Schema: clientes; Owner: postgres
--

GRANT ALL ON SEQUENCE clientes.cliente_id_cliente_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE clientes.cliente_id_cliente_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE clientes.cliente_id_cliente_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE clientes.cliente_id_cliente_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE clientes.cliente_id_cliente_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE clientes.cliente_id_cliente_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE clientes.cliente_id_cliente_seq TO rol_admin_contratos;


--
-- TOC entry 5347 (class 0 OID 0)
-- Dependencies: 249
-- Name: TABLE documento_cliente; Type: ACL; Schema: clientes; Owner: postgres
--

GRANT ALL ON TABLE clientes.documento_cliente TO sgiri_app;
GRANT SELECT ON TABLE clientes.documento_cliente TO rol_cliente;
GRANT SELECT ON TABLE clientes.documento_cliente TO rol_tecnico;
GRANT SELECT ON TABLE clientes.documento_cliente TO rol_admin_tecnicos;
GRANT SELECT ON TABLE clientes.documento_cliente TO rol_admin_master;
GRANT SELECT ON TABLE clientes.documento_cliente TO rol_admin_visual;
GRANT SELECT ON TABLE clientes.documento_cliente TO rol_admin_contratos;


--
-- TOC entry 5349 (class 0 OID 0)
-- Dependencies: 250
-- Name: SEQUENCE documento_cliente_id_documento_seq; Type: ACL; Schema: clientes; Owner: postgres
--

GRANT ALL ON SEQUENCE clientes.documento_cliente_id_documento_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE clientes.documento_cliente_id_documento_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE clientes.documento_cliente_id_documento_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE clientes.documento_cliente_id_documento_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE clientes.documento_cliente_id_documento_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE clientes.documento_cliente_id_documento_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE clientes.documento_cliente_id_documento_seq TO rol_admin_contratos;


--
-- TOC entry 5350 (class 0 OID 0)
-- Dependencies: 251
-- Name: TABLE pais; Type: ACL; Schema: clientes; Owner: postgres
--

GRANT ALL ON TABLE clientes.pais TO sgiri_app;
GRANT SELECT ON TABLE clientes.pais TO rol_cliente;
GRANT SELECT ON TABLE clientes.pais TO rol_tecnico;
GRANT SELECT ON TABLE clientes.pais TO rol_admin_tecnicos;
GRANT SELECT ON TABLE clientes.pais TO rol_admin_master;
GRANT SELECT ON TABLE clientes.pais TO rol_admin_visual;
GRANT SELECT ON TABLE clientes.pais TO rol_admin_contratos;


--
-- TOC entry 5352 (class 0 OID 0)
-- Dependencies: 252
-- Name: SEQUENCE pais_id_pais_seq; Type: ACL; Schema: clientes; Owner: postgres
--

GRANT ALL ON SEQUENCE clientes.pais_id_pais_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE clientes.pais_id_pais_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE clientes.pais_id_pais_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE clientes.pais_id_pais_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE clientes.pais_id_pais_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE clientes.pais_id_pais_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE clientes.pais_id_pais_seq TO rol_admin_contratos;


--
-- TOC entry 5353 (class 0 OID 0)
-- Dependencies: 253
-- Name: TABLE tipo_documento; Type: ACL; Schema: clientes; Owner: postgres
--

GRANT ALL ON TABLE clientes.tipo_documento TO sgiri_app;
GRANT SELECT ON TABLE clientes.tipo_documento TO rol_cliente;
GRANT SELECT ON TABLE clientes.tipo_documento TO rol_tecnico;
GRANT SELECT ON TABLE clientes.tipo_documento TO rol_admin_tecnicos;
GRANT SELECT ON TABLE clientes.tipo_documento TO rol_admin_master;
GRANT SELECT ON TABLE clientes.tipo_documento TO rol_admin_visual;
GRANT SELECT ON TABLE clientes.tipo_documento TO rol_admin_contratos;


--
-- TOC entry 5355 (class 0 OID 0)
-- Dependencies: 254
-- Name: SEQUENCE tipo_documento_id_tipo_documento_seq; Type: ACL; Schema: clientes; Owner: postgres
--

GRANT ALL ON SEQUENCE clientes.tipo_documento_id_tipo_documento_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE clientes.tipo_documento_id_tipo_documento_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE clientes.tipo_documento_id_tipo_documento_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE clientes.tipo_documento_id_tipo_documento_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE clientes.tipo_documento_id_tipo_documento_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE clientes.tipo_documento_id_tipo_documento_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE clientes.tipo_documento_id_tipo_documento_seq TO rol_admin_contratos;


--
-- TOC entry 5356 (class 0 OID 0)
-- Dependencies: 255
-- Name: TABLE area; Type: ACL; Schema: empleados; Owner: postgres
--

GRANT ALL ON TABLE empleados.area TO sgiri_app;
GRANT SELECT ON TABLE empleados.area TO rol_cliente;
GRANT SELECT ON TABLE empleados.area TO rol_tecnico;
GRANT SELECT ON TABLE empleados.area TO rol_admin_tecnicos;
GRANT ALL ON TABLE empleados.area TO rol_admin_master;
GRANT SELECT ON TABLE empleados.area TO rol_admin_visual;
GRANT SELECT,INSERT,UPDATE ON TABLE empleados.area TO rol_admin_contratos;


--
-- TOC entry 5358 (class 0 OID 0)
-- Dependencies: 256
-- Name: SEQUENCE area_id_area_seq; Type: ACL; Schema: empleados; Owner: postgres
--

GRANT ALL ON SEQUENCE empleados.area_id_area_seq TO sgiri_app;
GRANT ALL ON SEQUENCE empleados.area_id_area_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE empleados.area_id_area_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE empleados.area_id_area_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE empleados.area_id_area_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE empleados.area_id_area_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE empleados.area_id_area_seq TO rol_admin_contratos;


--
-- TOC entry 5359 (class 0 OID 0)
-- Dependencies: 257
-- Name: TABLE cargo; Type: ACL; Schema: empleados; Owner: postgres
--

GRANT ALL ON TABLE empleados.cargo TO sgiri_app;
GRANT SELECT ON TABLE empleados.cargo TO rol_cliente;
GRANT SELECT ON TABLE empleados.cargo TO rol_tecnico;
GRANT SELECT ON TABLE empleados.cargo TO rol_admin_tecnicos;
GRANT ALL ON TABLE empleados.cargo TO rol_admin_master;
GRANT SELECT ON TABLE empleados.cargo TO rol_admin_visual;
GRANT SELECT,INSERT,UPDATE ON TABLE empleados.cargo TO rol_admin_contratos;


--
-- TOC entry 5361 (class 0 OID 0)
-- Dependencies: 258
-- Name: SEQUENCE cargo_id_cargo_seq; Type: ACL; Schema: empleados; Owner: postgres
--

GRANT ALL ON SEQUENCE empleados.cargo_id_cargo_seq TO sgiri_app;
GRANT ALL ON SEQUENCE empleados.cargo_id_cargo_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE empleados.cargo_id_cargo_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE empleados.cargo_id_cargo_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE empleados.cargo_id_cargo_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE empleados.cargo_id_cargo_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE empleados.cargo_id_cargo_seq TO rol_admin_contratos;


--
-- TOC entry 5362 (class 0 OID 0)
-- Dependencies: 259
-- Name: TABLE documento_empleado; Type: ACL; Schema: empleados; Owner: postgres
--

GRANT ALL ON TABLE empleados.documento_empleado TO sgiri_app;
GRANT ALL ON TABLE empleados.documento_empleado TO rol_admin_master;
GRANT SELECT ON TABLE empleados.documento_empleado TO rol_cliente;
GRANT SELECT ON TABLE empleados.documento_empleado TO rol_tecnico;
GRANT SELECT ON TABLE empleados.documento_empleado TO rol_admin_tecnicos;
GRANT SELECT ON TABLE empleados.documento_empleado TO rol_admin_visual;
GRANT SELECT,INSERT,UPDATE ON TABLE empleados.documento_empleado TO rol_admin_contratos;


--
-- TOC entry 5364 (class 0 OID 0)
-- Dependencies: 260
-- Name: SEQUENCE documento_empleado_id_documento_seq; Type: ACL; Schema: empleados; Owner: postgres
--

GRANT ALL ON SEQUENCE empleados.documento_empleado_id_documento_seq TO sgiri_app;
GRANT ALL ON SEQUENCE empleados.documento_empleado_id_documento_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE empleados.documento_empleado_id_documento_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE empleados.documento_empleado_id_documento_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE empleados.documento_empleado_id_documento_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE empleados.documento_empleado_id_documento_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE empleados.documento_empleado_id_documento_seq TO rol_admin_contratos;


--
-- TOC entry 5365 (class 0 OID 0)
-- Dependencies: 261
-- Name: SEQUENCE empleado_id_empleado_seq; Type: ACL; Schema: empleados; Owner: postgres
--

GRANT ALL ON SEQUENCE empleados.empleado_id_empleado_seq TO sgiri_app;
GRANT ALL ON SEQUENCE empleados.empleado_id_empleado_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE empleados.empleado_id_empleado_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE empleados.empleado_id_empleado_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE empleados.empleado_id_empleado_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE empleados.empleado_id_empleado_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE empleados.empleado_id_empleado_seq TO rol_admin_contratos;


--
-- TOC entry 5366 (class 0 OID 0)
-- Dependencies: 262
-- Name: TABLE empleado; Type: ACL; Schema: empleados; Owner: postgres
--

GRANT ALL ON TABLE empleados.empleado TO sgiri_app;
GRANT SELECT ON TABLE empleados.empleado TO rol_cliente;
GRANT SELECT ON TABLE empleados.empleado TO rol_tecnico;
GRANT SELECT ON TABLE empleados.empleado TO rol_admin_tecnicos;
GRANT ALL ON TABLE empleados.empleado TO rol_admin_master;
GRANT SELECT ON TABLE empleados.empleado TO rol_admin_visual;
GRANT SELECT,INSERT,UPDATE ON TABLE empleados.empleado TO rol_admin_contratos;


--
-- TOC entry 5367 (class 0 OID 0)
-- Dependencies: 263
-- Name: TABLE tipo_contrato; Type: ACL; Schema: empleados; Owner: postgres
--

GRANT ALL ON TABLE empleados.tipo_contrato TO sgiri_app;
GRANT SELECT ON TABLE empleados.tipo_contrato TO rol_cliente;
GRANT SELECT ON TABLE empleados.tipo_contrato TO rol_tecnico;
GRANT SELECT ON TABLE empleados.tipo_contrato TO rol_admin_tecnicos;
GRANT ALL ON TABLE empleados.tipo_contrato TO rol_admin_master;
GRANT SELECT ON TABLE empleados.tipo_contrato TO rol_admin_visual;
GRANT SELECT,INSERT,UPDATE ON TABLE empleados.tipo_contrato TO rol_admin_contratos;


--
-- TOC entry 5369 (class 0 OID 0)
-- Dependencies: 264
-- Name: SEQUENCE tipo_contrato_id_tipo_contrato_seq; Type: ACL; Schema: empleados; Owner: postgres
--

GRANT ALL ON SEQUENCE empleados.tipo_contrato_id_tipo_contrato_seq TO sgiri_app;
GRANT ALL ON SEQUENCE empleados.tipo_contrato_id_tipo_contrato_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE empleados.tipo_contrato_id_tipo_contrato_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE empleados.tipo_contrato_id_tipo_contrato_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE empleados.tipo_contrato_id_tipo_contrato_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE empleados.tipo_contrato_id_tipo_contrato_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE empleados.tipo_contrato_id_tipo_contrato_seq TO rol_admin_contratos;


--
-- TOC entry 5370 (class 0 OID 0)
-- Dependencies: 265
-- Name: TABLE documento_empresa; Type: ACL; Schema: empresa; Owner: postgres
--

GRANT ALL ON TABLE empresa.documento_empresa TO sgiri_app;
GRANT SELECT ON TABLE empresa.documento_empresa TO rol_cliente;
GRANT SELECT ON TABLE empresa.documento_empresa TO rol_tecnico;
GRANT SELECT ON TABLE empresa.documento_empresa TO rol_admin_tecnicos;
GRANT SELECT ON TABLE empresa.documento_empresa TO rol_admin_master;
GRANT SELECT ON TABLE empresa.documento_empresa TO rol_admin_visual;
GRANT SELECT ON TABLE empresa.documento_empresa TO rol_admin_contratos;


--
-- TOC entry 5372 (class 0 OID 0)
-- Dependencies: 266
-- Name: SEQUENCE documento_empresa_id_documento_seq; Type: ACL; Schema: empresa; Owner: postgres
--

GRANT ALL ON SEQUENCE empresa.documento_empresa_id_documento_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE empresa.documento_empresa_id_documento_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE empresa.documento_empresa_id_documento_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE empresa.documento_empresa_id_documento_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE empresa.documento_empresa_id_documento_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE empresa.documento_empresa_id_documento_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE empresa.documento_empresa_id_documento_seq TO rol_admin_contratos;


--
-- TOC entry 5373 (class 0 OID 0)
-- Dependencies: 267
-- Name: TABLE empresa; Type: ACL; Schema: empresa; Owner: postgres
--

GRANT ALL ON TABLE empresa.empresa TO sgiri_app;
GRANT SELECT ON TABLE empresa.empresa TO rol_cliente;
GRANT SELECT ON TABLE empresa.empresa TO rol_tecnico;
GRANT SELECT ON TABLE empresa.empresa TO rol_admin_tecnicos;
GRANT SELECT ON TABLE empresa.empresa TO rol_admin_master;
GRANT SELECT ON TABLE empresa.empresa TO rol_admin_visual;
GRANT SELECT ON TABLE empresa.empresa TO rol_admin_contratos;


--
-- TOC entry 5375 (class 0 OID 0)
-- Dependencies: 268
-- Name: SEQUENCE empresa_id_empresa_seq; Type: ACL; Schema: empresa; Owner: postgres
--

GRANT ALL ON SEQUENCE empresa.empresa_id_empresa_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE empresa.empresa_id_empresa_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE empresa.empresa_id_empresa_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE empresa.empresa_id_empresa_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE empresa.empresa_id_empresa_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE empresa.empresa_id_empresa_seq TO rol_admin_visual;


--
-- TOC entry 5376 (class 0 OID 0)
-- Dependencies: 269
-- Name: TABLE empresa_servicio; Type: ACL; Schema: empresa; Owner: postgres
--

GRANT ALL ON TABLE empresa.empresa_servicio TO sgiri_app;
GRANT SELECT ON TABLE empresa.empresa_servicio TO rol_cliente;
GRANT SELECT ON TABLE empresa.empresa_servicio TO rol_tecnico;
GRANT SELECT ON TABLE empresa.empresa_servicio TO rol_admin_tecnicos;
GRANT SELECT ON TABLE empresa.empresa_servicio TO rol_admin_master;
GRANT SELECT ON TABLE empresa.empresa_servicio TO rol_admin_visual;


--
-- TOC entry 5377 (class 0 OID 0)
-- Dependencies: 270
-- Name: TABLE servicio; Type: ACL; Schema: empresa; Owner: postgres
--

GRANT ALL ON TABLE empresa.servicio TO sgiri_app;
GRANT SELECT ON TABLE empresa.servicio TO rol_cliente;
GRANT SELECT ON TABLE empresa.servicio TO rol_tecnico;
GRANT SELECT ON TABLE empresa.servicio TO rol_admin_tecnicos;
GRANT SELECT ON TABLE empresa.servicio TO rol_admin_master;
GRANT SELECT ON TABLE empresa.servicio TO rol_admin_visual;


--
-- TOC entry 5379 (class 0 OID 0)
-- Dependencies: 271
-- Name: SEQUENCE servicio_id_servicio_seq; Type: ACL; Schema: empresa; Owner: postgres
--

GRANT ALL ON SEQUENCE empresa.servicio_id_servicio_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE empresa.servicio_id_servicio_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE empresa.servicio_id_servicio_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE empresa.servicio_id_servicio_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE empresa.servicio_id_servicio_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE empresa.servicio_id_servicio_seq TO rol_admin_visual;


--
-- TOC entry 5380 (class 0 OID 0)
-- Dependencies: 272
-- Name: TABLE sucursal; Type: ACL; Schema: empresa; Owner: postgres
--

GRANT ALL ON TABLE empresa.sucursal TO sgiri_app;
GRANT SELECT ON TABLE empresa.sucursal TO rol_cliente;
GRANT SELECT ON TABLE empresa.sucursal TO rol_tecnico;
GRANT SELECT ON TABLE empresa.sucursal TO rol_admin_tecnicos;
GRANT SELECT ON TABLE empresa.sucursal TO rol_admin_master;
GRANT SELECT ON TABLE empresa.sucursal TO rol_admin_visual;


--
-- TOC entry 5382 (class 0 OID 0)
-- Dependencies: 273
-- Name: SEQUENCE sucursal_id_sucursal_seq; Type: ACL; Schema: empresa; Owner: postgres
--

GRANT ALL ON SEQUENCE empresa.sucursal_id_sucursal_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE empresa.sucursal_id_sucursal_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE empresa.sucursal_id_sucursal_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE empresa.sucursal_id_sucursal_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE empresa.sucursal_id_sucursal_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE empresa.sucursal_id_sucursal_seq TO rol_admin_visual;


--
-- TOC entry 5383 (class 0 OID 0)
-- Dependencies: 274
-- Name: TABLE cola_correo; Type: ACL; Schema: notificaciones; Owner: postgres
--

GRANT ALL ON TABLE notificaciones.cola_correo TO sgiri_app;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE notificaciones.cola_correo TO rol_tecnico;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE notificaciones.cola_correo TO rol_admin_tecnicos;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE notificaciones.cola_correo TO rol_admin_master;
GRANT SELECT ON TABLE notificaciones.cola_correo TO rol_cliente;
GRANT SELECT ON TABLE notificaciones.cola_correo TO rol_admin_visual;
GRANT SELECT ON TABLE notificaciones.cola_correo TO rol_admin_contratos;


--
-- TOC entry 5385 (class 0 OID 0)
-- Dependencies: 275
-- Name: SEQUENCE cola_correo_id_correo_seq; Type: ACL; Schema: notificaciones; Owner: postgres
--

GRANT ALL ON SEQUENCE notificaciones.cola_correo_id_correo_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE notificaciones.cola_correo_id_correo_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE notificaciones.cola_correo_id_correo_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE notificaciones.cola_correo_id_correo_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE notificaciones.cola_correo_id_correo_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE notificaciones.cola_correo_id_correo_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE notificaciones.cola_correo_id_correo_seq TO rol_admin_contratos;


--
-- TOC entry 5386 (class 0 OID 0)
-- Dependencies: 276
-- Name: TABLE notificacion_web; Type: ACL; Schema: notificaciones; Owner: postgres
--

GRANT ALL ON TABLE notificaciones.notificacion_web TO sgiri_app;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE notificaciones.notificacion_web TO rol_tecnico;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE notificaciones.notificacion_web TO rol_admin_tecnicos;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE notificaciones.notificacion_web TO rol_admin_master;
GRANT SELECT ON TABLE notificaciones.notificacion_web TO rol_cliente;
GRANT SELECT ON TABLE notificaciones.notificacion_web TO rol_admin_visual;
GRANT SELECT ON TABLE notificaciones.notificacion_web TO rol_admin_contratos;


--
-- TOC entry 5387 (class 0 OID 0)
-- Dependencies: 276 5386
-- Name: COLUMN notificacion_web.leida; Type: ACL; Schema: notificaciones; Owner: postgres
--

GRANT UPDATE(leida) ON TABLE notificaciones.notificacion_web TO rol_tecnico;
GRANT UPDATE(leida) ON TABLE notificaciones.notificacion_web TO rol_cliente;
GRANT UPDATE(leida) ON TABLE notificaciones.notificacion_web TO rol_admin_tecnicos;
GRANT UPDATE(leida) ON TABLE notificaciones.notificacion_web TO rol_admin_master;
GRANT UPDATE(leida) ON TABLE notificaciones.notificacion_web TO rol_admin_visual;


--
-- TOC entry 5388 (class 0 OID 0)
-- Dependencies: 276 5386
-- Name: COLUMN notificacion_web.fecha_lectura; Type: ACL; Schema: notificaciones; Owner: postgres
--

GRANT UPDATE(fecha_lectura) ON TABLE notificaciones.notificacion_web TO rol_tecnico;
GRANT UPDATE(fecha_lectura) ON TABLE notificaciones.notificacion_web TO rol_cliente;
GRANT UPDATE(fecha_lectura) ON TABLE notificaciones.notificacion_web TO rol_admin_tecnicos;
GRANT UPDATE(fecha_lectura) ON TABLE notificaciones.notificacion_web TO rol_admin_master;
GRANT UPDATE(fecha_lectura) ON TABLE notificaciones.notificacion_web TO rol_admin_visual;


--
-- TOC entry 5390 (class 0 OID 0)
-- Dependencies: 277
-- Name: SEQUENCE notificacion_web_id_notificacion_seq; Type: ACL; Schema: notificaciones; Owner: postgres
--

GRANT ALL ON SEQUENCE notificaciones.notificacion_web_id_notificacion_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE notificaciones.notificacion_web_id_notificacion_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE notificaciones.notificacion_web_id_notificacion_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE notificaciones.notificacion_web_id_notificacion_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE notificaciones.notificacion_web_id_notificacion_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE notificaciones.notificacion_web_id_notificacion_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE notificaciones.notificacion_web_id_notificacion_seq TO rol_admin_contratos;


--
-- TOC entry 5391 (class 0 OID 0)
-- Dependencies: 278
-- Name: TABLE configuracion_reporte; Type: ACL; Schema: reportes; Owner: postgres
--

GRANT ALL ON TABLE reportes.configuracion_reporte TO rol_admin_master;
GRANT SELECT ON TABLE reportes.configuracion_reporte TO rol_cliente;
GRANT SELECT ON TABLE reportes.configuracion_reporte TO rol_tecnico;
GRANT SELECT ON TABLE reportes.configuracion_reporte TO rol_admin_tecnicos;
GRANT SELECT ON TABLE reportes.configuracion_reporte TO rol_admin_visual;
GRANT SELECT ON TABLE reportes.configuracion_reporte TO rol_admin_contratos;


--
-- TOC entry 5393 (class 0 OID 0)
-- Dependencies: 279
-- Name: SEQUENCE configuracion_reporte_id_reporte_seq; Type: ACL; Schema: reportes; Owner: postgres
--

GRANT ALL ON SEQUENCE reportes.configuracion_reporte_id_reporte_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE reportes.configuracion_reporte_id_reporte_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE reportes.configuracion_reporte_id_reporte_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE reportes.configuracion_reporte_id_reporte_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE reportes.configuracion_reporte_id_reporte_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE reportes.configuracion_reporte_id_reporte_seq TO rol_admin_contratos;


--
-- TOC entry 5394 (class 0 OID 0)
-- Dependencies: 280
-- Name: TABLE historial_generacion; Type: ACL; Schema: reportes; Owner: postgres
--

GRANT ALL ON TABLE reportes.historial_generacion TO rol_admin_master;
GRANT SELECT ON TABLE reportes.historial_generacion TO rol_cliente;
GRANT SELECT ON TABLE reportes.historial_generacion TO rol_tecnico;
GRANT SELECT ON TABLE reportes.historial_generacion TO rol_admin_tecnicos;
GRANT SELECT ON TABLE reportes.historial_generacion TO rol_admin_visual;
GRANT SELECT ON TABLE reportes.historial_generacion TO rol_admin_contratos;


--
-- TOC entry 5396 (class 0 OID 0)
-- Dependencies: 281
-- Name: SEQUENCE historial_generacion_id_generacion_seq; Type: ACL; Schema: reportes; Owner: postgres
--

GRANT ALL ON SEQUENCE reportes.historial_generacion_id_generacion_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE reportes.historial_generacion_id_generacion_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE reportes.historial_generacion_id_generacion_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE reportes.historial_generacion_id_generacion_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE reportes.historial_generacion_id_generacion_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE reportes.historial_generacion_id_generacion_seq TO rol_admin_contratos;


--
-- TOC entry 5402 (class 0 OID 0)
-- Dependencies: 282
-- Name: TABLE ticket; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON TABLE soporte.ticket TO sgiri_app;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.ticket TO rol_tecnico;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.ticket TO rol_admin_tecnicos;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.ticket TO rol_admin_master;
GRANT SELECT,INSERT ON TABLE soporte.ticket TO rol_cliente;
GRANT SELECT ON TABLE soporte.ticket TO rol_admin_visual;
GRANT SELECT ON TABLE soporte.ticket TO rol_admin_contratos;


--
-- TOC entry 5403 (class 0 OID 0)
-- Dependencies: 282 5402
-- Name: COLUMN ticket.fecha_actualizacion; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT UPDATE(fecha_actualizacion) ON TABLE soporte.ticket TO rol_tecnico;


--
-- TOC entry 5404 (class 0 OID 0)
-- Dependencies: 282 5402
-- Name: COLUMN ticket.id_estado_item; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT UPDATE(id_estado_item) ON TABLE soporte.ticket TO rol_tecnico;


--
-- TOC entry 5405 (class 0 OID 0)
-- Dependencies: 282 5402
-- Name: COLUMN ticket.id_categoria_item; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT UPDATE(id_categoria_item) ON TABLE soporte.ticket TO rol_tecnico;


--
-- TOC entry 5406 (class 0 OID 0)
-- Dependencies: 282 5402
-- Name: COLUMN ticket.fecha_cierre; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT UPDATE(fecha_cierre) ON TABLE soporte.ticket TO rol_tecnico;


--
-- TOC entry 5407 (class 0 OID 0)
-- Dependencies: 282 5402
-- Name: COLUMN ticket.impacto; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT UPDATE(impacto) ON TABLE soporte.ticket TO rol_tecnico;


--
-- TOC entry 5408 (class 0 OID 0)
-- Dependencies: 282 5402
-- Name: COLUMN ticket.urgencia; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT UPDATE(urgencia) ON TABLE soporte.ticket TO rol_tecnico;


--
-- TOC entry 5409 (class 0 OID 0)
-- Dependencies: 282 5402
-- Name: COLUMN ticket.puntaje_prioridad; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT UPDATE(puntaje_prioridad) ON TABLE soporte.ticket TO rol_tecnico;


--
-- TOC entry 5410 (class 0 OID 0)
-- Dependencies: 283
-- Name: TABLE vw_csat_analisis; Type: ACL; Schema: reportes; Owner: postgres
--

GRANT ALL ON TABLE reportes.vw_csat_analisis TO rol_admin_master;
GRANT SELECT ON TABLE reportes.vw_csat_analisis TO rol_cliente;
GRANT SELECT ON TABLE reportes.vw_csat_analisis TO rol_tecnico;
GRANT SELECT ON TABLE reportes.vw_csat_analisis TO rol_admin_tecnicos;
GRANT SELECT ON TABLE reportes.vw_csat_analisis TO rol_admin_visual;
GRANT SELECT ON TABLE reportes.vw_csat_analisis TO rol_admin_contratos;


--
-- TOC entry 5411 (class 0 OID 0)
-- Dependencies: 284
-- Name: TABLE persona; Type: ACL; Schema: usuarios; Owner: postgres
--

GRANT ALL ON TABLE usuarios.persona TO sgiri_app;
GRANT SELECT ON TABLE usuarios.persona TO emp_1203587489_21;
GRANT SELECT ON TABLE usuarios.persona TO rol_cliente;
GRANT SELECT ON TABLE usuarios.persona TO rol_tecnico;
GRANT SELECT ON TABLE usuarios.persona TO rol_admin_tecnicos;
GRANT SELECT ON TABLE usuarios.persona TO rol_admin_visual;
GRANT ALL ON TABLE usuarios.persona TO rol_admin_master;
GRANT SELECT,INSERT ON TABLE usuarios.persona TO rol_admin_contratos;


--
-- TOC entry 5412 (class 0 OID 0)
-- Dependencies: 285
-- Name: TABLE vw_csat_detalle; Type: ACL; Schema: reportes; Owner: postgres
--

GRANT ALL ON TABLE reportes.vw_csat_detalle TO rol_admin_master;
GRANT SELECT ON TABLE reportes.vw_csat_detalle TO rol_cliente;
GRANT SELECT ON TABLE reportes.vw_csat_detalle TO rol_tecnico;
GRANT SELECT ON TABLE reportes.vw_csat_detalle TO rol_admin_tecnicos;
GRANT SELECT ON TABLE reportes.vw_csat_detalle TO rol_admin_visual;
GRANT SELECT ON TABLE reportes.vw_csat_detalle TO rol_admin_contratos;


--
-- TOC entry 5414 (class 0 OID 0)
-- Dependencies: 286
-- Name: TABLE visita_tecnica; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON TABLE soporte.visita_tecnica TO sgiri_app;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.visita_tecnica TO rol_tecnico;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.visita_tecnica TO rol_admin_tecnicos;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.visita_tecnica TO rol_admin_master;
GRANT SELECT ON TABLE soporte.visita_tecnica TO rol_cliente;
GRANT SELECT ON TABLE soporte.visita_tecnica TO rol_admin_visual;
GRANT SELECT ON TABLE soporte.visita_tecnica TO rol_admin_contratos;


--
-- TOC entry 5415 (class 0 OID 0)
-- Dependencies: 287
-- Name: TABLE "vw_desempeño_tecnicos"; Type: ACL; Schema: reportes; Owner: postgres
--

GRANT ALL ON TABLE reportes."vw_desempeño_tecnicos" TO rol_admin_master;
GRANT SELECT ON TABLE reportes."vw_desempeño_tecnicos" TO rol_cliente;
GRANT SELECT ON TABLE reportes."vw_desempeño_tecnicos" TO rol_tecnico;
GRANT SELECT ON TABLE reportes."vw_desempeño_tecnicos" TO rol_admin_tecnicos;
GRANT SELECT ON TABLE reportes."vw_desempeño_tecnicos" TO rol_admin_visual;
GRANT SELECT ON TABLE reportes."vw_desempeño_tecnicos" TO rol_admin_contratos;


--
-- TOC entry 5416 (class 0 OID 0)
-- Dependencies: 288
-- Name: TABLE vw_resumen_tickets; Type: ACL; Schema: reportes; Owner: postgres
--

GRANT ALL ON TABLE reportes.vw_resumen_tickets TO rol_admin_master;
GRANT SELECT ON TABLE reportes.vw_resumen_tickets TO rol_cliente;
GRANT SELECT ON TABLE reportes.vw_resumen_tickets TO rol_tecnico;
GRANT SELECT ON TABLE reportes.vw_resumen_tickets TO rol_admin_tecnicos;
GRANT SELECT ON TABLE reportes.vw_resumen_tickets TO rol_admin_visual;
GRANT SELECT ON TABLE reportes.vw_resumen_tickets TO rol_admin_contratos;


--
-- TOC entry 5417 (class 0 OID 0)
-- Dependencies: 289
-- Name: TABLE asignacion; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON TABLE soporte.asignacion TO sgiri_app;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.asignacion TO rol_tecnico;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.asignacion TO rol_admin_tecnicos;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.asignacion TO rol_admin_master;
GRANT SELECT ON TABLE soporte.asignacion TO rol_cliente;
GRANT SELECT ON TABLE soporte.asignacion TO rol_admin_visual;
GRANT SELECT ON TABLE soporte.asignacion TO rol_admin_contratos;


--
-- TOC entry 5419 (class 0 OID 0)
-- Dependencies: 290
-- Name: SEQUENCE asignacion_id_asignacion_seq; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON SEQUENCE soporte.asignacion_id_asignacion_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE soporte.asignacion_id_asignacion_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE soporte.asignacion_id_asignacion_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE soporte.asignacion_id_asignacion_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE soporte.asignacion_id_asignacion_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE soporte.asignacion_id_asignacion_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE soporte.asignacion_id_asignacion_seq TO rol_admin_contratos;


--
-- TOC entry 5420 (class 0 OID 0)
-- Dependencies: 291
-- Name: TABLE categoria; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON TABLE soporte.categoria TO sgiri_app;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.categoria TO rol_tecnico;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.categoria TO rol_admin_tecnicos;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.categoria TO rol_admin_master;
GRANT SELECT ON TABLE soporte.categoria TO rol_cliente;
GRANT SELECT ON TABLE soporte.categoria TO rol_admin_visual;
GRANT SELECT ON TABLE soporte.categoria TO rol_admin_contratos;


--
-- TOC entry 5422 (class 0 OID 0)
-- Dependencies: 292
-- Name: SEQUENCE categoria_id_categoria_seq; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON SEQUENCE soporte.categoria_id_categoria_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE soporte.categoria_id_categoria_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE soporte.categoria_id_categoria_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE soporte.categoria_id_categoria_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE soporte.categoria_id_categoria_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE soporte.categoria_id_categoria_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE soporte.categoria_id_categoria_seq TO rol_admin_contratos;


--
-- TOC entry 5423 (class 0 OID 0)
-- Dependencies: 293
-- Name: TABLE comentario_ticket; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON TABLE soporte.comentario_ticket TO sgiri_app;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.comentario_ticket TO rol_tecnico;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.comentario_ticket TO rol_admin_tecnicos;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.comentario_ticket TO rol_admin_master;
GRANT SELECT,INSERT ON TABLE soporte.comentario_ticket TO rol_cliente;
GRANT SELECT ON TABLE soporte.comentario_ticket TO rol_admin_visual;
GRANT SELECT ON TABLE soporte.comentario_ticket TO rol_admin_contratos;


--
-- TOC entry 5425 (class 0 OID 0)
-- Dependencies: 294
-- Name: SEQUENCE comentario_ticket_id_comentario_seq; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON SEQUENCE soporte.comentario_ticket_id_comentario_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE soporte.comentario_ticket_id_comentario_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE soporte.comentario_ticket_id_comentario_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE soporte.comentario_ticket_id_comentario_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE soporte.comentario_ticket_id_comentario_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE soporte.comentario_ticket_id_comentario_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE soporte.comentario_ticket_id_comentario_seq TO rol_admin_contratos;


--
-- TOC entry 5426 (class 0 OID 0)
-- Dependencies: 295
-- Name: TABLE documento_ticket; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON TABLE soporte.documento_ticket TO sgiri_app;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.documento_ticket TO rol_tecnico;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.documento_ticket TO rol_admin_tecnicos;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.documento_ticket TO rol_admin_master;
GRANT SELECT,INSERT ON TABLE soporte.documento_ticket TO rol_cliente;
GRANT SELECT ON TABLE soporte.documento_ticket TO rol_admin_visual;
GRANT SELECT ON TABLE soporte.documento_ticket TO rol_admin_contratos;


--
-- TOC entry 5428 (class 0 OID 0)
-- Dependencies: 296
-- Name: SEQUENCE documento_ticket_id_documento_seq; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON SEQUENCE soporte.documento_ticket_id_documento_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE soporte.documento_ticket_id_documento_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE soporte.documento_ticket_id_documento_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE soporte.documento_ticket_id_documento_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE soporte.documento_ticket_id_documento_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE soporte.documento_ticket_id_documento_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE soporte.documento_ticket_id_documento_seq TO rol_admin_contratos;


--
-- TOC entry 5429 (class 0 OID 0)
-- Dependencies: 297
-- Name: TABLE historial_estado; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON TABLE soporte.historial_estado TO sgiri_app;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.historial_estado TO rol_tecnico;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.historial_estado TO rol_admin_tecnicos;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.historial_estado TO rol_admin_master;
GRANT SELECT ON TABLE soporte.historial_estado TO rol_cliente;
GRANT SELECT ON TABLE soporte.historial_estado TO rol_admin_visual;
GRANT SELECT ON TABLE soporte.historial_estado TO rol_admin_contratos;


--
-- TOC entry 5431 (class 0 OID 0)
-- Dependencies: 298
-- Name: SEQUENCE historial_estado_id_historial_seq; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON SEQUENCE soporte.historial_estado_id_historial_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE soporte.historial_estado_id_historial_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE soporte.historial_estado_id_historial_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE soporte.historial_estado_id_historial_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE soporte.historial_estado_id_historial_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE soporte.historial_estado_id_historial_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE soporte.historial_estado_id_historial_seq TO rol_admin_contratos;


--
-- TOC entry 5441 (class 0 OID 0)
-- Dependencies: 299
-- Name: TABLE informe_trabajo_tecnico; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON TABLE soporte.informe_trabajo_tecnico TO sgiri_app;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.informe_trabajo_tecnico TO rol_tecnico;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.informe_trabajo_tecnico TO rol_admin_tecnicos;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.informe_trabajo_tecnico TO rol_admin_master;
GRANT SELECT ON TABLE soporte.informe_trabajo_tecnico TO rol_cliente;
GRANT SELECT ON TABLE soporte.informe_trabajo_tecnico TO rol_admin_visual;
GRANT SELECT ON TABLE soporte.informe_trabajo_tecnico TO rol_admin_contratos;


--
-- TOC entry 5443 (class 0 OID 0)
-- Dependencies: 300
-- Name: SEQUENCE informe_trabajo_tecnico_id_informe_seq; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON SEQUENCE soporte.informe_trabajo_tecnico_id_informe_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE soporte.informe_trabajo_tecnico_id_informe_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE soporte.informe_trabajo_tecnico_id_informe_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE soporte.informe_trabajo_tecnico_id_informe_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE soporte.informe_trabajo_tecnico_id_informe_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE soporte.informe_trabajo_tecnico_id_informe_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE soporte.informe_trabajo_tecnico_id_informe_seq TO rol_admin_contratos;


--
-- TOC entry 5444 (class 0 OID 0)
-- Dependencies: 301
-- Name: TABLE inventario; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON TABLE soporte.inventario TO sgiri_app;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.inventario TO rol_tecnico;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.inventario TO rol_admin_tecnicos;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.inventario TO rol_admin_master;
GRANT SELECT ON TABLE soporte.inventario TO rol_cliente;
GRANT SELECT ON TABLE soporte.inventario TO rol_admin_visual;
GRANT SELECT ON TABLE soporte.inventario TO rol_admin_contratos;


--
-- TOC entry 5446 (class 0 OID 0)
-- Dependencies: 302
-- Name: SEQUENCE inventario_id_item_inventario_seq; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON SEQUENCE soporte.inventario_id_item_inventario_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE soporte.inventario_id_item_inventario_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE soporte.inventario_id_item_inventario_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE soporte.inventario_id_item_inventario_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE soporte.inventario_id_item_inventario_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE soporte.inventario_id_item_inventario_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE soporte.inventario_id_item_inventario_seq TO rol_admin_contratos;


--
-- TOC entry 5447 (class 0 OID 0)
-- Dependencies: 303
-- Name: TABLE inventario_usado_ticket; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON TABLE soporte.inventario_usado_ticket TO sgiri_app;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.inventario_usado_ticket TO rol_tecnico;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.inventario_usado_ticket TO rol_admin_tecnicos;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.inventario_usado_ticket TO rol_admin_master;
GRANT SELECT ON TABLE soporte.inventario_usado_ticket TO rol_cliente;
GRANT SELECT ON TABLE soporte.inventario_usado_ticket TO rol_admin_visual;
GRANT SELECT ON TABLE soporte.inventario_usado_ticket TO rol_admin_contratos;


--
-- TOC entry 5449 (class 0 OID 0)
-- Dependencies: 304
-- Name: SEQUENCE inventario_usado_ticket_id_uso_seq; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON SEQUENCE soporte.inventario_usado_ticket_id_uso_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE soporte.inventario_usado_ticket_id_uso_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE soporte.inventario_usado_ticket_id_uso_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE soporte.inventario_usado_ticket_id_uso_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE soporte.inventario_usado_ticket_id_uso_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE soporte.inventario_usado_ticket_id_uso_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE soporte.inventario_usado_ticket_id_uso_seq TO rol_admin_contratos;


--
-- TOC entry 5450 (class 0 OID 0)
-- Dependencies: 305
-- Name: TABLE network_probe_result; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON TABLE soporte.network_probe_result TO sgiri_app;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.network_probe_result TO rol_tecnico;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.network_probe_result TO rol_admin_tecnicos;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.network_probe_result TO rol_admin_master;
GRANT SELECT ON TABLE soporte.network_probe_result TO rol_cliente;
GRANT SELECT ON TABLE soporte.network_probe_result TO rol_admin_visual;
GRANT SELECT ON TABLE soporte.network_probe_result TO rol_admin_contratos;


--
-- TOC entry 5452 (class 0 OID 0)
-- Dependencies: 306
-- Name: SEQUENCE network_probe_result_id_result_seq; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON SEQUENCE soporte.network_probe_result_id_result_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE soporte.network_probe_result_id_result_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE soporte.network_probe_result_id_result_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE soporte.network_probe_result_id_result_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE soporte.network_probe_result_id_result_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE soporte.network_probe_result_id_result_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE soporte.network_probe_result_id_result_seq TO rol_admin_contratos;


--
-- TOC entry 5453 (class 0 OID 0)
-- Dependencies: 307
-- Name: TABLE network_probe_run; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON TABLE soporte.network_probe_run TO sgiri_app;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.network_probe_run TO rol_tecnico;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.network_probe_run TO rol_admin_tecnicos;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.network_probe_run TO rol_admin_master;
GRANT SELECT ON TABLE soporte.network_probe_run TO rol_cliente;
GRANT SELECT ON TABLE soporte.network_probe_run TO rol_admin_visual;
GRANT SELECT ON TABLE soporte.network_probe_run TO rol_admin_contratos;


--
-- TOC entry 5455 (class 0 OID 0)
-- Dependencies: 308
-- Name: SEQUENCE network_probe_run_id_run_seq; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON SEQUENCE soporte.network_probe_run_id_run_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE soporte.network_probe_run_id_run_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE soporte.network_probe_run_id_run_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE soporte.network_probe_run_id_run_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE soporte.network_probe_run_id_run_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE soporte.network_probe_run_id_run_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE soporte.network_probe_run_id_run_seq TO rol_admin_contratos;


--
-- TOC entry 5456 (class 0 OID 0)
-- Dependencies: 309
-- Name: TABLE prioridad; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON TABLE soporte.prioridad TO sgiri_app;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.prioridad TO rol_tecnico;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.prioridad TO rol_admin_tecnicos;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.prioridad TO rol_admin_master;
GRANT SELECT ON TABLE soporte.prioridad TO rol_cliente;
GRANT SELECT ON TABLE soporte.prioridad TO rol_admin_visual;
GRANT SELECT ON TABLE soporte.prioridad TO rol_admin_contratos;


--
-- TOC entry 5458 (class 0 OID 0)
-- Dependencies: 310
-- Name: SEQUENCE prioridad_id_prioridad_seq; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON SEQUENCE soporte.prioridad_id_prioridad_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE soporte.prioridad_id_prioridad_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE soporte.prioridad_id_prioridad_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE soporte.prioridad_id_prioridad_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE soporte.prioridad_id_prioridad_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE soporte.prioridad_id_prioridad_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE soporte.prioridad_id_prioridad_seq TO rol_admin_contratos;


--
-- TOC entry 5459 (class 0 OID 0)
-- Dependencies: 311
-- Name: TABLE problema; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON TABLE soporte.problema TO sgiri_app;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.problema TO rol_tecnico;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.problema TO rol_admin_tecnicos;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.problema TO rol_admin_master;
GRANT SELECT ON TABLE soporte.problema TO rol_cliente;
GRANT SELECT ON TABLE soporte.problema TO rol_admin_visual;
GRANT SELECT ON TABLE soporte.problema TO rol_admin_contratos;


--
-- TOC entry 5461 (class 0 OID 0)
-- Dependencies: 312
-- Name: SEQUENCE problema_id_problema_seq; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON SEQUENCE soporte.problema_id_problema_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE soporte.problema_id_problema_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE soporte.problema_id_problema_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE soporte.problema_id_problema_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE soporte.problema_id_problema_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE soporte.problema_id_problema_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE soporte.problema_id_problema_seq TO rol_admin_contratos;


--
-- TOC entry 5462 (class 0 OID 0)
-- Dependencies: 313
-- Name: TABLE sla_ticket; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON TABLE soporte.sla_ticket TO sgiri_app;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.sla_ticket TO rol_tecnico;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.sla_ticket TO rol_admin_tecnicos;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.sla_ticket TO rol_admin_master;
GRANT SELECT ON TABLE soporte.sla_ticket TO rol_cliente;
GRANT SELECT ON TABLE soporte.sla_ticket TO rol_admin_visual;
GRANT SELECT ON TABLE soporte.sla_ticket TO rol_admin_contratos;


--
-- TOC entry 5464 (class 0 OID 0)
-- Dependencies: 314
-- Name: SEQUENCE sla_ticket_id_sla_seq; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON SEQUENCE soporte.sla_ticket_id_sla_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE soporte.sla_ticket_id_sla_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE soporte.sla_ticket_id_sla_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE soporte.sla_ticket_id_sla_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE soporte.sla_ticket_id_sla_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE soporte.sla_ticket_id_sla_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE soporte.sla_ticket_id_sla_seq TO rol_admin_contratos;


--
-- TOC entry 5465 (class 0 OID 0)
-- Dependencies: 315
-- Name: TABLE solucion_ticket; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON TABLE soporte.solucion_ticket TO sgiri_app;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.solucion_ticket TO rol_tecnico;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.solucion_ticket TO rol_admin_tecnicos;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE soporte.solucion_ticket TO rol_admin_master;
GRANT SELECT ON TABLE soporte.solucion_ticket TO rol_cliente;
GRANT SELECT ON TABLE soporte.solucion_ticket TO rol_admin_visual;
GRANT SELECT ON TABLE soporte.solucion_ticket TO rol_admin_contratos;


--
-- TOC entry 5467 (class 0 OID 0)
-- Dependencies: 316
-- Name: SEQUENCE solucion_ticket_id_solucion_seq; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON SEQUENCE soporte.solucion_ticket_id_solucion_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE soporte.solucion_ticket_id_solucion_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE soporte.solucion_ticket_id_solucion_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE soporte.solucion_ticket_id_solucion_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE soporte.solucion_ticket_id_solucion_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE soporte.solucion_ticket_id_solucion_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE soporte.solucion_ticket_id_solucion_seq TO rol_admin_contratos;


--
-- TOC entry 5469 (class 0 OID 0)
-- Dependencies: 317
-- Name: SEQUENCE ticket_id_ticket_seq; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON SEQUENCE soporte.ticket_id_ticket_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE soporte.ticket_id_ticket_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE soporte.ticket_id_ticket_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE soporte.ticket_id_ticket_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE soporte.ticket_id_ticket_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE soporte.ticket_id_ticket_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE soporte.ticket_id_ticket_seq TO rol_admin_contratos;


--
-- TOC entry 5471 (class 0 OID 0)
-- Dependencies: 318
-- Name: SEQUENCE visita_tecnica_id_visita_seq; Type: ACL; Schema: soporte; Owner: postgres
--

GRANT ALL ON SEQUENCE soporte.visita_tecnica_id_visita_seq TO sgiri_app;
GRANT SELECT,USAGE ON SEQUENCE soporte.visita_tecnica_id_visita_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE soporte.visita_tecnica_id_visita_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE soporte.visita_tecnica_id_visita_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE soporte.visita_tecnica_id_visita_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE soporte.visita_tecnica_id_visita_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE soporte.visita_tecnica_id_visita_seq TO rol_admin_contratos;


--
-- TOC entry 5473 (class 0 OID 0)
-- Dependencies: 319
-- Name: SEQUENCE persona_id_persona_seq; Type: ACL; Schema: usuarios; Owner: postgres
--

GRANT ALL ON SEQUENCE usuarios.persona_id_persona_seq TO sgiri_app;
GRANT ALL ON SEQUENCE usuarios.persona_id_persona_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE usuarios.persona_id_persona_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE usuarios.persona_id_persona_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE usuarios.persona_id_persona_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE usuarios.persona_id_persona_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE usuarios.persona_id_persona_seq TO rol_admin_contratos;


--
-- TOC entry 5474 (class 0 OID 0)
-- Dependencies: 320
-- Name: TABLE rol; Type: ACL; Schema: usuarios; Owner: postgres
--

GRANT ALL ON TABLE usuarios.rol TO sgiri_app;
GRANT ALL ON TABLE usuarios.rol TO rol_admin_master;
GRANT SELECT ON TABLE usuarios.rol TO rol_cliente;
GRANT SELECT ON TABLE usuarios.rol TO rol_tecnico;
GRANT SELECT ON TABLE usuarios.rol TO rol_admin_tecnicos;
GRANT SELECT ON TABLE usuarios.rol TO rol_admin_visual;
GRANT SELECT,INSERT ON TABLE usuarios.rol TO rol_admin_contratos;


--
-- TOC entry 5475 (class 0 OID 0)
-- Dependencies: 321
-- Name: TABLE rol_bd; Type: ACL; Schema: usuarios; Owner: postgres
--

GRANT ALL ON TABLE usuarios.rol_bd TO sgiri_app;
GRANT ALL ON TABLE usuarios.rol_bd TO rol_admin_master;
GRANT SELECT ON TABLE usuarios.rol_bd TO rol_cliente;
GRANT SELECT ON TABLE usuarios.rol_bd TO rol_tecnico;
GRANT SELECT ON TABLE usuarios.rol_bd TO rol_admin_tecnicos;
GRANT SELECT ON TABLE usuarios.rol_bd TO rol_admin_visual;
GRANT SELECT ON TABLE usuarios.rol_bd TO rol_admin_contratos;


--
-- TOC entry 5477 (class 0 OID 0)
-- Dependencies: 322
-- Name: SEQUENCE rol_bd_id_rol_bd_seq; Type: ACL; Schema: usuarios; Owner: postgres
--

GRANT ALL ON SEQUENCE usuarios.rol_bd_id_rol_bd_seq TO sgiri_app;
GRANT ALL ON SEQUENCE usuarios.rol_bd_id_rol_bd_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE usuarios.rol_bd_id_rol_bd_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE usuarios.rol_bd_id_rol_bd_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE usuarios.rol_bd_id_rol_bd_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE usuarios.rol_bd_id_rol_bd_seq TO rol_admin_visual;


--
-- TOC entry 5479 (class 0 OID 0)
-- Dependencies: 323
-- Name: SEQUENCE rol_id_rol_seq; Type: ACL; Schema: usuarios; Owner: postgres
--

GRANT ALL ON SEQUENCE usuarios.rol_id_rol_seq TO sgiri_app;
GRANT ALL ON SEQUENCE usuarios.rol_id_rol_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE usuarios.rol_id_rol_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE usuarios.rol_id_rol_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE usuarios.rol_id_rol_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE usuarios.rol_id_rol_seq TO rol_admin_visual;


--
-- TOC entry 5480 (class 0 OID 0)
-- Dependencies: 324
-- Name: TABLE usuario_bd; Type: ACL; Schema: usuarios; Owner: postgres
--

GRANT ALL ON TABLE usuarios.usuario_bd TO sgiri_app;
GRANT ALL ON TABLE usuarios.usuario_bd TO rol_admin_master;
GRANT SELECT ON TABLE usuarios.usuario_bd TO rol_cliente;
GRANT SELECT ON TABLE usuarios.usuario_bd TO rol_tecnico;
GRANT SELECT ON TABLE usuarios.usuario_bd TO rol_admin_tecnicos;
GRANT SELECT ON TABLE usuarios.usuario_bd TO rol_admin_visual;
GRANT SELECT,INSERT ON TABLE usuarios.usuario_bd TO rol_admin_contratos;


--
-- TOC entry 5482 (class 0 OID 0)
-- Dependencies: 325
-- Name: SEQUENCE usuario_bd_id_usuario_bd_seq; Type: ACL; Schema: usuarios; Owner: postgres
--

GRANT ALL ON SEQUENCE usuarios.usuario_bd_id_usuario_bd_seq TO sgiri_app;
GRANT ALL ON SEQUENCE usuarios.usuario_bd_id_usuario_bd_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE usuarios.usuario_bd_id_usuario_bd_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE usuarios.usuario_bd_id_usuario_bd_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE usuarios.usuario_bd_id_usuario_bd_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE usuarios.usuario_bd_id_usuario_bd_seq TO rol_admin_visual;


--
-- TOC entry 5484 (class 0 OID 0)
-- Dependencies: 326
-- Name: SEQUENCE usuario_id_usuario_seq; Type: ACL; Schema: usuarios; Owner: postgres
--

GRANT ALL ON SEQUENCE usuarios.usuario_id_usuario_seq TO sgiri_app;
GRANT ALL ON SEQUENCE usuarios.usuario_id_usuario_seq TO rol_admin_master;
GRANT SELECT,USAGE ON SEQUENCE usuarios.usuario_id_usuario_seq TO rol_cliente;
GRANT SELECT,USAGE ON SEQUENCE usuarios.usuario_id_usuario_seq TO rol_tecnico;
GRANT SELECT,USAGE ON SEQUENCE usuarios.usuario_id_usuario_seq TO rol_admin_tecnicos;
GRANT SELECT,USAGE ON SEQUENCE usuarios.usuario_id_usuario_seq TO rol_admin_visual;
GRANT SELECT,USAGE ON SEQUENCE usuarios.usuario_id_usuario_seq TO rol_admin_contratos;


--
-- TOC entry 2380 (class 826 OID 24813)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: auditoria; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA auditoria GRANT SELECT,USAGE ON SEQUENCES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA auditoria GRANT SELECT,USAGE ON SEQUENCES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA auditoria GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA auditoria GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA auditoria GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_visual;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA auditoria GRANT ALL ON SEQUENCES TO sgiri_app;


--
-- TOC entry 2365 (class 826 OID 24821)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: auditoria; Owner: sgiri_app
--

ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA auditoria GRANT SELECT,USAGE ON SEQUENCES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA auditoria GRANT SELECT,USAGE ON SEQUENCES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA auditoria GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA auditoria GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA auditoria GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_visual;


--
-- TOC entry 2361 (class 826 OID 24796)
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: auditoria; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA auditoria GRANT ALL ON FUNCTIONS TO sgiri_app;


--
-- TOC entry 2379 (class 826 OID 24805)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: auditoria; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA auditoria GRANT SELECT,INSERT ON TABLES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA auditoria GRANT SELECT,INSERT ON TABLES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA auditoria GRANT SELECT,INSERT ON TABLES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA auditoria GRANT SELECT,INSERT ON TABLES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA auditoria GRANT SELECT ON TABLES TO rol_admin_visual;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA auditoria GRANT ALL ON TABLES TO sgiri_app;


--
-- TOC entry 2364 (class 826 OID 24820)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: auditoria; Owner: sgiri_app
--

ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA auditoria GRANT SELECT,INSERT ON TABLES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA auditoria GRANT SELECT,INSERT ON TABLES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA auditoria GRANT SELECT,INSERT ON TABLES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA auditoria GRANT SELECT,INSERT ON TABLES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA auditoria GRANT SELECT ON TABLES TO rol_admin_visual;


--
-- TOC entry 2367 (class 826 OID 24812)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: catalogos; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA catalogos GRANT SELECT,USAGE ON SEQUENCES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA catalogos GRANT SELECT,USAGE ON SEQUENCES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA catalogos GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA catalogos GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA catalogos GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_visual;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA catalogos GRANT ALL ON SEQUENCES TO sgiri_app;


--
-- TOC entry 2369 (class 826 OID 24823)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: catalogos; Owner: sgiri_app
--

ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA catalogos GRANT SELECT,USAGE ON SEQUENCES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA catalogos GRANT SELECT,USAGE ON SEQUENCES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA catalogos GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA catalogos GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA catalogos GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_visual;


--
-- TOC entry 2360 (class 826 OID 24795)
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: catalogos; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA catalogos GRANT ALL ON FUNCTIONS TO sgiri_app;


--
-- TOC entry 2366 (class 826 OID 24804)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: catalogos; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA catalogos GRANT SELECT ON TABLES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA catalogos GRANT SELECT ON TABLES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA catalogos GRANT SELECT ON TABLES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA catalogos GRANT SELECT ON TABLES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA catalogos GRANT SELECT ON TABLES TO rol_admin_visual;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA catalogos GRANT ALL ON TABLES TO sgiri_app;


--
-- TOC entry 2368 (class 826 OID 24822)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: catalogos; Owner: sgiri_app
--

ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA catalogos GRANT SELECT ON TABLES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA catalogos GRANT SELECT ON TABLES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA catalogos GRANT SELECT ON TABLES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA catalogos GRANT SELECT ON TABLES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA catalogos GRANT SELECT ON TABLES TO rol_admin_visual;


--
-- TOC entry 2371 (class 826 OID 24810)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: clientes; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA clientes GRANT SELECT,USAGE ON SEQUENCES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA clientes GRANT SELECT,USAGE ON SEQUENCES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA clientes GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA clientes GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA clientes GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_visual;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA clientes GRANT ALL ON SEQUENCES TO sgiri_app;


--
-- TOC entry 2373 (class 826 OID 24825)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: clientes; Owner: sgiri_app
--

ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA clientes GRANT SELECT,USAGE ON SEQUENCES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA clientes GRANT SELECT,USAGE ON SEQUENCES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA clientes GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA clientes GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA clientes GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_visual;


--
-- TOC entry 2358 (class 826 OID 24793)
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: clientes; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA clientes GRANT ALL ON FUNCTIONS TO sgiri_app;


--
-- TOC entry 2370 (class 826 OID 24802)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: clientes; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA clientes GRANT SELECT ON TABLES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA clientes GRANT SELECT ON TABLES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA clientes GRANT SELECT ON TABLES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA clientes GRANT SELECT ON TABLES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA clientes GRANT SELECT ON TABLES TO rol_admin_visual;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA clientes GRANT ALL ON TABLES TO sgiri_app;


--
-- TOC entry 2372 (class 826 OID 24824)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: clientes; Owner: sgiri_app
--

ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA clientes GRANT SELECT ON TABLES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA clientes GRANT SELECT ON TABLES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA clientes GRANT SELECT ON TABLES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA clientes GRANT SELECT ON TABLES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA clientes GRANT SELECT ON TABLES TO rol_admin_visual;


--
-- TOC entry 2375 (class 826 OID 24809)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: empleados; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empleados GRANT SELECT,USAGE ON SEQUENCES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empleados GRANT SELECT,USAGE ON SEQUENCES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empleados GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empleados GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empleados GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_visual;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empleados GRANT ALL ON SEQUENCES TO sgiri_app;


--
-- TOC entry 2377 (class 826 OID 24827)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: empleados; Owner: sgiri_app
--

ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA empleados GRANT SELECT,USAGE ON SEQUENCES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA empleados GRANT SELECT,USAGE ON SEQUENCES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA empleados GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA empleados GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA empleados GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_visual;


--
-- TOC entry 2357 (class 826 OID 24792)
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: empleados; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empleados GRANT ALL ON FUNCTIONS TO sgiri_app;


--
-- TOC entry 2374 (class 826 OID 24801)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: empleados; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empleados GRANT SELECT ON TABLES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empleados GRANT SELECT ON TABLES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empleados GRANT SELECT ON TABLES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empleados GRANT SELECT ON TABLES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empleados GRANT SELECT ON TABLES TO rol_admin_visual;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empleados GRANT ALL ON TABLES TO sgiri_app;


--
-- TOC entry 2376 (class 826 OID 24826)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: empleados; Owner: sgiri_app
--

ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA empleados GRANT SELECT ON TABLES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA empleados GRANT SELECT ON TABLES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA empleados GRANT SELECT ON TABLES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA empleados GRANT SELECT ON TABLES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA empleados GRANT SELECT ON TABLES TO rol_admin_visual;


--
-- TOC entry 2381 (class 826 OID 24814)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: empresa; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empresa GRANT SELECT,USAGE ON SEQUENCES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empresa GRANT SELECT,USAGE ON SEQUENCES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empresa GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empresa GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empresa GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_visual;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empresa GRANT ALL ON SEQUENCES TO sgiri_app;


--
-- TOC entry 2383 (class 826 OID 24829)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: empresa; Owner: sgiri_app
--

ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA empresa GRANT SELECT,USAGE ON SEQUENCES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA empresa GRANT SELECT,USAGE ON SEQUENCES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA empresa GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA empresa GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA empresa GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_visual;


--
-- TOC entry 2362 (class 826 OID 24797)
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: empresa; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empresa GRANT ALL ON FUNCTIONS TO sgiri_app;


--
-- TOC entry 2378 (class 826 OID 24806)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: empresa; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empresa GRANT SELECT ON TABLES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empresa GRANT SELECT ON TABLES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empresa GRANT SELECT ON TABLES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empresa GRANT SELECT ON TABLES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empresa GRANT SELECT ON TABLES TO rol_admin_visual;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA empresa GRANT ALL ON TABLES TO sgiri_app;


--
-- TOC entry 2382 (class 826 OID 24828)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: empresa; Owner: sgiri_app
--

ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA empresa GRANT SELECT ON TABLES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA empresa GRANT SELECT ON TABLES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA empresa GRANT SELECT ON TABLES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA empresa GRANT SELECT ON TABLES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA empresa GRANT SELECT ON TABLES TO rol_admin_visual;


--
-- TOC entry 2385 (class 826 OID 24815)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: notificaciones; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA notificaciones GRANT SELECT,USAGE ON SEQUENCES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA notificaciones GRANT SELECT,USAGE ON SEQUENCES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA notificaciones GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA notificaciones GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA notificaciones GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_visual;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA notificaciones GRANT ALL ON SEQUENCES TO sgiri_app;


--
-- TOC entry 2387 (class 826 OID 24831)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: notificaciones; Owner: sgiri_app
--

ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA notificaciones GRANT SELECT,USAGE ON SEQUENCES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA notificaciones GRANT SELECT,USAGE ON SEQUENCES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA notificaciones GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA notificaciones GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA notificaciones GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_visual;


--
-- TOC entry 2363 (class 826 OID 24798)
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: notificaciones; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA notificaciones GRANT ALL ON FUNCTIONS TO sgiri_app;


--
-- TOC entry 2384 (class 826 OID 24807)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: notificaciones; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA notificaciones GRANT SELECT ON TABLES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA notificaciones GRANT SELECT ON TABLES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA notificaciones GRANT SELECT ON TABLES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA notificaciones GRANT SELECT ON TABLES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA notificaciones GRANT SELECT ON TABLES TO rol_admin_visual;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA notificaciones GRANT ALL ON TABLES TO sgiri_app;


--
-- TOC entry 2386 (class 826 OID 24830)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: notificaciones; Owner: sgiri_app
--

ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA notificaciones GRANT SELECT ON TABLES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA notificaciones GRANT SELECT ON TABLES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA notificaciones GRANT SELECT ON TABLES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA notificaciones GRANT SELECT ON TABLES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA notificaciones GRANT SELECT ON TABLES TO rol_admin_visual;


--
-- TOC entry 2389 (class 826 OID 24833)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: reportes; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA reportes GRANT SELECT,USAGE ON SEQUENCES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA reportes GRANT SELECT,USAGE ON SEQUENCES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA reportes GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA reportes GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA reportes GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_visual;


--
-- TOC entry 2391 (class 826 OID 24835)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: reportes; Owner: sgiri_app
--

ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA reportes GRANT SELECT,USAGE ON SEQUENCES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA reportes GRANT SELECT,USAGE ON SEQUENCES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA reportes GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA reportes GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA reportes GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_visual;


--
-- TOC entry 2388 (class 826 OID 24832)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: reportes; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA reportes GRANT SELECT ON TABLES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA reportes GRANT SELECT ON TABLES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA reportes GRANT SELECT ON TABLES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA reportes GRANT SELECT ON TABLES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA reportes GRANT SELECT ON TABLES TO rol_admin_visual;


--
-- TOC entry 2390 (class 826 OID 24834)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: reportes; Owner: sgiri_app
--

ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA reportes GRANT SELECT ON TABLES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA reportes GRANT SELECT ON TABLES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA reportes GRANT SELECT ON TABLES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA reportes GRANT SELECT ON TABLES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA reportes GRANT SELECT ON TABLES TO rol_admin_visual;


--
-- TOC entry 2393 (class 826 OID 24811)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: soporte; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA soporte GRANT SELECT,USAGE ON SEQUENCES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA soporte GRANT SELECT,USAGE ON SEQUENCES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA soporte GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA soporte GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA soporte GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_visual;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA soporte GRANT ALL ON SEQUENCES TO sgiri_app;


--
-- TOC entry 2395 (class 826 OID 24837)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: soporte; Owner: sgiri_app
--

ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA soporte GRANT SELECT,USAGE ON SEQUENCES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA soporte GRANT SELECT,USAGE ON SEQUENCES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA soporte GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA soporte GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA soporte GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_visual;


--
-- TOC entry 2359 (class 826 OID 24794)
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: soporte; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA soporte GRANT ALL ON FUNCTIONS TO sgiri_app;


--
-- TOC entry 2392 (class 826 OID 24803)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: soporte; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA soporte GRANT SELECT ON TABLES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA soporte GRANT SELECT ON TABLES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA soporte GRANT SELECT ON TABLES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA soporte GRANT SELECT ON TABLES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA soporte GRANT SELECT ON TABLES TO rol_admin_visual;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA soporte GRANT ALL ON TABLES TO sgiri_app;


--
-- TOC entry 2394 (class 826 OID 24836)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: soporte; Owner: sgiri_app
--

ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA soporte GRANT SELECT ON TABLES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA soporte GRANT SELECT ON TABLES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA soporte GRANT SELECT ON TABLES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA soporte GRANT SELECT ON TABLES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA soporte GRANT SELECT ON TABLES TO rol_admin_visual;


--
-- TOC entry 2397 (class 826 OID 24808)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: usuarios; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA usuarios GRANT SELECT,USAGE ON SEQUENCES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA usuarios GRANT SELECT,USAGE ON SEQUENCES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA usuarios GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA usuarios GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA usuarios GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_visual;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA usuarios GRANT ALL ON SEQUENCES TO sgiri_app;


--
-- TOC entry 2399 (class 826 OID 24839)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: usuarios; Owner: sgiri_app
--

ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA usuarios GRANT SELECT,USAGE ON SEQUENCES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA usuarios GRANT SELECT,USAGE ON SEQUENCES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA usuarios GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA usuarios GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA usuarios GRANT SELECT,USAGE ON SEQUENCES TO rol_admin_visual;


--
-- TOC entry 2356 (class 826 OID 24791)
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: usuarios; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA usuarios GRANT ALL ON FUNCTIONS TO sgiri_app;


--
-- TOC entry 2396 (class 826 OID 24800)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: usuarios; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA usuarios GRANT SELECT ON TABLES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA usuarios GRANT SELECT ON TABLES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA usuarios GRANT SELECT ON TABLES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA usuarios GRANT SELECT ON TABLES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA usuarios GRANT SELECT ON TABLES TO rol_admin_visual;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA usuarios GRANT ALL ON TABLES TO sgiri_app;


--
-- TOC entry 2398 (class 826 OID 24838)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: usuarios; Owner: sgiri_app
--

ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA usuarios GRANT SELECT ON TABLES TO rol_cliente;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA usuarios GRANT SELECT ON TABLES TO rol_tecnico;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA usuarios GRANT SELECT ON TABLES TO rol_admin_tecnicos;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA usuarios GRANT SELECT ON TABLES TO rol_admin_master;
ALTER DEFAULT PRIVILEGES FOR ROLE sgiri_app IN SCHEMA usuarios GRANT SELECT ON TABLES TO rol_admin_visual;


-- Completed on 2026-03-13 19:32:01 -05

--
-- PostgreSQL database dump complete
--

\unrestrict xw9g1IfeH5cpTbFZ0jcdjvfk2qwVgML8t1dsRI2uPuvyGhA7BCnHehkhbiEL2Ss

