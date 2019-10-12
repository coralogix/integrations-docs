variable "private_key" {
  type        = "string"
  description = "A private key which is used to validate your authenticity"
}

variable "app_name" {
  type        = "string"
  description = "The name of your application"
}

variable "sub_name" {
  type        = "string"
  description = "The subsystem name of your application"
}

variable "newline_pattern" {
  type        = "string"
  description = "Pattern for lines splitting"
  default     = "(?:\\r\\n|\\r|\\n)"
}

variable "bucket_name" {
  type        = "string"
  description = "The name of the S3 bucket to watch"
}

variable "filter_prefix" {
  type        = "string"
  description = "S3 bucket objects prefix"
  default     = ""
}

variable "filter_suffix" {
  type        = "string"
  description = "S3 bucket objects suffix"
  default     = ""
}

variable "lambda_source_bucket" {
  type        = "string"
  description = "S3 bucket with lambda function source code"
  default     = "coralogix-public"
}

variable "lambda_source_object" {
  type        = "string"
  description = "S3 bucket object with lambda function source code"
  default     = "tools/s3ToCoralogix.zip"
}

locals {
  lambda_name = "S3-${var.bucket_name}-ToCoralogix"
}
