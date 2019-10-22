data "aws_cloudwatch_log_group" "selected_log_group" {
  name = var.log_group
}

data "http" "function_source" {
  url = "https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/aws/cloudwatch/lambda/cw.js"
}

data "archive_file" "function_archive" {
  type        = "zip"
  output_path = "${path.module}/files/CWToCoralogix.zip"
  source {
    content  = data.http.function_source.body
    filename = "index.js"
  }
}

data "aws_iam_policy_document" "lambda_role_assume_policy_document" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_role_policy_document" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/lambda/${local.lambda_name}:*"]
  }
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${local.lambda_name}"
  retention_in_days = 14
}

resource "aws_iam_role" "lambda_role" {
  name               = "${local.lambda_name}-Role"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.lambda_role_assume_policy_document.json
}

resource "aws_iam_role_policy" "lambda_role_policy" {
  name       = "${local.lambda_name}-Role-Policy"
  role       = aws_iam_role.lambda_role.id
  policy     = data.aws_iam_policy_document.lambda_role_policy_document.json
  depends_on = [aws_iam_role.lambda_role]
}

resource "aws_lambda_function" "lambda_function" {
  function_name    = local.lambda_name
  description      = "Ship logs to Coralogix from CW ${data.aws_cloudwatch_log_group.selected_log_group.name} log group"
  filename         = data.archive_file.function_archive.output_path
  source_code_hash = data.archive_file.function_archive.output_base64sha256
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs10.x"
  memory_size      = 1024
  timeout          = 30
  publish          = true
  environment {
    variables = {
      private_key     = var.private_key
      app_name        = var.app_name
      sub_name        = var.sub_name
      newline_pattern = var.newline_pattern
    }
  }
  depends_on = [
    aws_cloudwatch_log_group.lambda_log_group,
    aws_iam_role.lambda_role,
    aws_iam_role_policy.lambda_role_policy
  ]
}

resource "aws_lambda_permission" "lambda_function_permissions" {
  function_name = aws_lambda_function.lambda_function.function_name
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  principal     = "logs.amazonaws.com"
  source_arn    = data.aws_cloudwatch_log_group.selected_log_group.arn
  depends_on    = [
    aws_iam_role.lambda_role,
    aws_lambda_function.lambda_function
  ]
}

resource "aws_cloudwatch_log_subscription_filter" "log_group_trigger" {
  name            = local.lambda_name
  log_group_name  = data.aws_cloudwatch_log_group.selected_log_group.name
  filter_pattern  = var.filter_pattern
  destination_arn = aws_lambda_function.lambda_function.arn
  depends_on = [
    aws_lambda_function.lambda_function,
    aws_lambda_permission.lambda_function_permissions
  ]
}
