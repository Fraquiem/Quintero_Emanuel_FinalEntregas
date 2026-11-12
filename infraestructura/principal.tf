terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Proyecto = "DE-Final-Entregas"
      Autor    = "Quintero_Emanuel"
    }
  }
}

locals {
  ubicacion_datos      = "s3://${aws_s3_bucket.datos.bucket}/${var.prefijo_datos}/"
  ubicacion_resultados = "s3://${aws_s3_bucket.datos.bucket}/${var.prefijo_resultados_athena}/"
}

# Bucket privado que contiene los datos (entregas/) y los resultados de Athena (resultados-athena/).
resource "aws_s3_bucket" "datos" {
  bucket = var.nombre_bucket
}

resource "aws_s3_bucket_public_access_block" "datos" {
  bucket = aws_s3_bucket.datos.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "datos" {
  bucket = aws_s3_bucket.datos.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "datos" {
  bucket = aws_s3_bucket.datos.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_glue_catalog_database" "entregas" {
  name        = var.nombre_base_datos
  description = "Catálogo de los intentos de entrega de paquetes."
}

# Tabla externa sobre los CSV con partition projection por fecha (sin particiones registradas).
resource "aws_glue_catalog_table" "intentos_entrega" {
  name          = var.nombre_tabla
  database_name = aws_glue_catalog_database.entregas.name
  description   = "Intentos de entrega diarios en CSV, particionados por fecha mediante partition projection."
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "EXTERNAL"                       = "TRUE"
    "classification"                 = "csv"
    "skip.header.line.count"         = "1"
    "projection.enabled"             = "true"
    "projection.fecha.type"          = "date"
    "projection.fecha.format"        = "yyyy-MM-dd"
    "projection.fecha.range"         = "${var.rango_proyeccion_fecha.inicio},${var.rango_proyeccion_fecha.fin}"
    "projection.fecha.interval"      = "1"
    "projection.fecha.interval.unit" = "DAYS"
    "storage.location.template"      = "${local.ubicacion_datos}fecha=$${fecha}/"
  }

  partition_keys {
    name = "fecha"
    type = "string"
  }

  storage_descriptor {
    location      = local.ubicacion_datos
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "csv"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "field.delim"          = ","
        "serialization.format" = ","
      }
    }

    columns {
      name = "id_envio"
      type = "string"
    }

    columns {
      name = "ciudad"
      type = "string"
    }

    columns {
      name = "transportadora"
      type = "string"
    }

    columns {
      name = "estado"
      type = "string"
    }

    columns {
      name = "duracion_minutos"
      type = "int"
    }
  }
}

resource "aws_athena_workgroup" "entregas" {
  name          = var.nombre_workgroup
  description   = "Workgroup para las consultas del ejercicio de intentos de entrega."
  force_destroy = true

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false

    result_configuration {
      output_location = local.ubicacion_resultados

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}
