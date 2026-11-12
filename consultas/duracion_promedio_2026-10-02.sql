-- Duración promedio (minutos) de las entregas exitosas del 2026-10-02, todas las ciudades y transportadoras.
-- Solo se incluyen intentos con estado 'entregado'; los fallidos (duración 0) quedan excluidos.
SELECT
    fecha,
    CAST(ROUND(AVG(CAST(duracion_minutos AS DOUBLE)), 2) AS DECIMAL(10, 2)) AS duracion_promedio_minutos
FROM mensajeria_entregas.intentos_entrega
WHERE fecha = '2026-10-02'
  AND estado = 'entregado'
GROUP BY fecha;
