-- =====================================================
-- 1. CREACIÓN DE TABLAS
-- =====================================================

-- FARMACIAS: Sucursales de la cadena
CREATE TABLE farmacias (
    farmacia_id     SERIAL PRIMARY KEY,
    nombre          VARCHAR(50) NOT NULL,
    direccion       VARCHAR(100),
    telefono        VARCHAR(20)
);

-- CLIENTES: Personas que compran
CREATE TABLE clientes (
    cliente_id      SERIAL PRIMARY KEY,
    nombre          VARCHAR(50) NOT NULL,
    telefono        VARCHAR(20),
    obra_social     VARCHAR(30)   -- NULL = particular, 'OSDE', 'PAMI', etc.
);

-- PRODUCTOS: Medicamentos y artículos
CREATE TABLE productos (
    producto_id     SERIAL PRIMARY KEY,
    nombre          VARCHAR(50) NOT NULL,
    precio          DECIMAL(8,2) NOT NULL,
    stock           INT DEFAULT 0,
    farmacia_id     INT NOT NULL REFERENCES farmacias(farmacia_id)
);

-- VENTAS: Relación entre todo (quién compró qué, dónde y cuándo)
CREATE TABLE ventas (
    venta_id        SERIAL PRIMARY KEY,
    cliente_id      INT REFERENCES clientes(cliente_id),  -- NULL = venta anónima
    producto_id     INT NOT NULL REFERENCES productos(producto_id),
    farmacia_id     INT NOT NULL REFERENCES farmacias(farmacia_id),
    cantidad        INT NOT NULL DEFAULT 1,
    fecha           DATE DEFAULT CURRENT_DATE
);

-- =====================================================
-- 2. INSERTS DE DATOS
-- =====================================================

-- 2.1 FARMACIAS (2 sucursales)
INSERT INTO farmacias (nombre, direccion, telefono) VALUES
('Farmacia Central', 'Av. Corrientes 1234', '011-4567-8900'),
('Farmacia Norte', 'Av. Libertador 5678', '011-4567-8901');

-- 2.2 CLIENTES (5 clientes, uno sin obra social)
INSERT INTO clientes (nombre, telefono, obra_social) VALUES
('Roberto Gómez', '15-2345-6789', 'OSDE'),
('María López', '15-8765-4321', 'PAMI'),
('Carlos Ruiz', '15-1111-2222', NULL),           -- Particular
('Ana Martínez', '15-3333-4444', 'OSDE'),
('Lucía Fernández', '15-5555-6666', 'PAMI');

-- 2.3 PRODUCTOS (6 productos, repartidos en 2 farmacias)
INSERT INTO productos (nombre, precio, stock, farmacia_id) VALUES
('Paracetamol 500mg', 850.00, 100, 1),
('Ibuprofeno 600mg', 1200.00, 80, 1),
('Amoxicilina 500mg', 2500.00, 50, 1),
('Tafirol', 950.00, 60, 2),                      -- Solo en Farmacia Norte
('Actron 400', 1350.00, 40, 2),                  -- Solo en Farmacia Norte
('Alcohol en gel', 450.00, 200, 2);

-- 2.4 VENTAS (8 ventas: algunas con cliente, otras sin)
INSERT INTO ventas (cliente_id, producto_id, farmacia_id, cantidad, fecha) VALUES
(1, 1, 1, 2, '2026-04-20'),   -- Roberto compró Paracetamol en Central
(1, 2, 1, 1, '2026-04-22'),   -- Roberto compró Ibuprofeno en Central
(2, 1, 1, 1, '2026-04-21'),   -- María compró Paracetamol en Central
(3, 3, 1, 1, '2026-04-23'),   -- Carlos compró Amoxicilina en Central
(4, 4, 2, 3, '2026-04-20'),   -- Ana compró Tafirol en Norte
(5, 5, 2, 2, '2026-04-22'),   -- Lucía compró Actron en Norte
(NULL, 6, 2, 5, '2026-04-24'),-- Venta anónima: Alcohol en gel en Norte
(2, 4, 2, 1, '2026-04-25');   -- María compró Tafirol en Norte