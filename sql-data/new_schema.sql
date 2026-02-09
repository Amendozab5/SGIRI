--
-- PostgreSQL database dump
--

\restrict 06W7unh3bonhi2YTnlA4DXpFV08pTB19eggsB2yGFzSHokng3cFe8VQtZaLjpmv

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

-- Started on 2026-02-02 13:10:41

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
-- TOC entry 6 (class 2615 OID 37858)
-- Name: auditoria; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA auditoria;


ALTER SCHEMA auditoria OWNER TO postgres;

--
-- TOC entry 7 (class 2615 OID 37859)
-- Name: catalogos; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA catalogos;


ALTER SCHEMA catalogos OWNER TO postgres;

--
-- TOC entry 8 (class 2615 OID 37860)
-- Name: clientes; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA clientes;


ALTER SCHEMA clientes OWNER TO postgres;

--
-- TOC entry 9 (class 2615 OID 37861)
-- Name: empleados; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA empleados;


ALTER SCHEMA empleados OWNER TO postgres;

--
-- TOC entry 10 (class 2615 OID 37862)
-- Name: empresa; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA empresa;


ALTER SCHEMA empresa OWNER TO postgres;

--
-- TOC entry 11 (class 2615 OID 37863)
-- Name: notificaciones; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA notificaciones;


ALTER SCHEMA notificaciones OWNER TO postgres;

--
-- TOC entry 12 (class 2615 OID 37864)
-- Name: soporte; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA soporte;


ALTER SCHEMA soporte OWNER TO postgres;

--
-- TOC entry 13 (class 2615 OID 37865)
-- Name: usuarios; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA usuarios;


ALTER SCHEMA usuarios OWNER TO postgres;

--
-- TOC entry 304 (class 1255 OID 39908)
-- Name: generar_username_unico(text, text); Type: FUNCTION; Schema: usuarios; Owner: postgres
--

CREATE FUNCTION usuarios.generar_username_unico(p_nombres text, p_apellidos text) RETURNS text
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


ALTER FUNCTION usuarios.generar_username_unico(p_nombres text, p_apellidos text) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 227 (class 1259 OID 37866)
-- Name: auditoria_estado_ticket; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.auditoria_estado_ticket (
    id_auditoria integer NOT NULL,
    id_ticket integer NOT NULL,
    estado_anterior character varying(50),
    estado_nuevo character varying(50),
    usuario_bd character varying(100) NOT NULL,
    fecha_cambio timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    id_estado_anterior integer,
    id_estado_nuevo integer NOT NULL,
    id_item_evento integer,
    id_usuario integer,
    id_estado_nuevo_item integer
);


ALTER TABLE auditoria.auditoria_estado_ticket OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 37875)
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
-- TOC entry 5549 (class 0 OID 0)
-- Dependencies: 228
-- Name: auditoria_estado_ticket_id_auditoria_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: postgres
--

ALTER SEQUENCE auditoria.auditoria_estado_ticket_id_auditoria_seq OWNED BY auditoria.auditoria_estado_ticket.id_auditoria;


--
-- TOC entry 229 (class 1259 OID 37876)
-- Name: auditoria_evento; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.auditoria_evento (
    id_evento integer NOT NULL,
    esquema_afectado character varying(50) NOT NULL,
    tabla_afectada character varying(50) NOT NULL,
    id_registro integer NOT NULL,
    accion character varying(50) NOT NULL,
    descripcion text,
    usuario_bd character varying(100) NOT NULL,
    rol_bd character varying(100) NOT NULL,
    fecha_evento timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    id_usuario integer,
    id_notificacion integer,
    id_accion integer NOT NULL
);


ALTER TABLE auditoria.auditoria_evento OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 37891)
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
-- TOC entry 5550 (class 0 OID 0)
-- Dependencies: 230
-- Name: auditoria_evento_id_evento_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: postgres
--

ALTER SEQUENCE auditoria.auditoria_evento_id_evento_seq OWNED BY auditoria.auditoria_evento.id_evento;


--
-- TOC entry 231 (class 1259 OID 37892)
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
-- TOC entry 232 (class 1259 OID 37899)
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
-- TOC entry 233 (class 1259 OID 37909)
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
-- TOC entry 5551 (class 0 OID 0)
-- Dependencies: 233
-- Name: auditoria_login_bd_id_auditoria_login_bd_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: postgres
--

ALTER SEQUENCE auditoria.auditoria_login_bd_id_auditoria_login_bd_seq OWNED BY auditoria.auditoria_login_bd.id_auditoria_login_bd;


--
-- TOC entry 234 (class 1259 OID 37910)
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
-- TOC entry 5552 (class 0 OID 0)
-- Dependencies: 234
-- Name: auditoria_login_id_login_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: postgres
--

ALTER SEQUENCE auditoria.auditoria_login_id_login_seq OWNED BY auditoria.auditoria_login.id_login;


--
-- TOC entry 235 (class 1259 OID 37911)
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
-- TOC entry 236 (class 1259 OID 37919)
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
-- TOC entry 5553 (class 0 OID 0)
-- Dependencies: 236
-- Name: catalogo_id_catalogo_seq; Type: SEQUENCE OWNED BY; Schema: catalogos; Owner: postgres
--

ALTER SEQUENCE catalogos.catalogo_id_catalogo_seq OWNED BY catalogos.catalogo.id_catalogo;


--
-- TOC entry 237 (class 1259 OID 37920)
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
-- TOC entry 238 (class 1259 OID 37927)
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
-- TOC entry 5554 (class 0 OID 0)
-- Dependencies: 238
-- Name: catalogo_item_id_item_seq; Type: SEQUENCE OWNED BY; Schema: catalogos; Owner: postgres
--

ALTER SEQUENCE catalogos.catalogo_item_id_item_seq OWNED BY catalogos.catalogo_item.id_item;


--
-- TOC entry 239 (class 1259 OID 37928)
-- Name: canton; Type: TABLE; Schema: clientes; Owner: postgres
--

CREATE TABLE clientes.canton (
    id_canton integer NOT NULL,
    nombre character varying(100) NOT NULL,
    id_ciudad integer NOT NULL
);


ALTER TABLE clientes.canton OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 37934)
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
-- TOC entry 5555 (class 0 OID 0)
-- Dependencies: 240
-- Name: canton_id_canton_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: postgres
--

ALTER SEQUENCE clientes.canton_id_canton_seq OWNED BY clientes.canton.id_canton;


--
-- TOC entry 241 (class 1259 OID 37935)
-- Name: ciudad; Type: TABLE; Schema: clientes; Owner: postgres
--

CREATE TABLE clientes.ciudad (
    id_ciudad integer NOT NULL,
    nombre character varying(100) NOT NULL,
    id_pais integer NOT NULL
);


ALTER TABLE clientes.ciudad OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 37941)
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
-- TOC entry 5556 (class 0 OID 0)
-- Dependencies: 242
-- Name: ciudad_id_ciudad_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: postgres
--

ALTER SEQUENCE clientes.ciudad_id_ciudad_seq OWNED BY clientes.ciudad.id_ciudad;


--
-- TOC entry 243 (class 1259 OID 37942)
-- Name: cliente; Type: TABLE; Schema: clientes; Owner: postgres
--

CREATE TABLE clientes.cliente (
    cedula character varying(10) NOT NULL,
    apellidos character varying(100) NOT NULL,
    celular character varying(15),
    direccion text NOT NULL,
    id_canton integer NOT NULL,
    contrato_pdf_path text,
    croquis_pdf_path text,
    estado_servicio character varying(20) NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    correo character varying(150),
    fecha_actualizacion timestamp without time zone,
    id_empresa integer NOT NULL,
    id_cliente integer NOT NULL,
    nombres character varying(100) NOT NULL,
    CONSTRAINT cliente_estado_servicio_check CHECK (((estado_servicio)::text = ANY (ARRAY[('ACTIVO'::character varying)::text, ('SUSPENDIDO'::character varying)::text, ('CANCELADO'::character varying)::text])))
);


ALTER TABLE clientes.cliente OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 37957)
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
-- TOC entry 5557 (class 0 OID 0)
-- Dependencies: 244
-- Name: cliente_id_cliente_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: postgres
--

ALTER SEQUENCE clientes.cliente_id_cliente_seq OWNED BY clientes.cliente.id_cliente;


--
-- TOC entry 245 (class 1259 OID 37958)
-- Name: documento_cliente; Type: TABLE; Schema: clientes; Owner: postgres
--

CREATE TABLE clientes.documento_cliente (
    id_documento integer NOT NULL,
    numero_documento character varying(10) NOT NULL,
    ruta_archivo text NOT NULL,
    descripcion text,
    fecha_subida timestamp without time zone DEFAULT now(),
    estado character varying(20) NOT NULL,
    id_cliente integer NOT NULL,
    id_tipo_documento integer NOT NULL
);


ALTER TABLE clientes.documento_cliente OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 37970)
-- Name: documento_cliente_id_cliente_seq; Type: SEQUENCE; Schema: clientes; Owner: postgres
--

CREATE SEQUENCE clientes.documento_cliente_id_cliente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE clientes.documento_cliente_id_cliente_seq OWNER TO postgres;

--
-- TOC entry 5558 (class 0 OID 0)
-- Dependencies: 246
-- Name: documento_cliente_id_cliente_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: postgres
--

ALTER SEQUENCE clientes.documento_cliente_id_cliente_seq OWNED BY clientes.documento_cliente.id_cliente;


--
-- TOC entry 247 (class 1259 OID 37971)
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
-- TOC entry 5559 (class 0 OID 0)
-- Dependencies: 247
-- Name: documento_cliente_id_documento_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: postgres
--

ALTER SEQUENCE clientes.documento_cliente_id_documento_seq OWNED BY clientes.documento_cliente.id_documento;


--
-- TOC entry 248 (class 1259 OID 37972)
-- Name: pais; Type: TABLE; Schema: clientes; Owner: postgres
--

CREATE TABLE clientes.pais (
    id_pais integer NOT NULL,
    nombre character varying(100) NOT NULL
);


ALTER TABLE clientes.pais OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 37977)
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
-- TOC entry 5560 (class 0 OID 0)
-- Dependencies: 249
-- Name: pais_id_pais_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: postgres
--

ALTER SEQUENCE clientes.pais_id_pais_seq OWNED BY clientes.pais.id_pais;


--
-- TOC entry 250 (class 1259 OID 37978)
-- Name: tipo_documento; Type: TABLE; Schema: clientes; Owner: postgres
--

CREATE TABLE clientes.tipo_documento (
    id_tipo_documento integer NOT NULL,
    codigo character varying(20) NOT NULL
);


ALTER TABLE clientes.tipo_documento OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 37983)
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
-- TOC entry 5561 (class 0 OID 0)
-- Dependencies: 251
-- Name: tipo_documento_id_tipo_documento_seq; Type: SEQUENCE OWNED BY; Schema: clientes; Owner: postgres
--

ALTER SEQUENCE clientes.tipo_documento_id_tipo_documento_seq OWNED BY clientes.tipo_documento.id_tipo_documento;


--
-- TOC entry 252 (class 1259 OID 37984)
-- Name: area; Type: TABLE; Schema: empleados; Owner: postgres
--

CREATE TABLE empleados.area (
    id_area integer NOT NULL,
    nombre character varying(100) NOT NULL
);


ALTER TABLE empleados.area OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 37989)
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
-- TOC entry 5562 (class 0 OID 0)
-- Dependencies: 253
-- Name: area_id_area_seq; Type: SEQUENCE OWNED BY; Schema: empleados; Owner: postgres
--

ALTER SEQUENCE empleados.area_id_area_seq OWNED BY empleados.area.id_area;


--
-- TOC entry 254 (class 1259 OID 37990)
-- Name: cargo; Type: TABLE; Schema: empleados; Owner: postgres
--

CREATE TABLE empleados.cargo (
    id_cargo integer NOT NULL,
    nombre character varying(100) NOT NULL
);


ALTER TABLE empleados.cargo OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 37995)
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
-- TOC entry 5563 (class 0 OID 0)
-- Dependencies: 255
-- Name: cargo_id_cargo_seq; Type: SEQUENCE OWNED BY; Schema: empleados; Owner: postgres
--

ALTER SEQUENCE empleados.cargo_id_cargo_seq OWNED BY empleados.cargo.id_cargo;


--
-- TOC entry 256 (class 1259 OID 37996)
-- Name: documento_empleado; Type: TABLE; Schema: empleados; Owner: postgres
--

CREATE TABLE empleados.documento_empleado (
    id_documento integer NOT NULL,
    cedula_empleado character varying(10) NOT NULL,
    tipo_documento character varying(50) NOT NULL,
    ruta_archivo text NOT NULL,
    descripcion text,
    fecha_subida timestamp without time zone DEFAULT now(),
    estado character varying(20) NOT NULL,
    id_empleado integer NOT NULL
);


ALTER TABLE empleados.documento_empleado OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 38008)
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
-- TOC entry 5564 (class 0 OID 0)
-- Dependencies: 257
-- Name: documento_empleado_id_documento_seq; Type: SEQUENCE OWNED BY; Schema: empleados; Owner: postgres
--

ALTER SEQUENCE empleados.documento_empleado_id_documento_seq OWNED BY empleados.documento_empleado.id_documento;


--
-- TOC entry 258 (class 1259 OID 38009)
-- Name: documento_empleado_id_empleado_seq; Type: SEQUENCE; Schema: empleados; Owner: postgres
--

CREATE SEQUENCE empleados.documento_empleado_id_empleado_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE empleados.documento_empleado_id_empleado_seq OWNER TO postgres;

--
-- TOC entry 5565 (class 0 OID 0)
-- Dependencies: 258
-- Name: documento_empleado_id_empleado_seq; Type: SEQUENCE OWNED BY; Schema: empleados; Owner: postgres
--

ALTER SEQUENCE empleados.documento_empleado_id_empleado_seq OWNED BY empleados.documento_empleado.id_empleado;


--
-- TOC entry 259 (class 1259 OID 38010)
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
-- TOC entry 260 (class 1259 OID 38011)
-- Name: empleado; Type: TABLE; Schema: empleados; Owner: postgres
--

CREATE TABLE empleados.empleado (
    cedula character varying(10) NOT NULL,
    nombre character varying(100) NOT NULL,
    apellido character varying(100) NOT NULL,
    celular character varying(15),
    correo_personal character varying(150),
    correo_corporativo character varying(150),
    fecha_ingreso date NOT NULL,
    id_cargo integer NOT NULL,
    id_area integer NOT NULL,
    id_tipo_contrato integer NOT NULL,
    contrato_pdf_path text,
    estado character varying(20) DEFAULT 'ACTIVO'::character varying NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion timestamp without time zone,
    id_empresa integer NOT NULL,
    id_empleado integer DEFAULT nextval('empleados.empleado_id_empleado_seq'::regclass) NOT NULL,
    CONSTRAINT empleado_estado_check CHECK (((estado)::text = ANY (ARRAY[('ACTIVO'::character varying)::text, ('INACTIVO'::character varying)::text])))
);


ALTER TABLE empleados.empleado OWNER TO postgres;

--
-- TOC entry 261 (class 1259 OID 38030)
-- Name: tipo_contrato; Type: TABLE; Schema: empleados; Owner: postgres
--

CREATE TABLE empleados.tipo_contrato (
    id_tipo_contrato integer NOT NULL,
    nombre character varying(100) NOT NULL
);


ALTER TABLE empleados.tipo_contrato OWNER TO postgres;

--
-- TOC entry 262 (class 1259 OID 38035)
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
-- TOC entry 5566 (class 0 OID 0)
-- Dependencies: 262
-- Name: tipo_contrato_id_tipo_contrato_seq; Type: SEQUENCE OWNED BY; Schema: empleados; Owner: postgres
--

ALTER SEQUENCE empleados.tipo_contrato_id_tipo_contrato_seq OWNED BY empleados.tipo_contrato.id_tipo_contrato;


--
-- TOC entry 263 (class 1259 OID 38036)
-- Name: documento_empresa; Type: TABLE; Schema: empresa; Owner: postgres
--

CREATE TABLE empresa.documento_empresa (
    id_documento integer NOT NULL,
    id_empresa integer NOT NULL,
    numero_documento character varying(50) NOT NULL,
    ruta_archivo text NOT NULL,
    descripcion text,
    fecha_subida timestamp without time zone DEFAULT now(),
    estado character varying(20) NOT NULL,
    id_tipo_documento integer NOT NULL
);


ALTER TABLE empresa.documento_empresa OWNER TO postgres;

--
-- TOC entry 264 (class 1259 OID 38048)
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
-- TOC entry 5567 (class 0 OID 0)
-- Dependencies: 264
-- Name: documento_empresa_id_documento_seq; Type: SEQUENCE OWNED BY; Schema: empresa; Owner: postgres
--

ALTER SEQUENCE empresa.documento_empresa_id_documento_seq OWNED BY empresa.documento_empresa.id_documento;


--
-- TOC entry 265 (class 1259 OID 38049)
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
    estado character varying(20) NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now()
);


ALTER TABLE empresa.empresa OWNER TO postgres;

--
-- TOC entry 266 (class 1259 OID 38061)
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
-- TOC entry 5568 (class 0 OID 0)
-- Dependencies: 266
-- Name: empresa_id_empresa_seq; Type: SEQUENCE OWNED BY; Schema: empresa; Owner: postgres
--

ALTER SEQUENCE empresa.empresa_id_empresa_seq OWNED BY empresa.empresa.id_empresa;


--
-- TOC entry 267 (class 1259 OID 38062)
-- Name: empresa_servicio; Type: TABLE; Schema: empresa; Owner: postgres
--

CREATE TABLE empresa.empresa_servicio (
    id_empresa integer NOT NULL,
    id_servicio integer NOT NULL
);


ALTER TABLE empresa.empresa_servicio OWNER TO postgres;

--
-- TOC entry 268 (class 1259 OID 38067)
-- Name: servicio; Type: TABLE; Schema: empresa; Owner: postgres
--

CREATE TABLE empresa.servicio (
    id_servicio integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    activo boolean DEFAULT true
);


ALTER TABLE empresa.servicio OWNER TO postgres;

--
-- TOC entry 269 (class 1259 OID 38075)
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
-- TOC entry 5569 (class 0 OID 0)
-- Dependencies: 269
-- Name: servicio_id_servicio_seq; Type: SEQUENCE OWNED BY; Schema: empresa; Owner: postgres
--

ALTER SEQUENCE empresa.servicio_id_servicio_seq OWNED BY empresa.servicio.id_servicio;


--
-- TOC entry 270 (class 1259 OID 38076)
-- Name: sucursal; Type: TABLE; Schema: empresa; Owner: postgres
--

CREATE TABLE empresa.sucursal (
    id_sucursal integer NOT NULL,
    id_empresa integer NOT NULL,
    nombre character varying(100) NOT NULL,
    direccion text NOT NULL,
    ciudad character varying(100) NOT NULL,
    canton character varying(100),
    telefono character varying(50),
    estado boolean DEFAULT true
);


ALTER TABLE empresa.sucursal OWNER TO postgres;

--
-- TOC entry 271 (class 1259 OID 38087)
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
-- TOC entry 5570 (class 0 OID 0)
-- Dependencies: 271
-- Name: sucursal_id_sucursal_seq; Type: SEQUENCE OWNED BY; Schema: empresa; Owner: postgres
--

ALTER SEQUENCE empresa.sucursal_id_sucursal_seq OWNED BY empresa.sucursal.id_sucursal;


--
-- TOC entry 272 (class 1259 OID 38088)
-- Name: canal_notificacion; Type: TABLE; Schema: notificaciones; Owner: postgres
--

CREATE TABLE notificaciones.canal_notificacion (
    id_canal integer NOT NULL,
    nombre character varying(50) NOT NULL,
    activo boolean DEFAULT true
);


ALTER TABLE notificaciones.canal_notificacion OWNER TO postgres;

--
-- TOC entry 273 (class 1259 OID 38094)
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
-- TOC entry 5571 (class 0 OID 0)
-- Dependencies: 273
-- Name: canal_notificacion_id_canal_seq; Type: SEQUENCE OWNED BY; Schema: notificaciones; Owner: postgres
--

ALTER SEQUENCE notificaciones.canal_notificacion_id_canal_seq OWNED BY notificaciones.canal_notificacion.id_canal;


--
-- TOC entry 274 (class 1259 OID 38095)
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
    id_usuario integer,
    id_tipo_notificacion integer,
    id_usuario_origen integer
);


ALTER TABLE notificaciones.notificacion OWNER TO postgres;

--
-- TOC entry 275 (class 1259 OID 38106)
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
-- TOC entry 5572 (class 0 OID 0)
-- Dependencies: 275
-- Name: notificacion_id_notificacion_seq; Type: SEQUENCE OWNED BY; Schema: notificaciones; Owner: postgres
--

ALTER SEQUENCE notificaciones.notificacion_id_notificacion_seq OWNED BY notificaciones.notificacion.id_notificacion;


--
-- TOC entry 276 (class 1259 OID 38107)
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
-- TOC entry 277 (class 1259 OID 38115)
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
-- TOC entry 5573 (class 0 OID 0)
-- Dependencies: 277
-- Name: asignacion_id_asignacion_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.asignacion_id_asignacion_seq OWNED BY soporte.asignacion.id_asignacion;


--
-- TOC entry 278 (class 1259 OID 38116)
-- Name: categoria; Type: TABLE; Schema: soporte; Owner: postgres
--

CREATE TABLE soporte.categoria (
    id_categoria integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    id_item integer NOT NULL
);


ALTER TABLE soporte.categoria OWNER TO postgres;

--
-- TOC entry 279 (class 1259 OID 38124)
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
-- TOC entry 5574 (class 0 OID 0)
-- Dependencies: 279
-- Name: categoria_id_categoria_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.categoria_id_categoria_seq OWNED BY soporte.categoria.id_categoria;


--
-- TOC entry 280 (class 1259 OID 38125)
-- Name: comentario_ticket; Type: TABLE; Schema: soporte; Owner: postgres
--

CREATE TABLE soporte.comentario_ticket (
    id_comentario integer NOT NULL,
    id_ticket integer NOT NULL,
    id_usuario integer NOT NULL,
    comentario text NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now(),
    es_interno boolean DEFAULT false,
    id_empresa integer NOT NULL
);


ALTER TABLE soporte.comentario_ticket OWNER TO postgres;

--
-- TOC entry 281 (class 1259 OID 38137)
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
-- TOC entry 5575 (class 0 OID 0)
-- Dependencies: 281
-- Name: comentario_ticket_id_comentario_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.comentario_ticket_id_comentario_seq OWNED BY soporte.comentario_ticket.id_comentario;


--
-- TOC entry 282 (class 1259 OID 38138)
-- Name: documento_ticket; Type: TABLE; Schema: soporte; Owner: postgres
--

CREATE TABLE soporte.documento_ticket (
    id_documento integer NOT NULL,
    id_ticket integer NOT NULL,
    tipo_documento character varying(50) NOT NULL,
    ruta_archivo text NOT NULL,
    descripcion text,
    fecha_subida timestamp without time zone DEFAULT now(),
    id_usuario integer
);


ALTER TABLE soporte.documento_ticket OWNER TO postgres;

--
-- TOC entry 283 (class 1259 OID 38148)
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
-- TOC entry 5576 (class 0 OID 0)
-- Dependencies: 283
-- Name: documento_ticket_id_documento_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.documento_ticket_id_documento_seq OWNED BY soporte.documento_ticket.id_documento;


--
-- TOC entry 284 (class 1259 OID 38149)
-- Name: historial_estado; Type: TABLE; Schema: soporte; Owner: postgres
--

CREATE TABLE soporte.historial_estado (
    id_historial integer NOT NULL,
    id_ticket integer NOT NULL,
    id_estado integer NOT NULL,
    usuario_bd character varying(100) NOT NULL,
    fecha_cambio timestamp without time zone DEFAULT now(),
    observacion text,
    id_estado_anterior integer,
    id_estado_nuevo integer NOT NULL,
    id_usuario integer
);


ALTER TABLE soporte.historial_estado OWNER TO postgres;

--
-- TOC entry 285 (class 1259 OID 38160)
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
-- TOC entry 5577 (class 0 OID 0)
-- Dependencies: 285
-- Name: historial_estado_id_historial_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.historial_estado_id_historial_seq OWNED BY soporte.historial_estado.id_historial;


--
-- TOC entry 286 (class 1259 OID 38161)
-- Name: prioridad; Type: TABLE; Schema: soporte; Owner: postgres
--

CREATE TABLE soporte.prioridad (
    id_prioridad integer NOT NULL,
    nombre character varying(30) NOT NULL,
    descripcion text,
    id_item integer NOT NULL
);


ALTER TABLE soporte.prioridad OWNER TO postgres;

--
-- TOC entry 287 (class 1259 OID 38169)
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
-- TOC entry 5578 (class 0 OID 0)
-- Dependencies: 287
-- Name: prioridad_id_prioridad_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.prioridad_id_prioridad_seq OWNED BY soporte.prioridad.id_prioridad;


--
-- TOC entry 288 (class 1259 OID 38170)
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
-- TOC entry 289 (class 1259 OID 38182)
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
-- TOC entry 5579 (class 0 OID 0)
-- Dependencies: 289
-- Name: sla_ticket_id_sla_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.sla_ticket_id_sla_seq OWNED BY soporte.sla_ticket.id_sla;


--
-- TOC entry 290 (class 1259 OID 38183)
-- Name: ticket; Type: TABLE; Schema: soporte; Owner: postgres
--

CREATE TABLE soporte.ticket (
    id_ticket integer NOT NULL,
    cedula_cliente character varying(20) NOT NULL,
    id_categoria integer NOT NULL,
    id_prioridad integer NOT NULL,
    id_estado integer NOT NULL,
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
    id_empresa integer NOT NULL,
    id_cliente integer NOT NULL,
    id_empleado integer NOT NULL
);


ALTER TABLE soporte.ticket OWNER TO postgres;

--
-- TOC entry 291 (class 1259 OID 38202)
-- Name: ticket_id_cliente_seq; Type: SEQUENCE; Schema: soporte; Owner: postgres
--

CREATE SEQUENCE soporte.ticket_id_cliente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE soporte.ticket_id_cliente_seq OWNER TO postgres;

--
-- TOC entry 5580 (class 0 OID 0)
-- Dependencies: 291
-- Name: ticket_id_cliente_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.ticket_id_cliente_seq OWNED BY soporte.ticket.id_cliente;


--
-- TOC entry 292 (class 1259 OID 38203)
-- Name: ticket_id_empleado_seq; Type: SEQUENCE; Schema: soporte; Owner: postgres
--

CREATE SEQUENCE soporte.ticket_id_empleado_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE soporte.ticket_id_empleado_seq OWNER TO postgres;

--
-- TOC entry 5581 (class 0 OID 0)
-- Dependencies: 292
-- Name: ticket_id_empleado_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.ticket_id_empleado_seq OWNED BY soporte.ticket.id_empleado;


--
-- TOC entry 293 (class 1259 OID 38204)
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
-- TOC entry 5582 (class 0 OID 0)
-- Dependencies: 293
-- Name: ticket_id_ticket_seq; Type: SEQUENCE OWNED BY; Schema: soporte; Owner: postgres
--

ALTER SEQUENCE soporte.ticket_id_ticket_seq OWNED BY soporte.ticket.id_ticket;


--
-- TOC entry 294 (class 1259 OID 38205)
-- Name: rol; Type: TABLE; Schema: usuarios; Owner: postgres
--

CREATE TABLE usuarios.rol (
    id_rol integer NOT NULL,
    codigo character varying(50) NOT NULL,
    descripcion text
);


ALTER TABLE usuarios.rol OWNER TO postgres;

--
-- TOC entry 295 (class 1259 OID 38212)
-- Name: rol_bd; Type: TABLE; Schema: usuarios; Owner: postgres
--

CREATE TABLE usuarios.rol_bd (
    id_rol_bd integer NOT NULL,
    nombre character varying(50) NOT NULL,
    descripcion text
);


ALTER TABLE usuarios.rol_bd OWNER TO postgres;

--
-- TOC entry 296 (class 1259 OID 38219)
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
-- TOC entry 5583 (class 0 OID 0)
-- Dependencies: 296
-- Name: rol_bd_id_rol_bd_seq; Type: SEQUENCE OWNED BY; Schema: usuarios; Owner: postgres
--

ALTER SEQUENCE usuarios.rol_bd_id_rol_bd_seq OWNED BY usuarios.rol_bd.id_rol_bd;


--
-- TOC entry 297 (class 1259 OID 38220)
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
-- TOC entry 5584 (class 0 OID 0)
-- Dependencies: 297
-- Name: rol_id_rol_seq; Type: SEQUENCE OWNED BY; Schema: usuarios; Owner: postgres
--

ALTER SEQUENCE usuarios.rol_id_rol_seq OWNED BY usuarios.rol.id_rol;


--
-- TOC entry 298 (class 1259 OID 38221)
-- Name: usuario; Type: TABLE; Schema: usuarios; Owner: postgres
--

CREATE TABLE usuarios.usuario (
    id_usuario integer NOT NULL,
    username character varying(50) NOT NULL,
    password_hash text NOT NULL,
    estado character varying(20) NOT NULL,
    primer_login boolean DEFAULT true,
    id_rol integer NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion timestamp without time zone,
    id_empresa integer NOT NULL,
    last_login timestamp(6) without time zone,
    CONSTRAINT usuario_estado_check CHECK (((estado)::text = ANY (ARRAY[('ACTIVO'::character varying)::text, ('INACTIVO'::character varying)::text, ('BLOQUEADO'::character varying)::text])))
);


ALTER TABLE usuarios.usuario OWNER TO postgres;

--
-- TOC entry 299 (class 1259 OID 38235)
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
-- TOC entry 300 (class 1259 OID 38243)
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
-- TOC entry 5585 (class 0 OID 0)
-- Dependencies: 300
-- Name: usuario_bd_id_usuario_bd_seq; Type: SEQUENCE OWNED BY; Schema: usuarios; Owner: postgres
--

ALTER SEQUENCE usuarios.usuario_bd_id_usuario_bd_seq OWNED BY usuarios.usuario_bd.id_usuario_bd;


--
-- TOC entry 301 (class 1259 OID 38244)
-- Name: usuario_cliente; Type: TABLE; Schema: usuarios; Owner: postgres
--

CREATE TABLE usuarios.usuario_cliente (
    id_usuario integer NOT NULL,
    cedula_cliente character varying(10) NOT NULL,
    id_cliente integer NOT NULL
);


ALTER TABLE usuarios.usuario_cliente OWNER TO postgres;

--
-- TOC entry 302 (class 1259 OID 38250)
-- Name: usuario_empleado; Type: TABLE; Schema: usuarios; Owner: postgres
--

CREATE TABLE usuarios.usuario_empleado (
    id_usuario integer NOT NULL,
    cedula_empleado character varying(10) NOT NULL,
    id_empleado integer NOT NULL
);


ALTER TABLE usuarios.usuario_empleado OWNER TO postgres;

--
-- TOC entry 303 (class 1259 OID 38256)
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
-- TOC entry 5586 (class 0 OID 0)
-- Dependencies: 303
-- Name: usuario_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: usuarios; Owner: postgres
--

ALTER SEQUENCE usuarios.usuario_id_usuario_seq OWNED BY usuarios.usuario.id_usuario;


--
-- TOC entry 5051 (class 2604 OID 38257)
-- Name: auditoria_estado_ticket id_auditoria; Type: DEFAULT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket ALTER COLUMN id_auditoria SET DEFAULT nextval('auditoria.auditoria_estado_ticket_id_auditoria_seq'::regclass);


--
-- TOC entry 5053 (class 2604 OID 38258)
-- Name: auditoria_evento id_evento; Type: DEFAULT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_evento ALTER COLUMN id_evento SET DEFAULT nextval('auditoria.auditoria_evento_id_evento_seq'::regclass);


--
-- TOC entry 5055 (class 2604 OID 38259)
-- Name: auditoria_login id_login; Type: DEFAULT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login ALTER COLUMN id_login SET DEFAULT nextval('auditoria.auditoria_login_id_login_seq'::regclass);


--
-- TOC entry 5057 (class 2604 OID 38260)
-- Name: auditoria_login_bd id_auditoria_login_bd; Type: DEFAULT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd ALTER COLUMN id_auditoria_login_bd SET DEFAULT nextval('auditoria.auditoria_login_bd_id_auditoria_login_bd_seq'::regclass);


--
-- TOC entry 5059 (class 2604 OID 38261)
-- Name: catalogo id_catalogo; Type: DEFAULT; Schema: catalogos; Owner: postgres
--

ALTER TABLE ONLY catalogos.catalogo ALTER COLUMN id_catalogo SET DEFAULT nextval('catalogos.catalogo_id_catalogo_seq'::regclass);


--
-- TOC entry 5061 (class 2604 OID 38262)
-- Name: catalogo_item id_item; Type: DEFAULT; Schema: catalogos; Owner: postgres
--

ALTER TABLE ONLY catalogos.catalogo_item ALTER COLUMN id_item SET DEFAULT nextval('catalogos.catalogo_item_id_item_seq'::regclass);


--
-- TOC entry 5063 (class 2604 OID 38263)
-- Name: canton id_canton; Type: DEFAULT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.canton ALTER COLUMN id_canton SET DEFAULT nextval('clientes.canton_id_canton_seq'::regclass);


--
-- TOC entry 5064 (class 2604 OID 38264)
-- Name: ciudad id_ciudad; Type: DEFAULT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.ciudad ALTER COLUMN id_ciudad SET DEFAULT nextval('clientes.ciudad_id_ciudad_seq'::regclass);


--
-- TOC entry 5066 (class 2604 OID 38265)
-- Name: cliente id_cliente; Type: DEFAULT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.cliente ALTER COLUMN id_cliente SET DEFAULT nextval('clientes.cliente_id_cliente_seq'::regclass);


--
-- TOC entry 5067 (class 2604 OID 38266)
-- Name: documento_cliente id_documento; Type: DEFAULT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.documento_cliente ALTER COLUMN id_documento SET DEFAULT nextval('clientes.documento_cliente_id_documento_seq'::regclass);


--
-- TOC entry 5069 (class 2604 OID 38267)
-- Name: documento_cliente id_cliente; Type: DEFAULT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.documento_cliente ALTER COLUMN id_cliente SET DEFAULT nextval('clientes.documento_cliente_id_cliente_seq'::regclass);


--
-- TOC entry 5070 (class 2604 OID 38268)
-- Name: pais id_pais; Type: DEFAULT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.pais ALTER COLUMN id_pais SET DEFAULT nextval('clientes.pais_id_pais_seq'::regclass);


--
-- TOC entry 5071 (class 2604 OID 38269)
-- Name: tipo_documento id_tipo_documento; Type: DEFAULT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.tipo_documento ALTER COLUMN id_tipo_documento SET DEFAULT nextval('clientes.tipo_documento_id_tipo_documento_seq'::regclass);


--
-- TOC entry 5072 (class 2604 OID 38270)
-- Name: area id_area; Type: DEFAULT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.area ALTER COLUMN id_area SET DEFAULT nextval('empleados.area_id_area_seq'::regclass);


--
-- TOC entry 5073 (class 2604 OID 38271)
-- Name: cargo id_cargo; Type: DEFAULT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.cargo ALTER COLUMN id_cargo SET DEFAULT nextval('empleados.cargo_id_cargo_seq'::regclass);


--
-- TOC entry 5074 (class 2604 OID 38272)
-- Name: documento_empleado id_documento; Type: DEFAULT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.documento_empleado ALTER COLUMN id_documento SET DEFAULT nextval('empleados.documento_empleado_id_documento_seq'::regclass);


--
-- TOC entry 5076 (class 2604 OID 38273)
-- Name: documento_empleado id_empleado; Type: DEFAULT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.documento_empleado ALTER COLUMN id_empleado SET DEFAULT nextval('empleados.documento_empleado_id_empleado_seq'::regclass);


--
-- TOC entry 5080 (class 2604 OID 38274)
-- Name: tipo_contrato id_tipo_contrato; Type: DEFAULT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.tipo_contrato ALTER COLUMN id_tipo_contrato SET DEFAULT nextval('empleados.tipo_contrato_id_tipo_contrato_seq'::regclass);


--
-- TOC entry 5081 (class 2604 OID 38275)
-- Name: documento_empresa id_documento; Type: DEFAULT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.documento_empresa ALTER COLUMN id_documento SET DEFAULT nextval('empresa.documento_empresa_id_documento_seq'::regclass);


--
-- TOC entry 5083 (class 2604 OID 38276)
-- Name: empresa id_empresa; Type: DEFAULT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.empresa ALTER COLUMN id_empresa SET DEFAULT nextval('empresa.empresa_id_empresa_seq'::regclass);


--
-- TOC entry 5085 (class 2604 OID 38277)
-- Name: servicio id_servicio; Type: DEFAULT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.servicio ALTER COLUMN id_servicio SET DEFAULT nextval('empresa.servicio_id_servicio_seq'::regclass);


--
-- TOC entry 5087 (class 2604 OID 38278)
-- Name: sucursal id_sucursal; Type: DEFAULT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.sucursal ALTER COLUMN id_sucursal SET DEFAULT nextval('empresa.sucursal_id_sucursal_seq'::regclass);


--
-- TOC entry 5089 (class 2604 OID 38279)
-- Name: canal_notificacion id_canal; Type: DEFAULT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.canal_notificacion ALTER COLUMN id_canal SET DEFAULT nextval('notificaciones.canal_notificacion_id_canal_seq'::regclass);


--
-- TOC entry 5091 (class 2604 OID 38280)
-- Name: notificacion id_notificacion; Type: DEFAULT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.notificacion ALTER COLUMN id_notificacion SET DEFAULT nextval('notificaciones.notificacion_id_notificacion_seq'::regclass);


--
-- TOC entry 5094 (class 2604 OID 38281)
-- Name: asignacion id_asignacion; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.asignacion ALTER COLUMN id_asignacion SET DEFAULT nextval('soporte.asignacion_id_asignacion_seq'::regclass);


--
-- TOC entry 5097 (class 2604 OID 38282)
-- Name: categoria id_categoria; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.categoria ALTER COLUMN id_categoria SET DEFAULT nextval('soporte.categoria_id_categoria_seq'::regclass);


--
-- TOC entry 5098 (class 2604 OID 38283)
-- Name: comentario_ticket id_comentario; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket ALTER COLUMN id_comentario SET DEFAULT nextval('soporte.comentario_ticket_id_comentario_seq'::regclass);


--
-- TOC entry 5101 (class 2604 OID 38284)
-- Name: documento_ticket id_documento; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.documento_ticket ALTER COLUMN id_documento SET DEFAULT nextval('soporte.documento_ticket_id_documento_seq'::regclass);


--
-- TOC entry 5103 (class 2604 OID 38285)
-- Name: historial_estado id_historial; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado ALTER COLUMN id_historial SET DEFAULT nextval('soporte.historial_estado_id_historial_seq'::regclass);


--
-- TOC entry 5105 (class 2604 OID 38286)
-- Name: prioridad id_prioridad; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.prioridad ALTER COLUMN id_prioridad SET DEFAULT nextval('soporte.prioridad_id_prioridad_seq'::regclass);


--
-- TOC entry 5106 (class 2604 OID 38287)
-- Name: sla_ticket id_sla; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.sla_ticket ALTER COLUMN id_sla SET DEFAULT nextval('soporte.sla_ticket_id_sla_seq'::regclass);


--
-- TOC entry 5109 (class 2604 OID 38288)
-- Name: ticket id_ticket; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket ALTER COLUMN id_ticket SET DEFAULT nextval('soporte.ticket_id_ticket_seq'::regclass);


--
-- TOC entry 5111 (class 2604 OID 38289)
-- Name: ticket id_cliente; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket ALTER COLUMN id_cliente SET DEFAULT nextval('soporte.ticket_id_cliente_seq'::regclass);


--
-- TOC entry 5112 (class 2604 OID 38290)
-- Name: ticket id_empleado; Type: DEFAULT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket ALTER COLUMN id_empleado SET DEFAULT nextval('soporte.ticket_id_empleado_seq'::regclass);


--
-- TOC entry 5113 (class 2604 OID 38291)
-- Name: rol id_rol; Type: DEFAULT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.rol ALTER COLUMN id_rol SET DEFAULT nextval('usuarios.rol_id_rol_seq'::regclass);


--
-- TOC entry 5114 (class 2604 OID 38292)
-- Name: rol_bd id_rol_bd; Type: DEFAULT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.rol_bd ALTER COLUMN id_rol_bd SET DEFAULT nextval('usuarios.rol_bd_id_rol_bd_seq'::regclass);


--
-- TOC entry 5115 (class 2604 OID 38293)
-- Name: usuario id_usuario; Type: DEFAULT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario ALTER COLUMN id_usuario SET DEFAULT nextval('usuarios.usuario_id_usuario_seq'::regclass);


--
-- TOC entry 5118 (class 2604 OID 38294)
-- Name: usuario_bd id_usuario_bd; Type: DEFAULT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_bd ALTER COLUMN id_usuario_bd SET DEFAULT nextval('usuarios.usuario_bd_id_usuario_bd_seq'::regclass);


--
-- TOC entry 5467 (class 0 OID 37866)
-- Dependencies: 227
-- Data for Name: auditoria_estado_ticket; Type: TABLE DATA; Schema: auditoria; Owner: postgres
--

COPY auditoria.auditoria_estado_ticket (id_auditoria, id_ticket, estado_anterior, estado_nuevo, usuario_bd, fecha_cambio, id_estado_anterior, id_estado_nuevo, id_item_evento, id_usuario, id_estado_nuevo_item) FROM stdin;
\.


--
-- TOC entry 5469 (class 0 OID 37876)
-- Dependencies: 229
-- Data for Name: auditoria_evento; Type: TABLE DATA; Schema: auditoria; Owner: postgres
--

COPY auditoria.auditoria_evento (id_evento, esquema_afectado, tabla_afectada, id_registro, accion, descripcion, usuario_bd, rol_bd, fecha_evento, id_usuario, id_notificacion, id_accion) FROM stdin;
\.


--
-- TOC entry 5471 (class 0 OID 37892)
-- Dependencies: 231
-- Data for Name: auditoria_login; Type: TABLE DATA; Schema: auditoria; Owner: postgres
--

COPY auditoria.auditoria_login (id_login, usuario_app, usuario_bd, exito, ip_origen, fecha_login, id_usuario, id_item_evento) FROM stdin;
\.


--
-- TOC entry 5472 (class 0 OID 37899)
-- Dependencies: 232
-- Data for Name: auditoria_login_bd; Type: TABLE DATA; Schema: auditoria; Owner: postgres
--

COPY auditoria.auditoria_login_bd (id_auditoria_login_bd, id_usuario_bd, id_item_evento, fecha_evento, ip_origen, observacion) FROM stdin;
\.


--
-- TOC entry 5475 (class 0 OID 37911)
-- Dependencies: 235
-- Data for Name: catalogo; Type: TABLE DATA; Schema: catalogos; Owner: postgres
--

COPY catalogos.catalogo (id_catalogo, nombre, descripcion, activo) FROM stdin;
\.


--
-- TOC entry 5477 (class 0 OID 37920)
-- Dependencies: 237
-- Data for Name: catalogo_item; Type: TABLE DATA; Schema: catalogos; Owner: postgres
--

COPY catalogos.catalogo_item (id_item, id_catalogo, codigo, nombre, orden, activo) FROM stdin;
\.


--
-- TOC entry 5479 (class 0 OID 37928)
-- Dependencies: 239
-- Data for Name: canton; Type: TABLE DATA; Schema: clientes; Owner: postgres
--

COPY clientes.canton (id_canton, nombre, id_ciudad) FROM stdin;
4	Guayaquil	3
5	Daule	3
6	Durán	3
7	Samborondón	3
8	Milagro	3
9	Quito	4
10	Mejía	4
11	Cayambe	4
12	Rumiñahui	4
13	Pedro Moncayo	4
14	Quevedo	5
15	Buena Fe	5
16	Mocache	5
17	Valencia	5
18	Ventanas	5
19	Ambato	6
20	Pelileo	6
21	Píllaro	6
22	Cevallos	6
23	Mocha	6
24	Loja	7
25	Calvas	7
26	Catamayo	7
27	Celica	7
28	Macará	7
29	Cuenca	8
30	Gualaceo	8
31	Paute	8
32	Santa Isabel	8
33	Girón	8
34	Manta	9
35	Montecristi	9
36	Jaramijó	9
37	Portoviejo	9
38	Jipijapa	9
39	Ibarra	10
40	Otavalo	10
41	Cotacachi	10
42	Antonio Ante	10
43	Pimampiro	10
44	Baños de Agua Santa	11
45	Santa Clara	11
46	Mera	11
47	Palora	11
48	Arajuno	11
49	Tena	12
50	Archidona	12
51	Carlos Julio Arosemena Tola	12
52	El Chaco	12
53	Quijos	12
54	La Boca	13
55	Palermo	13
56	Recoleta	13
57	San Telmo	13
58	Belgrano	13
59	Centro	14
60	Nueva Córdoba	14
61	General Paz	14
62	Cerro de las Rosas	14
63	Alta Córdoba	14
64	Centro	15
65	Pichincha	15
66	Norte	15
67	Sur	15
68	Oeste	15
69	Usaquén	16
70	Chapinero	16
71	La Candelaria	16
72	Teusaquillo	16
73	Suba	16
74	El Poblado	17
75	Laureles-Estadio	17
76	Belén	17
77	La Candelaria (Centro)	17
78	Guayabal	17
79	El Peñón	18
80	Granada	18
81	San Antonio	18
82	Ciudad Jardín	18
83	Pance	18
84	Coyoacán	19
85	Cuauhtémoc	19
86	Polanco	19
87	Condesa	19
88	Xochimilco	19
89	Centro	20
90	Zapopan	20
91	Tlaquepaque	20
92	Providencia	20
93	Chapalita	20
94	San Pedro Garza García	21
95	Centro	21
96	Obispado	21
97	Valle Oriente	21
98	Cumbres	21
\.


--
-- TOC entry 5481 (class 0 OID 37935)
-- Dependencies: 241
-- Data for Name: ciudad; Type: TABLE DATA; Schema: clientes; Owner: postgres
--

COPY clientes.ciudad (id_ciudad, nombre, id_pais) FROM stdin;
3	Guayaquil	9
4	Quito	9
5	Los Ríos	9
6	Ambato	9
7	Loja	9
8	Cuenca	9
9	Manta	9
10	Ibarra	9
11	Baños de Agua Santa	9
12	Tena	9
13	Buenos Aires	2
14	Córdoba	2
15	Rosario	2
16	Bogotá	6
17	Medellín	6
18	Cali	6
19	Ciudad de México	14
20	Guadalajara	14
21	Monterrey	14
\.


--
-- TOC entry 5483 (class 0 OID 37942)
-- Dependencies: 243
-- Data for Name: cliente; Type: TABLE DATA; Schema: clientes; Owner: postgres
--

COPY clientes.cliente (cedula, apellidos, celular, direccion, id_canton, contrato_pdf_path, croquis_pdf_path, estado_servicio, fecha_creacion, correo, fecha_actualizacion, id_empresa, id_cliente, nombres) FROM stdin;
1250062336	Zambrano Yong	0995220227	AV. 2 DE JULIO	4	\N	\N	ACTIVO	\N	zambranomourad@gmail.com	\N	1	11	Angel Daniel
0503360398	Mendoza Bermello	0963136286	Av. Patria Nueva	14	\N	\N	ACTIVO	\N	angellomendoza46@gmail.com	\N	1	12	Angello Agustin
1203548796	Mendoza Bermello	0987546251	Av. Patria Nueva Unión y Progreso	14	\N	\N	ACTIVO	\N	elianabermello2006@gmail.com	\N	1	13	Eliana Mishelle
\.


--
-- TOC entry 5485 (class 0 OID 37958)
-- Dependencies: 245
-- Data for Name: documento_cliente; Type: TABLE DATA; Schema: clientes; Owner: postgres
--

COPY clientes.documento_cliente (id_documento, numero_documento, ruta_archivo, descripcion, fecha_subida, estado, id_cliente, id_tipo_documento) FROM stdin;
\.


--
-- TOC entry 5488 (class 0 OID 37972)
-- Dependencies: 248
-- Data for Name: pais; Type: TABLE DATA; Schema: clientes; Owner: postgres
--

COPY clientes.pais (id_pais, nombre) FROM stdin;
2	Argentina
3	Bolivia
4	Brasil
5	Chile
6	Colombia
7	Costa Rica
8	Cuba
9	Ecuador
10	El Salvador
11	Guatemala
12	Haití
13	Honduras
14	México
15	Nicaragua
16	Panamá
17	Paraguay
18	Perú
19	República Dominicana
20	Uruguay
21	Venezuela
\.


--
-- TOC entry 5490 (class 0 OID 37978)
-- Dependencies: 250
-- Data for Name: tipo_documento; Type: TABLE DATA; Schema: clientes; Owner: postgres
--

COPY clientes.tipo_documento (id_tipo_documento, codigo) FROM stdin;
\.


--
-- TOC entry 5492 (class 0 OID 37984)
-- Dependencies: 252
-- Data for Name: area; Type: TABLE DATA; Schema: empleados; Owner: postgres
--

COPY empleados.area (id_area, nombre) FROM stdin;
\.


--
-- TOC entry 5494 (class 0 OID 37990)
-- Dependencies: 254
-- Data for Name: cargo; Type: TABLE DATA; Schema: empleados; Owner: postgres
--

COPY empleados.cargo (id_cargo, nombre) FROM stdin;
\.


--
-- TOC entry 5496 (class 0 OID 37996)
-- Dependencies: 256
-- Data for Name: documento_empleado; Type: TABLE DATA; Schema: empleados; Owner: postgres
--

COPY empleados.documento_empleado (id_documento, cedula_empleado, tipo_documento, ruta_archivo, descripcion, fecha_subida, estado, id_empleado) FROM stdin;
\.


--
-- TOC entry 5500 (class 0 OID 38011)
-- Dependencies: 260
-- Data for Name: empleado; Type: TABLE DATA; Schema: empleados; Owner: postgres
--

COPY empleados.empleado (cedula, nombre, apellido, celular, correo_personal, correo_corporativo, fecha_ingreso, id_cargo, id_area, id_tipo_contrato, contrato_pdf_path, estado, fecha_creacion, fecha_actualizacion, id_empresa, id_empleado) FROM stdin;
\.


--
-- TOC entry 5501 (class 0 OID 38030)
-- Dependencies: 261
-- Data for Name: tipo_contrato; Type: TABLE DATA; Schema: empleados; Owner: postgres
--

COPY empleados.tipo_contrato (id_tipo_contrato, nombre) FROM stdin;
\.


--
-- TOC entry 5503 (class 0 OID 38036)
-- Dependencies: 263
-- Data for Name: documento_empresa; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.documento_empresa (id_documento, id_empresa, numero_documento, ruta_archivo, descripcion, fecha_subida, estado, id_tipo_documento) FROM stdin;
\.


--
-- TOC entry 5505 (class 0 OID 38049)
-- Dependencies: 265
-- Data for Name: empresa; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.empresa (id_empresa, nombre_comercial, razon_social, ruc, tipo_empresa, correo_contacto, telefono_contacto, direccion_principal, estado, fecha_creacion) FROM stdin;
1	Empresa Por Defecto	Empresa Por Defecto S.A.	0000000000000	MATRIZ	\N	\N	\N	ACTIVO	2026-01-28 17:43:58.694565
\.


--
-- TOC entry 5507 (class 0 OID 38062)
-- Dependencies: 267
-- Data for Name: empresa_servicio; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.empresa_servicio (id_empresa, id_servicio) FROM stdin;
\.


--
-- TOC entry 5508 (class 0 OID 38067)
-- Dependencies: 268
-- Data for Name: servicio; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.servicio (id_servicio, nombre, descripcion, activo) FROM stdin;
\.


--
-- TOC entry 5510 (class 0 OID 38076)
-- Dependencies: 270
-- Data for Name: sucursal; Type: TABLE DATA; Schema: empresa; Owner: postgres
--

COPY empresa.sucursal (id_sucursal, id_empresa, nombre, direccion, ciudad, canton, telefono, estado) FROM stdin;
\.


--
-- TOC entry 5512 (class 0 OID 38088)
-- Dependencies: 272
-- Data for Name: canal_notificacion; Type: TABLE DATA; Schema: notificaciones; Owner: postgres
--

COPY notificaciones.canal_notificacion (id_canal, nombre, activo) FROM stdin;
\.


--
-- TOC entry 5514 (class 0 OID 38095)
-- Dependencies: 274
-- Data for Name: notificacion; Type: TABLE DATA; Schema: notificaciones; Owner: postgres
--

COPY notificaciones.notificacion (id_notificacion, id_canal, destinatario, asunto, mensaje, enviado, fecha_creacion, id_ticket, id_usuario, id_tipo_notificacion, id_usuario_origen) FROM stdin;
\.


--
-- TOC entry 5516 (class 0 OID 38107)
-- Dependencies: 276
-- Data for Name: asignacion; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.asignacion (id_asignacion, id_ticket, fecha_asignacion, activo, id_usuario) FROM stdin;
\.


--
-- TOC entry 5518 (class 0 OID 38116)
-- Dependencies: 278
-- Data for Name: categoria; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.categoria (id_categoria, nombre, descripcion, id_item) FROM stdin;
\.


--
-- TOC entry 5520 (class 0 OID 38125)
-- Dependencies: 280
-- Data for Name: comentario_ticket; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.comentario_ticket (id_comentario, id_ticket, id_usuario, comentario, fecha_creacion, es_interno, id_empresa) FROM stdin;
\.


--
-- TOC entry 5522 (class 0 OID 38138)
-- Dependencies: 282
-- Data for Name: documento_ticket; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.documento_ticket (id_documento, id_ticket, tipo_documento, ruta_archivo, descripcion, fecha_subida, id_usuario) FROM stdin;
\.


--
-- TOC entry 5524 (class 0 OID 38149)
-- Dependencies: 284
-- Data for Name: historial_estado; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.historial_estado (id_historial, id_ticket, id_estado, usuario_bd, fecha_cambio, observacion, id_estado_anterior, id_estado_nuevo, id_usuario) FROM stdin;
\.


--
-- TOC entry 5526 (class 0 OID 38161)
-- Dependencies: 286
-- Data for Name: prioridad; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.prioridad (id_prioridad, nombre, descripcion, id_item) FROM stdin;
\.


--
-- TOC entry 5528 (class 0 OID 38170)
-- Dependencies: 288
-- Data for Name: sla_ticket; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.sla_ticket (id_sla, nombre, descripcion, tiempo_respuesta_min, tiempo_solucion_min, aplica_prioridad, activo, fecha_creacion, id_empresa) FROM stdin;
\.


--
-- TOC entry 5530 (class 0 OID 38183)
-- Dependencies: 290
-- Data for Name: ticket; Type: TABLE DATA; Schema: soporte; Owner: postgres
--

COPY soporte.ticket (id_ticket, cedula_cliente, id_categoria, id_prioridad, id_estado, asunto, descripcion, fecha_creacion, fecha_actualizacion, id_servicio, id_sucursal, id_sla, id_estado_item, id_prioridad_item, id_categoria_item, id_usuario_creador, id_usuario_asignado, id_empresa, id_cliente, id_empleado) FROM stdin;
\.


--
-- TOC entry 5534 (class 0 OID 38205)
-- Dependencies: 294
-- Data for Name: rol; Type: TABLE DATA; Schema: usuarios; Owner: postgres
--

COPY usuarios.rol (id_rol, codigo, descripcion) FROM stdin;
1	ROLE_USER	Standard user role for clients.
2	ROLE_TECHNICIAN	Technician role for handling incidents.
3	ROLE_ADMIN	Administrator role with full access.
\.


--
-- TOC entry 5535 (class 0 OID 38212)
-- Dependencies: 295
-- Data for Name: rol_bd; Type: TABLE DATA; Schema: usuarios; Owner: postgres
--

COPY usuarios.rol_bd (id_rol_bd, nombre, descripcion) FROM stdin;
\.


--
-- TOC entry 5538 (class 0 OID 38221)
-- Dependencies: 298
-- Data for Name: usuario; Type: TABLE DATA; Schema: usuarios; Owner: postgres
--

COPY usuarios.usuario (id_usuario, username, password_hash, estado, primer_login, id_rol, fecha_creacion, fecha_actualizacion, id_empresa, last_login) FROM stdin;
10	admin	$2a$10$wQtX5iK7TVGM8n/QS0eecO04iBYlERFSuIFGz8DA.CVnhaifHks16	ACTIVO	f	3	2026-01-29 11:18:31.764587	\N	1	\N
11	tech	$2a$10$zsDI.xjkRmHgYa5dPpjOpOtE3EQK51aSIZmVSwFzBkxuKs2TLo5ya	ACTIVO	f	2	2026-01-29 11:18:31.840913	\N	1	\N
12	user	$2a$10$Nx1aPVs45bq01htRRyLwfeeDfmSK6uK/uB25HBk/Rt4HC3ZvOPaWO	ACTIVO	f	1	2026-01-29 11:18:31.910531	\N	1	\N
13	azambrano	$2a$10$zIdra8VPwlmbta1uBZ/nFuKa7/h0.MUWpXG7xX8nKAdfYcsKezDT6	ACTIVO	t	1	2026-01-31 01:50:53.228169	2026-01-31 03:16:34.026976	1	\N
14	pepe	$2a$10$mS/REUDY0Ar08XBUUNQ39OnJS13J2d/ZDiSveYjEnJCt9vM6qTVaO	ACTIVO	t	1	2026-01-31 04:43:47.025035	\N	1	\N
15	amendoza	$2a$10$g8m7GhOVxcKUAM7En2ExDeXcPvHVKoaIIJzk3XvYTYaDIyxtxOG7e	ACTIVO	t	1	2026-01-31 17:15:45.083627	\N	1	\N
16	emendozab	$2a$10$NwkAjPfg0luwdeQIqifuNOGjah.aqmJ6BnpeW0eHNEAED3Wpn3NCG	ACTIVO	t	1	2026-02-02 11:13:41.518164	\N	1	\N
\.


--
-- TOC entry 5539 (class 0 OID 38235)
-- Dependencies: 299
-- Data for Name: usuario_bd; Type: TABLE DATA; Schema: usuarios; Owner: postgres
--

COPY usuarios.usuario_bd (id_usuario_bd, nombre, id_rol_bd, fecha_creacion, id_usuario) FROM stdin;
\.


--
-- TOC entry 5541 (class 0 OID 38244)
-- Dependencies: 301
-- Data for Name: usuario_cliente; Type: TABLE DATA; Schema: usuarios; Owner: postgres
--

COPY usuarios.usuario_cliente (id_usuario, cedula_cliente, id_cliente) FROM stdin;
13	1250062336	11
15	0503360398	12
16	1203548796	13
\.


--
-- TOC entry 5542 (class 0 OID 38250)
-- Dependencies: 302
-- Data for Name: usuario_empleado; Type: TABLE DATA; Schema: usuarios; Owner: postgres
--

COPY usuarios.usuario_empleado (id_usuario, cedula_empleado, id_empleado) FROM stdin;
\.


--
-- TOC entry 5587 (class 0 OID 0)
-- Dependencies: 228
-- Name: auditoria_estado_ticket_id_auditoria_seq; Type: SEQUENCE SET; Schema: auditoria; Owner: postgres
--

SELECT pg_catalog.setval('auditoria.auditoria_estado_ticket_id_auditoria_seq', 1, false);


--
-- TOC entry 5588 (class 0 OID 0)
-- Dependencies: 230
-- Name: auditoria_evento_id_evento_seq; Type: SEQUENCE SET; Schema: auditoria; Owner: postgres
--

SELECT pg_catalog.setval('auditoria.auditoria_evento_id_evento_seq', 1, false);


--
-- TOC entry 5589 (class 0 OID 0)
-- Dependencies: 233
-- Name: auditoria_login_bd_id_auditoria_login_bd_seq; Type: SEQUENCE SET; Schema: auditoria; Owner: postgres
--

SELECT pg_catalog.setval('auditoria.auditoria_login_bd_id_auditoria_login_bd_seq', 1, false);


--
-- TOC entry 5590 (class 0 OID 0)
-- Dependencies: 234
-- Name: auditoria_login_id_login_seq; Type: SEQUENCE SET; Schema: auditoria; Owner: postgres
--

SELECT pg_catalog.setval('auditoria.auditoria_login_id_login_seq', 1, false);


--
-- TOC entry 5591 (class 0 OID 0)
-- Dependencies: 236
-- Name: catalogo_id_catalogo_seq; Type: SEQUENCE SET; Schema: catalogos; Owner: postgres
--

SELECT pg_catalog.setval('catalogos.catalogo_id_catalogo_seq', 1, false);


--
-- TOC entry 5592 (class 0 OID 0)
-- Dependencies: 238
-- Name: catalogo_item_id_item_seq; Type: SEQUENCE SET; Schema: catalogos; Owner: postgres
--

SELECT pg_catalog.setval('catalogos.catalogo_item_id_item_seq', 1, false);


--
-- TOC entry 5593 (class 0 OID 0)
-- Dependencies: 240
-- Name: canton_id_canton_seq; Type: SEQUENCE SET; Schema: clientes; Owner: postgres
--

SELECT pg_catalog.setval('clientes.canton_id_canton_seq', 98, true);


--
-- TOC entry 5594 (class 0 OID 0)
-- Dependencies: 242
-- Name: ciudad_id_ciudad_seq; Type: SEQUENCE SET; Schema: clientes; Owner: postgres
--

SELECT pg_catalog.setval('clientes.ciudad_id_ciudad_seq', 21, true);


--
-- TOC entry 5595 (class 0 OID 0)
-- Dependencies: 244
-- Name: cliente_id_cliente_seq; Type: SEQUENCE SET; Schema: clientes; Owner: postgres
--

SELECT pg_catalog.setval('clientes.cliente_id_cliente_seq', 13, true);


--
-- TOC entry 5596 (class 0 OID 0)
-- Dependencies: 246
-- Name: documento_cliente_id_cliente_seq; Type: SEQUENCE SET; Schema: clientes; Owner: postgres
--

SELECT pg_catalog.setval('clientes.documento_cliente_id_cliente_seq', 1, false);


--
-- TOC entry 5597 (class 0 OID 0)
-- Dependencies: 247
-- Name: documento_cliente_id_documento_seq; Type: SEQUENCE SET; Schema: clientes; Owner: postgres
--

SELECT pg_catalog.setval('clientes.documento_cliente_id_documento_seq', 1, false);


--
-- TOC entry 5598 (class 0 OID 0)
-- Dependencies: 249
-- Name: pais_id_pais_seq; Type: SEQUENCE SET; Schema: clientes; Owner: postgres
--

SELECT pg_catalog.setval('clientes.pais_id_pais_seq', 21, true);


--
-- TOC entry 5599 (class 0 OID 0)
-- Dependencies: 251
-- Name: tipo_documento_id_tipo_documento_seq; Type: SEQUENCE SET; Schema: clientes; Owner: postgres
--

SELECT pg_catalog.setval('clientes.tipo_documento_id_tipo_documento_seq', 1, false);


--
-- TOC entry 5600 (class 0 OID 0)
-- Dependencies: 253
-- Name: area_id_area_seq; Type: SEQUENCE SET; Schema: empleados; Owner: postgres
--

SELECT pg_catalog.setval('empleados.area_id_area_seq', 1, false);


--
-- TOC entry 5601 (class 0 OID 0)
-- Dependencies: 255
-- Name: cargo_id_cargo_seq; Type: SEQUENCE SET; Schema: empleados; Owner: postgres
--

SELECT pg_catalog.setval('empleados.cargo_id_cargo_seq', 1, false);


--
-- TOC entry 5602 (class 0 OID 0)
-- Dependencies: 257
-- Name: documento_empleado_id_documento_seq; Type: SEQUENCE SET; Schema: empleados; Owner: postgres
--

SELECT pg_catalog.setval('empleados.documento_empleado_id_documento_seq', 1, false);


--
-- TOC entry 5603 (class 0 OID 0)
-- Dependencies: 258
-- Name: documento_empleado_id_empleado_seq; Type: SEQUENCE SET; Schema: empleados; Owner: postgres
--

SELECT pg_catalog.setval('empleados.documento_empleado_id_empleado_seq', 1, false);


--
-- TOC entry 5604 (class 0 OID 0)
-- Dependencies: 259
-- Name: empleado_id_empleado_seq; Type: SEQUENCE SET; Schema: empleados; Owner: postgres
--

SELECT pg_catalog.setval('empleados.empleado_id_empleado_seq', 1, false);


--
-- TOC entry 5605 (class 0 OID 0)
-- Dependencies: 262
-- Name: tipo_contrato_id_tipo_contrato_seq; Type: SEQUENCE SET; Schema: empleados; Owner: postgres
--

SELECT pg_catalog.setval('empleados.tipo_contrato_id_tipo_contrato_seq', 1, false);


--
-- TOC entry 5606 (class 0 OID 0)
-- Dependencies: 264
-- Name: documento_empresa_id_documento_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.documento_empresa_id_documento_seq', 1, false);


--
-- TOC entry 5607 (class 0 OID 0)
-- Dependencies: 266
-- Name: empresa_id_empresa_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.empresa_id_empresa_seq', 1, true);


--
-- TOC entry 5608 (class 0 OID 0)
-- Dependencies: 269
-- Name: servicio_id_servicio_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.servicio_id_servicio_seq', 1, false);


--
-- TOC entry 5609 (class 0 OID 0)
-- Dependencies: 271
-- Name: sucursal_id_sucursal_seq; Type: SEQUENCE SET; Schema: empresa; Owner: postgres
--

SELECT pg_catalog.setval('empresa.sucursal_id_sucursal_seq', 1, false);


--
-- TOC entry 5610 (class 0 OID 0)
-- Dependencies: 273
-- Name: canal_notificacion_id_canal_seq; Type: SEQUENCE SET; Schema: notificaciones; Owner: postgres
--

SELECT pg_catalog.setval('notificaciones.canal_notificacion_id_canal_seq', 1, false);


--
-- TOC entry 5611 (class 0 OID 0)
-- Dependencies: 275
-- Name: notificacion_id_notificacion_seq; Type: SEQUENCE SET; Schema: notificaciones; Owner: postgres
--

SELECT pg_catalog.setval('notificaciones.notificacion_id_notificacion_seq', 1, false);


--
-- TOC entry 5612 (class 0 OID 0)
-- Dependencies: 277
-- Name: asignacion_id_asignacion_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.asignacion_id_asignacion_seq', 1, false);


--
-- TOC entry 5613 (class 0 OID 0)
-- Dependencies: 279
-- Name: categoria_id_categoria_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.categoria_id_categoria_seq', 1, false);


--
-- TOC entry 5614 (class 0 OID 0)
-- Dependencies: 281
-- Name: comentario_ticket_id_comentario_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.comentario_ticket_id_comentario_seq', 1, false);


--
-- TOC entry 5615 (class 0 OID 0)
-- Dependencies: 283
-- Name: documento_ticket_id_documento_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.documento_ticket_id_documento_seq', 1, false);


--
-- TOC entry 5616 (class 0 OID 0)
-- Dependencies: 285
-- Name: historial_estado_id_historial_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.historial_estado_id_historial_seq', 1, false);


--
-- TOC entry 5617 (class 0 OID 0)
-- Dependencies: 287
-- Name: prioridad_id_prioridad_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.prioridad_id_prioridad_seq', 1, false);


--
-- TOC entry 5618 (class 0 OID 0)
-- Dependencies: 289
-- Name: sla_ticket_id_sla_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.sla_ticket_id_sla_seq', 1, false);


--
-- TOC entry 5619 (class 0 OID 0)
-- Dependencies: 291
-- Name: ticket_id_cliente_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.ticket_id_cliente_seq', 1, false);


--
-- TOC entry 5620 (class 0 OID 0)
-- Dependencies: 292
-- Name: ticket_id_empleado_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.ticket_id_empleado_seq', 1, false);


--
-- TOC entry 5621 (class 0 OID 0)
-- Dependencies: 293
-- Name: ticket_id_ticket_seq; Type: SEQUENCE SET; Schema: soporte; Owner: postgres
--

SELECT pg_catalog.setval('soporte.ticket_id_ticket_seq', 1, false);


--
-- TOC entry 5622 (class 0 OID 0)
-- Dependencies: 296
-- Name: rol_bd_id_rol_bd_seq; Type: SEQUENCE SET; Schema: usuarios; Owner: postgres
--

SELECT pg_catalog.setval('usuarios.rol_bd_id_rol_bd_seq', 1, false);


--
-- TOC entry 5623 (class 0 OID 0)
-- Dependencies: 297
-- Name: rol_id_rol_seq; Type: SEQUENCE SET; Schema: usuarios; Owner: postgres
--

SELECT pg_catalog.setval('usuarios.rol_id_rol_seq', 3, true);


--
-- TOC entry 5624 (class 0 OID 0)
-- Dependencies: 300
-- Name: usuario_bd_id_usuario_bd_seq; Type: SEQUENCE SET; Schema: usuarios; Owner: postgres
--

SELECT pg_catalog.setval('usuarios.usuario_bd_id_usuario_bd_seq', 1, false);


--
-- TOC entry 5625 (class 0 OID 0)
-- Dependencies: 303
-- Name: usuario_id_usuario_seq; Type: SEQUENCE SET; Schema: usuarios; Owner: postgres
--

SELECT pg_catalog.setval('usuarios.usuario_id_usuario_seq', 16, true);


--
-- TOC entry 5124 (class 2606 OID 38296)
-- Name: auditoria_estado_ticket auditoria_estado_ticket_pkey; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT auditoria_estado_ticket_pkey PRIMARY KEY (id_auditoria);


--
-- TOC entry 5126 (class 2606 OID 38298)
-- Name: auditoria_evento auditoria_evento_pkey; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_evento
    ADD CONSTRAINT auditoria_evento_pkey PRIMARY KEY (id_evento);


--
-- TOC entry 5130 (class 2606 OID 38300)
-- Name: auditoria_login_bd auditoria_login_bd_pkey; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd
    ADD CONSTRAINT auditoria_login_bd_pkey PRIMARY KEY (id_auditoria_login_bd);


--
-- TOC entry 5128 (class 2606 OID 38302)
-- Name: auditoria_login auditoria_login_pkey; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login
    ADD CONSTRAINT auditoria_login_pkey PRIMARY KEY (id_login);


--
-- TOC entry 5136 (class 2606 OID 38304)
-- Name: catalogo_item catalogo_item_pkey; Type: CONSTRAINT; Schema: catalogos; Owner: postgres
--

ALTER TABLE ONLY catalogos.catalogo_item
    ADD CONSTRAINT catalogo_item_pkey PRIMARY KEY (id_item);


--
-- TOC entry 5132 (class 2606 OID 38306)
-- Name: catalogo catalogo_nombre_key; Type: CONSTRAINT; Schema: catalogos; Owner: postgres
--

ALTER TABLE ONLY catalogos.catalogo
    ADD CONSTRAINT catalogo_nombre_key UNIQUE (nombre);


--
-- TOC entry 5134 (class 2606 OID 38308)
-- Name: catalogo catalogo_pkey; Type: CONSTRAINT; Schema: catalogos; Owner: postgres
--

ALTER TABLE ONLY catalogos.catalogo
    ADD CONSTRAINT catalogo_pkey PRIMARY KEY (id_catalogo);


--
-- TOC entry 5138 (class 2606 OID 38310)
-- Name: canton canton_pkey; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.canton
    ADD CONSTRAINT canton_pkey PRIMARY KEY (id_canton);


--
-- TOC entry 5140 (class 2606 OID 38312)
-- Name: ciudad ciudad_pkey; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.ciudad
    ADD CONSTRAINT ciudad_pkey PRIMARY KEY (id_ciudad);


--
-- TOC entry 5146 (class 2606 OID 38314)
-- Name: documento_cliente documento_cliente_pkey; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.documento_cliente
    ADD CONSTRAINT documento_cliente_pkey PRIMARY KEY (id_documento);


--
-- TOC entry 5150 (class 2606 OID 38316)
-- Name: pais pais_nombre_key; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.pais
    ADD CONSTRAINT pais_nombre_key UNIQUE (nombre);


--
-- TOC entry 5152 (class 2606 OID 38318)
-- Name: pais pais_pkey; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.pais
    ADD CONSTRAINT pais_pkey PRIMARY KEY (id_pais);


--
-- TOC entry 5142 (class 2606 OID 38320)
-- Name: cliente pk_cliente; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.cliente
    ADD CONSTRAINT pk_cliente PRIMARY KEY (id_cliente);


--
-- TOC entry 5154 (class 2606 OID 38322)
-- Name: tipo_documento tipo_documento_codigo_key; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.tipo_documento
    ADD CONSTRAINT tipo_documento_codigo_key UNIQUE (codigo);


--
-- TOC entry 5156 (class 2606 OID 38324)
-- Name: tipo_documento tipo_documento_pkey; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.tipo_documento
    ADD CONSTRAINT tipo_documento_pkey PRIMARY KEY (id_tipo_documento);


--
-- TOC entry 5144 (class 2606 OID 38326)
-- Name: cliente uq_cliente_id_cliente; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.cliente
    ADD CONSTRAINT uq_cliente_id_cliente UNIQUE (id_cliente);


--
-- TOC entry 5148 (class 2606 OID 38328)
-- Name: documento_cliente uq_documento_cliente; Type: CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.documento_cliente
    ADD CONSTRAINT uq_documento_cliente UNIQUE (id_tipo_documento, numero_documento);


--
-- TOC entry 5158 (class 2606 OID 38330)
-- Name: area area_nombre_key; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.area
    ADD CONSTRAINT area_nombre_key UNIQUE (nombre);


--
-- TOC entry 5160 (class 2606 OID 38332)
-- Name: area area_pkey; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.area
    ADD CONSTRAINT area_pkey PRIMARY KEY (id_area);


--
-- TOC entry 5162 (class 2606 OID 38334)
-- Name: cargo cargo_nombre_key; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.cargo
    ADD CONSTRAINT cargo_nombre_key UNIQUE (nombre);


--
-- TOC entry 5164 (class 2606 OID 38336)
-- Name: cargo cargo_pkey; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.cargo
    ADD CONSTRAINT cargo_pkey PRIMARY KEY (id_cargo);


--
-- TOC entry 5166 (class 2606 OID 38338)
-- Name: documento_empleado documento_empleado_pkey; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.documento_empleado
    ADD CONSTRAINT documento_empleado_pkey PRIMARY KEY (id_documento);


--
-- TOC entry 5168 (class 2606 OID 38340)
-- Name: empleado empleado_correo_corporativo_key; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT empleado_correo_corporativo_key UNIQUE (correo_corporativo);


--
-- TOC entry 5170 (class 2606 OID 38342)
-- Name: empleado pk_empleado; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT pk_empleado PRIMARY KEY (id_empleado);


--
-- TOC entry 5176 (class 2606 OID 38344)
-- Name: tipo_contrato tipo_contrato_nombre_key; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.tipo_contrato
    ADD CONSTRAINT tipo_contrato_nombre_key UNIQUE (nombre);


--
-- TOC entry 5178 (class 2606 OID 38346)
-- Name: tipo_contrato tipo_contrato_pkey; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.tipo_contrato
    ADD CONSTRAINT tipo_contrato_pkey PRIMARY KEY (id_tipo_contrato);


--
-- TOC entry 5172 (class 2606 OID 38348)
-- Name: empleado uq_empleado_cedula; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT uq_empleado_cedula UNIQUE (cedula);


--
-- TOC entry 5174 (class 2606 OID 38350)
-- Name: empleado uq_empleado_id_empleado; Type: CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT uq_empleado_id_empleado UNIQUE (id_empleado);


--
-- TOC entry 5180 (class 2606 OID 38352)
-- Name: documento_empresa documento_empresa_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.documento_empresa
    ADD CONSTRAINT documento_empresa_pkey PRIMARY KEY (id_documento);


--
-- TOC entry 5184 (class 2606 OID 38354)
-- Name: empresa empresa_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.empresa
    ADD CONSTRAINT empresa_pkey PRIMARY KEY (id_empresa);


--
-- TOC entry 5186 (class 2606 OID 38356)
-- Name: empresa empresa_ruc_key; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.empresa
    ADD CONSTRAINT empresa_ruc_key UNIQUE (ruc);


--
-- TOC entry 5188 (class 2606 OID 38358)
-- Name: empresa_servicio empresa_servicio_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.empresa_servicio
    ADD CONSTRAINT empresa_servicio_pkey PRIMARY KEY (id_empresa, id_servicio);


--
-- TOC entry 5190 (class 2606 OID 38360)
-- Name: servicio servicio_nombre_key; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.servicio
    ADD CONSTRAINT servicio_nombre_key UNIQUE (nombre);


--
-- TOC entry 5192 (class 2606 OID 38362)
-- Name: servicio servicio_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.servicio
    ADD CONSTRAINT servicio_pkey PRIMARY KEY (id_servicio);


--
-- TOC entry 5194 (class 2606 OID 38364)
-- Name: sucursal sucursal_pkey; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.sucursal
    ADD CONSTRAINT sucursal_pkey PRIMARY KEY (id_sucursal);


--
-- TOC entry 5182 (class 2606 OID 38366)
-- Name: documento_empresa uq_documento_empresa; Type: CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.documento_empresa
    ADD CONSTRAINT uq_documento_empresa UNIQUE (id_tipo_documento, numero_documento);


--
-- TOC entry 5196 (class 2606 OID 38368)
-- Name: canal_notificacion canal_notificacion_pkey; Type: CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.canal_notificacion
    ADD CONSTRAINT canal_notificacion_pkey PRIMARY KEY (id_canal);


--
-- TOC entry 5198 (class 2606 OID 38370)
-- Name: notificacion notificacion_pkey; Type: CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.notificacion
    ADD CONSTRAINT notificacion_pkey PRIMARY KEY (id_notificacion);


--
-- TOC entry 5200 (class 2606 OID 38372)
-- Name: asignacion asignacion_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.asignacion
    ADD CONSTRAINT asignacion_pkey PRIMARY KEY (id_asignacion);


--
-- TOC entry 5202 (class 2606 OID 38374)
-- Name: categoria categoria_nombre_key; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.categoria
    ADD CONSTRAINT categoria_nombre_key UNIQUE (nombre);


--
-- TOC entry 5204 (class 2606 OID 38376)
-- Name: categoria categoria_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.categoria
    ADD CONSTRAINT categoria_pkey PRIMARY KEY (id_categoria);


--
-- TOC entry 5206 (class 2606 OID 38378)
-- Name: comentario_ticket comentario_ticket_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket
    ADD CONSTRAINT comentario_ticket_pkey PRIMARY KEY (id_comentario);


--
-- TOC entry 5208 (class 2606 OID 38380)
-- Name: documento_ticket documento_ticket_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.documento_ticket
    ADD CONSTRAINT documento_ticket_pkey PRIMARY KEY (id_documento);


--
-- TOC entry 5210 (class 2606 OID 38382)
-- Name: historial_estado historial_estado_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT historial_estado_pkey PRIMARY KEY (id_historial);


--
-- TOC entry 5212 (class 2606 OID 38384)
-- Name: prioridad prioridad_nombre_key; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.prioridad
    ADD CONSTRAINT prioridad_nombre_key UNIQUE (nombre);


--
-- TOC entry 5214 (class 2606 OID 38386)
-- Name: prioridad prioridad_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.prioridad
    ADD CONSTRAINT prioridad_pkey PRIMARY KEY (id_prioridad);


--
-- TOC entry 5216 (class 2606 OID 38388)
-- Name: sla_ticket sla_ticket_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.sla_ticket
    ADD CONSTRAINT sla_ticket_pkey PRIMARY KEY (id_sla);


--
-- TOC entry 5218 (class 2606 OID 38390)
-- Name: ticket ticket_pkey; Type: CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT ticket_pkey PRIMARY KEY (id_ticket);


--
-- TOC entry 5224 (class 2606 OID 38392)
-- Name: rol_bd rol_bd_nombre_key; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.rol_bd
    ADD CONSTRAINT rol_bd_nombre_key UNIQUE (nombre);


--
-- TOC entry 5226 (class 2606 OID 38394)
-- Name: rol_bd rol_bd_pkey; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.rol_bd
    ADD CONSTRAINT rol_bd_pkey PRIMARY KEY (id_rol_bd);


--
-- TOC entry 5220 (class 2606 OID 38396)
-- Name: rol rol_codigo_key; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.rol
    ADD CONSTRAINT rol_codigo_key UNIQUE (codigo);


--
-- TOC entry 5222 (class 2606 OID 38398)
-- Name: rol rol_pkey; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id_rol);


--
-- TOC entry 5228 (class 2606 OID 38400)
-- Name: usuario uk863n1y3x0jalatoir4325ehal; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT uk863n1y3x0jalatoir4325ehal UNIQUE (username);


--
-- TOC entry 5234 (class 2606 OID 38402)
-- Name: usuario_bd usuario_bd_nombre_key; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_bd
    ADD CONSTRAINT usuario_bd_nombre_key UNIQUE (nombre);


--
-- TOC entry 5236 (class 2606 OID 38404)
-- Name: usuario_bd usuario_bd_pkey; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_bd
    ADD CONSTRAINT usuario_bd_pkey PRIMARY KEY (id_usuario_bd);


--
-- TOC entry 5238 (class 2606 OID 38406)
-- Name: usuario_cliente usuario_cliente_pkey; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_cliente
    ADD CONSTRAINT usuario_cliente_pkey PRIMARY KEY (id_usuario);


--
-- TOC entry 5240 (class 2606 OID 38408)
-- Name: usuario_empleado usuario_empleado_pkey; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_empleado
    ADD CONSTRAINT usuario_empleado_pkey PRIMARY KEY (id_usuario);


--
-- TOC entry 5230 (class 2606 OID 38410)
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id_usuario);


--
-- TOC entry 5232 (class 2606 OID 38412)
-- Name: usuario usuario_username_key; Type: CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT usuario_username_key UNIQUE (username);


--
-- TOC entry 5241 (class 2606 OID 38413)
-- Name: auditoria_estado_ticket fk_aud_estado_ant; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_aud_estado_ant FOREIGN KEY (id_estado_anterior) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5242 (class 2606 OID 38418)
-- Name: auditoria_estado_ticket fk_aud_estado_nuevo; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_aud_estado_nuevo FOREIGN KEY (id_estado_nuevo) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5243 (class 2606 OID 38423)
-- Name: auditoria_estado_ticket fk_auditoria_estado_ticket; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_auditoria_estado_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 5244 (class 2606 OID 38428)
-- Name: auditoria_estado_ticket fk_auditoria_estado_ticket_estado; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_auditoria_estado_ticket_estado FOREIGN KEY (id_estado_nuevo_item) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5245 (class 2606 OID 38433)
-- Name: auditoria_estado_ticket fk_auditoria_estado_ticket_evento; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_auditoria_estado_ticket_evento FOREIGN KEY (id_item_evento) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5246 (class 2606 OID 38438)
-- Name: auditoria_estado_ticket fk_auditoria_estado_ticket_ticket; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_auditoria_estado_ticket_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5247 (class 2606 OID 38443)
-- Name: auditoria_estado_ticket fk_auditoria_estado_ticket_usuario; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_estado_ticket
    ADD CONSTRAINT fk_auditoria_estado_ticket_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5248 (class 2606 OID 38448)
-- Name: auditoria_evento fk_auditoria_evento_accion; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_evento
    ADD CONSTRAINT fk_auditoria_evento_accion FOREIGN KEY (id_accion) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5252 (class 2606 OID 38453)
-- Name: auditoria_login_bd fk_auditoria_login_bd_evento; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd
    ADD CONSTRAINT fk_auditoria_login_bd_evento FOREIGN KEY (id_item_evento) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5253 (class 2606 OID 38458)
-- Name: auditoria_login_bd fk_auditoria_login_bd_usuario; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd
    ADD CONSTRAINT fk_auditoria_login_bd_usuario FOREIGN KEY (id_usuario_bd) REFERENCES usuarios.usuario_bd(id_usuario_bd) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5254 (class 2606 OID 38463)
-- Name: auditoria_login_bd fk_auditoria_login_bd_usuario_bd; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd
    ADD CONSTRAINT fk_auditoria_login_bd_usuario_bd FOREIGN KEY (id_usuario_bd) REFERENCES usuarios.usuario_bd(id_usuario_bd) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5250 (class 2606 OID 38468)
-- Name: auditoria_login fk_auditoria_login_evento; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login
    ADD CONSTRAINT fk_auditoria_login_evento FOREIGN KEY (id_item_evento) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5251 (class 2606 OID 38473)
-- Name: auditoria_login fk_auditoria_login_usuario; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login
    ADD CONSTRAINT fk_auditoria_login_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5249 (class 2606 OID 38478)
-- Name: auditoria_evento fk_auditoria_usuario; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_evento
    ADD CONSTRAINT fk_auditoria_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 5255 (class 2606 OID 38483)
-- Name: auditoria_login_bd fk_login_bd_evento; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_login_bd
    ADD CONSTRAINT fk_login_bd_evento FOREIGN KEY (id_item_evento) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5256 (class 2606 OID 38488)
-- Name: catalogo_item catalogo_item_id_catalogo_fkey; Type: FK CONSTRAINT; Schema: catalogos; Owner: postgres
--

ALTER TABLE ONLY catalogos.catalogo_item
    ADD CONSTRAINT catalogo_item_id_catalogo_fkey FOREIGN KEY (id_catalogo) REFERENCES catalogos.catalogo(id_catalogo);


--
-- TOC entry 5257 (class 2606 OID 38493)
-- Name: canton fk_canton_ciudad; Type: FK CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.canton
    ADD CONSTRAINT fk_canton_ciudad FOREIGN KEY (id_ciudad) REFERENCES clientes.ciudad(id_ciudad);


--
-- TOC entry 5258 (class 2606 OID 38498)
-- Name: ciudad fk_ciudad_pais; Type: FK CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.ciudad
    ADD CONSTRAINT fk_ciudad_pais FOREIGN KEY (id_pais) REFERENCES clientes.pais(id_pais);


--
-- TOC entry 5259 (class 2606 OID 38503)
-- Name: cliente fk_cliente_canton; Type: FK CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.cliente
    ADD CONSTRAINT fk_cliente_canton FOREIGN KEY (id_canton) REFERENCES clientes.canton(id_canton);


--
-- TOC entry 5260 (class 2606 OID 38508)
-- Name: cliente fk_cliente_empresa; Type: FK CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.cliente
    ADD CONSTRAINT fk_cliente_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5261 (class 2606 OID 38513)
-- Name: documento_cliente fk_documento_cliente_cliente; Type: FK CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.documento_cliente
    ADD CONSTRAINT fk_documento_cliente_cliente FOREIGN KEY (id_cliente) REFERENCES clientes.cliente(id_cliente);


--
-- TOC entry 5262 (class 2606 OID 38518)
-- Name: documento_cliente fk_documento_tipo; Type: FK CONSTRAINT; Schema: clientes; Owner: postgres
--

ALTER TABLE ONLY clientes.documento_cliente
    ADD CONSTRAINT fk_documento_tipo FOREIGN KEY (id_tipo_documento) REFERENCES clientes.tipo_documento(id_tipo_documento);


--
-- TOC entry 5263 (class 2606 OID 38523)
-- Name: documento_empleado fk_documento_empleado_empleado; Type: FK CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.documento_empleado
    ADD CONSTRAINT fk_documento_empleado_empleado FOREIGN KEY (id_empleado) REFERENCES empleados.empleado(id_empleado);


--
-- TOC entry 5264 (class 2606 OID 38528)
-- Name: empleado fk_empleado_area; Type: FK CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT fk_empleado_area FOREIGN KEY (id_area) REFERENCES empleados.area(id_area);


--
-- TOC entry 5265 (class 2606 OID 38533)
-- Name: empleado fk_empleado_cargo; Type: FK CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT fk_empleado_cargo FOREIGN KEY (id_cargo) REFERENCES empleados.cargo(id_cargo);


--
-- TOC entry 5266 (class 2606 OID 38538)
-- Name: empleado fk_empleado_empresa; Type: FK CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT fk_empleado_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5267 (class 2606 OID 38543)
-- Name: empleado fk_empleado_tipo_contrato; Type: FK CONSTRAINT; Schema: empleados; Owner: postgres
--

ALTER TABLE ONLY empleados.empleado
    ADD CONSTRAINT fk_empleado_tipo_contrato FOREIGN KEY (id_tipo_contrato) REFERENCES empleados.tipo_contrato(id_tipo_contrato);


--
-- TOC entry 5268 (class 2606 OID 38548)
-- Name: documento_empresa documento_empresa_id_empresa_fkey; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.documento_empresa
    ADD CONSTRAINT documento_empresa_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa);


--
-- TOC entry 5269 (class 2606 OID 38553)
-- Name: documento_empresa fk_documento_empresa_tipo_documento; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.documento_empresa
    ADD CONSTRAINT fk_documento_empresa_tipo_documento FOREIGN KEY (id_tipo_documento) REFERENCES clientes.tipo_documento(id_tipo_documento);


--
-- TOC entry 5270 (class 2606 OID 38558)
-- Name: empresa_servicio fk_es_empresa; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.empresa_servicio
    ADD CONSTRAINT fk_es_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa);


--
-- TOC entry 5271 (class 2606 OID 38563)
-- Name: empresa_servicio fk_es_servicio; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.empresa_servicio
    ADD CONSTRAINT fk_es_servicio FOREIGN KEY (id_servicio) REFERENCES empresa.servicio(id_servicio);


--
-- TOC entry 5272 (class 2606 OID 38568)
-- Name: sucursal fk_sucursal_empresa; Type: FK CONSTRAINT; Schema: empresa; Owner: postgres
--

ALTER TABLE ONLY empresa.sucursal
    ADD CONSTRAINT fk_sucursal_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa);


--
-- TOC entry 5273 (class 2606 OID 38573)
-- Name: notificacion fk_notificacion_ticket; Type: FK CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.notificacion
    ADD CONSTRAINT fk_notificacion_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 5274 (class 2606 OID 38578)
-- Name: notificacion fk_notificacion_tipo; Type: FK CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.notificacion
    ADD CONSTRAINT fk_notificacion_tipo FOREIGN KEY (id_tipo_notificacion) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5275 (class 2606 OID 38583)
-- Name: notificacion fk_notificacion_usuario; Type: FK CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.notificacion
    ADD CONSTRAINT fk_notificacion_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 5276 (class 2606 OID 38588)
-- Name: notificacion fk_notificacion_usuario_origen; Type: FK CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.notificacion
    ADD CONSTRAINT fk_notificacion_usuario_origen FOREIGN KEY (id_usuario_origen) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 5277 (class 2606 OID 38593)
-- Name: notificacion notificacion_id_canal_fkey; Type: FK CONSTRAINT; Schema: notificaciones; Owner: postgres
--

ALTER TABLE ONLY notificaciones.notificacion
    ADD CONSTRAINT notificacion_id_canal_fkey FOREIGN KEY (id_canal) REFERENCES notificaciones.canal_notificacion(id_canal);


--
-- TOC entry 5278 (class 2606 OID 38598)
-- Name: asignacion fk_asignacion_ticket; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.asignacion
    ADD CONSTRAINT fk_asignacion_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 5279 (class 2606 OID 38603)
-- Name: asignacion fk_asignacion_usuario; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.asignacion
    ADD CONSTRAINT fk_asignacion_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5280 (class 2606 OID 38608)
-- Name: categoria fk_categoria_item; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.categoria
    ADD CONSTRAINT fk_categoria_item FOREIGN KEY (id_item) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5281 (class 2606 OID 38613)
-- Name: comentario_ticket fk_comentario_empresa; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket
    ADD CONSTRAINT fk_comentario_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5282 (class 2606 OID 38618)
-- Name: comentario_ticket fk_comentario_ticket; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket
    ADD CONSTRAINT fk_comentario_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 5283 (class 2606 OID 38623)
-- Name: comentario_ticket fk_comentario_usuario; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.comentario_ticket
    ADD CONSTRAINT fk_comentario_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario);


--
-- TOC entry 5284 (class 2606 OID 38628)
-- Name: documento_ticket fk_documento_ticket; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.documento_ticket
    ADD CONSTRAINT fk_documento_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 5285 (class 2606 OID 38633)
-- Name: documento_ticket fk_documento_ticket_usuario; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.documento_ticket
    ADD CONSTRAINT fk_documento_ticket_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 5286 (class 2606 OID 38638)
-- Name: historial_estado fk_hist_estado_anterior; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_hist_estado_anterior FOREIGN KEY (id_estado_anterior) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5287 (class 2606 OID 38643)
-- Name: historial_estado fk_hist_estado_nuevo; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_hist_estado_nuevo FOREIGN KEY (id_estado_nuevo) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5288 (class 2606 OID 38648)
-- Name: historial_estado fk_historial_estado_anterior; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_historial_estado_anterior FOREIGN KEY (id_estado_anterior) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5289 (class 2606 OID 38653)
-- Name: historial_estado fk_historial_estado_catalogo; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_historial_estado_catalogo FOREIGN KEY (id_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5290 (class 2606 OID 38658)
-- Name: historial_estado fk_historial_estado_nuevo; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_historial_estado_nuevo FOREIGN KEY (id_estado_nuevo) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5291 (class 2606 OID 38663)
-- Name: historial_estado fk_historial_ticket; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_historial_ticket FOREIGN KEY (id_ticket) REFERENCES soporte.ticket(id_ticket);


--
-- TOC entry 5292 (class 2606 OID 38668)
-- Name: historial_estado fk_historial_usuario; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.historial_estado
    ADD CONSTRAINT fk_historial_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5293 (class 2606 OID 38673)
-- Name: prioridad fk_prioridad_item; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.prioridad
    ADD CONSTRAINT fk_prioridad_item FOREIGN KEY (id_item) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5294 (class 2606 OID 38678)
-- Name: sla_ticket fk_sla_empresa; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.sla_ticket
    ADD CONSTRAINT fk_sla_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5295 (class 2606 OID 38683)
-- Name: sla_ticket fk_sla_prioridad; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.sla_ticket
    ADD CONSTRAINT fk_sla_prioridad FOREIGN KEY (aplica_prioridad) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5296 (class 2606 OID 38688)
-- Name: ticket fk_ticket_categoria; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_categoria FOREIGN KEY (id_categoria) REFERENCES soporte.categoria(id_categoria);


--
-- TOC entry 5297 (class 2606 OID 38693)
-- Name: ticket fk_ticket_categoria_item; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_categoria_item FOREIGN KEY (id_categoria_item) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5298 (class 2606 OID 38698)
-- Name: ticket fk_ticket_cliente; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_cliente FOREIGN KEY (id_cliente) REFERENCES clientes.cliente(id_cliente);


--
-- TOC entry 5299 (class 2606 OID 38703)
-- Name: ticket fk_ticket_empresa; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5300 (class 2606 OID 38708)
-- Name: ticket fk_ticket_empresa_servicio; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_empresa_servicio FOREIGN KEY (id_empresa, id_servicio) REFERENCES empresa.empresa_servicio(id_empresa, id_servicio) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5301 (class 2606 OID 38713)
-- Name: ticket fk_ticket_estado_catalogo; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_estado_catalogo FOREIGN KEY (id_estado) REFERENCES catalogos.catalogo_item(id_item);


--
-- TOC entry 5302 (class 2606 OID 38718)
-- Name: ticket fk_ticket_estado_item; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_estado_item FOREIGN KEY (id_estado_item) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5303 (class 2606 OID 38723)
-- Name: ticket fk_ticket_prioridad; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_prioridad FOREIGN KEY (id_prioridad) REFERENCES soporte.prioridad(id_prioridad);


--
-- TOC entry 5304 (class 2606 OID 38728)
-- Name: ticket fk_ticket_prioridad_item; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_prioridad_item FOREIGN KEY (id_prioridad_item) REFERENCES catalogos.catalogo_item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5305 (class 2606 OID 38733)
-- Name: ticket fk_ticket_servicio; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_servicio FOREIGN KEY (id_servicio) REFERENCES empresa.servicio(id_servicio);


--
-- TOC entry 5306 (class 2606 OID 38738)
-- Name: ticket fk_ticket_sla; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_sla FOREIGN KEY (id_sla) REFERENCES soporte.sla_ticket(id_sla);


--
-- TOC entry 5307 (class 2606 OID 38743)
-- Name: ticket fk_ticket_sucursal; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_sucursal FOREIGN KEY (id_sucursal) REFERENCES empresa.sucursal(id_sucursal);


--
-- TOC entry 5308 (class 2606 OID 38748)
-- Name: ticket fk_ticket_usuario_asignado; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_usuario_asignado FOREIGN KEY (id_usuario_asignado) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 5309 (class 2606 OID 38753)
-- Name: ticket fk_ticket_usuario_creador; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fk_ticket_usuario_creador FOREIGN KEY (id_usuario_creador) REFERENCES usuarios.usuario(id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5310 (class 2606 OID 38758)
-- Name: ticket fkhnex00iymgdjj4b8t3kvx0qk; Type: FK CONSTRAINT; Schema: soporte; Owner: postgres
--

ALTER TABLE ONLY soporte.ticket
    ADD CONSTRAINT fkhnex00iymgdjj4b8t3kvx0qk FOREIGN KEY (id_empleado) REFERENCES empleados.empleado(id_empleado);


--
-- TOC entry 5313 (class 2606 OID 38763)
-- Name: usuario_bd fk_usuario_bd_rol; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_bd
    ADD CONSTRAINT fk_usuario_bd_rol FOREIGN KEY (id_rol_bd) REFERENCES usuarios.rol_bd(id_rol_bd);


--
-- TOC entry 5314 (class 2606 OID 38768)
-- Name: usuario_bd fk_usuario_bd_rol_bd; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_bd
    ADD CONSTRAINT fk_usuario_bd_rol_bd FOREIGN KEY (id_rol_bd) REFERENCES usuarios.rol_bd(id_rol_bd) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5315 (class 2606 OID 38773)
-- Name: usuario_bd fk_usuario_bd_usuario; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_bd
    ADD CONSTRAINT fk_usuario_bd_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON DELETE CASCADE;


--
-- TOC entry 5316 (class 2606 OID 38778)
-- Name: usuario_cliente fk_usuario_cliente_cliente; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_cliente
    ADD CONSTRAINT fk_usuario_cliente_cliente FOREIGN KEY (id_cliente) REFERENCES clientes.cliente(id_cliente);


--
-- TOC entry 5317 (class 2606 OID 38783)
-- Name: usuario_cliente fk_usuario_cliente_usuario; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_cliente
    ADD CONSTRAINT fk_usuario_cliente_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON DELETE CASCADE;


--
-- TOC entry 5318 (class 2606 OID 38788)
-- Name: usuario_empleado fk_usuario_empleado_empleado; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_empleado
    ADD CONSTRAINT fk_usuario_empleado_empleado FOREIGN KEY (id_empleado) REFERENCES empleados.empleado(id_empleado);


--
-- TOC entry 5319 (class 2606 OID 38793)
-- Name: usuario_empleado fk_usuario_empleado_usuario; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario_empleado
    ADD CONSTRAINT fk_usuario_empleado_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario) ON DELETE CASCADE;


--
-- TOC entry 5311 (class 2606 OID 38798)
-- Name: usuario fk_usuario_empresa; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT fk_usuario_empresa FOREIGN KEY (id_empresa) REFERENCES empresa.empresa(id_empresa) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5312 (class 2606 OID 38803)
-- Name: usuario fk_usuario_rol; Type: FK CONSTRAINT; Schema: usuarios; Owner: postgres
--

ALTER TABLE ONLY usuarios.usuario
    ADD CONSTRAINT fk_usuario_rol FOREIGN KEY (id_rol) REFERENCES usuarios.rol(id_rol);


-- Completed on 2026-02-02 13:10:41

--
-- PostgreSQL database dump complete
--

\unrestrict 06W7unh3bonhi2YTnlA4DXpFV08pTB19eggsB2yGFzSHokng3cFe8VQtZaLjpmv

