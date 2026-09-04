data "aws_iam_policy_document" "lambda_ecr_pull" {
  statement {
    effect = "Allow"

    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:SourceARN"
      values = [
        for key, _ in var.lambda_functions :
        "arn:aws:lambda:${var.aws_region}:${var.account_id}:function:${replace(key, "_", "-")}"
      ]
    }
  }
}

module "ecr" {
  for_each = var.lambda_functions
  source   = "github.com/defdevio/terraform-aws-ecr?ref=v1.0.0"

  name                 = "defdevio/lambda-${replace(each.key, "_", "-")}"
  is_immutable         = var.environment != "dev"
  repo_policy_document = data.aws_iam_policy_document.lambda_ecr_pull.json
}
