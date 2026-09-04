output "lambda_function_arns" {
  description = "Lambda ARNs keyed by the caller-defined function key."
  value       = { for key, function in module.lambda_functions : key => function.function_arn }
}

output "ecr_repository_urls" {
  description = "ECR repository URLs keyed by the caller-defined function key."
  value       = { for key, repository in module.ecr : key => repository.repo_url }
}

output "s3_bucket_arns" {
  description = "S3 bucket ARNs keyed by the caller-defined bucket key."
  value       = { for key, bucket in module.s3 : key => bucket.bucket_arn }
}
