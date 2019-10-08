data "aws_iam_policy_document" "lambda_role_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.bucket}/*"]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/lambda/${local.lambda_name}:*"]
  }
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${local.lambda_name}"
  retention_in_days = 14
}

resource "aws_iam_role" "lambda_role" {
  name               = "S3-${var.bucket}-ReadOnly"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.lambda_role_policy.json
}

resource "aws_lambda_function" "lambda_function" {
  function_name    = local.lambda_name
  description      = "Ship logs to Coralogix from S3 ${var.bucket} bucket"
  s3_bucket        = "coralogix-public"
  s3_key           = "tools/s3ToCoralogix.zip"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs8.10"
  memory_size      = "1024"
  timeout          = "30"
  publish          = true
  environment {
    variables = {
      private_key     = var.private_key
      app_name        = var.app_name
      sub_name        = var.sub_name
      newline_pattern = var.newline_pattern
    }
  }
  depends_on       = [
    aws_cloudwatch_log_group.lambda_log_group,
    aws_iam_role.lambda_role
  ]
}

resource "aws_s3_bucket_notification" "bucket_trigger" {
  bucket     = var.bucket
  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_lambda_function.lambda_function]
}
