
-------*******************************************
--1.-  **************** FUNCIONES ****************

-- Creamos la funcion
CREATE OR REPLACE FUNCTION trigger_hola_persona()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'Nueva persona registrada: %', NEW.nombre;
    RETURN NEW;  -- Siempre retornar NEW en BEFORE INSERT
END;
$$;


--Creamos el trigguer
CREATE TRIGGER tr_hola_persona
AFTER INSERT ON personas
FOR EACH ROW
EXECUTE FUNCTION trigger_hola_persona();


-- Probamos insert
INSERT INTO personas (nombre, primer_apellido, segundo_apellido, ci)
VALUES ('Fernando', 'Torres', NULL, '9988776');


-- Eliminar trigger
DROP TRIGGER IF EXISTS tr_hola_persona ON personas;

-- Eliminar función trigger
DROP FUNCTION IF EXISTS trigger_hola_persona();


-------******************************************* 
--2.-  **************** BEFORE ****************
--Antes de insertar un viaje, si la persona ya viajó a ese país, bloquear la inserción.
CREATE OR REPLACE FUNCTION trigger_validar_viaje()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_existe INT;
BEGIN
    SELECT COUNT(*) INTO v_existe
    FROM viajes
    WHERE persona_id = NEW.persona_id
      AND pais_id = NEW.pais_id;
    
    IF v_existe > 0 THEN
        RAISE EXCEPTION 'REINCIDENTE: Esta persona ya viajó a este país';
    END IF;
    
    RETURN NEW;  -- Permite la inserción
END;
$$;


--Crear trigger
CREATE TRIGGER tr_validar_viaje
BEFORE INSERT ON viajes
FOR EACH ROW
EXECUTE FUNCTION trigger_validar_viaje();


--Probar
INSERT INTO viajes (persona_id, pais_id, fecha_llegada)
VALUES (1, 21, '2025-12-25');



-------******************************************* 
--3.-  **************** AFTER ****************
--Cada vez que se elimina un viaje, guardar en un log quién y cuándo fue.


--Creamos tabla auditoria
CREATE TABLE auditoria_viajes (
    log_id SERIAL PRIMARY KEY,
    accion VARCHAR(10),
    viaje_id INT,
    persona_id INT,
    pais_id INT,
    fecha_eliminacion TIMESTAMP DEFAULT NOW()
);


--Creamos funciona para registrar auditoria
CREATE OR REPLACE FUNCTION trigger_auditar_eliminacion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO auditoria_viajes (accion, viaje_id, persona_id, pais_id)
    VALUES ('DELETE', OLD.viaje_id, OLD.persona_id, OLD.pais_id);
    RAISE EXCEPTION 'Se registro log de auditoria';
    RETURN OLD;
END;
$$;


--Creamos trigger
CREATE TRIGGER tr_auditar_eliminacion
AFTER DELETE ON viajes
FOR EACH ROW
EXECUTE FUNCTION trigger_auditar_eliminacion();

-- Verificamos
-- Eliminar un viaje
DELETE FROM viajes WHERE viaje_id = 1;

-- Ver auditoría
SELECT * FROM auditoria_viajes;





-------******************************************* 
--4.-  **************** LLAMAR PROCEDIMIENTO *****

CREATE OR REPLACE PROCEDURE notificar_viaje(
    p_persona_id INT,
    p_pais_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_nombre VARCHAR(50);
    v_pais VARCHAR(60);
    v_total_viajes INT;
BEGIN
    -- Datos de la persona
    SELECT nombre INTO v_nombre 
    FROM personas 
    WHERE persona_id = p_persona_id;
    
    -- Datos del país
    SELECT pais_nombre INTO v_pais 
    FROM paises 
    WHERE pais_id = p_pais_id;
    
    -- Contar viajes totales de esa persona
    SELECT COUNT(*) INTO v_total_viajes 
    FROM viajes 
    WHERE persona_id = p_persona_id;
    
    -- Notificación
    IF v_total_viajes = 1 THEN
        RAISE NOTICE '🎉 PRIMER VIAJE: % visita % por primera vez', v_nombre, v_pais;
    ELSE
        RAISE NOTICE '✈️ NUEVO VIAJE: % ahora tiene % viajes registrados', v_nombre, v_total_viajes;
    END IF;
    
END;
$$;


-- Llamar procedura desde la funcion
CREATE OR REPLACE FUNCTION trigger_notificar_viaje()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Llamar al procedimiento desde el trigger
    CALL notificar_viaje(NEW.persona_id, NEW.pais_id);
    
    RETURN NEW;
END;
$$;

-- Creamos trigguer
CREATE TRIGGER tr_notificar_viaje
AFTER INSERT ON viajes
FOR EACH ROW
EXECUTE FUNCTION trigger_notificar_viaje();


-- Probamos
-- Primer viaje de Juan (persona_id=1) a Cuba (pais_id=21)
INSERT INTO viajes (persona_id, pais_id, fecha_llegada)
VALUES (1, 21, '2025-12-25');

-- Segundo viaje de Juan a Argentina (pais_id=1)
INSERT INTO viajes (persona_id, pais_id, fecha_llegada)
VALUES (1, 1, '2025-06-15');




-------******************************************* 
--5.-  **************** Log auditoria ************
-- Se requiere en la tabla personas añadir 2 columnas de auditoria
-- fecha registro de persona y fecha actualizacion de persona.


--  Paso 1: ALTER TABLE (añadir columnas)
ALTER TABLE personas
ADD COLUMN fecha_registro TIMESTAMP DEFAULT NOW(),
ADD COLUMN fecha_update TIMESTAMP,
ADD COLUMN creator_user_id INT,
ADD COLUMN updater_user_id INT;


-- Paso 2: Función trigger con variables de sesión
CREATE OR REPLACE FUNCTION trigger_actualizar_fechas_usuario()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_user_id INT;
BEGIN
    -- Leer usuario actual desde variable de sesión (seteada antes)
    v_current_user_id := NULLIF(current_setting('app.current_user_id', TRUE), '')::INT;
    
    -- INSERT: setear creador
    IF TG_OP = 'INSERT' THEN
        NEW.fecha_registro := NOW();
        NEW.creator_user_id := v_current_user_id;
    END IF;
    
    -- UPDATE: setear editor
    IF TG_OP = 'UPDATE' THEN
        NEW.fecha_update := NOW();
        NEW.updater_user_id := v_current_user_id;
    END IF;
    
    RETURN NEW;
END;
$$;


-- Paso 3: Crear trigger
CREATE TRIGGER tr_actualizar_fechas_usuario
BEFORE INSERT OR UPDATE ON personas
FOR EACH ROW
EXECUTE FUNCTION trigger_actualizar_fechas_usuario();


--  Probar INSERT
-- Simular que usuario ID=5 está logueado
SET app.current_user_id = '5';

-- insert
INSERT INTO personas (nombre, primer_apellido, segundo_apellido, ci)
VALUES ('Elena', 'Vargas', NULL, '4433221');

--ver cambios
select * FROM personas;


--  Probar UPDATE
-- Simular que otro usuario ID=8 edita
SET app.current_user_id = '8';

UPDATE personas 
SET nombre = 'Elena María' 
WHERE ci = '4433221';

-- Ver resultado
select * FROM personas;

