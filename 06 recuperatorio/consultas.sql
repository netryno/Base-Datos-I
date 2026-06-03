-- Apuntes de clase recuperatorio
-- Sabado 08am a 10am - 23-05-2026

-------************************************************************
-- 1.- **************** Gestion de Base de datos ****************

-- Crear BD (desde pgadmin)
create database bd_prueba

-- Elimiar BD (desde pgadmin)
drop database bd_prueba

-- Para evitar errores, uso de IF EXISTS (desde pgadmin)
drop database IF EXISTS bd_prueba


-------************************************************************
-- 2.- **************** Gestion de tablas ****************

-- Estructura de sql para crear tabla
CREATE TABLE personas (
	id SERIAL PRIMARY KEY,
	nombre VARCHAR(50) NOT NULL
);

-- Eliminar tabla
DROP TABLE personas;

-- Estructura de sql para insertar datos
INSERT INTO  personas(nombre)
VALUES
('Juan Perez'),
('Pedro Aguilar'),
('Anabel Gutierrez');

--Listar datos de la tabla
select * from personas

-- Vaciar tabla, pero no eliminarla
TRUNCATE TABLE personas


-------************************************************************
-- 3.- **************** Gestion de contenedores ****************

-- Listar contenedores activos
docker ps

-- Conectar al contenedor de la base de datos, via terminal
-- Es decir, desde nuestro equipo local al contenedor de la base de datos
docker exec -it my-database bash 

-- Luego de conectarnos al contenedor, podemos conectarnos a la base de datos, usando el cliente psql
-- desde la terminal del contenedor al motor de base de datos
psql -U alumno -d bd_prueba

-- Una vez dentro del cliente psql, podemos ejecutar comandos SQL, 
-- como listar tablas, insertar datos, etc.
select * from personas;

-- Desde la terminal conectado, podemos ejecutar sentencias SQL,Por ejemplo:
-- Vaciar tabla
TRUNCATE TABLE personas;

-- Eliminar tabla
DROP TABLE personas;

-- Eliminar base de datos
DROP DATABASE bd_prueba;

-- Comandos útiles del cliente psql:
-- listar bases de datos
\l 

-- listar usuarios
\du

-- Switch entre bases de datos del servidor,
-- es decir, cambiar de base de datos sin salir del cliente psql
\c

-- Para salir del cliente psql, usamos el comando \q
\q

-- Revisar documentación oficial de psql para más comandos útiles:
-- https://www.postgresql.org/docs/current/app-psql.html

-------************************************************************
-- 4.- **************** Comandos SQL desde el cliente psql (terminal) ********

--- Crear table alternativa
CREATE TABLE persona_idiomas(
    id SERIAL PRIMARY KEY,
    idioma_nombre VARCHAR(50) NOT NULL,
    nivel VARCHAR(30) NOT NULL,
    persona_id INT,

    CONSTRAINT fk_personas
    FOREIGN KEY (persona_id)
    REFERENCES personas(id)
    ON DELETE CASCADE
);

--- insertar informacion alternativa
INSERT INTO  persona_idiomas(idioma_nombre,nivel, persona_id)
VALUES
('Español', 'Avanzando', 1),
('Ingles', 'Basico', 1),
('Ingles', 'Nativo', 2),
('Frances', 'Avanzado', 3);


-------************************************************************
-- 5.- **************** Gestion de Usuarios ****************

-- Estos comandos ejecutamos desde el cliente psql, 
-- conectado al motor de base de datos (terminal), no desde pgadmin.
-- Registrar un nuevo usuario
CREATE ROLE "paul" WITH LOGIN PASSWORD '123456';

-- Asignar privilegios, en siguiente linea, asignamos privilegio de superusuario
ALTER ROLE "paul" SUPERUSER;

-- Revocar privilegios, en siguiente linea, revocamos privilegio de login
ALTER ROLE "paul" NOLOGIN;

--Desde otra consola, intentamos conectarnos usando  user paul (para verifiar)
psql -U paul -d bd_prueba


-- Eliminar usuario, para eliminar un usuario, 
-- primero debemos revocar todos los privilegios que tiene, 
-- y luego eliminarlo. 
REASSIGN OWNED BY "paul" TO "alumno";
DROP OWNED BY "paul";
DROP ROLE "paul";


-------************************************************************
-- 7.- **************** Permisos: limitando a solo tablas *********
-- Configuración de privilegios para un usuario específico, 
-- para que pueda acceder a ciertas tablas, pero no a otras.

-- Primero: asignar al esquema (public)
GRANT USAGE ON SCHEMA public TO "paul";

-- Segundo: asignar privilegios a tablas específicas, 
--en este caso, solo puede seleccionar datos de la tabla persona_idiomas, 
-- pero no de la tabla personas.
GRANT SELECT ON TABLE persona_idiomas TO "paul";

-- Tercero: quitamos acceso a otras tablas. 
REVOKE ALL PRIVILEGES ON TABLE personas FROM "paul"


-- Cuarto: (opcional) 
-- asignar privilegios de actualización a la tabla persona_idiomas,
GRANT UPDATE ON TABLE persona_idiomas TO "paul";


-------************************************************************
-- 7.- **************** Permisos: limitando a columnas ****************

-- USUARIO DE SOlO LECTURA DE COLUMNAS
-- Creamos otro usuario
CREATE ROLE "pepe" WITH LOGIN PASSWORD '654321';
-- Asignamos a la eschema public
GRANT USAGE ON SCHEMA public TO "pepe";
-- Asignamos privilegios a columnas específicas
GRANT SELECT(idioma_nombre,persona_id) ON TABLE persona_idiomas TO "pepe";


-- Desde otra consola, nos conecatamos. con usuario pepe
docker exec -it my-database bash 
psql -U pepe -d bd_prueba

-- Desde la consola conectada con pepe, intentamos seleccionar datos de la tabla persona_idiomas, 
-- pero no retorna nada, ya que el usuario pepe solo tiene acceso a las columnas especificadas.
SELECT * FROM persona_idiomas;

-- Y siguiente consulta si funciona, ya que el usuario pepe tiene acceso a las columnas idioma_nombre y persona_id
SELECT idioma_nombre, persona_id FROM persona_idiomas;


-- Una vez probado, restauramos su acceso a todas las columnas de la tabla persona_idiomas, 
-- para que pueda seleccionar todas las columnas.
GRANT SELECT ON TABLE persona_idiomas TO "pepe";