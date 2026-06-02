--1.- 
-- Crear funcion y llamar:

CREATE FUNCTION get_persona(persona_id INT)
RETURNS TEXT
LANGUAGE sql
AS $$
	SELECT nombre FROM personas WHERE persona_id =$1;
$$;

-- llamar funcion
SELECT get_persona(3);

-- para verificar si esta ahi el dao
SELECT * FROM personas

-- otra manera de llamara
SELECT persona_id, get_persona(persona_id)  FROM personas;

--- otra en where
select * FROM personas where nombre = get_persona(1)


--- 2
-- PROCEDIMENTO HOLA MUNDO
CREATE OR REPLACE PROCEDURE hello_world()
LANGUAGE plpgsql
AS $$
DECLARE
	mensaje TEXT;
	contador INT;
	repeticiones INT := 5;
BEGIN
	mensaje := 'hOLA desde ppotsgres';
	RAISE NOTICE '%', mensaje;

	FOR contador IN 1 .. repeticiones LOOP
		RAISE NOTICE 'Interacion numero: %', contador;
	END LOOP;

	RAISE NOTICE 'Proc finalizado, total inter: %',repeticiones;

END;
$$;


--lLMAR PROCEDIMIENTO
CALL hello_world();
-- .-3
-- PROCEDIMENTO  sumar y multimplicar
CREATE OR REPLACE PROCEDURE sumar_multiplicar(a INT, b INT, c INT, d)
LANGUAGE plpgsql
AS $$
DECLARE
	sumado INT;
	multi INT;
BEGIN
	sumado := a + b;
	RAISE NOTICE 'Suma de % + % = % ', a , b, sumado;

	multi := sumado *  c;
	RAISE NOTICE 'Mulplicacion de  de % + % = % ',sumado, c, multi;

END;
$$;


--lLMAR PROCEDIMIENTO
CALL sumar_multiplicar(2,5,5);

---4.- CALCULADOR EJEMPLO
-- PROCEDIMENTO  sumar y multimplicar
CREATE OR REPLACE PROCEDURE calculador(a INT, b INT )
LANGUAGE plpgsql
AS $$
DECLARE
	suma INT;
	resta INT;
	multiplicacion INT;
	division NUMERIC(10,2);
	i INT;
BEGIN
	
	--suma
	suma := a + b;
	RAISE NOTICE 'Suma de % + % = % ', a , b, suma;

	resta := a - b;
	RAISE NOTICE ' % - % = % ', a , b, resta;	
	
	multiplicacion := a *  b;
	RAISE NOTICE ' % * % = % ',a, b, multiplicacion;

	
	IF b = 0 THEN 
		RAISE NOTICE 'No es posible dividir';
	ELSE
		division := a::NUMERIC /   b::NUMERIC;
		RAISE NOTICE ' % / % = %',a, b, division;
	END IF;
	
	FOR i IN 1..b LOOP
		RAISE NOTICE ' %', i;
	END LOOP;
	
	--RAISE NOTICE 'fin';
END;
$$;


--lLMAR PROCEDIMIENTO
CALL calculador(2,5);


-- 5.- REalizar factorialde un numero
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
    
    -- Ciclo o bucle: multiplicamos desde 1 hasta p_numero
    FOR v_contador IN 1..p_numero LOOP
        v_resultado := v_resultado * v_contador;
        
        -- Mostramos cada paso (opcional, para ver cómo funciona)
        RAISE NOTICE 'Paso %: resultado parcial = %', v_contador, v_resultado;
    END LOOP;
    
    -- El factorial
    RAISE NOTICE ' %! = %', v_original, v_resultado;
    
END;
$$;


---resultado
CALL calcular_factorial(50);

--6.- Listar procediimentos de mi BD, y eliminar
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

--elminar ... si tiene mas parametros es necesario especificar
DROP PROCEDURE IF EXISTS hello_world();
DROP PROCEDURE IF EXISTS calculadora(INT, INT);


-- 7.- REgistrar viaje, si es que ya viajo ya no registrar (a dicho pais)

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
        RAISE NOTICE 'REINCIDENTE: % ya viajó a %', v_nombre_persona, v_nombre_pais;
        RETURN;  -- Sale sin insertar
    END IF;
    
    -- Insertar viaje nuevo
    INSERT INTO viajes (persona_id, pais_id, fecha_llegada)
    VALUES (p_persona_id, p_pais_id, p_fecha_llegada);
    
    RAISE NOTICE 'Viaje registrado: % → % en %', v_nombre_persona, v_nombre_pais, p_fecha_llegada;
    
END;
$$;

select * from personas
select * from viajes where persona_id = 21


-- Nuevo viaje (Juan nunca fue a Cuba pais_id=21)
CALL registrar_viaje_simple(1, 21, '2025-12-25');

-- Reincidente (Luis YA fue a Argentina pais_id=1 en 2023 y 2024)
CALL registrar_viaje_simple(5, 1, '2025-06-01');


--8.-  Ejercicios: Si una persona ya habla el idioma, no hacer nada, si es que NO habla ese idioma, registrar.