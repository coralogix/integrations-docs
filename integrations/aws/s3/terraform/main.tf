data "aws_s3_bucket" "selected_bucket" {
  bucket = var.bucket_name
}

data "aws_iam_policy_document" "lambda_assume_role_policy_document" {
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
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${data.aws_s3_bucket.selected_bucket.bucket}/*"]
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
  name               = "${local.lambda_name}-ReadOnly"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy_document.json
}

resource "aws_iam_role_policy" "lambda_role_policy" {
  name       = "${local.lambda_name}-ReadOnly-Policy"
  role       = aws_iam_role.lambda_role.id
  policy     = data.aws_iam_policy_document.lambda_role_policy_document.json
  depends_on = [aws_iam_role.lambda_role]
}

resource "aws_lambda_function" "lambda_function" {
  function_name    = local.lambda_name
  description      = "Ship logs to Coralogix from S3 ${data.aws_s3_bucket.selected_bucket.bucket} bucket"
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
  depends_on = [
    aws_cloudwatch_log_group.lambda_log_group,
    aws_iam_role.lambda_role,
    aws_iam_role_policy.lambda_role_policy
  ]
}

resource "aws_lambda_permission" "lambda_function_permissions" {
  function_name = aws_lambda_function.lambda_function.function_name
  statement_id  = "AllowExecutionFromS3Bucket-${data.aws_s3_bucket.selected_bucket.bucket}"
  action        = "lambda:InvokeFunction"
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.selected_bucket.arn
  depends_on    = [
    aws_iam_role.lambda_role,
    aws_lambda_function.lambda_function
  ]
}

resource "aws_s3_bucket_notification" "bucket_trigger" {
  bucket = data.aws_s3_bucket.selected_bucket.bucket
  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
  }
  depends_on = [
    aws_lambda_function.lambda_function,
    aws_lambda_permission.lambda_function_permissions
  ]
}
