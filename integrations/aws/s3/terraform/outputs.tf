output "lambda_name" {
  description = "Lambda name"
  value       = aws_lambda_function.lambda_function.function_name
}

output "lambda_role" {
  description = "Lambda role"
  value       = aws_iam_role.lambda_role.name
}

output "lambda_logs" {
  description = "Lambda logs"
  value       = aws_cloudwatch_log_group.lambda_log_group.name
}

output "bucket_name" {
  description = "Watched bucket"
  value       = aws_s3_bucket_notification.bucket_trigger.bucket
}

output "app_name" {
  description = "Application name"
  value       = aws_lambda_function.lambda_function.environment[0].variables.app_name
}

output "sub_name" {
  description = "Subsystem name"
  value       = aws_lambda_function.lambda_function.environment[0].variables.sub_name
}
