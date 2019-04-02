output "project" {
  description = "GCP Project ID"
  value       = "${google_cloudfunctions_function.coralogix_function.project}"
}

output "region" {
  description = "GCP Region"
  value       = "${google_cloudfunctions_function.coralogix_function.region}"
}

output "bucket_name" {
  description = "Watched bucket"
  value       = "${google_cloudfunctions_function.coralogix_function.event_trigger.resource}"
}

output "function_sources_hash_md5" {
  description = "MD5 hash of the function sources"
  value       = "${base64decode(google_storage_bucket_object.function_archive.md5hash)}"
}

output "function_sources_hash_crc32" {
  description = "CRC32 hash of the function sources"
  value       = "${base64decode(google_storage_bucket_object.function_archive.crc32c)}"
}

output "app_name" {
  description = "Application name"
  value       = "${google_cloudfunctions_function.coralogix_function.environment_variables.app_name}"
}

output "sub_name" {
  description = "Subsystem name"
  type        = "${google_cloudfunctions_function.coralogix_function.environment_variables.sub_name}"
}
