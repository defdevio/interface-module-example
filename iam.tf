module "iam" {
  source = "github.com/defdevio/terraform-aws-iam?ref=v1.2.0"

  account_id = var.account_id

  roles = {
    for key, function in var.lambda_functions : key => {
      name                         = "lambda-execution-${replace(key, "_", "-")}"
      custom_iam_policy_statements = function.spec.custom_iam_policy_statements
    }
  }
}
