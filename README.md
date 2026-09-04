# Interface Module

An opinionated OpenTofu/Terraform Interface Module for the [Interface Module pattern](https://defdev.io/blog/interface-module-pattern).

This module exposes an application-oriented contract and orchestrates four lower-level modules:

- IAM roles, including optional per-role custom policy statements
- ECR repositories with Lambda-only pull policies
- Lambda functions using images from the matching ECR repository
- S3 buckets with optional Lambda role association through `resource_key_ref`

The map keys are stable logical identifiers. Consumers describe relationships such as `resource_key_ref = "orders"`; they do not pass role ARNs or assemble bucket environment variables themselves.

The module is designed for application teams, so it validates relationships at the interface boundary and applies secure defaults before lower-level modules are called.

The S3 module's access-policy data source uses `count` based on whether `iam_role_arn` is null. Passing the IAM module's computed `role_arns` output would make that count unknown during plan. This example derives the ARN from the IAM module's stable role naming contract instead, so `tofu plan` can determine the S3 graph before apply. The IAM module still creates and owns the role.

## Usage

Call this module from an application or platform stack and provide the consumer contract:

```hcl
module "application" {
  source = "github.com/defdevio/interface-module-example?ref=v1.0.0"

  account_id = var.account_id

  lambda_functions = {
    orders = {
      spec = {
        description = "Processes order events"
        ecr = {
          image_tag = "2026.09.1"
        }
      }
    }
  }

  s3_buckets = {
    order_exports = {
      spec = {
        resource_key_ref = "orders"
      }
    }
  }
}
```

For a complete runnable stack, including provider configuration, direct application inputs, and plan instructions, see the [`interface-module-stack-example`](../interface-module-stack-example) repository.

## Test

The plan-only Terratest suite in `test` verifies the resources and wiring produced by this module without applying AWS resources:

```sh
cd test
go test ./...
```

The test supplies typed consumer inputs through Terratest and checks the planned IAM, ECR, Lambda, and S3 resources directly at the Interface Module boundary.

Pull requests run this Terratest suite automatically when opened.

## Releases

Releases are created automatically from conventional commits merged into `main`:

- `feat:` creates a minor release
- `fix:` creates a patch release
- `feat!:` or `fix!:` creates a major release
- `chore:` does not create a release

Install `pre-commit` and `terraform-docs`, then enable the repository hooks:

```sh
pre-commit install
pre-commit run --all-files
```

## Published module versions

The example pins the releases used by the article:

- `terraform-aws-iam` `v1.2.0`
- `terraform-aws-ecr` `v1.0.0` (the currently published release)
- `terraform-aws-lambda` `v1.1.1`
- `terraform-aws-s3` `v1.2.0`

The ECR module does not currently publish `v1.1.0`; the working example therefore uses its actual `v1.0.0` tag.

## Layout

- `variables.tf`: the consumer API and input validation
- `iam.tf`, `ecr.tf`, `lambda.tf`, `s3.tf`: implementation wiring
- `outputs.tf`: stable resource outputs for downstream consumers

## Module Reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.63.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ecr"></a> [ecr](#module\_ecr) | github.com/defdevio/terraform-aws-ecr | v1.0.0 |
| <a name="module_iam"></a> [iam](#module\_iam) | github.com/defdevio/terraform-aws-iam | v1.2.0 |
| <a name="module_lambda_functions"></a> [lambda\_functions](#module\_lambda\_functions) | github.com/defdevio/terraform-aws-lambda | v1.1.1 |
| <a name="module_s3"></a> [s3](#module\_s3) | github.com/defdevio/terraform-aws-s3 | v1.2.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy_document.lambda_ecr_pull](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | AWS account ID used in names and IAM trust policies. | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region where the example resources will be created. | `string` | `"us-west-2"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name; development permits mutable ECR tags. | `string` | `"dev"` | no |
| <a name="input_lambda_functions"></a> [lambda\_functions](#input\_lambda\_functions) | Application Lambda function specifications. | <pre>map(object({<br/>    spec = object({<br/>      concurrent_executions = optional(number, -1)<br/>      description           = string<br/>      environment_variables = optional(map(string), {})<br/>      timeout               = optional(number, 5)<br/><br/>      custom_iam_policy_statements = optional(list(object({<br/>        actions   = set(string)<br/>        effect    = optional(string, "Allow")<br/>        resources = set(string)<br/>        sid       = optional(string)<br/><br/>        conditions = optional(list(object({<br/>          test     = string<br/>          values   = set(string)<br/>          variable = string<br/>        })), [])<br/>      })), [])<br/><br/>      ecr = object({<br/>        image_tag = string<br/>      })<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_s3_buckets"></a> [s3\_buckets](#input\_s3\_buckets) | S3 bucket specifications, optionally associated with a Lambda function key. | <pre>map(object({<br/>    spec = object({<br/>      resource_key_ref    = optional(string, null)<br/>      source_file_path    = optional(string, null)<br/>      source_file_pattern = optional(string, null)<br/>    })<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ecr_repository_urls"></a> [ecr\_repository\_urls](#output\_ecr\_repository\_urls) | ECR repository URLs keyed by the caller-defined function key. |
| <a name="output_lambda_function_arns"></a> [lambda\_function\_arns](#output\_lambda\_function\_arns) | Lambda ARNs keyed by the caller-defined function key. |
| <a name="output_s3_bucket_arns"></a> [s3\_bucket\_arns](#output\_s3\_bucket\_arns) | S3 bucket ARNs keyed by the caller-defined bucket key. |
<!-- END_TF_DOCS -->
