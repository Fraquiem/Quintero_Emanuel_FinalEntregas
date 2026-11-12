variable "region" {
  description = "Región de AWS donde se despliegan los recursos del ejercicio."
  type        = string
  default     = "us-east-2"
}

variable "nombre_bucket" {
  description = "Nombre global y único del bucket S3 privado del ejercicio."
  type        = string
  default     = "quintero-emanuel-entregas-final-de"
}

variable "prefijo_datos" {
  description = "Prefijo del bucket donde se cargan los CSV de entregas (sin barra final)."
  type        = string
  default     = "entregas"
}

variable "prefijo_resultados_athena" {
  description = "Prefijo del bucket donde Athena escribe los resultados de las consultas (sin barra final)."
  type        = string
  default     = "resultados-athena"
}

variable "nombre_base_datos" {
  description = "Nombre de la base de datos de Glue Data Catalog."
  type        = string
  default     = "mensajeria_entregas"
}

variable "nombre_tabla" {
  description = "Nombre de la tabla externa de Glue con los intentos de entrega."
  type        = string
  default     = "intentos_entrega"
}

variable "nombre_workgroup" {
  description = "Nombre del workgroup de Athena usado para ejecutar las consultas."
  type        = string
  default     = "wg_entregas_quintero"
}

variable "rango_proyeccion_fecha" {
  description = "Rango inclusivo de la proyección de la partición fecha, en formato yyyy-MM-dd."
  type = object({
    inicio = string
    fin    = string
  })
  default = {
    inicio = "2026-10-01"
    fin    = "2026-10-03"
  }
}
