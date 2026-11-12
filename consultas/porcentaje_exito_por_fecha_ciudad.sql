-- Porcentaje de entregas exitosas por fecha y ciudad: 100 * entregados / total de intentos (todos los estados).
-- Se divide en DOUBLE para evitar la división entera y se presenta como DECIMAL(5,2).
SELECT
    fecha,
    ciudad,
    CAST(
        ROUND(100.0 * COUNT_IF(estado = 'entregado') / CAST(COUNT(*) AS DOUBLE), 2)
        AS DECIMAL(5, 2)
    ) AS porcentaje_exito
FROM mensajeria_entregas.intentos_entrega
WHERE fecha BETWEEN '2026-10-01' AND '2026-10-03'
GROUP BY fecha, ciudad
ORDER BY fecha ASC, ciudad ASC;
