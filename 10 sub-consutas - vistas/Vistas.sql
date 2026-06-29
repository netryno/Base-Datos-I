##VISTAS (Views)
##Una vista es una tabla "virtual" que almacena una consulta SQL. No guarda datos físicos, sino la instrucción para obtenerlos.


#Vista 1: v_active_drivers — Conductores activos con info completa
-- ¿Para qué sirve? Facilita consultas frecuentes sobre conductores disponibles sin tener que escribir el JOIN cada vez.

CREATE VIEW v_active_drivers AS
SELECT 
    d.driver_id,
    u.name,
    u.email,
    u.phone,
    u.city,
    d.vehicle_make,
    d.vehicle_model,
    d.vehicle_year,
    d.license_plate,
    d.rating,
    d.join_date
FROM drivers d
JOIN users u ON d.user_id = u.user_id
WHERE d.is_active = 1;


-- Ahora es súper sencillo consultar:
SELECT * FROM v_active_drivers WHERE city = 'Houston';
SELECT * FROM v_active_drivers WHERE rating >= 4.5;




#Vista 2: v_trip_summary — Resumen completo de viajes
-- ¿Para qué sirve? Unifica toda la información dispersa en varias tablas (pasajero, conductor, lugares, pagos) en una sola "tabla" fácil de consultar para reportes.

CREATE VIEW v_trip_summary AS
SELECT 
    t.trip_id,
    t.status,
    t.requested_at,
    t.completed_at,
    t.distance_km,
    t.duration_mins,
    t.total_fare,
    t.payment_method,
    
    -- Pasajero
    ru.name AS rider_name,
    
    -- Conductor
    du.name AS driver_name,
    d.license_plate,
    
    -- Origen
    pl.zone_name AS pickup_zone,
    pl.city AS pickup_city,
    
    -- Destino
    dl.zone_name AS dropoff_zone,
    dl.city AS dropoff_city,
    
    -- Pago
    p.amount AS paid_amount,
    p.status AS payment_status

FROM trips t
JOIN riders r ON t.rider_id = r.rider_id
JOIN users ru ON r.user_id = ru.user_id
JOIN drivers d ON t.driver_id = d.driver_id
JOIN users du ON d.user_id = du.user_id
JOIN locations pl ON t.pickup_location_id = pl.location_id
JOIN locations dl ON t.dropoff_location_id = dl.location_id
LEFT JOIN payments p ON t.trip_id = p.trip_id;


-- uso:
-- Viajes completados en mayo:
SELECT * FROM v_trip_summary 
WHERE status = 'completed' 
  AND completed_at >= '2024-05-01';

-- Ingresos por ciudad de origen:
SELECT pickup_city, SUM(total_fare) 
FROM v_trip_summary 
WHERE status = 'completed'
GROUP BY pickup_city;


#Vista 3: como listar vistas
-- Ver todas las vistas del esquema actual
SELECT 
    table_name AS vista,
    table_schema AS esquema
FROM INFORMATION_SCHEMA.VIEWS
WHERE table_schema NOT IN ('pg_catalog', 'information_schema');

-- O usando pg_views (más detallada)
SELECT 
    viewname AS vista,
    schemaname AS esquema,
    definition AS definicion_sql
FROM pg_views
WHERE schemaname NOT IN ('pg_catalog', 'information_schema');



 Ventajas	
Simplifican consultas complejas — escribes una vez, usas siempre
Seguridad — puedes dar acceso a la vista sin dar acceso a las tablas base
Consistencia — todos usan la misma lógica de negocio
Abstracción — el usuario no necesita saber la estructura compleja de la BD


 Desventajas
No almacenan datos — se ejecutan cada vez que las consultas (pueden ser lentas)
Dependencia — si cambias una tabla base, la vista puede "romperse"
No se pueden indexar directamente (en la mayoría de BDs)
Actualizaciones limitadas — no todas las vistas permiten INSERT/UPDATE/DELETE



Concepto	
Vista	

Piénsalo como...	
Una tabla virtual / un reporte guardado

Úsalo cuando...	
Repites la misma consulta compleja muchas veces