# Consultas de entregas con Athena

El ejercicio consulta intentos de entrega por fecha y estado, porcentaje de éxito por ciudad y duración promedio de entregas exitosas. Los CSV residen en S3; una tabla externa de Glue describe su esquema y proyecta la partición `fecha`; Athena lee los datos y guarda sus resultados en otro prefijo del mismo bucket. Los recursos de la ejecución documentada ya fueron eliminados.

En `us-east-2` se desplegaron el bucket privado `quintero-emanuel-entregas-final-de`, la base `mensajeria_entregas`, la tabla `intentos_entrega` y el workgroup `wg_entregas_quintero`. El bucket tiene los cuatro bloqueos de acceso público, `BucketOwnerEnforced` y cifrado SSE-S3 AES256. Los datos van en `entregas/` y los resultados de Athena en `resultados-athena/`. La proyección cubre del 1 al 3 de octubre de 2026, ambos incluidos.

## Estructura

```text
.
├── README.md
├── respuestas.md
├── .gitignore
├── infraestructura/
│   ├── .terraform.lock.hcl
│   ├── principal.tf
│   ├── variables.tf
│   └── salidas.tf
├── data/entregas/
│   ├── fecha=2026-10-01/entregas.csv
│   ├── fecha=2026-10-02/entregas.csv
│   └── fecha=2026-10-03/entregas.csv
├── consultas/
│   ├── intentos_por_fecha_estado.sql
│   ├── porcentaje_exito_por_fecha_ciudad.sql
│   ├── duracion_promedio_2026-10-02.sql
│   ├── verificacion_carga_inicial.sql
│   └── verificacion_tercer_dia.sql
├── scripts/ejecutar_consulta_athena.sh
├── resultados/
│   ├── inicial/
│   │   ├── intentos_por_fecha_estado.csv
│   │   ├── porcentaje_exito_por_fecha_ciudad.csv
│   │   ├── duracion_promedio_2026-10-02.csv
│   │   └── verificacion_carga_inicial.csv
│   └── final/
│       ├── intentos_por_fecha_estado.csv
│       ├── porcentaje_exito_por_fecha_ciudad.csv
│       ├── duracion_promedio_2026-10-02.csv
│       ├── verificacion_tercer_dia.csv
│       ├── conteo_estados_tercer_dia.csv
│       └── total_registros.csv
├── resultados_esperados/
│   ├── intentos_por_fecha_estado_inicial.csv
│   ├── intentos_por_fecha_estado_final.csv
│   ├── porcentaje_exito_por_fecha_ciudad_inicial.csv
│   ├── porcentaje_exito_por_fecha_ciudad_final.csv
│   └── duracion_promedio_2026-10-02.csv
└── evidencias/
    ├── aplicacion_terraform.txt
    ├── outputs.json
    ├── verificacion_recursos_aws.txt
    ├── carga_inicial_s3.txt
    ├── carga_tercer_dia_s3.txt
    ├── ejecuciones_athena.csv
    ├── detalle_ejecuciones_athena.json
    └── eliminacion_terraform.txt
```

## Prerrequisitos y configuración

- Terraform v1.17.1 en la ejecución documentada; la configuración requiere al menos 1.5.0. El proveedor AWS exige `~> 6.0` y el lock fija la versión 6.73.0.
- AWS CLI v2, Bash y utilidades estándar como `sed`, `awk`, `tr` y `diff`.
- Una identidad AWS autenticada mediante el mecanismo habitual de AWS CLI y del proveedor Terraform, con permisos para administrar los recursos S3, Glue y Athena y ejecutar consultas. No se deben guardar credenciales ni identificadores de cuenta en el repositorio.
- Seleccionar la región `us-east-2` para la CLI. Terraform la toma de `infraestructura/variables.tf` por defecto.

Los nombres de bucket S3 son globales. Si el nombre predeterminado no está disponible, elija uno único y úselo en `-var nombre_bucket=...` al crear el plan. Los comandos posteriores obtienen el nombre del estado de Terraform. Las demás variables y sus valores predeterminados están en `infraestructura/variables.tf`. El estado, los planes, los archivos tfvars, las credenciales y `.terraform/` están excluidos por `.gitignore`.

## Reproducción

Ejecute desde la raíz de la entrega. La preparación original comenzó con `git init`, `.gitignore` y un primer commit del material suministrado. Para reproducir las etapas sin mezclar registros con los históricos, conserve aparte las evidencias y resultados originales: el helper sobrescribe los CSV de salida y agrega filas al registro de ejecuciones. Los nuevos ID serán distintos.

### 1. Desplegar y verificar

```bash
export AWS_DEFAULT_REGION=us-east-2
terraform -chdir=infraestructura init
terraform -chdir=infraestructura validate
terraform -chdir=infraestructura plan -var 'nombre_bucket=quintero-emanuel-entregas-final-de' -out=/tmp/entregas.tfplan
terraform -chdir=infraestructura apply /tmp/entregas.tfplan
terraform -chdir=infraestructura output -json > evidencias/outputs.json
BUCKET="$(terraform -chdir=infraestructura output -raw bucket)"
aws s3api get-bucket-location --bucket "$BUCKET"
aws s3api get-public-access-block --bucket "$BUCKET"
aws s3api get-bucket-ownership-controls --bucket "$BUCKET"
aws s3api get-bucket-encryption --bucket "$BUCKET"
aws glue get-table --database-name mensajeria_entregas --name intentos_entrega
aws glue get-partitions --database-name mensajeria_entregas --table-name intentos_entrega --query 'length(Partitions)'
aws athena get-work-group --work-group wg_entregas_quintero
```

Sustituya el valor de `nombre_bucket` en el plan si hace falta. El plan se guarda fuera del repositorio. La ejecución original siguió `init`, `validate`, `plan` y `apply` del plan guardado; la verificación de Glue mostró cero particiones registradas.

### 2. Cargar solo los dos primeros días

No suba `resultados_esperados/` al prefijo `entregas/` ni cargue la carpeta recursivamente. El tercer archivo permanece local hasta la etapa siguiente.

```bash
aws s3 cp data/entregas/fecha=2026-10-01/entregas.csv "s3://$BUCKET/entregas/fecha=2026-10-01/entregas.csv"
aws s3 cp data/entregas/fecha=2026-10-02/entregas.csv "s3://$BUCKET/entregas/fecha=2026-10-02/entregas.csv"
scripts/ejecutar_consulta_athena.sh inicial consultas/intentos_por_fecha_estado.sql resultados/inicial/intentos_por_fecha_estado.csv
scripts/ejecutar_consulta_athena.sh inicial consultas/porcentaje_exito_por_fecha_ciudad.sql resultados/inicial/porcentaje_exito_por_fecha_ciudad.csv
scripts/ejecutar_consulta_athena.sh inicial consultas/duracion_promedio_2026-10-02.sql resultados/inicial/duracion_promedio_2026-10-02.csv
scripts/ejecutar_consulta_athena.sh inicial consultas/verificacion_carga_inicial.sql resultados/inicial/verificacion_carga_inicial.csv
```

La verificación inicial registra 12 datos. El helper recibe etapa, SQL, resultado y, opcionalmente, el índice de sentencia desde 1; lee el workgroup y la región de los outputs del estado Terraform, inicia la consulta, espera su finalización, descarga el CSV de Athena, elimina las comillas y agrega el ID a `evidencias/ejecuciones_athena.csv`. Requiere `infraestructura/` inicializada y con su estado disponible.

### 3. Incorporar el tercer día

Sin cambiar infraestructura ni propiedades de la tabla, cargue solo el archivo nuevo y ejecute las consultas:

```bash
aws s3 cp data/entregas/fecha=2026-10-03/entregas.csv "s3://$BUCKET/entregas/fecha=2026-10-03/entregas.csv"
scripts/ejecutar_consulta_athena.sh final consultas/verificacion_tercer_dia.sql resultados/final/verificacion_tercer_dia.csv 1
scripts/ejecutar_consulta_athena.sh final consultas/verificacion_tercer_dia.sql resultados/final/conteo_estados_tercer_dia.csv 2
scripts/ejecutar_consulta_athena.sh final consultas/verificacion_tercer_dia.sql resultados/final/total_registros.csv 3
scripts/ejecutar_consulta_athena.sh final consultas/intentos_por_fecha_estado.sql resultados/final/intentos_por_fecha_estado.csv
scripts/ejecutar_consulta_athena.sh final consultas/porcentaje_exito_por_fecha_ciudad.sql resultados/final/porcentaje_exito_por_fecha_ciudad.csv
scripts/ejecutar_consulta_athena.sh final consultas/duracion_promedio_2026-10-02.sql resultados/final/duracion_promedio_2026-10-02.csv
```

Las sentencias de verificación muestran seis registros del día 3, conteos por estado y 18 registros en total. Las consultas agregadas ya filtraban con `fecha BETWEEN '2026-10-01' AND '2026-10-03'`, por lo que no fue necesario modificar su SQL. No se utilizaron crawler, `MSCK REPAIR TABLE`, `ALTER TABLE ADD PARTITION` ni particiones individuales en Terraform.

### 4. Comparar con las referencias

Los seis resultados comparables de la ejecución documentada son idénticos byte a byte a sus referencias. `diff` no muestra salida cuando coinciden:

```bash
diff resultados/inicial/intentos_por_fecha_estado.csv resultados_esperados/intentos_por_fecha_estado_inicial.csv
diff resultados/inicial/porcentaje_exito_por_fecha_ciudad.csv resultados_esperados/porcentaje_exito_por_fecha_ciudad_inicial.csv
diff resultados/inicial/duracion_promedio_2026-10-02.csv resultados_esperados/duracion_promedio_2026-10-02.csv
diff resultados/final/intentos_por_fecha_estado.csv resultados_esperados/intentos_por_fecha_estado_final.csv
diff resultados/final/porcentaje_exito_por_fecha_ciudad.csv resultados_esperados/porcentaje_exito_por_fecha_ciudad_final.csv
diff resultados/final/duracion_promedio_2026-10-02.csv resultados_esperados/duracion_promedio_2026-10-02.csv
```

| Resultado | Referencia en `resultados_esperados/` | ID de Athena |
| --- | --- | --- |
| `resultados/inicial/intentos_por_fecha_estado.csv` | `intentos_por_fecha_estado_inicial.csv` | `21124626-73ec-499b-b446-e3d37f501a68` |
| `resultados/inicial/porcentaje_exito_por_fecha_ciudad.csv` | `porcentaje_exito_por_fecha_ciudad_inicial.csv` | `17b01941-b30a-487f-a59d-5c4e41e43255` |
| `resultados/inicial/duracion_promedio_2026-10-02.csv` | `duracion_promedio_2026-10-02.csv` | `204a4bb9-a8fe-450c-8e32-f55057ef152f` |
| `resultados/final/intentos_por_fecha_estado.csv` | `intentos_por_fecha_estado_final.csv` | `dc03d83f-07c1-45e1-b76b-9043e4e0696e` |
| `resultados/final/porcentaje_exito_por_fecha_ciudad.csv` | `porcentaje_exito_por_fecha_ciudad_final.csv` | `58765ecf-e1de-4401-aa2a-8043890e02f3` |
| `resultados/final/duracion_promedio_2026-10-02.csv` | `duracion_promedio_2026-10-02.csv` | `cf17865b-48ae-4013-97d7-780ee6cd0f74` |

Otras ejecuciones registradas: verificación inicial `2ffae99c-8b8b-40c3-a9c6-68ec38987ab9`; registros del tercer día `55064003-1e57-4fc0-bffa-ecc5ff245bf9`; conteos por estado `81f55afa-e264-43c1-8413-d8c8378628a2`; total `14416c99-7d19-4240-aec9-a5fffd37c393`.

## Evidencias

- `aplicacion_terraform.txt` y `outputs.json`: aplicación y nombres de recursos.
- `verificacion_recursos_aws.txt`: comprobaciones CLI del bucket, catálogo, cero particiones y workgroup.
- `carga_inicial_s3.txt` y `carga_tercer_dia_s3.txt`: cargas separadas; el segundo compara propiedades de la tabla antes y después.
- `ejecuciones_athena.csv`: etapa, SQL, ID y resultado de cada ejecución; `detalle_ejecuciones_athena.json`: estado `SUCCEEDED` y workgroup de las ejecuciones.
- `eliminacion_terraform.txt`: vaciado, destrucción y verificaciones posteriores. Los identificadores de cuenta de las evidencias se reemplazaron por `<ID_CUENTA_AWS>`.

## Limpieza

Guarde antes los resultados y evidencias necesarios. Compruebe que `BUCKET` identifica exclusivamente el bucket de este ejercicio: el primer comando elimina todos sus objetos, incluidos resultados de Athena. Después destruya usando el estado del mismo despliegue y verifique que los recursos ya no existen:

```bash
aws s3 rm "s3://$BUCKET" --recursive
terraform -chdir=infraestructura destroy -auto-approve
aws s3api head-bucket --bucket "$BUCKET"
aws glue get-database --name mensajeria_entregas
aws glue get-table --database-name mensajeria_entregas --name intentos_entrega
aws athena get-work-group --work-group wg_entregas_quintero
```

Tras la eliminación se esperan respuestas de recurso inexistente. La ejecución documentada destruyó siete recursos; su estado y `.terraform/` se movieron fuera del repositorio después de la destrucción.
