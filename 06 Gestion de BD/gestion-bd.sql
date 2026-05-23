-- 1.- ************** Gestion Base de datos **************
-- Crear BD
create database bd_usuarios;

-- Eliminar BD
drop database bd_usuarios;

-- Eliminar de forma segura
DROP DATABASE IF EXISTS bd_usuarios;


-- 2.- ************** Gestion Tablas **************
---  Crear tablas
CREATE TABLE personas (
	id SERIAL PRIMARY KEY,
	nombre_persona VARCHAR(50) NOT NULL
);


-- insertar un un item
INSERT INTO personas (nombre_persona)
VALUES ('Javier Mendez');


-- listar datos tabla
select * from personas;


-- eliminar tabla
DROP TABLE personas;


-- vaciar tabla
TRUNCATE TABLE personas;

-- insertar varios items
-- insertar un un item
INSERT INTO personas 
(nombre_persona)
VALUES 
('Javier Mendez'),
('Paul Caihuara'),
('Pedro domingo');




-- 3.- ************** Gestion docker **************
-- conectarse a La consola de psql
--docker conectar, ingresar al docker
docker exec -it my-database bash

--dentro del docker contectar al motor bd
psql -U alumno -d bd_usuarios

psql -U alumno -d course-db

--si pide contraseña
PGPASSWORD=123456 psql -U alumno -d course-db

--cambiarnos a otra bd
\c bd_usuarios alumno

-- select
select * from personas;


-- listar base de datos
\l

-- listar usuarios
\du

-- describe tablas de la BD actual
\dt

-- lista esquemas de la BD actual
\dn

--ayuda / docs
\?

-- salir
\q


-- 4.- Roles y permisos
-- crear usuario
CREATE ROLE "paul" WITH LOGIN PASSWORD '123456';

-- asignar rol
ALTER ROLE "paul" SUPERUSER;

--probar conexion (desde el docker)
psql -U paul -d bd_usuarios


-- quitar acceso
ALTER ROLE "paul" NOLOGIN;

-- volver a dar acceso
ALTER ROLE "paul" LOGIN;


-- para quitar definitivo
REASSIGN OWNED BY "paul" TO alumno;
DROP OWNED BY "paul";
-- Ahora sí te dejará borrarlo:
DROP ROLE "paul";




--- crear otras tablas para inner join 
CREATE TABLE persona_idiomas (
	id SERIAL PRIMARY KEY,
	nombre VARCHAR(50) NOT NULL,
	nivel VARCHAR(20) NOT NULL,
	personas_id INT,

    CONSTRAINT fk_personas 
        FOREIGN KEY (personas_id) 
        REFERENCES personas(id) 
        ON DELETE CASCADE
);


-- insertar un un item
INSERT INTO persona_idiomas 
(nombre, nivel, personas_id)
VALUES 
('Ingles','Avanzado', 1),
('Aleman','Basico', 1),
('Frances','Intermedio',2),
('Frances','Basico',3);



--5.- usuario a una sola tabla
-- esquema publico ok
GRANT USAGE ON SCHEMA public TO "paul";

-- select unicamente a tabla idiomas
GRANT SELECT ON TABLE persona_idiomas TO "paul";

-- por si quitamos otros permisos
REVOKE ALL PRIVILEGES ON TABLE personas FROM "paul";

REVOKE SELECT (nivel) ON TABLE persona_idiomas FROM "paul";

-- Verificar haciendo select ambas tablas
select * from personas;
select * from persona_idiomas;

-- si en futuro se requiere que se haga update
GRANT UPDATE ON TABLE persona_idiomas TO "paul";




--5.- usuario a una sola tabla ademas solo ciertas filas

--listar
-- ok
SELECT nombre, personas_id FROM persona_idiomas; 
SELECT * FROM  persona_idiomas; 





-- para quitar definitivo
REASSIGN OWNED BY "paul" TO alumno;
DROP OWNED BY "paul";
DROP ROLE "paul";


-- crear usuario
CREATE ROLE "paul" WITH LOGIN PASSWORD '123456';

REVOKE SELECT ON TABLE persona_idiomas FROM PUBLIC;
REVOKE SELECT ON TABLE personas FROM PUBLIC;

GRANT USAGE ON SCHEMA public TO "paul";


GRANT SELECT ON TABLE persona_idiomas TO "paul";
GRANT SELECT ( nombre, personas_id) ON TABLE persona_idiomas TO "paul";



SELECT nombre, personas_id FROM persona_idiomas; 


--REVOKE SELECT ON TABLE persona_idiomas FROM PUBLIC;


--REVOKE SELECT (nivel) ON TABLE persona_idiomas FROM "paul";

-- Verificar haciendo select ambas tablas
select * from personas;
select * from persona_idiomas;


--probar conexion (desde el docker)
psql -U paul -d bd_usuarios


-- quitar acceso
ALTER ROLE "paul" NOLOGIN;

-- volver a dar acceso
ALTER ROLE "paul" LOGIN;