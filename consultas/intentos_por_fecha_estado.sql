-- Cantidad de intentos por fecha y estado (todos los intentos, todo el rango proyectado).
SELECT
    fecha,
    estado,
    COUNT(*) AS total_intentos
FROM mensajeria_entregas.intentos_entrega
WHERE fecha BETWEEN '2026-10-01' AND '2026-10-03'
GROUP BY fecha, estado
ORDER BY fecha ASC, estado ASC;
