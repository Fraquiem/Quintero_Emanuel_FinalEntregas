-- Verificación de la carga inicial: solo los días 1 y 2 están en S3 (12 registros esperados).
SELECT
    COUNT(*) AS total_registros,
    COUNT(DISTINCT fecha) AS fechas_con_datos,
    MIN(fecha) AS fecha_minima,
    MAX(fecha) AS fecha_maxima
FROM mensajeria_entregas.intentos_entrega;
