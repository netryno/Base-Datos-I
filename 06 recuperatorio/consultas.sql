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
)

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