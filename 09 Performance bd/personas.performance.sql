-- Para ver ejemplos reales es necesario tener la BD poblada

-- ************************************************************
-- Ejemplo 1: Seq Scan vs Index Scan
-- ************************************************************


EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM personas
WHERE nombre = 'Juan';


'''
Seq Scan = leyó las X filas, una por una.
Rows Removed by Filter = cuántas descartó después de leerlas (trabajo desperdiciado).
Buffers: read= = páginas leídas desde disco (no estaban en memoria/caché). 
Si en una segunda ejecución bajan los read y suben los hit, 
es porque ya quedó en caché (shared_buffers) — punto para visualizar memoria.
'''


CREATE INDEX idx_personas_nombre ON personas(nombre);

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM personas
WHERE nombre = 'Juan';

-- Solo para fines de prueba eliminamos index
DROP INDEX IF EXISTS idx_personas_nombre;



-- Mucho más selectivo, mejor para ver Index Scan puro, para ver diferencia entre ci y nombre
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM personas WHERE ci = '123456';

-- ************************************************************
-- Ejemplo 2: SELECT * vs columnas específicas
-- ************************************************************
'''
Concepto: no es solo "estilo de código feo". 
SELECT * puede impedir que Postgres use un Index-Only Scan 
(cuando todos los datos que necesitas ya están en el índice, sin tocar la tabla) 
y siempre transfiere más bytes de los necesarios 
(CPU de serialización + memoria en cliente + red).
'''

-- Preparación: crear un índice "covering"
CREATE INDEX idx_personas_nombre_id ON personas(nombre) INCLUDE (persona_id);

-- IMPORTANTE: VACUUM actualiza el "visibility map", que le dice a Postgres
-- qué páginas no necesitan verificar el heap. Sin esto, el Index-Only Scan
-- no funciona aunque tengas el índice correcto.
VACUUM personas;


-- ❌ Mala práctica
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM personas
WHERE nombre = 'Pedro';


-- ✅ Optimizado
EXPLAIN (ANALYZE, BUFFERS)
SELECT persona_id, nombre
FROM personas
WHERE nombre = 'Pedro';


-- Otro ejemplo
EXPLAIN (ANALYZE, BUFFERS)
SELECT persona_id, nombre, ci   -- agregamos 'ci', que NO está en el índice
FROM personas
WHERE nombre = 'Pedro';




-- ************************************************************
-- Ejemplo 3: Funciones sobre columnas indexadas
-- ************************************************************
'''
Concepto: si aplicas una función a la columna en el WHERE, 
el índice normal no sirve (Postgres no puede usarlo porque 
el índice guarda el valor original, no el resultado de la función).
'''

-- ❌ Mala práctica
EXPLAIN (ANALYZE, BUFFERS)
SELECT persona_id, nombre
FROM personas
WHERE UPPER(nombre) = 'PEDRO';

-- El índice idx_personas_nombre existe, pero se ignora por completo → vuelve a leer las 500,000 filas.



-- ✅ Optimizado (índice de expresión)
CREATE INDEX idx_personas_nombre_upper ON personas (UPPER(nombre));

EXPLAIN (ANALYZE, BUFFERS)
SELECT persona_id, nombre
FROM personas
WHERE UPPER(nombre) = 'PEDRO';


-- Execution Time: 10 ms
'''
El índice no es "sobre la columna", es "sobre la expresión exacta que aparece en el WHERE". 
Si cambian a WHERE LOWER(nombre)=..., este índice tampoco sirve — necesitarían otro.
'''


-- ************************************************************
-- Ejemplo 4: JOIN sin índice en FK vs con índice
-- ************************************************************
'''
Concepto: las FK en Postgres no crean índice automáticamente. 
Si haces JOIN por esa columna sin índice, 
el motor debe barrer la tabla completa por cada fila del otro lado.
'''

-- ❌ Mala práctica
EXPLAIN (ANALYZE, BUFFERS)
SELECT v.viaje_id, p.nombre
FROM viajes v
JOIN personas p ON v.persona_id = p.persona_id
WHERE p.ci = '123456';
-- Execution Time: 35.529 ms

-- ✅ Optimizado
CREATE INDEX idx_viajes_persona_id ON viajes(persona_id);

EXPLAIN (ANALYZE, BUFFERS)
SELECT v.viaje_id, p.nombre
FROM viajes v
JOIN personas p ON v.persona_id = p.persona_id
WHERE p.ci = '123456';
-- Execution Time: 0.026 ms

'''
El punto clave para los alumnos: "FOREIGN KEY" garantiza integridad de datos, 
no rendimiento de búsqueda. 
Toda FK que se use para JOINs frecuentes necesita su propio índice — créalo siempre junto con la FK, 
no como ocurrencia tardía.
'''
--


-- ************************************************************
-- Ejemplo 5: Subconsulta correlacionada vs JOIN
-- ************************************************************
'''
Concepto: una subconsulta correlacionada se ejecuta una vez por cada 
fila del resultado externo. Con JOIN, Postgres resuelve todo en un solo barrido.
'''
-- ❌ Mala práctica (subconsulta correlacionada)

EXPLAIN (ANALYZE, BUFFERS)
SELECT p.persona_id, p.nombre,
       (SELECT COUNT(*) FROM viajes v WHERE v.persona_id = p.persona_id) AS num_viajes
FROM personas p
where p.persona_id in (1,2,3,4,5);

-- ✅ Optimizado (JOIN + GROUP BY)
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.persona_id, p.nombre, COUNT(v.viaje_id) AS num_viajes
FROM personas p
LEFT JOIN viajes v ON v.persona_id = p.persona_id
where p.persona_id in (1,2,3,4,5)
GROUP BY p.persona_id, p.nombre;


'''
El punto clave para los alumnos: un solo Hash Join + una sola agregación resuelve todo en un barrido, 
en vez de 500,000 ejecuciones repetidas de la subconsulta. Aunque el tiempo total siga siendo "alto" 
(porque son 2 millones de viajes), la diferencia crece exponencialmente 
si la tabla viajes fuera aún más grande — la subconsulta escala linealmente por cada persona, el JOIN no.
'''


-- ************************************************************
-- Ejemplo 6: LIKE '%texto%' vs índice trigram
-- ************************************************************
'''
Concepto: un índice normal (B-tree) s
olo sirve si el patrón empieza con texto fijo ("Pe%"). 
Con %texto% (comodín al inicio), el índice normal no sirve de nada — necesita 
un tipo de índice especial.
'''
-- ❌ Mala práctica

EXPLAIN (ANALYZE, BUFFERS)
SELECT persona_id, nombre
FROM personas
WHERE nombre LIKE '%edr%';




-- ✅ Optimizado (extensión pg_trgm)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX idx_personas_nombre_trgm ON personas USING gin (nombre gin_trgm_ops);

EXPLAIN (ANALYZE, BUFFERS)
SELECT persona_id, nombre
FROM personas
WHERE nombre LIKE '%edr%';


-- Eliminar par comparar
DROP INDEX IF EXISTS idx_personas_nombre_trgm;
DROP EXTENSION IF EXISTS pg_trgm;


'''
El punto clave para los alumnos: pg_trgm descompone 
el texto en "trigramas" (grupos de 3 letras) y los 
indexa, por eso puede encontrar coincidencias en 
cualquier posición del string, no solo al inicio. 
Es la solución real a "necesito buscar como si fuera 
Google" sin migrar a un motor de búsqueda externo.
Aclaración importante: si el patrón fuera 'Pedr%' 
(sin % al inicio), el índice B-tree normal sí 
funciona — no necesitas trigram en ese caso. 
El problema es específicamente el comodín al inicio.
'''


-- ************************************************************
-- Ejemplo 7: Paginación con OFFSET vs Cursor-Based (Keyset Pagination)
-- ************************************************************
'''
Concepto: OFFSET es intuitivo pero letal en tablas grandes. 
PostgreSQL debe leer y descartar todas las filas anteriores 
al offset, aunque no las devuelva. Con millones de registros, 
la página 10,000 tarda lo mismo que leer 10,000 páginas enteras.
'''

-- OFFSET le dice a PostgreSQL cuántas filas debe saltar antes de empezar a devolver resultados.
-- SELECT * FROM personas OFFSET 10;
-- Omite las primeras 10 filas y devuelve las restantes.
-- OFFSET 0 → no salta ninguna fila.
-- OFFSET 20 → salta las primeras 20 filas.

-- ❌ Mala práctica: OFFSET para paginación profunda
EXPLAIN (ANALYZE, BUFFERS)
SELECT persona_id, nombre, primer_apellido, ci
FROM personas
ORDER BY persona_id
LIMIT 20 OFFSET 100000;


-- ✅ Optimizado: Cursor-based (Keyset Pagination)
-- Usar el último ID conocido como "cursor" en lugar de OFFSET
EXPLAIN (ANALYZE, BUFFERS)
SELECT persona_id, nombre, primer_apellido, ci
FROM personas
WHERE persona_id > 100000        -- "Dame los siguientes a partir de aquí"
ORDER BY persona_id
LIMIT 20;

'''
Con OFFSET, la última página cuesta lo mismo que leer toda la tabla. Con cursor, siempre cuesta leer 20 filas.

Escenario	   OFFSET	Cursor
Página 1	    0.5 ms	0.04 ms
Página 1,000	15 ms	0.04 ms
Página 25,000	246 ms	0.04 ms
Página 100,000	980 ms	0.04 ms


✅ SÍ usar OFFSET	                ❌ NO usar OFFSET
Tablas pequeñas (< 10K filas)	Tablas grandes (> 100K filas)
'''

-- ************************************************************
-- Ejemplo 8: COUNT(*) vs COUNT(1) vs EXISTS (mito vs realidad)
-- ************************************************************
'''
Concepto: Los alumnos creen que COUNT(*) es "lento" y que 
COUNT(1) o COUNT(columna) es "más rápido". En PostgreSQL eso es FALSO.
El verdadero problema: usar COUNT cuando solo necesitas saber SI EXISTE.
'''

-- ❌ Mala práctica: COUNT(*) para verificar existencia
-- Lee TODA la tabla aunque encuentre la primera coincidencia

EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*) > 0
FROM viajes
WHERE pais_id = 1;

/*
Execution Time: 45.230 ms
Buffers: shared read=2847

PostgreSQL cuenta TODOS los viajes a Bolivia (ej: 150,000) 
solo para decirte "sí, hay al menos uno". Trabajo desperdiciado.
*/


-- ✅ Optimizado: EXISTS (para en la primera coincidencia)

EXPLAIN (ANALYZE, BUFFERS)
SELECT EXISTS (
    SELECT 1 FROM viajes WHERE pais_id = 1
);

/*
Execution Time: 0.015 ms
Buffers: shared read=2

Postgregres encuentra el primer viaje a Bolivia y PARA.
No cuenta, no suma, no recorre más.
*/


-- ❌ Mala práctica: COUNT(*) en subconsulta para filtrar

EXPLAIN (ANALYZE, BUFFERS)
SELECT p.nombre
FROM personas p
WHERE (SELECT COUNT(*) FROM viajes v WHERE v.persona_id = p.persona_id) > 0;

/*
Execution Time: 8,420.000 ms
Para CADA persona, cuenta TODOS sus viajes. O(n²).
*/


-- ✅ Optimizado: EXISTS para filtrar

EXPLAIN (ANALYZE, BUFFERS)
SELECT p.nombre
FROM personas p
WHERE EXISTS (
    SELECT 1 FROM viajes v WHERE v.persona_id = p.persona_id
);



-- ************************************************************
-- Bonus: COUNT(*) vs COUNT(1) vs COUNT(columna) en PostgreSQL
-- ************************************************************

/*
MITO: "COUNT(1) es más rápido que COUNT(*)"
REALIDAD: PostgreSQL los optimiza EXACTAMENTE igual.
Ambos cuentan filas, no evalúan expresiones.

MITO: "COUNT(columna) es más rápido"
REALIDAD: COUNT(columna) ignora NULLs, así que ES MÁS LENTO 
(verifica si cada valor es NULL). COUNT(*) nunca verifica NULLs.
*/

EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*) FROM personas;      -- Rápido: solo cuenta filas

EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(1) FROM personas;       -- Igual de rápido: optimizado igual

EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(segundo_apellido)       -- MÁS LENTO: verifica NULLs en cada fila
FROM personas;


-- ************************************************************
-- Resumen 
-- ************************************************************

/*
┌─────────────────┬─────────────────────────────────────────────┐
│ Necesitas...    │ Usa...                                      │
├─────────────────┼─────────────────────────────────────────────┤
│ Saber SI EXISTE  │ EXISTS (para en la primera)                │
│ Contar filas     │ COUNT(*) (siempre, nunca COUNT(1))         │
│ Contar no-NULLs  │ COUNT(columna) (único caso válido)         │
│ Número exacto    │ COUNT(*)                                   │
│ Aproximación     │ pg_class.reltuples (instantáneo)           │
│ Dashboards       │ Cache + estimaciones, no COUNT cada vez    │
└─────────────────┴─────────────────────────────────────────────┘
