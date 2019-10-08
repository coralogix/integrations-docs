variable "bucket" {
  type        = "string"
  description = "The name of the S3 bucket to watch"
}

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
  default     = "/(?:\r\n|\r|\n)/g"
}

locals {
  lambda_name = "S3-${var.bucket}-ToCoralogix"
}
