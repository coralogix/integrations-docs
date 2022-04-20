variable "private_key" {
  type        = string
  description = "A private key which is used to validate your authenticity"
}

variable "app_name" {
  type        = string
  description = "The name of your application"
}

variable "sub_name" {
  type        = string
  description = "The subsystem name of your application"
  default     = ""
}

variable "newline_pattern" {
  type        = string
  description = "Pattern for lines splitting"
  default     = "(?:\\r\\n|\\r|\\n)"
}

variable "log_group" {
  type        = list(string)
  description = "The list of the CloudWatch log groups to watch"
}

variable "filter_pattern" {
  type        = string
  description = "Filter pattern for CloudWatch subscription filter"
  default     = ""
}

locals {
  lambda_name = "${var.app_name}-ToCoralogix"
}