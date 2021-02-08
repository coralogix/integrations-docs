data "http" "function_source" {
  url = "https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/gcp/gcs/lambda/main.py"
}

data "http" "function_requirements" {
  url = "https://raw.githubusercontent.com/coralogix/integrations-docs/master/integrations/gcp/gcs/lambda/requirements.txt"
}

data "archive_file" "function_archive" {
  type        = "zip"
  output_path = "${path.module}/files/gcsToCoralogix.zip"
  source {
    content  = data.http.function_source.body
    filename = "main.py"
  }
  source {
    content  = data.http.function_requirements.body
    filename = "requirements.txt"
  }
}

resource "google_storage_bucket_object" "function_archive" {
  name         = "gcsToCoralogix.zip"
  bucket       = var.bucket_name
  source       = data.archive_file.function_archive.output_path
}

resource "google_cloudfunctions_function" "coralogix_function" {
  name                  = "${var.bucket_name}_to-coralogix"
  description           = "Cloud Function which send logs from storage bucket to Coralogix."
  runtime               = "python38"
  available_memory_mb   = 1024
  timeout               = 60
  entry_point           = "to_coralogix"
  source_archive_bucket = var.bucket_name
  source_archive_object = google_storage_bucket_object.function_archive.name
  event_trigger {
    resource            = var.bucket_name
    event_type          = "google.storage.object.finalize"
  }
  environment_variables = {
    private_key = var.private_key
    app_name    = var.app_name
    sub_name    = var.sub_name
  }
  depends_on = [google_storage_bucket_object.function_archive]
}
