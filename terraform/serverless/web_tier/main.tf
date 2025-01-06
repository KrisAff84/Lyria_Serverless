provider "aws" {
  region  = "us-east-1"
  profile = "kris84"
}

######################################################
# S3 Buckets - For static files
######################################################

resource "aws_s3_bucket" "static_files" {
  for_each      = toset(["dev", "prod"])
  force_destroy = false
  bucket        = "${var.name_prefix}-static-files-${each.key}"
}

resource "aws_s3_bucket_website_configuration" "static_files" {
  bucket = aws_s3_bucket.static_files["dev"].bucket

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "static_files" {
  bucket = aws_s3_bucket.static_files["dev"].bucket
}

resource "aws_s3_bucket_ownership_controls" "static_files" {
  bucket = aws_s3_bucket.static_files["dev"].bucket
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_policy" "prod_static_files" {
  bucket = aws_s3_bucket.static_files["prod"].bucket
  policy = jsonencode({
    Version = "2008-10-17"
    Id      = "PolicyForCloudFrontPrivateContent"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.static_files["prod"].arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.static_files.arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "dev_static_files" {
  bucket = aws_s3_bucket.static_files["dev"].bucket
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "PublicReadAccess"
    Statement = [
      {
        Sid    = "PublicReadGetObject"
        Effect = "Allow"
        Principal = "*"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.static_files["dev"].arn}/*"
      }
    ]
  })
}



######################################################
# CloudFront Distribution - For caching static files
######################################################

resource "aws_cloudfront_distribution" "static_files" {
  comment             = "Caches Lyria Static Files from S3"
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = var.domain_aliases


  origin {
    domain_name              = aws_s3_bucket.static_files["prod"].bucket_regional_domain_name
    origin_id                = "prod_static_files"
    origin_access_control_id = aws_cloudfront_origin_access_control.static_files.id
  }

  default_cache_behavior {
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD", "OPTIONS"]
    target_origin_id         = "prod_static_files"
    cache_policy_id          = var.cache_policy_id
    origin_request_policy_id = var.origin_request_policy_id
    viewer_protocol_policy   = "redirect-to-https"
    min_ttl                  = 0
    default_ttl              = 0
    max_ttl                  = 0
    compress                 = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"

  }

  # Add logging bucket eventually
  # logging_config {
  #   bucket          = var.log_bucket
  #   include_cookies = false
  #   prefix          = "static_files/"
  # }

  tags = {
    App = var.name_prefix
    Use = "Caching Static Files"
  }
}

resource "aws_cloudfront_origin_access_control" "static_files" {
  name                              = "${var.name_prefix}-static-files"
  description                       = "Restricts access to S3 bucket to CloudFront"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
  origin_access_control_origin_type = "s3"
}