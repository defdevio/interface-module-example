variable "account_id" {
  description = "AWS account ID used in names and IAM trust policies."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "account_id must be a 12-digit AWS account ID."
  }
}

variable "aws_region" {
  description = "AWS region where the example resources will be created."
  type        = string
  default     = "us-west-2"
}

variable "aws_skip_credentials_validation" {
  description = "Skip AWS credential, metadata, and account ID validation; intended for plan-only tests."
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment name; development permits mutable ECR tags."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be one of dev, test, or prod."
  }
}

variable "lambda_functions" {
  default     = {}
  description = "Application Lambda function specifications."

  type = map(object({
    spec = object({
      concurrent_executions = optional(number, -1)
      description           = string
      environment_variables = optional(map(string), {})
      timeout               = optional(number, 5)

      custom_iam_policy_statements = optional(list(object({
        actions   = set(string)
        effect    = optional(string, "Allow")
        resources = set(string)
        sid       = optional(string)

        conditions = optional(list(object({
          test     = string
          values   = set(string)
          variable = string
        })), [])
      })), [])

      ecr = object({
        image_tag = string
      })
    })
  }))

  validation {
    condition = alltrue(flatten([
      for _, function in var.lambda_functions : [
        for statement in function.spec.custom_iam_policy_statements :
        !contains(statement.actions, "*") && !contains(statement.resources, "*")
      ]
    ]))
    error_message = "Custom IAM policy statements must not use wildcard (*) actions or resources."
  }
}

variable "s3_buckets" {
  default     = {}
  description = "S3 bucket specifications, optionally associated with a Lambda function key."

  type = map(object({
    spec = object({
      resource_key_ref    = optional(string, null)
      source_file_path    = optional(string, null)
      source_file_pattern = optional(string, null)
    })
  }))

  validation {
    condition = alltrue([
      for _, bucket in var.s3_buckets :
      bucket.spec.resource_key_ref == null ? true : contains(keys(var.lambda_functions), bucket.spec.resource_key_ref)
    ])
    error_message = "Each non-null S3 resource_key_ref must match a key in lambda_functions."
  }
}
