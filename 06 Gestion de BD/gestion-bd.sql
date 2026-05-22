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
VALUES ('Paul Caihuara')


-- listar datos tabla
select * from personas


-- eliminar tabla
DROP TABLE personas


-- vaciar tabla
TRUNCATE TABLE personas

-- insertar varios items
-- insertar un un item
INSERT INTO personas 
(nombre_persona)
VALUES 
('Paul Caihuara'),
('Paul Caba'),
('Pedro domingo')


-- conectarse a La consola de psql

#docker conectar, ingresar al docker
docker exec -it my-database bash

#dentro del docker contectar al motor bd
psql -U alumno -d course-db


#si pide contraseña
PGPASSWORD=123456 psql -U alumno -d course-db



#cambiarnos a otra bd
\c bd_usuarios alumno

# select
select * from personas


-- listar base de datos
\l

-- listar usuarios
\du

-- describe tablas de la BD actual
\dt

-- lista esquemas de la BD actual
\dn

-- salir
\q