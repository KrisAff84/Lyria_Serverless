data "aws_cloudfront_distribution" "static_files" {
  id = var.cloudfront_id
}