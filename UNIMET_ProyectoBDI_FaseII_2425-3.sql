PGDMP  %    )                }            BD1GestionHospitales    17.5    17.5 �    	           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                           false            
           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                           false                       0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                           false                       1262    29950    BD1GestionHospitales    DATABASE     �   CREATE DATABASE "BD1GestionHospitales" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Spanish_Venezuela.1252';
 &   DROP DATABASE "BD1GestionHospitales";
                     postgres    false            �           1247    29967    dias    DOMAIN     �   CREATE DOMAIN public.dias AS character varying
	CONSTRAINT dias_check CHECK ((lower((VALUE)::text) = ANY (ARRAY['l'::text, 'm'::text, 'mi'::text, 'j'::text, 'v'::text, 's'::text, 'd'::text])));
    DROP DOMAIN public.dias;
       public               postgres    false            }           1247    29955    estado    DOMAIN     �   CREATE DOMAIN public.estado AS character varying
	CONSTRAINT estado_check CHECK ((lower((VALUE)::text) = ANY (ARRAY['pendiente'::text, 'pagada'::text, 'cancelada'::text, 'reembolsada'::text])));
    DROP DOMAIN public.estado;
       public               postgres    false            �           1247    29970    genero    DOMAIN     �   CREATE DOMAIN public.genero AS character varying
	CONSTRAINT genero_check CHECK ((upper((VALUE)::text) = ANY (ARRAY['M'::text, 'F'::text, 'N/A'::text])));
    DROP DOMAIN public.genero;
       public               postgres    false            �           1247    29958    metodo_de_pago    DOMAIN     �   CREATE DOMAIN public.metodo_de_pago AS character varying
	CONSTRAINT metodo_de_pago_check CHECK ((lower((VALUE)::text) = ANY (ARRAY['transferencia'::text, 'efectivo'::text, 'punto de venta'::text, 'mixto'::text])));
 #   DROP DOMAIN public.metodo_de_pago;
       public               postgres    false            �           1247    29973    presentacion_dominio    DOMAIN       CREATE DOMAIN public.presentacion_dominio AS character varying
	CONSTRAINT presentacion_dominio_check CHECK ((lower((VALUE)::text) = ANY (ARRAY['tabletas'::text, 'capsulas'::text, 'jarabe'::text, 'inyectable'::text, 'pomada'::text, 'polvo'::text, 'suspension'::text])));
 )   DROP DOMAIN public.presentacion_dominio;
       public               postgres    false            y           1247    29952    telefono_dominio    DOMAIN     �   CREATE DOMAIN public.telefono_dominio AS character varying(15)
	CONSTRAINT telefono_dominio_check CHECK (((VALUE)::text ~ '^\+?[0-9]{7,15}$'::text));
 %   DROP DOMAIN public.telefono_dominio;
       public               postgres    false            �           1247    29961    tipo_de_departamento    DOMAIN     �   CREATE DOMAIN public.tipo_de_departamento AS character varying
	CONSTRAINT tipo_de_departamento_check CHECK ((lower((VALUE)::text) = ANY (ARRAY['medico'::text, 'administrativo'::text, 'operativo'::text])));
 )   DROP DOMAIN public.tipo_de_departamento;
       public               postgres    false            �           1247    29964    tipo_de_habitacion    DOMAIN     �   CREATE DOMAIN public.tipo_de_habitacion AS character varying
	CONSTRAINT tipo_de_habitacion_check CHECK ((lower((VALUE)::text) = ANY (ARRAY['individual'::text, 'compartida'::text])));
 '   DROP DOMAIN public.tipo_de_habitacion;
       public               postgres    false            �           1247    29976    tipo_suministro    DOMAIN       CREATE DOMAIN public.tipo_suministro AS character varying
	CONSTRAINT tipo_suministro_check CHECK ((lower((VALUE)::text) = ANY (ARRAY['desinfectante'::text, 'detergente'::text, 'jabon'::text, 'alcohol'::text, 'guantes'::text, 'toallas'::text, 'mascarillas'::text])));
 $   DROP DOMAIN public.tipo_suministro;
       public               postgres    false            �            1255    30451    actualizar_annios_servicio()    FUNCTION     r  CREATE FUNCTION public.actualizar_annios_servicio() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    fecha_mas_antigua DATE;
BEGIN
    -- Obtener la fecha de contratación más antigua del trabajador
    SELECT MIN(fecha_contratacion)
    INTO fecha_mas_antigua
    FROM Contratado
    WHERE ci_personal = NEW.ci_personal;

    -- Actualizar los años de servicio en la tabla Personal
    IF fecha_mas_antigua IS NOT NULL THEN
        UPDATE Personal
        SET annios_serv = DATE_PART('year', AGE(CURRENT_DATE, fecha_mas_antigua))
        WHERE CI_personal = NEW.ci_personal;
    END IF;

    RETURN NEW;
END;
$$;
 3   DROP FUNCTION public.actualizar_annios_servicio();
       public               postgres    false                        1255    30453    actualizar_inventario()    FUNCTION     -  CREATE FUNCTION public.actualizar_inventario() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM Inventario
        WHERE id_insumo = NEW.id_insumo AND id_hospital = NEW.id_hospital
    ) THEN
        UPDATE Inventario
        SET cantidad = cantidad + NEW.cantidad
        WHERE id_insumo = NEW.id_insumo AND id_hospital = NEW.id_hospital;
    ELSE
        INSERT INTO Inventario(id_insumo, id_hospital, cantidad)
        VALUES (NEW.id_insumo, NEW.id_hospital, NEW.cantidad);
    END IF;

    RETURN NEW;
END;
$$;
 .   DROP FUNCTION public.actualizar_inventario();
       public               postgres    false            �            1255    30445    actualizar_num_camas()    FUNCTION     3  CREATE FUNCTION public.actualizar_num_camas() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_id_departamento INT;
  v_id_hospital INT;
BEGIN
  -- Determinar el id_departamento afectado
  IF TG_OP = 'DELETE' THEN
    v_id_departamento := OLD.id_departamento;
  ELSE
    v_id_departamento := NEW.id_departamento;
  END IF;

  -- Buscar el hospital asociado a ese departamento
  SELECT id_hospital INTO v_id_hospital
  FROM departamento
  WHERE id_departamento = v_id_departamento;

  -- Actualizar el número de camas en ese hospital
  UPDATE hospital
  SET num_camas = (
    SELECT COALESCE(SUM(ha.num_camas), 0)
    FROM departamento d
    JOIN habitacion ha ON d.id_departamento = ha.id_departamento
    WHERE d.id_hospital = v_id_hospital
  )
  WHERE id_hospital = v_id_hospital;

  RETURN NULL;
END;
$$;
 -   DROP FUNCTION public.actualizar_num_camas();
       public               postgres    false                       1255    30457    calcular_costo_encargo()    FUNCTION     l  CREATE FUNCTION public.calcular_costo_encargo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    precio_unitario NUMERIC;
BEGIN
    -- Obtener el precio unitario del proveedor para el insumo
    SELECT precio
    INTO precio_unitario
    FROM Provee
    WHERE id_insumo = NEW.id_insumo AND nombre_ca = NEW.nombre_ca;

    -- Validación
    IF precio_unitario IS NULL THEN
        RAISE EXCEPTION 'No se encontró el precio del insumo % con proveedor %', NEW.id_insumo, NEW.nombre_ca;
    END IF;

    -- Calcular el costo total
    NEW.costo_total := precio_unitario * NEW.cantidad;

    RETURN NEW;
END;
$$;
 /   DROP FUNCTION public.calcular_costo_encargo();
       public               postgres    false            �            1255    30447    calcular_edad_paciente()    FUNCTION       CREATE FUNCTION public.calcular_edad_paciente() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    f_nac DATE;
BEGIN
    -- Obtener la fecha de nacimiento desde Persona
    SELECT fecha_nacimiento INTO f_nac
    FROM Persona
    WHERE CI = NEW.CI_paciente;

    -- Calcular la edad
    IF f_nac IS NOT NULL THEN
        NEW.edad := DATE_PART('year', AGE(CURRENT_DATE, f_nac));
    ELSE
        RAISE EXCEPTION 'No se encontró la fecha de nacimiento para el paciente %', NEW.CI_paciente;
    END IF;

    RETURN NEW;
END;
$$;
 /   DROP FUNCTION public.calcular_edad_paciente();
       public               postgres    false            �            1255    30449    calcular_estado_factura()    FUNCTION     �  CREATE FUNCTION public.calcular_estado_factura() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.monto_pagado = 0 THEN
        NEW.estado_factura := 'pendiente';
    ELSIF NEW.monto_pagado < NEW.monto_factura THEN
        NEW.estado_factura := 'pendiente';
    ELSIF NEW.monto_pagado = NEW.monto_factura THEN
        NEW.estado_factura := 'pagada';
    ELSIF NEW.monto_pagado > NEW.monto_factura THEN
        NEW.estado_factura := 'reembolsada';
    END IF;

    RETURN NEW;
END;
$$;
 0   DROP FUNCTION public.calcular_estado_factura();
       public               postgres    false                       1255    30461    calcular_total_consulta()    FUNCTION     A  CREATE FUNCTION public.calcular_total_consulta() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    precio_proc NUMERIC;
BEGIN
    -- Obtener el precio del procedimiento
    SELECT precio INTO precio_proc
    FROM Procedimiento
    WHERE id_procedimiento = NEW.id_procedimiento;

    -- Validación
    IF precio_proc IS NULL THEN
        RAISE EXCEPTION 'No se encontró precio del procedimiento %', NEW.id_procedimiento;
    END IF;

    -- Calcular total: procedimiento + precio consulta
    NEW.total := precio_proc + NEW.precio_consulta;

    RETURN NEW;
END;
$$;
 0   DROP FUNCTION public.calcular_total_consulta();
       public               postgres    false                       1255    30459    calcular_total_se_realiza()    FUNCTION       CREATE FUNCTION public.calcular_total_se_realiza() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    precio_proc NUMERIC;
BEGIN
    -- Buscar el precio del procedimiento
    SELECT precio INTO precio_proc
    FROM Procedimiento
    WHERE id_procedimiento = NEW.id_procedimiento;

    -- Validar existencia
    IF precio_proc IS NULL THEN
        RAISE EXCEPTION 'No se encontró precio para el procedimiento %', NEW.id_procedimiento;
    END IF;

    -- Asignar el total
    NEW.total := precio_proc;

    RETURN NEW;
END;
$$;
 2   DROP FUNCTION public.calcular_total_se_realiza();
       public               postgres    false                       1255    30455    sumar_stock_insumo()    FUNCTION     �   CREATE FUNCTION public.sumar_stock_insumo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE Insumo_Medico
    SET stock = stock + NEW.cantidad
    WHERE id_insumo = NEW.id_insumo;

    RETURN NEW;
END;
$$;
 +   DROP FUNCTION public.sumar_stock_insumo();
       public               postgres    false            �            1259    29978    compania_aseguradora    TABLE     �   CREATE TABLE public.compania_aseguradora (
    nombre_ca text NOT NULL,
    calle_ca text,
    codpos_ca integer,
    ciudad_ca text,
    telefono_ca public.telefono_dominio
);
 (   DROP TABLE public.compania_aseguradora;
       public         heap r       postgres    false    889            �            1259    30200    consulta    TABLE     �  CREATE TABLE public.consulta (
    ci_medico character varying(9) NOT NULL,
    ci_paciente character varying(9) NOT NULL,
    id_procedimiento integer NOT NULL,
    hora time without time zone NOT NULL,
    total double precision,
    observaciones text,
    fecha date NOT NULL,
    precio_consulta double precision,
    CONSTRAINT precio_consulta_ck CHECK ((precio_consulta >= (0)::double precision)),
    CONSTRAINT total_ck CHECK ((total >= (0)::double precision))
);
    DROP TABLE public.consulta;
       public         heap r       postgres    false            �            1259    30368 
   contratado    TABLE     0  CREATE TABLE public.contratado (
    ci_personal character varying(9) NOT NULL,
    id_departamento integer NOT NULL,
    id_hospital integer NOT NULL,
    fecha_retiro date,
    salario integer,
    cargo text,
    fecha_contratacion date NOT NULL,
    CONSTRAINT salario_check CHECK ((salario > 0))
);
    DROP TABLE public.contratado;
       public         heap r       postgres    false            �            1259    30343    cuentan_con    TABLE     �   CREATE TABLE public.cuentan_con (
    id_hospital integer NOT NULL,
    ci_medico character varying(9) NOT NULL,
    id_departamento integer NOT NULL,
    id_insumo integer NOT NULL
);
    DROP TABLE public.cuentan_con;
       public         heap r       postgres    false            �            1259    30008    departamento    TABLE     �   CREATE TABLE public.departamento (
    id_departamento integer NOT NULL,
    piso text,
    nombre text,
    tipo public.tipo_de_departamento,
    id_hospital integer NOT NULL
);
     DROP TABLE public.departamento;
       public         heap r       postgres    false    901            �            1259    30180    emitida    TABLE     �   CREATE TABLE public.emitida (
    ci_paciente character varying(9) NOT NULL,
    ci_trabajador character varying(9) NOT NULL,
    num_factura integer NOT NULL
);
    DROP TABLE public.emitida;
       public         heap r       postgres    false            �            1259    30257    encargo    TABLE     �  CREATE TABLE public.encargo (
    id_insumo integer NOT NULL,
    id_hospital integer NOT NULL,
    nombre_ca text NOT NULL,
    ci_resp character varying(9) NOT NULL,
    fecha date NOT NULL,
    cantidad integer,
    num_lote text,
    costo_total double precision,
    CONSTRAINT cantidad_check CHECK ((cantidad >= 0)),
    CONSTRAINT total_ck2 CHECK ((costo_total >= (0)::double precision))
);
    DROP TABLE public.encargo;
       public         heap r       postgres    false            �            1259    30165    factura    TABLE     �  CREATE TABLE public.factura (
    num_factura integer NOT NULL,
    monto_pagado double precision,
    estado_factura public.estado,
    monto_factura double precision,
    metodo_factura public.metodo_de_pago,
    fecha_factura date,
    cobertura double precision,
    num_poliza character varying(15),
    CONSTRAINT cobertura_ck CHECK ((cobertura >= (0)::double precision)),
    CONSTRAINT monto_factura_ck CHECK ((monto_factura >= (0)::double precision))
);
    DROP TABLE public.factura;
       public         heap r       postgres    false    897    893            �            1259    30164    factura_num_factura_seq    SEQUENCE     �   CREATE SEQUENCE public.factura_num_factura_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.factura_num_factura_seq;
       public               postgres    false    239                       0    0    factura_num_factura_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.factura_num_factura_seq OWNED BY public.factura.num_factura;
          public               postgres    false    238            �            1259    30020 
   habitacion    TABLE       CREATE TABLE public.habitacion (
    num_habitacion integer NOT NULL,
    ocupado boolean,
    num_camas integer,
    tarifa numeric(12,2),
    tipo public.tipo_de_habitacion,
    id_departamento integer NOT NULL,
    CONSTRAINT camas_check CHECK ((num_camas >= 0))
);
    DROP TABLE public.habitacion;
       public         heap r       postgres    false    905            �            1259    30034    horario_de_atencion    TABLE     �   CREATE TABLE public.horario_de_atencion (
    id_horario integer NOT NULL,
    dia public.dias,
    hora_finalizacion time without time zone,
    hora_comienzo time without time zone
);
 '   DROP TABLE public.horario_de_atencion;
       public         heap r       postgres    false    909            �            1259    30033 "   horario_de_atencion_id_horario_seq    SEQUENCE     �   CREATE SEQUENCE public.horario_de_atencion_id_horario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 9   DROP SEQUENCE public.horario_de_atencion_id_horario_seq;
       public               postgres    false    224                       0    0 "   horario_de_atencion_id_horario_seq    SEQUENCE OWNED BY     i   ALTER SEQUENCE public.horario_de_atencion_id_horario_seq OWNED BY public.horario_de_atencion.id_horario;
          public               postgres    false    223            �            1259    29999    hospital    TABLE     �   CREATE TABLE public.hospital (
    id_hospital integer NOT NULL,
    nombre text,
    num_camas integer,
    calle_hosp text,
    codpos_hosp integer,
    ciudad_hosp text,
    CONSTRAINT camas_check1 CHECK ((num_camas >= 0))
);
    DROP TABLE public.hospital;
       public         heap r       postgres    false            �            1259    29998    hospital_id_hospital_seq    SEQUENCE     �   CREATE SEQUENCE public.hospital_id_hospital_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.hospital_id_hospital_seq;
       public               postgres    false    220                       0    0    hospital_id_hospital_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.hospital_id_hospital_seq OWNED BY public.hospital.id_hospital;
          public               postgres    false    219            �            1259    30112    instrumental_medico    TABLE     l   CREATE TABLE public.instrumental_medico (
    id_instrumental_medico integer NOT NULL,
    material text
);
 '   DROP TABLE public.instrumental_medico;
       public         heap r       postgres    false            �            1259    30079    insumo_medico    TABLE     �   CREATE TABLE public.insumo_medico (
    id_insumo integer NOT NULL,
    nombre text,
    stock integer,
    descripcion text,
    esequipo_medico boolean,
    essuministro_desechable boolean,
    CONSTRAINT stock_check CHECK ((stock >= 0))
);
 !   DROP TABLE public.insumo_medico;
       public         heap r       postgres    false            �            1259    30078    insumo_medico_id_insumo_seq    SEQUENCE     �   CREATE SEQUENCE public.insumo_medico_id_insumo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE public.insumo_medico_id_insumo_seq;
       public               postgres    false    229                       0    0    insumo_medico_id_insumo_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public.insumo_medico_id_insumo_seq OWNED BY public.insumo_medico.id_insumo;
          public               postgres    false    228            �            1259    30286 
   inventario    TABLE     �   CREATE TABLE public.inventario (
    id_insumo integer NOT NULL,
    id_hospital integer NOT NULL,
    cantidad integer,
    CONSTRAINT cantidad_check2 CHECK ((cantidad >= 0))
);
    DROP TABLE public.inventario;
       public         heap r       postgres    false            �            1259    30088    medicamento    TABLE     �   CREATE TABLE public.medicamento (
    id_medicamento integer NOT NULL,
    fecha_vencimiento date,
    presentacion public.presentacion_dominio
);
    DROP TABLE public.medicamento;
       public         heap r       postgres    false    917            �            1259    30224 	   necesitan    TABLE     i   CREATE TABLE public.necesitan (
    id_insumo integer NOT NULL,
    id_procedimiento integer NOT NULL
);
    DROP TABLE public.necesitan;
       public         heap r       postgres    false            �            1259    30141 	   operacion    TABLE     �   CREATE TABLE public.operacion (
    id_operacion integer NOT NULL,
    duracion_estimada integer,
    CONSTRAINT duracion_check CHECK ((duracion_estimada >= 0))
);
    DROP TABLE public.operacion;
       public         heap r       postgres    false            �            1259    30049    paciente    TABLE     V  CREATE TABLE public.paciente (
    ci_paciente character varying(9) NOT NULL,
    telefono public.telefono_dominio,
    contacto_emerg public.telefono_dominio,
    condicion text,
    medicamento_regedad text,
    requiere_resp boolean,
    edad integer,
    num_poliza character varying(15),
    CONSTRAINT edad_check CHECK ((edad >= 0))
);
    DROP TABLE public.paciente;
       public         heap r       postgres    false    889    889            �            1259    30042    persona    TABLE     �   CREATE TABLE public.persona (
    ci text NOT NULL,
    calle_pe text,
    codpos_pe text,
    ciudad_pe text,
    fecha_nacimiento date NOT NULL,
    apellido text NOT NULL,
    nombre text NOT NULL,
    sexo public.genero
);
    DROP TABLE public.persona;
       public         heap r       postgres    false    913            �            1259    30067    personal    TABLE     �   CREATE TABLE public.personal (
    ci_personal character varying(9) NOT NULL,
    annios_serv integer,
    esmedico boolean,
    esadmin boolean,
    CONSTRAINT anios_check CHECK ((annios_serv >= 0))
);
    DROP TABLE public.personal;
       public         heap r       postgres    false            �            1259    30132    procedimiento    TABLE     �   CREATE TABLE public.procedimiento (
    id_procedimiento integer NOT NULL,
    nombre text,
    instrucciones text,
    precio integer,
    CONSTRAINT precio_check CHECK ((precio >= 0))
);
 !   DROP TABLE public.procedimiento;
       public         heap r       postgres    false            �            1259    30131 "   procedimiento_id_procedimiento_seq    SEQUENCE     �   CREATE SEQUENCE public.procedimiento_id_procedimiento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 9   DROP SEQUENCE public.procedimiento_id_procedimiento_seq;
       public               postgres    false    235                       0    0 "   procedimiento_id_procedimiento_seq    SEQUENCE OWNED BY     i   ALTER SEQUENCE public.procedimiento_id_procedimiento_seq OWNED BY public.procedimiento.id_procedimiento;
          public               postgres    false    234            �            1259    30239    provee    TABLE     �   CREATE TABLE public.provee (
    id_insumo integer NOT NULL,
    nombre_ca text NOT NULL,
    precio double precision,
    CONSTRAINT precio_check2 CHECK ((precio >= (0)::double precision))
);
    DROP TABLE public.provee;
       public         heap r       postgres    false            �            1259    30124 	   proveedor    TABLE     �   CREATE TABLE public.proveedor (
    nombre_ca text NOT NULL,
    contacto public.telefono_dominio,
    calle text,
    codpos text,
    ciudad text
);
    DROP TABLE public.proveedor;
       public         heap r       postgres    false    889            �            1259    30302 
   se_realiza    TABLE     �  CREATE TABLE public.se_realiza (
    id_departamento integer NOT NULL,
    id_hospital integer NOT NULL,
    num_habitacion integer NOT NULL,
    id_procedimiento integer NOT NULL,
    hora_operacion integer NOT NULL,
    ci_medico character varying(9) NOT NULL,
    ci_paciente character varying(9),
    fecha date NOT NULL,
    total double precision,
    CONSTRAINT total_check3 CHECK ((total >= (0)::double precision))
);
    DROP TABLE public.se_realiza;
       public         heap r       postgres    false            �            1259    29985    seguro_medico    TABLE     �   CREATE TABLE public.seguro_medico (
    num_poliza text NOT NULL,
    sum_asg_sm integer,
    condiciones_sm text,
    nombre_ca text,
    CONSTRAINT sum_check CHECK ((sum_asg_sm >= 0))
);
 !   DROP TABLE public.seguro_medico;
       public         heap r       postgres    false            �            1259    30100    suministro_limpieza    TABLE     z   CREATE TABLE public.suministro_limpieza (
    id_suministro_limpieza integer NOT NULL,
    tipo public.tipo_suministro
);
 '   DROP TABLE public.suministro_limpieza;
       public         heap r       postgres    false    921            �            1259    30416    telefono_departamento    TABLE     �   CREATE TABLE public.telefono_departamento (
    id_hospital integer NOT NULL,
    id_departamento integer NOT NULL,
    telefono_departamento public.telefono_dominio NOT NULL
);
 )   DROP TABLE public.telefono_departamento;
       public         heap r       postgres    false    889            �            1259    30433    telefono_personal    TABLE     �   CREATE TABLE public.telefono_personal (
    ci_personal character varying NOT NULL,
    telefono public.telefono_dominio NOT NULL
);
 %   DROP TABLE public.telefono_personal;
       public         heap r       postgres    false    889            �            1259    30391 
   trabaja_en    TABLE     �   CREATE TABLE public.trabaja_en (
    id_horario integer NOT NULL,
    ci_personal character varying(9) NOT NULL,
    id_departamento integer NOT NULL,
    id_hospital integer NOT NULL
);
    DROP TABLE public.trabaja_en;
       public         heap r       postgres    false            �            1259    30152    tratamiento    TABLE     Z   CREATE TABLE public.tratamiento (
    id_procedimiento integer NOT NULL,
    tipo text
);
    DROP TABLE public.tratamiento;
       public         heap r       postgres    false            �           2604    30168    factura num_factura    DEFAULT     z   ALTER TABLE ONLY public.factura ALTER COLUMN num_factura SET DEFAULT nextval('public.factura_num_factura_seq'::regclass);
 B   ALTER TABLE public.factura ALTER COLUMN num_factura DROP DEFAULT;
       public               postgres    false    238    239    239            �           2604    30037    horario_de_atencion id_horario    DEFAULT     �   ALTER TABLE ONLY public.horario_de_atencion ALTER COLUMN id_horario SET DEFAULT nextval('public.horario_de_atencion_id_horario_seq'::regclass);
 M   ALTER TABLE public.horario_de_atencion ALTER COLUMN id_horario DROP DEFAULT;
       public               postgres    false    224    223    224            �           2604    30002    hospital id_hospital    DEFAULT     |   ALTER TABLE ONLY public.hospital ALTER COLUMN id_hospital SET DEFAULT nextval('public.hospital_id_hospital_seq'::regclass);
 C   ALTER TABLE public.hospital ALTER COLUMN id_hospital DROP DEFAULT;
       public               postgres    false    219    220    220            �           2604    30082    insumo_medico id_insumo    DEFAULT     �   ALTER TABLE ONLY public.insumo_medico ALTER COLUMN id_insumo SET DEFAULT nextval('public.insumo_medico_id_insumo_seq'::regclass);
 F   ALTER TABLE public.insumo_medico ALTER COLUMN id_insumo DROP DEFAULT;
       public               postgres    false    228    229    229            �           2604    30135    procedimiento id_procedimiento    DEFAULT     �   ALTER TABLE ONLY public.procedimiento ALTER COLUMN id_procedimiento SET DEFAULT nextval('public.procedimiento_id_procedimiento_seq'::regclass);
 M   ALTER TABLE public.procedimiento ALTER COLUMN id_procedimiento DROP DEFAULT;
       public               postgres    false    235    234    235            �          0    29978    compania_aseguradora 
   TABLE DATA           f   COPY public.compania_aseguradora (nombre_ca, calle_ca, codpos_ca, ciudad_ca, telefono_ca) FROM stdin;
    public               postgres    false    217   �      �          0    30200    consulta 
   TABLE DATA           �   COPY public.consulta (ci_medico, ci_paciente, id_procedimiento, hora, total, observaciones, fecha, precio_consulta) FROM stdin;
    public               postgres    false    241   �                0    30368 
   contratado 
   TABLE DATA           �   COPY public.contratado (ci_personal, id_departamento, id_hospital, fecha_retiro, salario, cargo, fecha_contratacion) FROM stdin;
    public               postgres    false    248   @                0    30343    cuentan_con 
   TABLE DATA           Y   COPY public.cuentan_con (id_hospital, ci_medico, id_departamento, id_insumo) FROM stdin;
    public               postgres    false    247   �!      �          0    30008    departamento 
   TABLE DATA           X   COPY public.departamento (id_departamento, piso, nombre, tipo, id_hospital) FROM stdin;
    public               postgres    false    221    "      �          0    30180    emitida 
   TABLE DATA           J   COPY public.emitida (ci_paciente, ci_trabajador, num_factura) FROM stdin;
    public               postgres    false    240   �"      �          0    30257    encargo 
   TABLE DATA           u   COPY public.encargo (id_insumo, id_hospital, nombre_ca, ci_resp, fecha, cantidad, num_lote, costo_total) FROM stdin;
    public               postgres    false    244   �#      �          0    30165    factura 
   TABLE DATA           �   COPY public.factura (num_factura, monto_pagado, estado_factura, monto_factura, metodo_factura, fecha_factura, cobertura, num_poliza) FROM stdin;
    public               postgres    false    239   �(      �          0    30020 
   habitacion 
   TABLE DATA           g   COPY public.habitacion (num_habitacion, ocupado, num_camas, tarifa, tipo, id_departamento) FROM stdin;
    public               postgres    false    222   b*      �          0    30034    horario_de_atencion 
   TABLE DATA           `   COPY public.horario_de_atencion (id_horario, dia, hora_finalizacion, hora_comienzo) FROM stdin;
    public               postgres    false    224   �,      �          0    29999    hospital 
   TABLE DATA           h   COPY public.hospital (id_hospital, nombre, num_camas, calle_hosp, codpos_hosp, ciudad_hosp) FROM stdin;
    public               postgres    false    220   S-      �          0    30112    instrumental_medico 
   TABLE DATA           O   COPY public.instrumental_medico (id_instrumental_medico, material) FROM stdin;
    public               postgres    false    232   .      �          0    30079    insumo_medico 
   TABLE DATA           x   COPY public.insumo_medico (id_insumo, nombre, stock, descripcion, esequipo_medico, essuministro_desechable) FROM stdin;
    public               postgres    false    229   �.                 0    30286 
   inventario 
   TABLE DATA           F   COPY public.inventario (id_insumo, id_hospital, cantidad) FROM stdin;
    public               postgres    false    245   �4      �          0    30088    medicamento 
   TABLE DATA           V   COPY public.medicamento (id_medicamento, fecha_vencimiento, presentacion) FROM stdin;
    public               postgres    false    230   =6      �          0    30224 	   necesitan 
   TABLE DATA           @   COPY public.necesitan (id_insumo, id_procedimiento) FROM stdin;
    public               postgres    false    242   7      �          0    30141 	   operacion 
   TABLE DATA           D   COPY public.operacion (id_operacion, duracion_estimada) FROM stdin;
    public               postgres    false    236   �7      �          0    30049    paciente 
   TABLE DATA           �   COPY public.paciente (ci_paciente, telefono, contacto_emerg, condicion, medicamento_regedad, requiere_resp, edad, num_poliza) FROM stdin;
    public               postgres    false    226   �7      �          0    30042    persona 
   TABLE DATA           o   COPY public.persona (ci, calle_pe, codpos_pe, ciudad_pe, fecha_nacimiento, apellido, nombre, sexo) FROM stdin;
    public               postgres    false    225   j:      �          0    30067    personal 
   TABLE DATA           O   COPY public.personal (ci_personal, annios_serv, esmedico, esadmin) FROM stdin;
    public               postgres    false    227   �@      �          0    30132    procedimiento 
   TABLE DATA           X   COPY public.procedimiento (id_procedimiento, nombre, instrucciones, precio) FROM stdin;
    public               postgres    false    235   �A      �          0    30239    provee 
   TABLE DATA           >   COPY public.provee (id_insumo, nombre_ca, precio) FROM stdin;
    public               postgres    false    243   �C      �          0    30124 	   proveedor 
   TABLE DATA           O   COPY public.proveedor (nombre_ca, contacto, calle, codpos, ciudad) FROM stdin;
    public               postgres    false    233   DI                0    30302 
   se_realiza 
   TABLE DATA           �   COPY public.se_realiza (id_departamento, id_hospital, num_habitacion, id_procedimiento, hora_operacion, ci_medico, ci_paciente, fecha, total) FROM stdin;
    public               postgres    false    246   =J      �          0    29985    seguro_medico 
   TABLE DATA           Z   COPY public.seguro_medico (num_poliza, sum_asg_sm, condiciones_sm, nombre_ca) FROM stdin;
    public               postgres    false    218   0K      �          0    30100    suministro_limpieza 
   TABLE DATA           K   COPY public.suministro_limpieza (id_suministro_limpieza, tipo) FROM stdin;
    public               postgres    false    231   9L                0    30416    telefono_departamento 
   TABLE DATA           d   COPY public.telefono_departamento (id_hospital, id_departamento, telefono_departamento) FROM stdin;
    public               postgres    false    250   �L                0    30433    telefono_personal 
   TABLE DATA           B   COPY public.telefono_personal (ci_personal, telefono) FROM stdin;
    public               postgres    false    251   nM                0    30391 
   trabaja_en 
   TABLE DATA           [   COPY public.trabaja_en (id_horario, ci_personal, id_departamento, id_hospital) FROM stdin;
    public               postgres    false    249   O      �          0    30152    tratamiento 
   TABLE DATA           =   COPY public.tratamiento (id_procedimiento, tipo) FROM stdin;
    public               postgres    false    237   6Q                 0    0    factura_num_factura_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.factura_num_factura_seq', 1, false);
          public               postgres    false    238                       0    0 "   horario_de_atencion_id_horario_seq    SEQUENCE SET     Q   SELECT pg_catalog.setval('public.horario_de_atencion_id_horario_seq', 15, true);
          public               postgres    false    223                       0    0    hospital_id_hospital_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.hospital_id_hospital_seq', 4, true);
          public               postgres    false    219                       0    0    insumo_medico_id_insumo_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.insumo_medico_id_insumo_seq', 1, false);
          public               postgres    false    228                       0    0 "   procedimiento_id_procedimiento_seq    SEQUENCE SET     Q   SELECT pg_catalog.setval('public.procedimiento_id_procedimiento_seq', 1, false);
          public               postgres    false    234            �           2606    29984 .   compania_aseguradora compania_aseguradora_pkey 
   CONSTRAINT     s   ALTER TABLE ONLY public.compania_aseguradora
    ADD CONSTRAINT compania_aseguradora_pkey PRIMARY KEY (nombre_ca);
 X   ALTER TABLE ONLY public.compania_aseguradora DROP CONSTRAINT compania_aseguradora_pkey;
       public                 postgres    false    217                       2606    30208    consulta consulta_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.consulta
    ADD CONSTRAINT consulta_pkey PRIMARY KEY (ci_medico, ci_paciente, id_procedimiento, fecha, hora);
 @   ALTER TABLE ONLY public.consulta DROP CONSTRAINT consulta_pkey;
       public                 postgres    false    241    241    241    241    241                       2606    30375    contratado contratado_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.contratado
    ADD CONSTRAINT contratado_pkey PRIMARY KEY (ci_personal, id_departamento, fecha_contratacion);
 D   ALTER TABLE ONLY public.contratado DROP CONSTRAINT contratado_pkey;
       public                 postgres    false    248    248    248                       2606    30347    cuentan_con cuentan_con_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.cuentan_con
    ADD CONSTRAINT cuentan_con_pkey PRIMARY KEY (id_hospital, ci_medico, id_departamento, id_insumo);
 F   ALTER TABLE ONLY public.cuentan_con DROP CONSTRAINT cuentan_con_pkey;
       public                 postgres    false    247    247    247    247            �           2606    30014    departamento departamento_pkey 
   CONSTRAINT     i   ALTER TABLE ONLY public.departamento
    ADD CONSTRAINT departamento_pkey PRIMARY KEY (id_departamento);
 H   ALTER TABLE ONLY public.departamento DROP CONSTRAINT departamento_pkey;
       public                 postgres    false    221                       2606    30184    emitida emitida_pkey 
   CONSTRAINT     w   ALTER TABLE ONLY public.emitida
    ADD CONSTRAINT emitida_pkey PRIMARY KEY (ci_paciente, ci_trabajador, num_factura);
 >   ALTER TABLE ONLY public.emitida DROP CONSTRAINT emitida_pkey;
       public                 postgres    false    240    240    240            
           2606    30265    encargo encargo_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.encargo
    ADD CONSTRAINT encargo_pkey PRIMARY KEY (id_insumo, id_hospital, nombre_ca, ci_resp, fecha);
 >   ALTER TABLE ONLY public.encargo DROP CONSTRAINT encargo_pkey;
       public                 postgres    false    244    244    244    244    244                        2606    30174    factura factura_pkey 
   CONSTRAINT     [   ALTER TABLE ONLY public.factura
    ADD CONSTRAINT factura_pkey PRIMARY KEY (num_factura);
 >   ALTER TABLE ONLY public.factura DROP CONSTRAINT factura_pkey;
       public                 postgres    false    239            �           2606    30027    habitacion habitacion_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.habitacion
    ADD CONSTRAINT habitacion_pkey PRIMARY KEY (num_habitacion);
 D   ALTER TABLE ONLY public.habitacion DROP CONSTRAINT habitacion_pkey;
       public                 postgres    false    222            �           2606    30041 ,   horario_de_atencion horario_de_atencion_pkey 
   CONSTRAINT     r   ALTER TABLE ONLY public.horario_de_atencion
    ADD CONSTRAINT horario_de_atencion_pkey PRIMARY KEY (id_horario);
 V   ALTER TABLE ONLY public.horario_de_atencion DROP CONSTRAINT horario_de_atencion_pkey;
       public                 postgres    false    224            �           2606    30007    hospital hospital_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.hospital
    ADD CONSTRAINT hospital_pkey PRIMARY KEY (id_hospital);
 @   ALTER TABLE ONLY public.hospital DROP CONSTRAINT hospital_pkey;
       public                 postgres    false    220            �           2606    30118 ,   instrumental_medico instrumental_medico_pkey 
   CONSTRAINT     ~   ALTER TABLE ONLY public.instrumental_medico
    ADD CONSTRAINT instrumental_medico_pkey PRIMARY KEY (id_instrumental_medico);
 V   ALTER TABLE ONLY public.instrumental_medico DROP CONSTRAINT instrumental_medico_pkey;
       public                 postgres    false    232            �           2606    30087     insumo_medico insumo_medico_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY public.insumo_medico
    ADD CONSTRAINT insumo_medico_pkey PRIMARY KEY (id_insumo);
 J   ALTER TABLE ONLY public.insumo_medico DROP CONSTRAINT insumo_medico_pkey;
       public                 postgres    false    229                       2606    30291    inventario inventario_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.inventario
    ADD CONSTRAINT inventario_pkey PRIMARY KEY (id_insumo, id_hospital);
 D   ALTER TABLE ONLY public.inventario DROP CONSTRAINT inventario_pkey;
       public                 postgres    false    245    245            �           2606    30094    medicamento medicamento_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.medicamento
    ADD CONSTRAINT medicamento_pkey PRIMARY KEY (id_medicamento);
 F   ALTER TABLE ONLY public.medicamento DROP CONSTRAINT medicamento_pkey;
       public                 postgres    false    230                       2606    30228    necesitan necesitan_pkey 
   CONSTRAINT     o   ALTER TABLE ONLY public.necesitan
    ADD CONSTRAINT necesitan_pkey PRIMARY KEY (id_insumo, id_procedimiento);
 B   ALTER TABLE ONLY public.necesitan DROP CONSTRAINT necesitan_pkey;
       public                 postgres    false    242    242            �           2606    30146    operacion operacion_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.operacion
    ADD CONSTRAINT operacion_pkey PRIMARY KEY (id_operacion);
 B   ALTER TABLE ONLY public.operacion DROP CONSTRAINT operacion_pkey;
       public                 postgres    false    236            �           2606    30056    paciente paciente_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.paciente
    ADD CONSTRAINT paciente_pkey PRIMARY KEY (ci_paciente);
 @   ALTER TABLE ONLY public.paciente DROP CONSTRAINT paciente_pkey;
       public                 postgres    false    226            �           2606    30048    persona persona_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.persona
    ADD CONSTRAINT persona_pkey PRIMARY KEY (ci);
 >   ALTER TABLE ONLY public.persona DROP CONSTRAINT persona_pkey;
       public                 postgres    false    225            �           2606    30072    personal personal_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.personal
    ADD CONSTRAINT personal_pkey PRIMARY KEY (ci_personal);
 @   ALTER TABLE ONLY public.personal DROP CONSTRAINT personal_pkey;
       public                 postgres    false    227            �           2606    30140     procedimiento procedimiento_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.procedimiento
    ADD CONSTRAINT procedimiento_pkey PRIMARY KEY (id_procedimiento);
 J   ALTER TABLE ONLY public.procedimiento DROP CONSTRAINT procedimiento_pkey;
       public                 postgres    false    235                       2606    30246    provee provee_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.provee
    ADD CONSTRAINT provee_pkey PRIMARY KEY (id_insumo, nombre_ca);
 <   ALTER TABLE ONLY public.provee DROP CONSTRAINT provee_pkey;
       public                 postgres    false    243    243            �           2606    30130    proveedor proveedor_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.proveedor
    ADD CONSTRAINT proveedor_pkey PRIMARY KEY (nombre_ca);
 B   ALTER TABLE ONLY public.proveedor DROP CONSTRAINT proveedor_pkey;
       public                 postgres    false    233                       2606    30307    se_realiza se_realiza_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.se_realiza
    ADD CONSTRAINT se_realiza_pkey PRIMARY KEY (id_departamento, id_hospital, num_habitacion, id_procedimiento, fecha, ci_medico);
 D   ALTER TABLE ONLY public.se_realiza DROP CONSTRAINT se_realiza_pkey;
       public                 postgres    false    246    246    246    246    246    246            �           2606    29992     seguro_medico seguro_medico_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.seguro_medico
    ADD CONSTRAINT seguro_medico_pkey PRIMARY KEY (num_poliza);
 J   ALTER TABLE ONLY public.seguro_medico DROP CONSTRAINT seguro_medico_pkey;
       public                 postgres    false    218            �           2606    30106 ,   suministro_limpieza suministro_limpieza_pkey 
   CONSTRAINT     ~   ALTER TABLE ONLY public.suministro_limpieza
    ADD CONSTRAINT suministro_limpieza_pkey PRIMARY KEY (id_suministro_limpieza);
 V   ALTER TABLE ONLY public.suministro_limpieza DROP CONSTRAINT suministro_limpieza_pkey;
       public                 postgres    false    231                       2606    30422 0   telefono_departamento telefono_departamento_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.telefono_departamento
    ADD CONSTRAINT telefono_departamento_pkey PRIMARY KEY (id_hospital, id_departamento, telefono_departamento);
 Z   ALTER TABLE ONLY public.telefono_departamento DROP CONSTRAINT telefono_departamento_pkey;
       public                 postgres    false    250    250    250                       2606    30439 (   telefono_personal telefono_personal_pkey 
   CONSTRAINT     y   ALTER TABLE ONLY public.telefono_personal
    ADD CONSTRAINT telefono_personal_pkey PRIMARY KEY (ci_personal, telefono);
 R   ALTER TABLE ONLY public.telefono_personal DROP CONSTRAINT telefono_personal_pkey;
       public                 postgres    false    251    251                       2606    30395    trabaja_en trabaja_en_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.trabaja_en
    ADD CONSTRAINT trabaja_en_pkey PRIMARY KEY (id_horario, ci_personal, id_departamento, id_hospital);
 D   ALTER TABLE ONLY public.trabaja_en DROP CONSTRAINT trabaja_en_pkey;
       public                 postgres    false    249    249    249    249            �           2606    30158    tratamiento tratamiento_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.tratamiento
    ADD CONSTRAINT tratamiento_pkey PRIMARY KEY (id_procedimiento);
 F   ALTER TABLE ONLY public.tratamiento DROP CONSTRAINT tratamiento_pkey;
       public                 postgres    false    237            R           2620    30452 -   contratado trigger_actualizar_annios_servicio    TRIGGER     �   CREATE TRIGGER trigger_actualizar_annios_servicio AFTER INSERT OR UPDATE OF fecha_contratacion ON public.contratado FOR EACH ROW EXECUTE FUNCTION public.actualizar_annios_servicio();
 F   DROP TRIGGER trigger_actualizar_annios_servicio ON public.contratado;
       public               postgres    false    248    248    255            J           2620    30446 #   habitacion trigger_actualizar_camas    TRIGGER     �   CREATE TRIGGER trigger_actualizar_camas AFTER INSERT OR DELETE OR UPDATE ON public.habitacion FOR EACH ROW EXECUTE FUNCTION public.actualizar_num_camas();
 <   DROP TRIGGER trigger_actualizar_camas ON public.habitacion;
       public               postgres    false    252    222            N           2620    30454 %   encargo trigger_actualizar_inventario    TRIGGER     �   CREATE TRIGGER trigger_actualizar_inventario AFTER INSERT ON public.encargo FOR EACH ROW EXECUTE FUNCTION public.actualizar_inventario();
 >   DROP TRIGGER trigger_actualizar_inventario ON public.encargo;
       public               postgres    false    256    244            O           2620    30458 &   encargo trigger_calcular_costo_encargo    TRIGGER     �   CREATE TRIGGER trigger_calcular_costo_encargo BEFORE INSERT OR UPDATE OF cantidad, id_insumo, nombre_ca ON public.encargo FOR EACH ROW EXECUTE FUNCTION public.calcular_costo_encargo();
 ?   DROP TRIGGER trigger_calcular_costo_encargo ON public.encargo;
       public               postgres    false    244    258    244    244    244            K           2620    30448 '   paciente trigger_calcular_edad_paciente    TRIGGER     �   CREATE TRIGGER trigger_calcular_edad_paciente BEFORE INSERT OR UPDATE ON public.paciente FOR EACH ROW EXECUTE FUNCTION public.calcular_edad_paciente();
 @   DROP TRIGGER trigger_calcular_edad_paciente ON public.paciente;
       public               postgres    false    226    253            L           2620    30450    factura trigger_estado_factura    TRIGGER     �   CREATE TRIGGER trigger_estado_factura BEFORE INSERT OR UPDATE ON public.factura FOR EACH ROW EXECUTE FUNCTION public.calcular_estado_factura();
 7   DROP TRIGGER trigger_estado_factura ON public.factura;
       public               postgres    false    254    239            P           2620    30456    encargo trigger_sumar_stock    TRIGGER     }   CREATE TRIGGER trigger_sumar_stock AFTER INSERT ON public.encargo FOR EACH ROW EXECUTE FUNCTION public.sumar_stock_insumo();
 4   DROP TRIGGER trigger_sumar_stock ON public.encargo;
       public               postgres    false    257    244            M           2620    30462    consulta trigger_total_consulta    TRIGGER     �   CREATE TRIGGER trigger_total_consulta BEFORE INSERT OR UPDATE OF id_procedimiento, precio_consulta ON public.consulta FOR EACH ROW EXECUTE FUNCTION public.calcular_total_consulta();
 8   DROP TRIGGER trigger_total_consulta ON public.consulta;
       public               postgres    false    241    241    260    241            Q           2620    30460 #   se_realiza trigger_total_se_realiza    TRIGGER     �   CREATE TRIGGER trigger_total_se_realiza BEFORE INSERT OR UPDATE OF id_procedimiento ON public.se_realiza FOR EACH ROW EXECUTE FUNCTION public.calcular_total_se_realiza();
 <   DROP TRIGGER trigger_total_se_realiza ON public.se_realiza;
       public               postgres    false    246    259    246            (           2606    30209     consulta consulta_ci_medico_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.consulta
    ADD CONSTRAINT consulta_ci_medico_fkey FOREIGN KEY (ci_medico) REFERENCES public.personal(ci_personal);
 J   ALTER TABLE ONLY public.consulta DROP CONSTRAINT consulta_ci_medico_fkey;
       public               postgres    false    227    4846    241            )           2606    30214 "   consulta consulta_ci_paciente_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.consulta
    ADD CONSTRAINT consulta_ci_paciente_fkey FOREIGN KEY (ci_paciente) REFERENCES public.paciente(ci_paciente);
 L   ALTER TABLE ONLY public.consulta DROP CONSTRAINT consulta_ci_paciente_fkey;
       public               postgres    false    226    4844    241            *           2606    30219 '   consulta consulta_id_procedimiento_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.consulta
    ADD CONSTRAINT consulta_id_procedimiento_fkey FOREIGN KEY (id_procedimiento) REFERENCES public.tratamiento(id_procedimiento);
 Q   ALTER TABLE ONLY public.consulta DROP CONSTRAINT consulta_id_procedimiento_fkey;
       public               postgres    false    237    241    4862            @           2606    30376 &   contratado contratado_ci_personal_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.contratado
    ADD CONSTRAINT contratado_ci_personal_fkey FOREIGN KEY (ci_personal) REFERENCES public.personal(ci_personal);
 P   ALTER TABLE ONLY public.contratado DROP CONSTRAINT contratado_ci_personal_fkey;
       public               postgres    false    248    4846    227            A           2606    30381 *   contratado contratado_id_departamento_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.contratado
    ADD CONSTRAINT contratado_id_departamento_fkey FOREIGN KEY (id_departamento) REFERENCES public.departamento(id_departamento);
 T   ALTER TABLE ONLY public.contratado DROP CONSTRAINT contratado_id_departamento_fkey;
       public               postgres    false    248    4836    221            B           2606    30386 &   contratado contratado_id_hospital_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.contratado
    ADD CONSTRAINT contratado_id_hospital_fkey FOREIGN KEY (id_hospital) REFERENCES public.hospital(id_hospital);
 P   ALTER TABLE ONLY public.contratado DROP CONSTRAINT contratado_id_hospital_fkey;
       public               postgres    false    248    4834    220            <           2606    30353 &   cuentan_con cuentan_con_ci_medico_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.cuentan_con
    ADD CONSTRAINT cuentan_con_ci_medico_fkey FOREIGN KEY (ci_medico) REFERENCES public.personal(ci_personal);
 P   ALTER TABLE ONLY public.cuentan_con DROP CONSTRAINT cuentan_con_ci_medico_fkey;
       public               postgres    false    227    247    4846            =           2606    30358 ,   cuentan_con cuentan_con_id_departamento_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.cuentan_con
    ADD CONSTRAINT cuentan_con_id_departamento_fkey FOREIGN KEY (id_departamento) REFERENCES public.departamento(id_departamento);
 V   ALTER TABLE ONLY public.cuentan_con DROP CONSTRAINT cuentan_con_id_departamento_fkey;
       public               postgres    false    4836    221    247            >           2606    30348 (   cuentan_con cuentan_con_id_hospital_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.cuentan_con
    ADD CONSTRAINT cuentan_con_id_hospital_fkey FOREIGN KEY (id_hospital) REFERENCES public.hospital(id_hospital);
 R   ALTER TABLE ONLY public.cuentan_con DROP CONSTRAINT cuentan_con_id_hospital_fkey;
       public               postgres    false    247    4834    220            ?           2606    30363 &   cuentan_con cuentan_con_id_insumo_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.cuentan_con
    ADD CONSTRAINT cuentan_con_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.insumo_medico(id_insumo);
 P   ALTER TABLE ONLY public.cuentan_con DROP CONSTRAINT cuentan_con_id_insumo_fkey;
       public               postgres    false    247    4848    229                       2606    30015 *   departamento departamento_id_hospital_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.departamento
    ADD CONSTRAINT departamento_id_hospital_fkey FOREIGN KEY (id_hospital) REFERENCES public.hospital(id_hospital);
 T   ALTER TABLE ONLY public.departamento DROP CONSTRAINT departamento_id_hospital_fkey;
       public               postgres    false    220    4834    221            %           2606    30185     emitida emitida_ci_paciente_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.emitida
    ADD CONSTRAINT emitida_ci_paciente_fkey FOREIGN KEY (ci_paciente) REFERENCES public.paciente(ci_paciente);
 J   ALTER TABLE ONLY public.emitida DROP CONSTRAINT emitida_ci_paciente_fkey;
       public               postgres    false    240    226    4844            &           2606    30190 "   emitida emitida_ci_trabajador_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.emitida
    ADD CONSTRAINT emitida_ci_trabajador_fkey FOREIGN KEY (ci_trabajador) REFERENCES public.personal(ci_personal);
 L   ALTER TABLE ONLY public.emitida DROP CONSTRAINT emitida_ci_trabajador_fkey;
       public               postgres    false    4846    227    240            '           2606    30195     emitida emitida_num_factura_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.emitida
    ADD CONSTRAINT emitida_num_factura_fkey FOREIGN KEY (num_factura) REFERENCES public.factura(num_factura);
 J   ALTER TABLE ONLY public.emitida DROP CONSTRAINT emitida_num_factura_fkey;
       public               postgres    false    240    239    4864            /           2606    30281    encargo encargo_ci_resp_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.encargo
    ADD CONSTRAINT encargo_ci_resp_fkey FOREIGN KEY (ci_resp) REFERENCES public.personal(ci_personal);
 F   ALTER TABLE ONLY public.encargo DROP CONSTRAINT encargo_ci_resp_fkey;
       public               postgres    false    227    4846    244            0           2606    30271     encargo encargo_id_hospital_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.encargo
    ADD CONSTRAINT encargo_id_hospital_fkey FOREIGN KEY (id_hospital) REFERENCES public.hospital(id_hospital);
 J   ALTER TABLE ONLY public.encargo DROP CONSTRAINT encargo_id_hospital_fkey;
       public               postgres    false    4834    244    220            1           2606    30266    encargo encargo_id_insumo_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.encargo
    ADD CONSTRAINT encargo_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.insumo_medico(id_insumo);
 H   ALTER TABLE ONLY public.encargo DROP CONSTRAINT encargo_id_insumo_fkey;
       public               postgres    false    4848    244    229            2           2606    30276    encargo encargo_nombre_ca_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.encargo
    ADD CONSTRAINT encargo_nombre_ca_fkey FOREIGN KEY (nombre_ca) REFERENCES public.proveedor(nombre_ca);
 H   ALTER TABLE ONLY public.encargo DROP CONSTRAINT encargo_nombre_ca_fkey;
       public               postgres    false    4856    233    244            $           2606    30175    factura factura_num_poliza_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.factura
    ADD CONSTRAINT factura_num_poliza_fkey FOREIGN KEY (num_poliza) REFERENCES public.seguro_medico(num_poliza);
 I   ALTER TABLE ONLY public.factura DROP CONSTRAINT factura_num_poliza_fkey;
       public               postgres    false    239    4832    218                       2606    30028 *   habitacion habitacion_id_departamento_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.habitacion
    ADD CONSTRAINT habitacion_id_departamento_fkey FOREIGN KEY (id_departamento) REFERENCES public.departamento(id_departamento);
 T   ALTER TABLE ONLY public.habitacion DROP CONSTRAINT habitacion_id_departamento_fkey;
       public               postgres    false    222    4836    221            !           2606    30119 C   instrumental_medico instrumental_medico_id_instrumental_medico_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.instrumental_medico
    ADD CONSTRAINT instrumental_medico_id_instrumental_medico_fkey FOREIGN KEY (id_instrumental_medico) REFERENCES public.insumo_medico(id_insumo);
 m   ALTER TABLE ONLY public.instrumental_medico DROP CONSTRAINT instrumental_medico_id_instrumental_medico_fkey;
       public               postgres    false    232    4848    229            3           2606    30297 &   inventario inventario_id_hospital_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.inventario
    ADD CONSTRAINT inventario_id_hospital_fkey FOREIGN KEY (id_hospital) REFERENCES public.hospital(id_hospital);
 P   ALTER TABLE ONLY public.inventario DROP CONSTRAINT inventario_id_hospital_fkey;
       public               postgres    false    220    4834    245            4           2606    30292 $   inventario inventario_id_insumo_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.inventario
    ADD CONSTRAINT inventario_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.insumo_medico(id_insumo);
 N   ALTER TABLE ONLY public.inventario DROP CONSTRAINT inventario_id_insumo_fkey;
       public               postgres    false    245    4848    229                       2606    30095 +   medicamento medicamento_id_medicamento_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.medicamento
    ADD CONSTRAINT medicamento_id_medicamento_fkey FOREIGN KEY (id_medicamento) REFERENCES public.insumo_medico(id_insumo);
 U   ALTER TABLE ONLY public.medicamento DROP CONSTRAINT medicamento_id_medicamento_fkey;
       public               postgres    false    4848    229    230            +           2606    30229 "   necesitan necesitan_id_insumo_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.necesitan
    ADD CONSTRAINT necesitan_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.instrumental_medico(id_instrumental_medico);
 L   ALTER TABLE ONLY public.necesitan DROP CONSTRAINT necesitan_id_insumo_fkey;
       public               postgres    false    4854    232    242            ,           2606    30234 )   necesitan necesitan_id_procedimiento_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.necesitan
    ADD CONSTRAINT necesitan_id_procedimiento_fkey FOREIGN KEY (id_procedimiento) REFERENCES public.procedimiento(id_procedimiento);
 S   ALTER TABLE ONLY public.necesitan DROP CONSTRAINT necesitan_id_procedimiento_fkey;
       public               postgres    false    242    235    4858            "           2606    30147 %   operacion operacion_id_operacion_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.operacion
    ADD CONSTRAINT operacion_id_operacion_fkey FOREIGN KEY (id_operacion) REFERENCES public.procedimiento(id_procedimiento);
 O   ALTER TABLE ONLY public.operacion DROP CONSTRAINT operacion_id_operacion_fkey;
       public               postgres    false    4858    235    236                       2606    30057 "   paciente paciente_ci_paciente_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.paciente
    ADD CONSTRAINT paciente_ci_paciente_fkey FOREIGN KEY (ci_paciente) REFERENCES public.persona(ci);
 L   ALTER TABLE ONLY public.paciente DROP CONSTRAINT paciente_ci_paciente_fkey;
       public               postgres    false    226    225    4842                       2606    30062 !   paciente paciente_num_poliza_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.paciente
    ADD CONSTRAINT paciente_num_poliza_fkey FOREIGN KEY (num_poliza) REFERENCES public.seguro_medico(num_poliza);
 K   ALTER TABLE ONLY public.paciente DROP CONSTRAINT paciente_num_poliza_fkey;
       public               postgres    false    218    226    4832                       2606    30073 "   personal personal_ci_personal_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.personal
    ADD CONSTRAINT personal_ci_personal_fkey FOREIGN KEY (ci_personal) REFERENCES public.persona(ci);
 L   ALTER TABLE ONLY public.personal DROP CONSTRAINT personal_ci_personal_fkey;
       public               postgres    false    227    4842    225            -           2606    30247    provee provee_id_insumo_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.provee
    ADD CONSTRAINT provee_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.insumo_medico(id_insumo);
 F   ALTER TABLE ONLY public.provee DROP CONSTRAINT provee_id_insumo_fkey;
       public               postgres    false    229    243    4848            .           2606    30252    provee provee_nombre_ca_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.provee
    ADD CONSTRAINT provee_nombre_ca_fkey FOREIGN KEY (nombre_ca) REFERENCES public.proveedor(nombre_ca);
 F   ALTER TABLE ONLY public.provee DROP CONSTRAINT provee_nombre_ca_fkey;
       public               postgres    false    233    243    4856            5           2606    30333 $   se_realiza se_realiza_ci_medico_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.se_realiza
    ADD CONSTRAINT se_realiza_ci_medico_fkey FOREIGN KEY (ci_medico) REFERENCES public.personal(ci_personal);
 N   ALTER TABLE ONLY public.se_realiza DROP CONSTRAINT se_realiza_ci_medico_fkey;
       public               postgres    false    246    227    4846            6           2606    30338 &   se_realiza se_realiza_ci_paciente_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.se_realiza
    ADD CONSTRAINT se_realiza_ci_paciente_fkey FOREIGN KEY (ci_paciente) REFERENCES public.paciente(ci_paciente);
 P   ALTER TABLE ONLY public.se_realiza DROP CONSTRAINT se_realiza_ci_paciente_fkey;
       public               postgres    false    4844    246    226            7           2606    30328 )   se_realiza se_realiza_hora_operacion_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.se_realiza
    ADD CONSTRAINT se_realiza_hora_operacion_fkey FOREIGN KEY (hora_operacion) REFERENCES public.horario_de_atencion(id_horario);
 S   ALTER TABLE ONLY public.se_realiza DROP CONSTRAINT se_realiza_hora_operacion_fkey;
       public               postgres    false    4840    246    224            8           2606    30308 *   se_realiza se_realiza_id_departamento_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.se_realiza
    ADD CONSTRAINT se_realiza_id_departamento_fkey FOREIGN KEY (id_departamento) REFERENCES public.departamento(id_departamento);
 T   ALTER TABLE ONLY public.se_realiza DROP CONSTRAINT se_realiza_id_departamento_fkey;
       public               postgres    false    246    221    4836            9           2606    30313 &   se_realiza se_realiza_id_hospital_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.se_realiza
    ADD CONSTRAINT se_realiza_id_hospital_fkey FOREIGN KEY (id_hospital) REFERENCES public.hospital(id_hospital);
 P   ALTER TABLE ONLY public.se_realiza DROP CONSTRAINT se_realiza_id_hospital_fkey;
       public               postgres    false    220    246    4834            :           2606    30323 +   se_realiza se_realiza_id_procedimiento_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.se_realiza
    ADD CONSTRAINT se_realiza_id_procedimiento_fkey FOREIGN KEY (id_procedimiento) REFERENCES public.operacion(id_operacion);
 U   ALTER TABLE ONLY public.se_realiza DROP CONSTRAINT se_realiza_id_procedimiento_fkey;
       public               postgres    false    236    246    4860            ;           2606    30318 )   se_realiza se_realiza_num_habitacion_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.se_realiza
    ADD CONSTRAINT se_realiza_num_habitacion_fkey FOREIGN KEY (num_habitacion) REFERENCES public.habitacion(num_habitacion);
 S   ALTER TABLE ONLY public.se_realiza DROP CONSTRAINT se_realiza_num_habitacion_fkey;
       public               postgres    false    4838    246    222                       2606    29993 *   seguro_medico seguro_medico_nombre_ca_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.seguro_medico
    ADD CONSTRAINT seguro_medico_nombre_ca_fkey FOREIGN KEY (nombre_ca) REFERENCES public.compania_aseguradora(nombre_ca);
 T   ALTER TABLE ONLY public.seguro_medico DROP CONSTRAINT seguro_medico_nombre_ca_fkey;
       public               postgres    false    4830    217    218                        2606    30107 C   suministro_limpieza suministro_limpieza_id_suministro_limpieza_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.suministro_limpieza
    ADD CONSTRAINT suministro_limpieza_id_suministro_limpieza_fkey FOREIGN KEY (id_suministro_limpieza) REFERENCES public.insumo_medico(id_insumo);
 m   ALTER TABLE ONLY public.suministro_limpieza DROP CONSTRAINT suministro_limpieza_id_suministro_limpieza_fkey;
       public               postgres    false    4848    229    231            G           2606    30428 @   telefono_departamento telefono_departamento_id_departamento_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.telefono_departamento
    ADD CONSTRAINT telefono_departamento_id_departamento_fkey FOREIGN KEY (id_departamento) REFERENCES public.departamento(id_departamento);
 j   ALTER TABLE ONLY public.telefono_departamento DROP CONSTRAINT telefono_departamento_id_departamento_fkey;
       public               postgres    false    221    4836    250            H           2606    30423 <   telefono_departamento telefono_departamento_id_hospital_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.telefono_departamento
    ADD CONSTRAINT telefono_departamento_id_hospital_fkey FOREIGN KEY (id_hospital) REFERENCES public.hospital(id_hospital);
 f   ALTER TABLE ONLY public.telefono_departamento DROP CONSTRAINT telefono_departamento_id_hospital_fkey;
       public               postgres    false    220    250    4834            I           2606    30440 4   telefono_personal telefono_personal_ci_personal_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.telefono_personal
    ADD CONSTRAINT telefono_personal_ci_personal_fkey FOREIGN KEY (ci_personal) REFERENCES public.personal(ci_personal);
 ^   ALTER TABLE ONLY public.telefono_personal DROP CONSTRAINT telefono_personal_ci_personal_fkey;
       public               postgres    false    251    4846    227            C           2606    30401 &   trabaja_en trabaja_en_ci_personal_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.trabaja_en
    ADD CONSTRAINT trabaja_en_ci_personal_fkey FOREIGN KEY (ci_personal) REFERENCES public.personal(ci_personal);
 P   ALTER TABLE ONLY public.trabaja_en DROP CONSTRAINT trabaja_en_ci_personal_fkey;
       public               postgres    false    249    227    4846            D           2606    30406 *   trabaja_en trabaja_en_id_departamento_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.trabaja_en
    ADD CONSTRAINT trabaja_en_id_departamento_fkey FOREIGN KEY (id_departamento) REFERENCES public.departamento(id_departamento);
 T   ALTER TABLE ONLY public.trabaja_en DROP CONSTRAINT trabaja_en_id_departamento_fkey;
       public               postgres    false    221    4836    249            E           2606    30396 %   trabaja_en trabaja_en_id_horario_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.trabaja_en
    ADD CONSTRAINT trabaja_en_id_horario_fkey FOREIGN KEY (id_horario) REFERENCES public.horario_de_atencion(id_horario);
 O   ALTER TABLE ONLY public.trabaja_en DROP CONSTRAINT trabaja_en_id_horario_fkey;
       public               postgres    false    224    249    4840            F           2606    30411 &   trabaja_en trabaja_en_id_hospital_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.trabaja_en
    ADD CONSTRAINT trabaja_en_id_hospital_fkey FOREIGN KEY (id_hospital) REFERENCES public.hospital(id_hospital);
 P   ALTER TABLE ONLY public.trabaja_en DROP CONSTRAINT trabaja_en_id_hospital_fkey;
       public               postgres    false    249    4834    220            #           2606    30159 -   tratamiento tratamiento_id_procedimiento_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.tratamiento
    ADD CONSTRAINT tratamiento_id_procedimiento_fkey FOREIGN KEY (id_procedimiento) REFERENCES public.procedimiento(id_procedimiento);
 W   ALTER TABLE ONLY public.tratamiento DROP CONSTRAINT tratamiento_id_procedimiento_fkey;
       public               postgres    false    4858    235    237            �   �   x�U��N�0�g�)�#Uqj'�H�6�j�rM�p�I����1�}1l�ܭ�����6���:��q^�g���+8գڃW-r�=z����۔:�zO�p�0��5��s.�j�ta�B�6�t3\ikm�|���wuX�����~f`�4r@Q&�c3ȴ�eY[�;���Ȟ�}�>��:�[�ω<}`X�V�MSW�ȴ�@���=@X�j߾��E[�,����R��`[      �   X  x�mTKj�@]�O�$��k�Y�d�j6�V��Gm$;���a.6Uݲ[��e�����x��ф�è�X� ��*�~V���C�a�CwRdSAmv� �Z] ��o4S�v�ߩ�L�� >���� �h����aL�I$�;:�Z��H0��!o�Y���36z��fx/�#��e	��f�]�9��)�S?���2����q~�!F>̚��B�2u{�0t��UN����W�����¢��
�D�Ԝ��;��fB��c��f��H�/+_�4�]����u����ļ�q���
���7�4��:/��|l؎�u�@�^��c��I�˩��W���'�\$Dc2����-|���K�ѯ�gÝ���}/)��eq-ޒ��MV���c1/d��z��s�mN��<�ӗ�KƔ(�rb�t��Yv֑�^�gꯜ��|�սQ�|�M�vK�)��cMޏ�:l�潋Y�z]��r�R6�9�1����]���R��0fU>S
S�[
�Z{+�K�9 ��q�x,��Ę���Zd��a��,��m�[k!o���O�XӒ���e��a�V��).����f��W�         4  x��VAn�0<ӯ�T�KR��AP��(��rQm�P�H���R=�	�X�K*�dI&��8��ٙ]>	ȵ� ���{��r�9����_e�n益��x�~��F0��}�k����K����ϯUw��]]�0��&O�2�#@LZ(�	�0�-�jA*��v�Ur���b��VPN�ȍ-\�<Fq��8���K����S��-�D���D��n��uSO]�o� 0�m[ wJ��D���� �&��g�~����jN�v_m5���2\t1nVl���6��6�2�Ť����%�V�@j�ozA��T���<+��ty3 ��+�^����K{p N�� �6�طj_����,�p���!�k��!SJQ�?�"�zN�,�b$'��g�BHW5���L&]�(
(Xѽu2&�s���Op�w.��I�I$���w-x��ʹ�,��"-�f~�Έ"6~����:�6�Ǥq���_�sL�7,G>�+�3���7��$	�0v����1�,�/�,ek&����vQ{@~��h��(:(),Ƥ�r�"��w53�m���̬7����Y��$��0J�.�����pz��Y<�*��7-��J$�~b���W��ˌ*��=�Q�ԕ��d)15¥��c����W�P�,
\��5X"�#w�n<s��^��F k&g`�5&�2|�]ɩ?�s�!22ĕ��j2���v�q%ׇ}��2{�-���ה�o��WJ�������~����p?���zJ�51۬�Qf|D�0�FE�,�(�,��	w�)���i�����7^         l   x�eϱ�0����@��H��?G�����y��;� &���3e#�r�M�k5K�(Vn;�D=�}(QO9w�Ny�3�C�<M����fJ����#q�V#H��~�����D�      �   �   x���Q
�@����St�pw� %B�P��2�"��v��:�k�"DR|ۙ_؏UF�l+�Kcs�*SP�@
)���o�����$��b8J���yl�'�n���"Ku�1��e��35�Q�1�䱭�7�'qeRFl��L�8ϐ)�Ge:���{6�Ț|��6��<C�E<��CcՁG��Hmc��~�D^M�8�@��B���2      �   �   x�M�� Ck3L�|���sDrG��xZ���l�h}�fH}���bccZdo����	z�����؊���8�AF�X�oͺx�6o�fM�r���ma]���#�N����G7wJ[n��W��w�pۋ���!�n`fMx~!>�1����@�[�=��9���T12�M�t��,^�[����o�A��P=�1([���?2}?)�ޞ`�      �     x����n�FE���8`?ؤ�� ;��@V�(c!��8r �jj�a�D�-{Ņn�8�,�q��O�������w�~:���X�e7�!�i��};��Hq���(��������t�a:�~����kNcȔ���������/���|���������<�)щx<��=~:R�.}�8|��ޜP��1L4����_����׻�OG�n_�4�X�PAVu�5T3�j�X)�xQ-Cj7)�ܨ(�Leq�aQd�O1b�������`���K�;�[�Lxtw��31/E�4����~_V``���5ң�k���3;Fͼ��D{ig[h�!uWL�t8�I�+&AJ�iC�K&#.5��2�Q�%����IvjfH�5�`�ӑ�k&�y�#]-�3��S�5�lM!{ZF�v�2�2Jd��Q"-5d�(�3MxG�(["!�Vgi�Q��q�������c���G,Cm���,y�n}*�����P�P�ߖ\ɇ�_����X(�&���X(�7&�(t�w4�S��U�
\�rym���%z���l-�vJyG�(۞��Ӷ�����P�eZ�L텟�X���FN�?m��֟�xmL�OWim$��1Vb�*�~'*�~/*c�(,c�-k�/c�>^������ü��c���c���������V�H����qV������;�IP�e&#���������Qhb�(4�~73�~?1�~�Z?L�������&���2β��n2α��.2Ω�ë�G��㻟G������Ad��Ah���Ќ����w`S�G���������������qlj��
�eSn���� ����+�n���������&�����uZ��b�+�~�Z��Z���~��~���~���~/k�N`��a^��1`��1`j�N`��a`�\dk���8���IL�b���$�֏2�j�nhj�hb�(4�~�X��[��[?L���S��S�wS�Vg��{7���{����U�#�����#��qbj� 2c� 4c�^h���Ԍ�;�������Qnj�nnj�~nb�86��r�I������?�Cyc������9����u�� ����m����r�����X?�J�C���D���Ee��e��e��e����Z���~���~��~�Z���~�*�Z?1Ϊ�w��X'1	����d�Z��Z��X?
M��&��f���'�֏S�����������������U�Y���M�9���E�9�~x���~|���~��Z?��X?�X���~75c�lj�(7�~��Z���Z���X?������B���`�      �   i  x���=n�0Fg���
�ԏ=wn� �,F������l7R�4���'QF@2p�ݮ�]�_�o 2�AY@��Ջ��� ]I���]Q�и�J�kJTȺ�be������dh�|}/�TXPH`�+�����ss��r%�* rI��Z����cUVY��T�`^���*(VҨ.)�QV�0�օ!⃁Y�aغP��M���5C�q۷�Q �7�L�h*�S�}��)v۶��iMy��֩�����.>��0��������i�)ꁲ�u�z��i��xY ��@ʙ�Oor��r����v�|5�E�9��]� ?u�ԋ{�ɋ���mi:�7�J�?�\
      �   [  x���M��@��5fD���]��bE���DQ����f��z1�G�C�*�iIK��MiJ��,���������}����%���k�?��~�~�o�\c^c�b�ļ�|9-� �ܜs�cnb�M���171�&��Ę[c����s��s.�y�rK����u�����_��{��<�3�2]VH?�|�W���F���՘LW�Ktui��j�7&�+sV���V;��m5C[��V3��m5C[;S[żr�5��䘛scnb�M���171�֘s;�+��s.�y�r����5�5�-�K�{�א{n��nNF�#`�u㺹)�nfX71��c�㍕��vXsj�Zj�����fh�Zj��������b^�Úsnr�M���171�&��Ę�sk̹���V����f�u3ú�a�̰nfX73��֭3���sa�i�C\��5�����I3]-.��������}�������\�u;�9��-5CK��R3��-5CK�����R1��a�979�&��Ę�scnb�M��5��N�jm�#�P�e�u�tB��	�N'T;�P�tB�'Ty�:OK�V�+�j�G�O+g���<����%�/ifx�<���<�� \J�E      �   v   x�m�K
�0E���b$�G�kq�Dё��M�Q�B���+Df}������ڙ|�޴�)`{�g!�:�m[l3����g��)a�,���ea�XD�R;�`u2�ʎ��S����zl��$�>@      �   �   x�E��
�0 �s�y����<�!(8O�A�ĶH�k%�{'>�^�n ��C>�P���YO(�P��}gE����A��nMB����.�'w��칷S.��rL?�uذ��X�yͤ����k�;I�B�z=�Մ7!]֓౳�F�Q�T�fx�+ol����"V���V�e1n+C�)����Ob      �   �   x�m�A�0EםSp���������
��xvn���\������ʛ��踑��dj���!�t
�Ű��h��㲄��FI�ɋ[���R����8��Loٱ�+P-m8���v�����u�d�$C�Y�OnK��EM�P�Z(⪈����s?�6_U��e _��m0      �   �  x��V=s�8��_���D��K�Qe�8�s�+��@H�0 ���o\�p�qw-�ؽ(��ss�J#o����v欮��zg]�/u%�*�dƖ�k]8�i���cYi�?�Kg�J�J�|�n���$eK�d�>���΋�cß�	{�t9d��Vڈ4Δl�,���Z���J��We�� g�#���A�Vv[�8���%�TʋB�m��^!O�cv*rm��t曻�h)ظ�ya�x6�BjEy섽U�Vo|K|y�Sl��ʕ�)+qp�o<uʾ�H�����Rg��sP_.���q�M���������rV@��̲��=,hΖ���/����A��nY'�^۝+�+ }2��%�W6s��{��Ó�m-
�#\�N��׻��|����Ȉ��޷���L�\�w0A'��͝ѥ.iK^�LJ��� }dK�٢��4�_���6��$��R��1��(!^M�`ü��t��d�.`#�v�9[����O]S��\jeI��L����,*��p8\���u0�(�Y�P�y�
�;a��.������=%��C�:׶�@�_��O2eotYվy�K�ܣ����ǝ:@���~<�E��"4$5���b�Fe-�h�2gg�D��f��2�w�jc�ڟ�+���ؖU'逽��h����q���(��34P������vͦ�_æ�D�����_hA6�E�#X��G�t�4 GO6�c�̦��m�GiD$���31��L��T�v�Ri6� ���g�7�5ʧ<��Md��V���K{�s�TMR��X�Z݊��cM�G�!JLw��'�M(R�b�@H��}�
�)[鮜�+������t>�Eo;F�]���GEcJ�1�M,��K��9�°j~�V��q{2�����"�
�3��@��,�����t�M�XH��?Cy����k��1��� )���'H
W�L�wΨ�L�y6�z�j䄖{�>E���~9b��Lܻ��� �_Ґ`�^
��O���j���LT��a�� ������V�]s_R�7�;	`F�q+��𬘰զ�s����"~$ }`D�`��E�"����F{���1�xl�*��ùe]���Ga�N5Q0��!H��d2~�'L�ya4͌"��f��ji(!�{ex�'�JT�cA��Yz!��U]ᕃGA�t�ggt;���x��Q�i��yL�}0a�l�X�����FT�7�Y�2�
��n�#2e�*��0r� 6W���C���I�*�;QGC��΃%�%Ѫy���a߫�h�{��:Ow!�E�,M#��y��lp_����]���i0࿯^S�I��'ͽ�O����b����JT�>���nE���v�N�Z�]�=\��s	L2�ΣE���:�,<#��%Lk��O�����AGy�B��!9�.��a�8DSd�#�O�W��&B	߱�蹝;5����:99��[�          �  x�5��m�@Cѵ�@E�?����16�w�t7E8��|�R�{���}��z߽߽�����g����&�6�F��ʹ�K7q&B<�'�"��f�,�e�l����'�"���'r�a"�a9,���`��EEQQTEEQQTEC�P4EC�P4EC(E��"P�@(E��"P�@(E��"P�@(E��"P�>(.��⢸(.��⢸(���x(���x(��bP�A1(Š�bP�A1(Š�bP�A1(Š�bP�A1(ŠPR�%EIQR�%EIQ2�%C�P2�%C�P2�%���PJ@	(%���PJ@	(%���PJ@	(%���PJ@	(���u�4p�5      �   �   x�U���0E���Yۍ���2p��Ŀwh#3��Yszo��ܠmP��b?�-f�Fq�Bf�k~L;�=�7�x�}iw��5��J���� Y�.�x���N���8ٛ��k������AU:'�QJ�
;Uw�Uث�J�:�Ӓd���jo��n�^j������q)�5�R�;�� o�	]e      �   u   x���!��q178������qQh�B�OX�����I��%_�ăkl�֎�Y���2^y��j�V����g��å�O������^\��{$���������9��$��#!^      �   F   x�%̻�0B���Y�g��?Gl���c���0��.\b?9)Ndqa�ύM�v�w�BX|���      �   y  x�uTMk1=����c��G�@�[��%ّ�`�k�J(�����
���<�7�F[�r�h��7����j8�r<y����-��б̔f�՝�R�q���
�j��J#��э���x)�~�CϞ�ѧ�{v`��lr���E�ׂ�T�P��~r�:�ÐN���%ۚK�����(D;�[�c�P��{;����[ok����:�F�A!W�8[v!��g����_���Bs�
���Aι�j�b�hp���(U[S���x*:�7R*5#2�rLC|��i`���ߩi���|g`ai��vF4�eʉ���}�M�{��j.��~��D&�b�P�������i�h
g�� fD>Ş$�؋S��6�?�B ` %��V�
��?N�~��9��E������]w�a��n�����{͡^���i�D!�9$а�Czm>O�Ѕ��yq�
"�13*:�p�1�4���Z�u+�%53�1"ũZAOQs��p+�lB8���.�I�S?�ue5�7�_��2]�fcF$��5��K�)���u�	ݞ�*
d�Ҷ(0f��n��N��\������pz�V��M�1�.5��9B��e�����*Ilu�j�R}1��}�X�Rv      �   =  x�}V�r�H|�~�[s�|��;>�v��l��H�(LQ�w(�*��m���RR��� ht7�
��$�b�>z���	%����vB��di%�λ�7V\���,צ�3����(��Z<pT5k��4���_�ƭ,�Y��x8{�:K�XiJz�a�T��������nEI���/U�n��S��!���ռB��x��k�>�H��H���u�sf�M�E�}'
��W���&�Y�r����������N$�51�\͜_ٲ�"�����]S�(鵸n�5JZ�ҷ�M�ҏ���7^l3���[�3[S!Y$�HQi?��{��y�A P!�m]�[/R�&��6܃�$�O P�k;ǩ�$E�2�V���9��'� ;ҙ�Z�T_��Z�mJ�K)��nt�84�T�Q�躷���y��ϾjV��GWwm��3����m&a�UF��#e�U��<:��fn>L�p<������H�#��d=we+�\���AqD�?Cf
���h�v�C߯�|�1��thkjW�H�H�)Q���`_��;�Jm�}QH���e���m6І	�<��6 ��A,b���\����JC�I$C �B' �ѓ�/m�%�4��G�/�̅}�J�c��F��/@�������K��ئr�0�0�4<��h�D���\�܃&.A�O~�Vܸ�
ja��$�&���\��ֳ�s.�y�1�9c�>XN:p�2��5�~h$Ę�y���NĹ��؇��b����P����}ve &�{_�m��߂��:�
��-@�q�����% �㍺n�BK;pQ����f9ј����1�p-�=*�i��kȳ�s���ym�A�|#Pwh=�ǖM�/h��|#�]Tn1$�.~k��{�6�F�rT�r`�R�,�}�:tl4�a�����kXX�V9�m6F�AW�#��-�a�$�5OM%��ԎM�Kĵ�����33�:���W���I��m��A˙�W0�5J;^�l��q��]G����G�M��/f���_-�n��~e��~uK�<o�}CEY�d�)�'�T�*�����c!o�T��^�ΙAOoP�e�r�`� ,r�����q�2xk>� ����j� c7(LO4O�C��u�ˋ����am������C�'�]S;��1H9<���N�^��D�À�3N�����kX�ۃ�t[mOJ?���M7 ���<C�huK"0vֳmp������qx��,c�<���eBgK���ww���}x��˪F"w;�M�Y�����b��C�*ɯ�^��@���e�ªȋ��n�SKr�rl��.�ݭ����	���wwG�͢�/��ӕ��:q�/�����6����?v9����4��q�H��T7�g�x�]Ϸt�.rܬ[�m�W'��e��y��Gܕ�F�a�mܡ.���A۸��+W��[��.�0JL��O;����Kt���a�kAqR�>���&����fx���V5���j 8k�o��pe�Z��޶u���` �{U���V��ޣa��*6;u�b�,0l��m�'�����qvv�?}��      �   �   x�]��1EcT�>:�ȱ+p�c-<v�V����9:5zӫ\2��R�������\��ުB���^n�`�=�B���:'��T���e��mny�]�s�j�������;a��9d?So5�n��՛_?��}�{]C�y��o=�>��F�弧ϫ�K�4��.?�q��á��+��f�����?z���|�R>_�l�      �   `  x�mS�n�@<S_�_�Z����U�:���N�S/��:4������ח+;���"@∜sX�d���1��5Z1�g(G���JZ�هO�i9�ư��,֬��`� �K��ZzF�����Rj�R{P׷�&��C�9�6p-x���nS�ȣ�3�<�o�=zo*qbѱ��y�E�1�eǇۏ*��D,��oP��
�

?$�7��F풏����1v�<�4&�a��O^�y���-�m1Q�Ru+��C���`�f>@�M{`Q�|��~��%ldm���.���V�Y�����n���j։�4���0W�~E��%��I���93�6W�������uhz��ju��r�%/i��6��H>-++FP�k��A�p����5YY�ý�T�y���.�'&>f�a�+KM<q�4���z5_Y1��1j�ͽ��e�!hc-�z�x<K�Y�~�-�b��I.W^p���G���E��A3�S��3�峆
�:��g�~Z��`^f��^鿋֪'Uձ>%�$+�z>��$���$vG�`����!�y����k������Cg���2��P��FZ���R�2����,��z�`�      �   5  x���ώ$5�ϝ��'���SGXq�h�\���4�=4oO>s);����Tٟ��ݕO?]^��oo��>}����~�)�@�<`.ʜ	vV�sUf�n����K,C�웲o0�ߊ�笟#Ie�,�]g��nd+/0ҕ|�N��]g,�e���Θ�ts���lc�sͳ�V]�<G ��|�N��������ՙ��B1J9��έ��3�8Bѩ�H���8�[���.�<��	N�NpƦ���F�e��˸��͢�Nl���Ml�e`��Xg�[�X��������������v��r�Y(s4��@��91(s���@����2G3��Q�E(�쉄2G�6�ʨ��*�Q��	eT<ie��6�
ʨlkʨ�P�x�3eLٲ�X��:c���Y����^���Nd�7�7*�����'f@G	�-�o�����}�'�=��2�u�B�gL ����@ڟ�"�
�x�BڼS�R��l�(u��V���@2����E�xU]���Ф�od��,#�|��e�/ڹZ8U?�u��}{��~��o�_�̿<�Χ:��ɬ��`Y��癚�JK�2����9eٞ���'k�@��[;�*�[:l\�}�pǶ�\�,h_����[�Z��+@����}/[z�R�~����tCv�$@̑r�u���C߀Y��ح܎�[9J�y��F��o]�y�ɑ��R��C���8a] kGg88:ᨣ#ō�q�	E���i��q"5�Äkq��JG�=KGH��n?��y�{���#;2Ή�e�u���;2n�+f�����VW�Q������4�}Y�?]��};���X���a`.�C&l��x��aҬ+bs��'��2l�Tdڬ=6�2n�8k�y�eT����"��h���U�%�9N�Ԛ��K�S�AᲧ�tG�T�����Oσ0y���~���i:�g��i�ȓ�a9$O���'��ay�0�hZ<M�~�ay��E�{F�rZ;q�$�E�����AY�'鞬'�Dʞ�s �]�.K���>eO�9�Xƒ�S�6��Cw�T�"u̦�Ξ����'*fl>}��|����������:�K��6��(��d�d�Yd`�Z'�/#�:�6��zQm��:J,��8���L2�h�Wc끣��+B��bj�Ͷ��ێ�!s�8�4d`��ͦR�l�A�@�sl4L�˷eS{��X�F�	`��Vb��j4���v@�8���y�c�����XS��C"��A��Q���Z|��<�1,,�{�/:#1@�*?��@���6՘�m`���8 �U��Tc��rHC����8¯1���Fe�      �   �   x�M��n�0�k�)�G�������EH��l`u�����H���pM���~3��}Z�#�y�Ȟl�J���EY�z���0� �Yy���bސ���Q��򬫲�F��l��+t��4���;��xOR�ѐ�8h+��s�>r�V��h d*҄��=���X�ぷ8���`���k����ڍ>��<���W��x��G���R�;]ϿV�%z<�[�|���s���\�         �   x�]�K��0е�#�H���瘲C�*�ȣ�a%!aeɕ>�-�4w�ţ1)k��N	�Cn��/҇�}�I���x�$�[�M�t�T#��^9�b}̍:N�N��Y�G����S���P&�ˈr�6JI�H4j�M:2x�M��P�Ȫ�j6[�a���E�T��I�H�J�����p���
�q�ie��3���	�E�Hݴ#�a4�?>� ����#1c�      �   �   x���Aj�0E��)|�Y�M�m���I@M!����Y#)��&g�ŪB�d�����̗\���s^�:��m4�rM=�x���r	-�BFV�E�`��`�������N�.4�D�y����HX���գ�셏\�� #r�,���M\V���l�I�_�}��5N_�'=��y|�.��6�(��}߬jcO[�.HV9d�}b�:����U�W���D�^i1���~,��4�@��oku�Z9<E���э      �   \   x�E�K� E�q�#��{qR�"!��Q��{�j����伧��{S.T�$�t�=l�]���ۡ�!�,k���PO@��#z\D| NW#�         �   x�m�A
AD�u�U�*�z�Ō���SZ�i]�i��>C['3X|��,0�u�B`�6����mM+�,�����}u6�u�i����i!0�u��R`붦��;V�����[O���mL��ۜ�3X�5�f�ع�������f�n=�3X�1-f�nsZ
�`�ִ��b��{�7e��#         �  x�m�Kr� ���U:�;r������XN4�]�E�_��v�[��>�n{�����������Tʧ�����-���O���Aw�S)7���yX�S)���D��Tʧ���#R��K)���=��Tʧ��Ǹ�1�rDOn��+�T��/��8�X�Tʱ�1�'�I��!��`���O�~EZ�?�rԧ������R��ɭ��?�r�C���{�7���/y�sޗT�1���,U�gH�1���5��9���c��-p���cw��O�ߥ���wD�y��c�-�r>�R��$醙�_��#rkR�T��_�~Š�}\J9�����#_rk�~6��o�x���H��T�1����r������<�R�|���땯K���M{�߫�.�'��ٶ��i>f         $  x�e�K�� @�q��:F�6ң��:Z$x�|�@��������G{�&����ix���+�6��Zc:�]��De�&$%�I!=]e�S 
1�Cb��<�V�����3�+s��%9)��u��s�\�!
1�C�r�E!rC:d@��U�G��|E���$#9)�"3�
(��!����>$�/3'i!}��͜lo͜l�eN亲I�MBR���=#�{Q�A�9�H��zoH�H�䠪�Z�ܯ��$#9)j�@�����8��d�.ѓ�O6��}�S�I�{��?}�������h5�
(��!���_9٥C�rrP�z��ع��=����e��+Iw��D!qH�W�}��!2 u�T�=7ԊV99HIFrR���sf@��16o��ǘ�y�����>9��κ�ht���������R��_9�E!qH�*���bݐ�y��)g=�1�&5�>����e��0��ݪ�@b��Ͳ�O��>٥Cd�>w�J�O�EVNR���E��.���Cb���<������      �   �   x�M���0��هq�(?��em+�N��B}~+�[�ɗ�=����1�*L�w��/�9��	A8Uf#����^Lɵ]��E���ˣ��\���|��
�e=HN�nHQ�¯H���\/~̀u��99�#;/�����J	�k�Z�ds-�/D�n�G�     