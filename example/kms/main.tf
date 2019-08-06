provider "aws" {
  region = "eu-west-1"
}

terraform {
  required_version = "~> 0.12"
}

# Encrypted bucket
module "test_kinesis_key" {
  source = "git@github.com:netf/terraform-aws-kms.git?ref=master"

  keys = [
    {
      description = "kinesis-firehose-key-01"
      alias       = "kinesis-firehose-key-01"
    },
  ]
}
