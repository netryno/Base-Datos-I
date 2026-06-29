--- Una subconsulta es una consulta SQL dentro de otra consulta.
-- Se usa para obtener datos que luego servirán como filtro o cálculo para la consulta principal.

## 1.- Conductores con rating mayor al promedio
-- Objetivo: Encontrar todos los conductores cuyo rating está por encima del promedio general.


SELECT 
    d.driver_id,
    u.name,
    d.rating
FROM drivers d
JOIN users u ON d.user_id = u.user_id
WHERE d.rating > (
    -- Subconsulta: calcula el promedio de TODOS los conductores
    SELECT AVG(rating) 
    FROM drivers
);


## 2.- Usuarios que NUNCA han viajado como pasajeros
-- Objetivo: Listar usuarios registrados que no tienen registros en la tabla riders.
SELECT 
    user_id,
    name,
    email,
    city
FROM users
WHERE user_id NOT IN (
    -- Subconsulta: obtiene todos los user_id que SÍ están en riders
    SELECT user_id 
    FROM riders
);


## 3.- El viaje más caro de cada pasajero
-- Objetivo: Para cada pasajero, mostrar solo su viaje más caro (no todos sus viajes).

SELECT 
    r.rider_id,
    u.name AS pasajero,
    t.trip_id,
    t.total_fare,
    t.completed_at
FROM riders r
JOIN users u ON r.user_id = u.user_id
JOIN trips t ON r.rider_id = t.rider_id
WHERE t.total_fare = (
    -- Subconsulta correlacionada: busca el MAX por CADA pasajero
    SELECT MAX(total_fare)
    FROM trips t2
    WHERE t2.rider_id = r.rider_id  -- ¡Se relaciona con la fila externa!
)
ORDER BY t.total_fare DESC;



## 4.- Calcular un valor por fila
-- Objetivo: Mostrar cada pasajero con su total gastado en viajes (calculado en el SELECT)
SELECT 
    r.rider_id,
    u.name AS pasajero,
    -- Subconsulta en SELECT: calcula un valor para CADA fila
    (SELECT SUM(total_fare) 
     FROM trips t 
     WHERE t.rider_id = r.rider_id) AS total_gastado
FROM riders r
JOIN users u ON r.user_id = u.user_id;





Ventajas	
Fáciles de entender — la lógica va paso a paso
Reutilizan resultados — calculas algo una vez y lo usas en el WHERE
Muy flexibles — funcionan en SELECT, WHERE, FROM, HAVING
No requieren permisos especiales

Desventajas
Rendimiento — pueden ser lentas en tablas grandes
No siempre optimizables — el motor de BD a veces no las optimiza bien
Subconsultas correlacionadas son especialmente lentas (se ejecutan fila por fila)
Difíciles de depurar cuando son muy anidadas


Concepto	
Subconsulta	

Piénsalo como...	
Una pregunta dentro de otra pregunta

Úsalo cuando...	
Necesitas un valor calculado para filtrar