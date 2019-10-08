output "project" {
  description = "GCP Project ID"
  value       = google_cloudfunctions_function.coralogix_function.project
}

output "region" {
  description = "GCP Region"
  value       = google_cloudfunctions_function.coralogix_function.region
}

output "bucket_name" {
  description = "Watched bucket"
  value       = google_cloudfunctions_function.coralogix_function.event_trigger.0.resource
}

output "local_hash" {
  description = "MD5 hash of the local file"
  value       = data.archive_file.function_archive.output_md5
}

output "remote_hash" {
  description = "MD5 hash of the remote file"
  value       = base64decode(google_storage_bucket_object.function_archive.md5hash)
}

output "app_name" {
  description = "Application name"
  value       = google_cloudfunctions_function.coralogix_function.environment_variables.app_name
}

output "sub_name" {
  description = "Subsystem name"
  value       = google_cloudfunctions_function.coralogix_function.environment_variables.sub_name
}
