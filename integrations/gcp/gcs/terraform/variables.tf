variable "private_key" {
  description = "Coralogix Private Key"
  type        = "string"
}

variable "app_name" {
  description = "Application name"
  type        = "string"
}

variable "sub_name" {
  description = "Subsystem name"
  type        = "string"
}

variable "bucket_name" {
  description = "The name of the storage bucket to watch"
  type        = "string"
}
