--1.- Introduccion *********************

--- crear procedimiento almacenado  -- 
CREATE OR REPLACE PROCEDURE mostrar_persona(p_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_nombre TEXT;
BEGIN
    SELECT nombre INTO v_nombre FROM personas WHERE persona_id = p_id;
    RAISE NOTICE 'La persona es: %', v_nombre;  -- Solo muestra, NO devuelve
END;
$$;

--- llamar producedimento:
call mostrar_persona(1);


-- 2.- funciones *********************
-- Solo puedes hacer esto. NO hay variables, NO hay IF, NO hay bucles.
CREATE FUNCTION obtener_nombre(persona_id INT)
RETURNS TEXT
LANGUAGE sql
AS $$
    SELECT nombre FROM personas WHERE persona_id = $1;
$$;

-- llamar funcion
Select obtener_nombre(1);


-- Forma 2: Dentro de otro SELECT
SELECT persona_id, obtener_nombre(persona_id) 
FROM personas 
WHERE persona_id <= 3;

-- Forma 3: En un WHERE
SELECT * FROM personas 
WHERE obtener_nombre(persona_id) = 'Juan';


--3.- Ejerecicios prodceimientos *********************

CREATE OR REPLACE PROCEDURE hola_mundo()
LANGUAGE plpgsql
AS $$
DECLARE
    mensaje TEXT;           -- variable de tipo texto
    contador INT;           -- variable de tipo número entero
    repeticiones INT := 5;  -- variable con valor inicial (5)
BEGIN
    -- Asignar un valor a la variable
    mensaje := 'Hola Mundo desde PostgreSQL!';
    
    -- Mostrar el mensaje una vez
    RAISE NOTICE '%', mensaje;
    
    -- Bucle: contar del 1 al 5
    FOR contador IN 1..repeticiones LOOP
        RAISE NOTICE 'Iteración número: %', contador;
    END LOOP;
    
    -- Mensaje final
    RAISE NOTICE '✅ Procedimiento finalizado. Total de iteraciones: %', repeticiones;
    
END;
$$;



--4.- suma y multiplicacion ,, sumar a y b, y multilicar por c *********************
CREATE OR REPLACE PROCEDURE calculador(a INT, b INT, c INT)
LANGUAGE plpgsql
AS $$
DECLARE
    resultado INT;
BEGIN
    resultado := (a + b) * c;
    
    RAISE NOTICE '( % + % ) × % = %', a, b, c, resultado;
END;
$$;

--llamar
call calculador(2, 3, 4);  -- (2 + 3) × 4 = 20


--5.- Calculadora completa *********************

CREATE OR REPLACE PROCEDURE calculadora(a INT, b INT)
LANGUAGE plpgsql
AS $$
DECLARE
    suma INT;
    resta INT;
    multiplicacion INT;
    division NUMERIC(10,2);
    i INT;              -- ← variable para el bucle
BEGIN
    -- Suma
    suma := a + b;
    RAISE NOTICE '% + % = %', a, b, suma;
    
    -- Resta
    resta := a - b;
    RAISE NOTICE '% - % = %', a, b, resta;
    
    -- Multiplicación
    multiplicacion := a * b;
    RAISE NOTICE '% × % = %', a, b, multiplicacion;
    
    -- División (con validación)
    IF b = 0 THEN
        RAISE NOTICE '% / % = ERROR (no se divide por cero)', a, b;
    ELSE
        division := a::NUMERIC / b::NUMERIC;
        RAISE NOTICE '% / % = %', a, b, division;
    END IF;
    
    -- NUEVO: Imprimir del 1 al b
    RAISE NOTICE '';
    RAISE NOTICE 'Contando del 1 al %:', b;
    
    FOR i IN 1..b LOOP
        RAISE NOTICE '  %', i;
    END LOOP;
    
    RAISE NOTICE 'fin';
    
END;
$$;


---llamar
CALL calculadora(10, 5);



-- 6, factorial ********************* (practico)

CREATE OR REPLACE PROCEDURE calcular_factorial(p_numero INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_resultado BIGINT := 1;   -- Guarda el resultado (BIGINT para números grandes)
    v_contador INT;            -- Va contando de 1 hasta p_numero
    v_original INT;            -- Guarda el número original para mostrarlo al final
BEGIN
    -- Guardamos el número original
    v_original := p_numero;
    
    -- Validación: el factorial solo existe para números >= 0
    IF p_numero < 0 THEN
        RAISE EXCEPTION 'Error: No existe factorial de números negativos';
    END IF;
    
    -- Caso especial: 0! = 1
    IF p_numero = 0 THEN
        RAISE NOTICE '0! = 1';
        RETURN;
    END IF;
    
    -- Bucle: multiplicamos desde 1 hasta p_numero
    FOR v_contador IN 1..p_numero LOOP
        v_resultado := v_resultado * v_contador;
        
        -- Mostramos cada paso (opcional, para ver cómo funciona)
        RAISE NOTICE 'Paso %: resultado parcial = %', v_contador, v_resultado;
    END LOOP;
    
    -- Resultado final
    RAISE NOTICE ' %! = %', v_original, v_resultado;
    
END;
$$;


---resultado
CALL calcular_factorial(5);




--7.- listar procedimeintos y elminar

SELECT 
    p.proname AS nombre,
    n.nspname AS esquema,
    pg_get_function_arguments(p.oid) AS parametros,
    CASE p.prokind 
        WHEN 'p' THEN 'PROCEDIMIENTO'
        WHEN 'f' THEN 'FUNCIÓN'
    END AS tipo
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.prokind = 'p'
  AND n.nspname = 'public'      -- Cambia 'public' por tu esquema
ORDER BY p.proname;


DROP PROCEDURE IF EXISTS calculadora();
DROP PROCEDURE IF EXISTS calculadora(INT, INT);


--8 registrar si es que no viajo si viajo ya no hacer nada

CREATE OR REPLACE PROCEDURE registrar_viaje_simple(
    p_persona_id INT,
    p_pais_id INT,
    p_fecha_llegada DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_nombre_persona VARCHAR(50);
    v_nombre_pais VARCHAR(60);
    v_ya_viajo INT;
BEGIN
    -- Obtener nombre de la persona
    SELECT nombre INTO v_nombre_persona 
    FROM personas WHERE persona_id = p_persona_id;
    
    -- Obtener nombre del país
    SELECT pais_nombre INTO v_nombre_pais 
    FROM paises WHERE pais_id = p_pais_id;
    
    -- Verificar si YA viajó a ese país (cualquier fecha)
    SELECT COUNT(*) INTO v_ya_viajo 
    FROM viajes 
    WHERE persona_id = p_persona_id 
      AND pais_id = p_pais_id;
    
    -- Validación
    IF v_ya_viajo > 0 THEN
        RAISE NOTICE '⚠️ REINCIDENTE: % ya viajó a %', v_nombre_persona, v_nombre_pais;
        RETURN;  -- Sale sin insertar
    END IF;
    
    -- Insertar viaje nuevo
    INSERT INTO viajes (persona_id, pais_id, fecha_llegada)
    VALUES (p_persona_id, p_pais_id, p_fecha_llegada);
    
    RAISE NOTICE '✅ Viaje registrado: % → % en %', v_nombre_persona, v_nombre_pais, p_fecha_llegada;
    
END;
$$;

-- ✅ Nuevo viaje (Juan nunca fue a Cuba pais_id=21)
CALL registrar_viaje_simple(1, 21, '2025-12-25');

-- ⚠️ Reincidente (Luis YA fue a Argentina pais_id=1 en 2023 y 2024)
CALL registrar_viaje_simple(5, 1, '2025-06-01');

