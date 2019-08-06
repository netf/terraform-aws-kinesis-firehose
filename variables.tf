variable "name" {
  type    = string
  default = "variable_check_test"
}

variable "enabled" {
  type    = bool
  default = true
}

variable "s3_bucket_name" {
  type    = string
  default = ""
}

variable "s3_bucket_create" {
  type    = bool
  default = true
}

variable "kinesis_stream_name" {
  type    = string
  default = ""
}

variable "kinesis_stream_create" {
  type = bool
  default = true
}

variable "kinesis_shard_count" {
  type    = string
  default = "1"
}

variable "kinesis_retention_period" {
  type    = string
  default = "24"
}

variable "buffer_size" {
  type    = string
  default = "128"
}

variable "buffer_interval" {
  type    = string
  default = "300"
}

variable "compression_format" {
  type    = string
  default = "Snappy"
}

variable "kms_master_key_id" {
  type    = string
  default = ""
}

variable "prefix" {
  type    = string
  default = ""
}

variable "error_output_prefix" {
  type    = string
  default = ""
}

variable "output_format" {
  type    = string
  default = "json"
}

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "convert_format" {
  type    = string
  default = "none"   // Enable Firehose Delivery Stream Convert record format - settings none / orc / parquet
}

variable "glue_catalog_db_name" {
  type    = string
  default = ""
}

variable "glue_catalog_table_name" {
  type    = string
  default = ""
}

# ARNs list to allow assuming a role that has permissions to write to the kinesis stream
variable "allow_stream_write_arns" {
  type    = list(string)
  default = []
}

# ARNs list to allow assuming a role that has permissions to read from the kinesis stream
variable "allow_stream_read_arns" {
  type    = list(string)
  default = []
}
