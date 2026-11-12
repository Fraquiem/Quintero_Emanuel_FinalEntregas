output "bucket" {
  description = "Nombre del bucket S3 privado del ejercicio."
  value       = aws_s3_bucket.datos.bucket
}

output "ubicacion_datos" {
  description = "Prefijo S3 donde se cargan los CSV de entregas."
  value       = local.ubicacion_datos
}

output "ubicacion_resultados_athena" {
  description = "Prefijo S3 configurado como ubicación de resultados del workgroup."
  value       = local.ubicacion_resultados
}

output "base_datos_glue" {
  description = "Nombre de la base de datos de Glue Data Catalog."
  value       = aws_glue_catalog_database.entregas.name
}

output "tabla_glue" {
  description = "Nombre de la tabla externa con partition projection."
  value       = aws_glue_catalog_table.intentos_entrega.name
}

output "plantilla_ubicacion_particion" {
  description = "Plantilla de ubicación de la partición fecha usada por partition projection."
  value       = aws_glue_catalog_table.intentos_entrega.parameters["storage.location.template"]
}

output "workgroup_athena" {
  description = "Nombre del workgroup de Athena."
  value       = aws_athena_workgroup.entregas.name
}

output "region" {
  description = "Región de AWS del despliegue."
  value       = var.region
}
