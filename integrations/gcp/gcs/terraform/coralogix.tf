variable "private_key" {
  type        = "string"
  description = "Coralogix Private Key."
}

variable "app_name" {
  type        = "string"
  description = "Application name."
}

variable "sub_name" {
  type        = "string"
  description = "Subsystem name."
}

variable "bucket_name" {
  type        = "string"
  description = "Name of storage bucket to watch."
}

provider "google" {
  project     = "YOUR_GCP_PROJECT_ID"
  region      = "us-central1"
}

resource "google_storage_bucket_object" "gcs_to_coralogix_function_sources" {
  name   = "gcsToCoralogix.zip"
  bucket = "${var.bucket_name}"
  source = "./gcsToCoralogix.zip"
}

resource "google_cloudfunctions_function" "gcs_to_coralogix_function" {
  name                  = "${var.bucket_name}_to_coralogix"
  description           = "Cloud Function which send logs from storage bucket to Coralogix."
  runtime               = "python37"
  available_memory_mb   = 1024
  timeout               = 60
  entry_point           = "to_coralogix"
  source_archive_bucket = "${var.bucket_name}"
  source_archive_object = "${google_storage_bucket_object.gcs_to_coralogix_function_sources.name}"
  event_trigger {
    resource            = "${var.bucket_name}"
    event_type          = "google.storage.object.finalize"
  }
  environment_variables = {
    private_key = "${var.private_key}"
    app_name    = "${var.app_name}"
    sub_name    = "${var.sub_name}"
  }
}
