
-------******************************************* 
--5.-  **************** notificaciones ************
--  Al registrar un viaje, enviar notificación a Telegram con los datos del viaje.


-- Para enviar mensaje telegram, entrar @bootfather, crear boot: @bd_ucb_bot
-- Copiamos token
-- Entramos al boot creado y escribimos hola o algo, 
-- Probamos con esto para obtener el chatid
-- https://api.telegram.org/bot8993408551:AAEM5MO29C7CUP1g_9PBHMEkxbPMgbJWBS8/getUpdates

-- 152318263

-- probar envio de mensaje:
-- https://api.telegram.org/bot8993408551:AAEM5MO29C7CUP1g_9PBHMEkxbPMgbJWBS8/sendMessage?chat_id=152318263&text=Hola+desde+la+base+de+datos



    /*
    # Entrar al contenedor
    docker exec -it my-database bash

    # Instalar Python y la extensión
    apt-get update
    apt-get install -y postgresql-plpython3-17 python3

    # Salir
    exit
    */

--  Paso 1: Instalar extensión Python (una sola vez)
-- probar python 
CREATE EXTENSION IF NOT EXISTS plpython3u;
--verificar
SELECT * FROM pg_available_extensions WHERE name LIKE '%python%';



-- Paso 2: Tabla de configuración (chat_id en sesión)
CREATE TABLE IF NOT EXISTS config_notificaciones (
    clave VARCHAR(50) PRIMARY KEY,
    valor TEXT NOT NULL
);

-- Insertar tu token de bot de Telegram (obtenido de @BotFather)
INSERT INTO config_notificaciones (clave, valor) 
VALUES ('telegram_bot_token', '8993408551:AAEM5MO29C7CUP1g_9PBHMEkxbPMgbJWBS8');


INSERT INTO config_notificaciones (clave, valor) 
VALUES ('telegram_bot_token', '8993408551:AAEM5MO29C7CUP1g_9PBHMEkxbPMgbJWBS8')
ON CONFLICT (clave) DO UPDATE SET valor = EXCLUDED.valor;


-- Paso 3: Función que envía mensaje  a Telegram
CREATE OR REPLACE FUNCTION enviar_telegram_real(p_chat_id TEXT, p_mensaje TEXT)
RETURNS TEXT
LANGUAGE plpython3u
AS $$
import urllib.request
import urllib.parse

# Obtener token de la tabla
plan = plpy.prepare("SELECT valor FROM config_notificaciones WHERE clave = 'telegram_bot_token'")
result = plpy.execute(plan)

if len(result) == 0:
    plpy.error('Token no encontrado')
    
token = result[0]['valor']

# Construir URL
url = f"https://api.telegram.org/bot{token}/sendMessage"
data = urllib.parse.urlencode({
    'chat_id': p_chat_id,
    'text': p_mensaje
}).encode()

try:
    req = urllib.request.Request(url, data=data, method='POST')
    response = urllib.request.urlopen(req, timeout=10)
    return response.read().decode('utf-8')
except Exception as e:
    plpy.error(f'Error Telegram: {str(e)}')
    return f'Error: {str(e)}'
$$;


-- Paso 4: Función trigger que llama al envío
CREATE OR REPLACE FUNCTION trigger_notificar_viaje_telegram()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_nombre VARCHAR(50);
    v_pais VARCHAR(60);
    v_chat_id TEXT;
    v_mensaje TEXT;
BEGIN
    -- Obtener nombre de persona
    SELECT nombre INTO v_nombre 
    FROM personas 
    WHERE persona_id = NEW.persona_id;
    
    -- Obtener nombre de país
    SELECT pais_nombre INTO v_pais 
    FROM paises 
    WHERE pais_id = NEW.pais_id;
    
    -- Obtener chat_id de variable de sesión (seteada antes)
    BEGIN
        v_chat_id := current_setting('app.telegram_chat_id', TRUE);
    EXCEPTION WHEN OTHERS THEN
        v_chat_id := NULL;
    END;
    
    -- Si no hay chat_id, solo loguear
    IF v_chat_id IS NULL OR v_chat_id = '' THEN
        RAISE NOTICE '⚠️ No hay chat_id configurado. Viaje registrado sin notificación.';
        RETURN NEW;
    END IF;
    
    -- Preparar mensaje
    v_mensaje := '✈️ NUEVO VIAJE' || E'\n' ||
                 '👤 ' || v_nombre || E'\n' ||
                 '🌍 ' || v_pais || E'\n' ||
                 '📅 ' || NEW.fecha_llegada;
    
    -- Enviar a Telegram
    PERFORM enviar_telegram_real(v_chat_id, v_mensaje);
    
    RETURN NEW;
END;
$$;


-- Paso 5: Crear el trigger

DROP TRIGGER IF EXISTS tr_notificar_viaje ON viajes;

CREATE TRIGGER tr_notificar_viaje
AFTER INSERT ON viajes
FOR EACH ROW
EXECUTE FUNCTION trigger_notificar_viaje_telegram();




-- SQL para probar
SET app.telegram_chat_id = '152318263';


INSERT INTO viajes (persona_id, pais_id, fecha_llegada)
VALUES (1, 22, '2025-12-25');




