-- =====================================================
-- 1. CREACIÓN DE TABLAS
-- =====================================================

-- SALAS: Lugares físicos del hospital
CREATE TABLE salas (
    sala_id     SERIAL PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL,
    piso        INT NOT NULL
);

-- MEDICOS: Personal médico
CREATE TABLE medicos (
    medico_id   SERIAL PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL,
    especialidad VARCHAR(50) NOT NULL,
    telefono    VARCHAR(20),
    sala_id     INT REFERENCES salas(sala_id)
);

-- PACIENTES: Personas que se atienden
CREATE TABLE pacientes (
    paciente_id SERIAL PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL,
    edad        INT,
    telefono    VARCHAR(20),
    obra_social VARCHAR(30)   -- NULL = particular, 'OSDE', 'PAMI', etc.
);

-- CITAS: Relación entre pacientes, médicos y salas
CREATE TABLE citas (
    cita_id     SERIAL PRIMARY KEY,
    paciente_id INT REFERENCES pacientes(paciente_id),
    medico_id   INT NOT NULL REFERENCES medicos(medico_id),
    sala_id     INT NOT NULL REFERENCES salas(sala_id),
    fecha       DATE NOT NULL,
    hora        TIME NOT NULL,
    motivo      VARCHAR(100),
    atendido    BOOLEAN DEFAULT FALSE
);

-- =====================================================
-- 2. INSERTS DE DATOS
-- =====================================================

-- 2.1 SALAS (4 salas en distintos pisos)
INSERT INTO salas (nombre, piso) VALUES
('Consultorio 101', 1),
('Consultorio 102', 1),
('Quirofano A', 2),
('Quirofano B', 2);

-- 2.2 MEDICOS (5 médicos, cada uno en una sala)
INSERT INTO medicos (nombre, especialidad, telefono, sala_id) VALUES
('Dr. García', 'Cardiología', '011-4444-1111', 1),
('Dra. López', 'Pediatría', '011-4444-2222', 2),
('Dr. Ruiz', 'Cirugía General', '011-4444-3333', 3),
('Dra. Martínez', 'Dermatología', '011-4444-4444', 1),
('Dr. Fernández', 'Traumatología', '011-4444-5555', 4);

-- 2.3 PACIENTES (6 pacientes, uno sin obra social)
INSERT INTO pacientes (nombre, edad, telefono, obra_social) VALUES
('Roberto Gómez', 65, '15-2345-6789', 'OSDE'),
('María López', 34, '15-8765-4321', 'PAMI'),
('Carlos Ruiz', 28, '15-1111-2222', NULL),        -- Particular
('Ana Martínez', 45, '15-3333-4444', 'OSDE'),
('Lucía Fernández', 8, '15-5555-6666', 'PAMI'),
('Pedro Sánchez', 52, '15-7777-8888', 'OSDE');

-- 2.4 CITAS (8 citas: algunas atendidas, otras no, un paciente sin cita)
INSERT INTO citas (paciente_id, medico_id, sala_id, fecha, hora, motivo, atendido) VALUES
(1, 1, 1, '2026-05-05', '09:00', 'Control cardiaco', TRUE),      -- Roberto con García
(1, 1, 1, '2026-05-12', '09:00', 'Seguimiento cardiaco', FALSE),  -- Roberto segunda cita
(2, 2, 2, '2026-05-05', '10:30', 'Fiebre persistente', TRUE),       -- María con López
(3, 3, 3, '2026-05-06', '08:00', 'Apendicitis', TRUE),             -- Carlos con Ruiz
(4, 4, 1, '2026-05-07', '11:00', 'Revisión de mancha', FALSE),    -- Ana con Martínez
(5, 2, 2, '2026-05-07', '10:00', 'Control pediátrico', FALSE),     -- Lucía con López
(2, 1, 1, '2026-05-08', '09:30', 'Dolor en el pecho', FALSE),      -- María segunda cita
(6, 5, 4, '2026-05-08', '14:00', 'Esguince de tobillo', FALSE);    -- Pedro con Fernández