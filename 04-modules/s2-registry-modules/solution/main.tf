variable "envs" {
  type    = set(string)
  default = ["dev", "stg"]
}

module "artifacts" {
  source   = "terraform-aws-modules/s3-bucket/aws"
  version  = "~> 4.1"
  for_each = var.envs

  bucket_prefix = "tfadv-${each.key}-"
  force_destroy = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

resource "aws_s3_object" "readme" {
  for_each = module.artifacts

  bucket  = each.value.s3_bucket_id
  key     = "README.txt"
  content = "artifacts for ${each.key}"
}

output "buckets" {
  value = { for env, m in module.artifacts : env => m.s3_bucket_arn }
}
