provider "aws" {
  region = "eu-west-1"
}

terraform {
  required_version = "~> 0.12"
}

variable "kms_key_alias" {
  type = map(string)

  default = {
    "kms_key" = "kms-dev-01"
  }
}

locals {
  kms_alias = format("alias/%s", lookup(var.kms_key_alias, "kms_key"))
}

data "aws_kms_key" "kms_key" {
  key_id = local.kms_alias
}

module "kinesis_firehose" {
  source              = "../../"
  name                = "kinesis-firehose-test-1"
  s3_bucket_name      = "kinesis-firehose-test-s3-1"
  kinesis_stream_name = "kinesis-firehose-stream-1"
//  kinesis_stream_create = false
  kms_master_key_id   = data.aws_kms_key.kms_key.arn

  allow_stream_read_arns = [
    "arn:aws:iam::12345678:user/test",
  ]

  allow_stream_write_arns = [
    "arn:aws:iam::12345678:user/test",
  ]
}
