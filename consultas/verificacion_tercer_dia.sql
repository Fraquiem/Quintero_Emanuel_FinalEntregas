-- Verificación de la incorporación del 2026-10-03 sin modificar la tabla.
-- Athena ejecuta una sentencia por llamada: cada consulta se ejecuta por separado.

-- 1. Registros del tercer día (6 esperados) -> resultados/final/verificacion_tercer_dia.csv
SELECT
    fecha,
    id_envio,
    ciudad,
    transportadora,
    estado,
    duracion_minutos
FROM mensajeria_entregas.intentos_entrega
WHERE fecha = '2026-10-03'
ORDER BY id_envio ASC;

-- 2. Conteos por estado del tercer día -> resultados/final/conteo_estados_tercer_dia.csv
SELECT
    fecha,
    estado,
    COUNT(*) AS total_intentos
FROM mensajeria_entregas.intentos_entrega
WHERE fecha = '2026-10-03'
GROUP BY fecha, estado
ORDER BY estado ASC;

-- 3. Total de la tabla (18 esperados) y registros del tercer día -> resultados/final/total_registros.csv
SELECT
    COUNT(*) AS total_registros,
    COUNT_IF(fecha = '2026-10-03') AS registros_tercer_dia,
    COUNT(DISTINCT fecha) AS fechas_con_datos
FROM mensajeria_entregas.intentos_entrega;
