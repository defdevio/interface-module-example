locals {
  lambda_environment_variables = {
    for function_key, _ in var.lambda_functions : function_key => {
      DEFDEVIO_BUCKET_ARNS = join(",", [
        for _, bucket in module.s3 : bucket.bucket_arn
        if bucket.resource_key_ref == function_key
      ])
    }
  }
}

module "lambda_functions" {
  for_each = var.lambda_functions
  source   = "github.com/defdevio/terraform-aws-lambda?ref=v1.1.1"

  concurrent_executions = each.value.spec.concurrent_executions
  description           = each.value.spec.description
  function_name         = replace(each.key, "_", "-")
  iam_role_arn          = module.iam.role_arns[each.key]
  image_uri             = "${module.ecr[each.key].repo_url}:${each.value.spec.ecr.image_tag}"
  timeout               = each.value.spec.timeout

  environment_variables = merge(
    each.value.spec.environment_variables,
    local.lambda_environment_variables[each.key]
  )
}
