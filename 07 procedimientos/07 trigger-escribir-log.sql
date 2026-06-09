-- Función para escribir fichero
CREATE OR REPLACE FUNCTION escribir_log(p_texto TEXT)
RETURNS VOID
LANGUAGE plpython3u
AS $$
import datetime

ruta = '/tmp/actualizacion_personas.log'

try:
    with open(ruta, 'a') as f:
        f.write(p_texto + '\n')
except Exception as e:
    plpy.error('Error escribir log: ' + str(e))
$$;


-- trigger para armar texto y llamar al metood para escribir fichero con el texto que se le pase por parametro
CREATE OR REPLACE FUNCTION trigger_log_actualizar_nombre()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id TEXT;
    v_linea TEXT;
BEGIN
    -- Solo si cambió el nombre
    IF OLD.nombre IS DISTINCT FROM NEW.nombre THEN
        
        -- Obtener user_id de sesión (o 'desconocido')
        BEGIN
            v_user_id := current_setting('app.user_id', TRUE);
        EXCEPTION WHEN OTHERS THEN
            v_user_id := 'desconocido';
        END;
        
        -- Armar línea del log
        v_linea := NOW()::TEXT || ' | user_id:' || v_user_id 
                   || ' | persona_id:' || OLD.persona_id 
                   || ' | antiguo_nombre:' || OLD.nombre 
                   || ' | nuevo_nombre:' || NEW.nombre;
        
        -- Escribir en archivo
        PERFORM escribir_log(v_linea);
        
        RAISE NOTICE 'Log guardado: %', v_linea;
    END IF;
    
    RETURN NEW;
END;
$$;



-- Crear trigguer
DROP TRIGGER IF EXISTS tr_log_actualizar_nombre ON personas;

CREATE TRIGGER tr_log_actualizar_nombre
BEFORE UPDATE ON personas
FOR EACH ROW
EXECUTE FUNCTION trigger_log_actualizar_nombre();


-- Setear user_id para simular session
SET app.user_id = '123';

-- Probamos
-- Actualizar nombre
UPDATE personas 
SET nombre = 'JuanK' 
WHERE persona_id = 1;


-- Verificamos que se este escribiendo el fichero: /tmp/actualizacion_personas.log


