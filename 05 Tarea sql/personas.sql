-- =====================================================
-- 1. CREACIÓN DE TABLAS
-- =====================================================

CREATE TABLE personas (
    persona_id          SERIAL PRIMARY KEY,
    nombre              VARCHAR(50) NOT NULL,
    primer_apellido     VARCHAR(50) NOT NULL,
    segundo_apellido    VARCHAR(50),
    ci                  VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE paises (
    pais_id             SERIAL PRIMARY KEY,
    pais_nombre         VARCHAR(60) NOT NULL,
    pais_codigo         CHAR(3) UNIQUE NOT NULL
);

CREATE TABLE persona_idiomas (
    id                  SERIAL PRIMARY KEY,
    persona_id          INT NOT NULL REFERENCES personas(persona_id),
    idioma              VARCHAR(30) NOT NULL,
    nivel               VARCHAR(10) NOT NULL CHECK (nivel IN ('A1','A2','B1','B2','C1','C2','Nativo'))
);

CREATE TABLE viajes (
    viaje_id            SERIAL PRIMARY KEY,
    persona_id          INT NOT NULL REFERENCES personas(persona_id),
    pais_id             INT NOT NULL REFERENCES paises(pais_id),
    fecha_llegada       DATE NOT NULL
);



-- =====================================================
-- 2. INSERTS - PERSONAS (15 personas)
-- =====================================================
INSERT INTO personas (nombre, primer_apellido, segundo_apellido, ci) VALUES
('Juan', 'Perez', 'Gomez', '1234567'),
('Maria', 'Lopez', 'Fernandez', '2345678'),
('Carlos', 'Garcia', 'Martinez', '3456789'),
('Ana', 'Rodriguez', 'Silva', '4567890'),
('Luis', 'Gonzalez', 'Torres', '5678901'),
('Laura', 'Sanchez', 'Ramirez', '6789012'),
('Pedro', 'Flores', 'Morales', '7890123'),
('Carmen', 'Rivera', 'Ortega', '8901234'),
('Diego', 'Castro', 'Vargas', '9012345'),
('Sofia', 'Reyes', 'Cruz', '1123456'),
('Miguel', 'Ortiz', 'Mendoza', '2234567'),
('Valentina', 'Herrera', 'Aguirre', '3345678'),
('Andres', 'Jimenez', 'Paredes', '4456789'),
('Camila', 'Moreno', 'Bravo', '5567890'),
('Jose', 'Ruiz', 'Navarro', '6678901'),
('Ariel', 'Castro', 'Contreraz', '6774904');

-- =====================================================
-- 3. INSERTS - PAISES (20 países)
-- =====================================================
INSERT INTO paises (pais_nombre, pais_codigo) VALUES
('Argentina', 'ARG'),
('Bolivia', 'BOL'),
('Brasil', 'BRA'),
('Chile', 'CHL'),
('Colombia', 'COL'),
('Costa Rica', 'CRI'),
('Ecuador', 'ECU'),
('Espana', 'ESP'),
('Estados Unidos', 'USA'),
('Francia', 'FRA'),
('Italia', 'ITA'),
('Japon', 'JPN'),
('Mexico', 'MEX'),
('Peru', 'PER'),
('Portugal', 'PRT'),
('Reino Unido', 'GBR'),
('Alemania', 'DEU'),
('Australia', 'AUS'),
('Canada', 'CAN'),
('Uruguay', 'URY'),
('Cuba', 'CUB'),
('Venezuela', 'VEN');


-- =====================================================
-- 4. INSERTS - IDIOMAS (15 personas)
-- =====================================================
INSERT INTO persona_idiomas (persona_id, idioma, nivel) VALUES
(1, 'Espanol', 'Nativo'),           -- Juan
(2, 'Espanol', 'Nativo'),           -- Maria
(3, 'Espanol', 'Nativo'),           -- Carlos
(4, 'Espanol', 'Nativo'),           -- Ana
(5, 'Espanol', 'Nativo'),           -- Luis
(6, 'Espanol', 'Nativo'),           -- Laura
(7, 'Espanol', 'Nativo'),           -- Pedro
(8, 'Espanol', 'Nativo'),           -- Carmen
(9, 'Espanol', 'Nativo'),           -- Diego
(10, 'Espanol', 'Nativo'),          -- Sofia
(11, 'Espanol', 'Nativo'),          -- Miguel
(11, 'Ingles', 'C1'),
(12, 'Espanol', 'Nativo'),          -- Valentina
(12, 'Portugues', 'B2'),
(13, 'Espanol', 'Nativo'),          -- Andres
(13, 'Aleman', 'B1'),
(14, 'Espanol', 'Nativo'),          -- Camila
(14, 'Frances', 'B2'),
(15, 'Espanol', 'Nativo'),          -- Jose
(15, 'Ingles', 'C2'),
(15, 'Italiano', 'B1');


-- =====================================================
-- 5. INSERTS - VIAJES (distribución por persona)
-- =====================================================
INSERT INTO viajes (persona_id, pais_id, fecha_llegada) VALUES
(5, 1, '2023-01-15'),   -- Luis -> Argentina
(5, 1, '2024-01-15'),   -- Luis -> Argentina
(7, 3, '2025-04-10'),   -- Pedro -> Brasil
(6, 2, '2022-06-20'),   -- Laura -> Bolivia
(7, 3, '2024-03-10'),   -- Pedro -> Brasil
(8, 4, '2021-11-05'),   -- Carmen -> Chile
(9, 5, '2023-08-12'),   -- Diego -> Colombia
(10, 6, '2020-02-28'),  -- Sofia -> Costa Rica
(11, 7, '2019-07-14'),  -- Miguel -> Ecuador
(11, 8, '2022-09-22'),  -- Miguel -> Espana
(12, 9, '2023-04-18'),  -- Valentina -> USA
(12, 10, '2024-01-30'), -- Valentina -> Francia
(13, 11, '2021-05-25'), -- Andres -> Italia
(13, 12, '2023-10-08'), -- Andres -> Japon
(14, 13, '2018-03-12'), -- Camila -> Mexico
(14, 14, '2020-07-19'), -- Camila -> Peru
(14, 15, '2022-11-03'), -- Camila -> Portugal
(15, 16, '2019-09-15'), -- Jose -> Reino Unido
(15, 17, '2021-06-22'), -- Jose -> Alemania
(15, 18, '2023-02-10'), -- Jose -> Australia
(15, 19, '2024-08-05'), -- Jose -> Canada
(15, 20, '2025-01-20'); -- Jose -> Uruguay


