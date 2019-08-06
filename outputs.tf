output "firehose_arn" {
  value = aws_kinesis_firehose_delivery_stream.main.*.arn
}

output "kinesis_stream_arn" {
  value = module.kinesis_stream.arn
}

output "bucket_arn" {
  value = module.s3.bucket_arn
}

output "role_firehose_arn" {
  value = module.role_firehose.role_arn
}

output "role_kinses_stream_read_arn" {
  value = module.role_kinesis_stream_read.role_arn
}

output "role_kinesis_stream_write_arn" {
  value = module.role_kinesis_stream_write.role_arn
}
