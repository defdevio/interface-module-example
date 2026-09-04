module "s3" {
  for_each = var.s3_buckets
  source   = "github.com/defdevio/terraform-aws-s3?ref=v1.2.0"

  resource_key_ref    = each.value.spec.resource_key_ref
  source_file_path    = each.value.spec.source_file_path
  source_file_pattern = each.value.spec.source_file_pattern

  bucket_name = replace(
    substr(
      "${var.account_id}-${replace(each.key, "_", "-")}-${var.aws_region}", 0, 63
    ), "-", ""
  )

  iam_role_arn = each.value.spec.resource_key_ref != null ? format(
    "arn:aws:iam::%s:role/lambda-execution-%s",
    var.account_id,
    replace(each.value.spec.resource_key_ref, "_", "-")
  ) : null
}
