-- Enviar notificacion por correo 

-- Para ello usaremos protocolo smpt:
/*
Paso 1: Activar verificación en 2 pasos
    Ve a https://myaccount.google.com/security
    Activa "Verificación en dos pasos"
Paso 2: Crear contraseña de aplicación
    Ve a https://myaccount.google.com/apppasswords
    Selecciona app: "Correo"
    Selecciona dispositivo: "Otro" → escribe "PostgreSQL"
    Copia la contraseña generada 
*/


-- Paso 1: Función para enviar email

CREATE OR REPLACE FUNCTION enviar_email(
    p_destino TEXT,
    p_asunto TEXT,
    p_mensaje TEXT
)
RETURNS TEXT
LANGUAGE plpython3u
AS $$
import smtplib
from email.mime.text import MIMEText

SMTP_SERVER = 'smtp.gmail.com'
SMTP_PORT = 587
SMTP_USER = 'paulcaihuara@gmail.com'
SMTP_PASS = 'aqui-copiar-contraseña-app' 

try:
    msg = MIMEText(p_mensaje)
    msg['Subject'] = p_asunto
    msg['From'] = SMTP_USER
    msg['To'] = p_destino

    server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
    server.starttls()
    server.login(SMTP_USER, SMTP_PASS)
    server.sendmail(SMTP_USER, p_destino, msg.as_string())
    server.quit()

    return 'Email enviado a ' + p_destino

except Exception as e:
    plpy.error('Error email: ' + str(e))
    return 'Error'
$$;


--- corroboramos que este enviando mensaje, el metodo:
SELECT enviar_email('pcaihuara@ucb.edu.bo', 'Prueba', 'Hola desde PostgreSQL');

-- verificamos que se haya enviado correo a: pcaihuara@ucb.edu.bo
-- Si todo ok, ya podemos crear la funcion trigger

-- Paso 2: Trigger que envía email al registrar viaje

CREATE OR REPLACE FUNCTION trigger_notificar_viaje_email()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_nombre VARCHAR(50);
    v_pais VARCHAR(60);
    v_email TEXT;
    v_mensaje TEXT;
BEGIN
    -- Obtener datos
    SELECT nombre INTO v_nombre 
    FROM personas 
    WHERE persona_id = NEW.persona_id;
    
    SELECT pais_nombre INTO v_pais 
    FROM paises 
    WHERE pais_id = NEW.pais_id;
    
    -- Email de sesión o de tabla personas
    BEGIN
        v_email := current_setting('app.email_destino', TRUE);
    EXCEPTION WHEN OTHERS THEN
        v_email := NULL;
    END;
    
    -- Si no hay email, no enviar
    IF v_email IS NULL OR v_email = '' THEN
        RAISE NOTICE '⚠️ No hay email configurado';
        RETURN NEW;
    END IF;
    
    -- Preparar mensaje
    v_mensaje := 'Nuevo viaje registrado:' || E'\n' ||
                 'Persona: ' || v_nombre || E'\n' ||
                 'Destino: ' || v_pais || E'\n' ||
                 'Fecha: ' ||  NEW.fecha_llegada || E'\n' ||
                 'By: Paul Caihuara' ;
    
    -- Enviar email
    PERFORM enviar_email(v_email, 'Nuevo Viaje Registrado', v_mensaje);
    
    RETURN NEW;
END;
$$;


-- Creamos trigger
DROP TRIGGER IF EXISTS tr_notificar_viaje_email ON viajes;

CREATE TRIGGER tr_notificar_viaje_email
AFTER INSERT ON viajes
FOR EACH ROW
EXECUTE FUNCTION trigger_notificar_viaje_email();


-- probar
-- Setear email destino
SET app.email_destino = 'pcaihuara@ucb.edu.bo';

-- Insertar viaje (dispara email automático)
INSERT INTO viajes (persona_id, pais_id, fecha_llegada)
VALUES (1, 21, '2025-12-25');




