data "aws_dynamodb_table" "song_order" {
  name = "lyria_song_order"
}

data "aws_s3_bucket" "lyria_storage_dev" {
  bucket = "lyria-storage-2024-dev"
}

data "aws_s3_bucket" "lyria_storage_prod" {
  bucket = "lyria-storage-2024-prod"
}