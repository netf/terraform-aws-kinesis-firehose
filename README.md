# dp-terraform-kinesis-firehose

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| allow\_stream\_read\_arns | ARNs list to allow assuming a role that has permissions to read from the kinesis stream | list | `[]` | no |
| allow\_stream\_write\_arns | ARNs list to allow assuming a role that has permissions to write to the kinesis stream | list | `[]` | no |
| aws\_region |  | string | `"eu-west-1"` | no |
| buffer\_interval |  | string | `"300"` | no |
| buffer\_size |  | string | `"128"` | no |
| compression\_format |  | string | `"Snappy"` | no |
| convert\_format |  | string | `"none"` | no |
| error\_output\_prefix |  | string | `""` | no |
| glue\_catalog\_db\_name |  | string | `""` | no |
| glue\_catalog\_table\_name |  | string | `""` | no |
| kinesis\_retention\_period |  | string | `"24"` | no |
| kinesis\_shard\_count |  | string | `"1"` | no |
| kinesis\_stream\_name |  | string | `""` | no |
| kms\_master\_key\_id |  | string | `""` | no |
| name |  | string | `"variable_check_test"` | no |
| output\_format |  | string | `"json"` | no |
| prefix |  | string | `""` | no |
| s3\_bucket\_name |  | string | `""` | no |
| tags |  | map | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket\_arn |  |
| firehose\_arn |  |
| kinesis\_stream\_arn |  |
| role\_firehose\_arn |  |
| role\_kinesis\_stream\_write\_arn |  |
| role\_kinses\_stream\_read\_arn |  |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


