output "key_id" {
  value = "${module.test_kinesis_key.key_id}"
}

output "key_arn" {
  value = "${module.test_kinesis_key.key_arn}"
}
