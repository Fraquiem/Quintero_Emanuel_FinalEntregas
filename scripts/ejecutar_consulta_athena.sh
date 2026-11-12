#!/usr/bin/env bash
# Ejecuta UNA sentencia SQL en el workgroup del ejercicio, descarga el CSV que Athena
# escribió en resultados-athena/, lo guarda sin comillas en la ruta indicada y registra
# la ejecución en evidencias/ejecuciones_athena.csv.
#
# Uso (desde la raíz del repositorio):
#   scripts/ejecutar_consulta_athena.sh <etapa> <archivo_sql> <archivo_resultado> [indice_sentencia]
# indice_sentencia (por defecto 1) selecciona la N-ésima sentencia terminada en ';'
# cuando el archivo SQL contiene varias consultas.
set -euo pipefail

etapa="$1"; archivo_sql="$2"; archivo_resultado="$3"; indice="${4:-1}"
raiz="$(cd "$(dirname "$0")/.." && pwd)"; cd "$raiz"
workgroup="$(terraform -chdir=infraestructura output -raw workgroup_athena)"
region="$(terraform -chdir=infraestructura output -raw region)"
registro="evidencias/ejecuciones_athena.csv"

# Extrae la sentencia solicitada ignorando los comentarios de línea.
sentencia="$(sed 's/--.*$//' "$archivo_sql" | awk -v n="$indice" 'BEGIN{RS=";"} NR==n{print}')"
[[ -n "${sentencia//[[:space:]]/}" ]] || { echo "Sentencia $indice vacía en $archivo_sql" >&2; exit 1; }

id="$(aws athena start-query-execution --region "$region" --work-group "$workgroup" \
      --query-string "$sentencia" --query QueryExecutionId --output text)"

while :; do
  estado="$(aws athena get-query-execution --region "$region" --query-execution-id "$id" \
            --query QueryExecution.Status.State --output text)"
  case "$estado" in
    SUCCEEDED) break ;;
    FAILED|CANCELLED)
      aws athena get-query-execution --region "$region" --query-execution-id "$id" \
        --query QueryExecution.Status.StateChangeReason --output text >&2
      exit 1 ;;
    *) sleep 1 ;;
  esac
done

salida="$(aws athena get-query-execution --region "$region" --query-execution-id "$id" \
          --query QueryExecution.ResultConfiguration.OutputLocation --output text)"
mkdir -p "$(dirname "$archivo_resultado")"
# Los valores no contienen comas ni comillas: basta con quitar las comillas que añade Athena.
aws s3 cp --region "$region" --quiet "$salida" - | tr -d '"' > "$archivo_resultado"

[[ -f "$registro" ]] || echo "etapa,archivo_sql,id_ejecucion,archivo_resultado" > "$registro"
echo "$etapa,$archivo_sql,$id,$archivo_resultado" >> "$registro"
echo "$id -> $archivo_resultado"
