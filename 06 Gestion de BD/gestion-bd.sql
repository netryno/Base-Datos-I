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
