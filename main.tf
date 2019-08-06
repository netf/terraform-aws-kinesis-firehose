locals {
  s3_bucket_name      = var.s3_bucket_name != "" ? var.s3_bucket_name : var.name
  s3_bucket_arn       = var.s3_bucket_create ? module.s3.bucket_arn : format("arn:aws:s3:::%s", local.s3_bucket_name)
  kinesis_stream_name = var.kinesis_stream_name != "" ? var.kinesis_stream_name : var.name
}

data aws_caller_identity "main" {}

module "s3" {
  source                    = "git@github.com:netf/terraform-aws-s3.git?ref=master"
  enabled                   = var.s3_bucket_create
  name                      = local.s3_bucket_name
  allow_read                = [module.role_firehose.role_arn]
  allow_write               = [module.role_firehose.role_arn]
  enable_sse                = true
  bucket_owner_full_control = false
  kms_master_key_id         = var.kms_master_key_id
  tags                      = var.tags
}

resource "aws_cloudwatch_log_group" "main" {
  name = local.kinesis_stream_name
  tags = var.tags
}

resource "aws_cloudwatch_log_stream" "main" {
  name           = local.kinesis_stream_name
  log_group_name = aws_cloudwatch_log_group.main.name
}

module "role_firehose" {
  source        = "git@github.com:netf/terraform-aws-iam-role.git?ref=master"
  allow_service = "firehose.amazonaws.com"
  name          = "${local.kinesis_stream_name}-read-s3-write"
  tags          = var.tags

  s3_write = [
    local.s3_bucket_name,
  ]

  policy_inline = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "glue:GetTableVersions"
      ],
      "Resource": "*"
    }, {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::${local.s3_bucket_name}",
        "arn:aws:s3:::${local.s3_bucket_name}/*",
        "arn:aws:s3:::%FIREHOSE_BUCKET_NAME%",
        "arn:aws:s3:::%FIREHOSE_BUCKET_NAME%/*"
      ]
    }, {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction",
        "lambda:GetFunctionConfiguration"
      ],
      "Resource": "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.main.account_id}:function:%FIREHOSE_DEFAULT_FUNCTION%:%FIREHOSE_DEFAULT_VERSION%"
    }, {
      "Effect": "Allow",
      "Action": [
        "kms:GenerateDataKey",
        "kms:Decrypt"
      ],
      "Resource": [
        "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.main.account_id}:key/${var.kms_master_key_id}"
      ],
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "s3.eu-west-1.amazonaws.com"
        },
        "StringLike": {
          "kms:EncryptionContext:aws:s3:arn": [
            "arn:aws:s3:::${local.s3_bucket_name}/*"
          ]
        }
      }
    }, {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.main.account_id}:log-group:${aws_cloudwatch_log_group.main.name}:log-stream:${aws_cloudwatch_log_stream.main.name}"
      ]
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "kinesis:DescribeStream",
        "kinesis:GetShardIterator",
        "kinesis:GetRecords"
      ],
      "Resource": "arn:aws:kinesis:${var.aws_region}:${data.aws_caller_identity.main.account_id}:stream/${local.kinesis_stream_name}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": [
        "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.main.account_id}:key/%SSE_KEY_ID%"
      ],
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "kinesis.eu-west-1.amazonaws.com"
        },
        "StringLike": {
          "kms:EncryptionContext:aws:kinesis:arn": "arn:aws:kinesis:${var.aws_region}:${data.aws_caller_identity.main.account_id}:stream/${local.kinesis_stream_name}"
        }
      }
    }
  ]
}
EOF
}

module "kinesis_stream" {
  source           = "git@github.com:netf/terraform-aws-kinesis-stream.git?ref=master"
  enabled          = var.kinesis_stream_create
  name             = local.kinesis_stream_name
  shard_count      = var.kinesis_shard_count
  retention_period = var.kinesis_retention_period
  tags             = var.tags
}

module "role_kinesis_stream_read" {
  source    = "git@github.com:netf/terraform-aws-iam-role.git?ref=master"
  enabled   = length(var.allow_stream_read_arns) > 0 ? true : false
  allow_arn = var.allow_stream_read_arns
  name      = "${var.name}-read"
  tags      = var.tags

  policy_inline = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "kinesis:Get*",
                "kinesis:DescribeStream"
            ],
            "Resource": "arn:aws:kinesis:${var.aws_region}:${data.aws_caller_identity.main.account_id}:stream/${local.kinesis_stream_name}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "kinesis:ListStreams"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

module "role_kinesis_stream_write" {
  source    = "git@github.com:netf/terraform-aws-iam-role.git?ref=master"
  enabled   = length(var.allow_stream_write_arns) > 0 ? true : false
  allow_arn = var.allow_stream_write_arns
  name      = "${var.name}-write"
  tags      = var.tags

  policy_inline = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "kinesis:Get*",
                "kinesis:PutRecord",
                "kinesis:PutRecords",
                "kinesis:DescribeStream"
            ],
            "Resource": "arn:aws:kinesis:${var.aws_region}:${data.aws_caller_identity.main.account_id}:stream/${local.kinesis_stream_name}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "kinesis:ListStreams"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_kinesis_firehose_delivery_stream" "main" {
  count       = var.convert_format == "none" ? 1 : 0
  name        = local.kinesis_stream_name
  destination = "extended_s3"

  tags = merge(var.tags, {
    "Name" = local.kinesis_stream_name
  })

  kinesis_source_configuration {
    kinesis_stream_arn = "arn:aws:kinesis:${var.aws_region}:${data.aws_caller_identity.main.account_id}:stream/${local.kinesis_stream_name}"
    role_arn           = module.role_firehose.role_arn
  }

  extended_s3_configuration {
    role_arn            = module.role_firehose.role_arn
    bucket_arn          = local.s3_bucket_arn
    buffer_size         = var.buffer_size
    buffer_interval     = var.buffer_interval
    compression_format  = var.compression_format
    kms_key_arn         = var.kms_master_key_id
    prefix              = var.prefix
    error_output_prefix = var.error_output_prefix

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.main.name
      log_stream_name = aws_cloudwatch_log_stream.main.name
    }
  }
}

resource "aws_kinesis_firehose_delivery_stream" "orc" {
  count       = var.convert_format == "orc" ? 1 : 0
  name        = local.kinesis_stream_name
  destination = "extended_s3"

  tags = merge(var.tags, {
    "Name" = local.kinesis_stream_name
  })

  kinesis_source_configuration {
    kinesis_stream_arn = "arn:aws:kinesis:${var.aws_region}:${data.aws_caller_identity.main.account_id}:stream/${local.kinesis_stream_name}"
    role_arn           = module.role_firehose.role_arn
  }

  extended_s3_configuration {
    role_arn            = module.role_firehose.role_arn
    bucket_arn          = local.s3_bucket_arn
    buffer_size         = var.buffer_size
    buffer_interval     = var.buffer_interval
    kms_key_arn         = var.kms_master_key_id
    prefix              = var.prefix
    error_output_prefix = var.error_output_prefix

    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          hive_json_ser_de {}
        }
      }

      output_format_configuration {
        serializer {
          orc_ser_de {}
        }
      }

      schema_configuration {
        database_name = var.glue_catalog_db_name
        role_arn      = module.role_firehose.role_arn
        table_name    = var.glue_catalog_table_name
      }
    }

    cloudwatch_logging_options {
      enabled         = "true"
      log_group_name  = aws_cloudwatch_log_group.main.name
      log_stream_name = aws_cloudwatch_log_stream.main.name
    }
  }
}

resource "aws_kinesis_firehose_delivery_stream" "parquet" {
  count       = var.convert_format == "parquet" ? 1 : 0
  name        = local.kinesis_stream_name
  destination = "extended_s3"

  tags = merge(var.tags, {
    "Name" = local.kinesis_stream_name
  })

  kinesis_source_configuration {
    kinesis_stream_arn = "arn:aws:kinesis:${var.aws_region}:${data.aws_caller_identity.main.account_id}:stream/${local.kinesis_stream_name}"
    role_arn           = module.role_firehose.role_arn
  }

  extended_s3_configuration {
    role_arn            = module.role_firehose.role_arn
    bucket_arn          = local.s3_bucket_arn
    buffer_size         = var.buffer_size
    buffer_interval     = var.buffer_interval
    kms_key_arn         = var.kms_master_key_id
    prefix              = var.prefix
    error_output_prefix = var.error_output_prefix

    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          hive_json_ser_de {}
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {}
        }
      }

      schema_configuration {
        database_name = var.glue_catalog_db_name
        role_arn      = module.role_firehose.role_arn
        table_name    = var.glue_catalog_table_name
      }
    }

    cloudwatch_logging_options {
      enabled         = "true"
      log_group_name  = aws_cloudwatch_log_group.main.name
      log_stream_name = aws_cloudwatch_log_stream.main.name
    }
  }
}
