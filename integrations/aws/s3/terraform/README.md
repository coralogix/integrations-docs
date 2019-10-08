provider "aws" {
  region = "eu-central-1"
}

module "s3_to_coralogix" {
  source =  "git::https://github.com/coralogix/integrations-docs.git//integrations/aws/s3/terraform"
  version = "1.0.0"

  private_key = "YOUR_PRIVATE_KEY"
  app_name    = "APP_NAME"
  sub_name    = "SUB_NAME"
  bucket_name = "YOUR_BUCKET_NAME"
}
