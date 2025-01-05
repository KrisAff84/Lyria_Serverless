data "aws_s3_bucket" "dev" {
    bucket = "lyria-static-files-dev"
}

data "aws_s3_bucket" "prod" {
    bucket = "lyria-static-files-prod"
}

data "aws_cloudfront_distribution" "static_files" {
    id = "E11QCPE7ZK4PG7"
}