/*
DynamoDB Table that provides song order for the Lyria application.
Once the new infrastructure is deployed, this configuration should be
moved to serverless/data_tier, along with the S3 storage bucket configuration.
*/

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

resource "aws_dynamodb_table" "lyria_song_order" {
    name = var.table_name
    billing_mode = var.billing_mode
    read_capacity = var.read_capacity
    write_capacity = var.write_capacity
    hash_key = var.hash_key


    attribute {
        name = var.hash_key
        type = var.hash_key_type
    }
}