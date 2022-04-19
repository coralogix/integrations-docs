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

output "log_group" {
  description = "Watched log group"
  value       = aws_cloudwatch_log_subscription_filter.log_group_trigger.log_group_name
}

output "app_name" {
  description = "Application name"
  value       = aws_lambda_function.lambda_function.environment[0].variables.app_name
}

output "sub_name" {
  description = "Subsystem name"
  value       = aws_lambda_function.lambda_function.environment[0].variables.sub_name
}