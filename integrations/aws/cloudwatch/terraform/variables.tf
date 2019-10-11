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
  default     = ""
}

variable "newline_pattern" {
  type        = "string"
  description = "Pattern for lines splitting"
  default     = "/(?:\r\n|\r|\n)/g"
}

variable "log_group" {
  type        = "string"
  description = "The name of the CloudWatch log group to watch"
}

locals {
  lambda_name = "CW-${var.log_group}-ToCoralogix"
}
