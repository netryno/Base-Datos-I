-- 1.- Recibir un nivel e imprimir el Triángulo de Pascal hasta esa fila. (crear procedimiento)



-- El procedimiento debe ser llamado de la siguiente manera:
CALL triangulo_pascal(4);
-- y resultado:
Nivel 0:        1
Nivel 1:       1 1
Nivel 2:      1 2 1
Nivel 3:     1 3 3 1
Nivel 4:    1 4 6 4 1




-- En esta Base de datos:
-- https://github.com/netryno/Base-Datos-I/blob/main/05%20Tarea%20sql/personas.sql
-- 2.- Registrar persona con sus datos. Si el CI ya existe, no hacer nada. Si no, registrar persona más un idioma. (crear procedimiento)



-- El procedimiento debe ser llamado de la siguiente manera:
CALL registrar_persona('Pedro', 'Gomez', NULL, '9988776', 'Espanol', 'Nativo');