-- 1.- Gestion de BAse de datos
-- Crear BD
create database bd_prueba

-- Elimiar BD
drop database bd_prueba

-- Para evitar errores
drop database IF EXISTS bd_prueba

-- 2.- Gestion de tablas
CREATE TABLE personas (
	id SERIAL PRIMARY KEY,
	nombre VARCHAR(50) NOT NULL
);

DROP TABLE personas;

-- insertar
INSERT INTO  personas(nombre)
VALUES
('Juan Perez'),
('Pedro Aguilar'),
('Anabel Gutierrez');

--listar
select * from personas


-- vaciar
TRUNCATE TABLE personas


-- 3.- Gestion DOCKER
docker ps

-- lista detalles del contenedor

-- contectar al contenedor
docker exec -it my-database bash 

-- conectar al bd postgres desde la consola de linux docker
psql -U alumno -d bd_prueba

-- Una vez conectado pode temos sentescia sql
select * from personas;

TRUNCATE TABLE personas;
DROP TABLE personas;

DROP DATABASE bd_prueba;

-- comando especiales
-- listar base de datos
\l 

-- listar usuario
\du

-- switch entre base de datos
\c


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


-- 5.- Gestion USUARIOS
CREATE ROLE "paul" WITH LOGIN PASSWORD '123456';

-- asignar privilegios
ALTER ROLE "paul" SUPERUSER;

-- revocar privilegios
ALTER ROLE "paul" NOLOGIN;

--Desde otra consola usando este user paul, nos conectamos
psql -U paul -d bd_prueba


-- Eliminar usuario definita
REASSIGN OWNED BY "paul" TO "alumno";
DROP OWNED BY "paul";
DROP ROLE "paul";


-- usuario con limitacion a una tabla
-- asignar al esquema (public)
GRANT USAGE ON SCHEMA public TO "paul";

GRANT SELECT ON TABLE persona_idiomas TO "paul";

-- no lo probamos, pero sirve para que pueda hacer actualizaciones
GRANT UPDATE ON TABLE persona_idiomas TO "paul";


-- no hemos ejecutado
REVOKE ALL PRIVILEGES ON TABLE personas FROM "paul"


-- .-6 USUARIO DE SOlO LECTURA DE COLUMNAS
CREATE ROLE "pepe" WITH LOGIN PASSWORD '654321';
GRANT USAGE ON SCHEMA public TO "pepe";
GRANT SELECT(idioma_nombre,persona_id) ON TABLE persona_idiomas TO "pepe";


-- desde la consola de mi SO, al docker, del docker al motor BD
docker exec -it my-database bash 
psql -U pepe -d bd_prueba



GRANT SELECT ON TABLE persona_idiomas TO "pepe";