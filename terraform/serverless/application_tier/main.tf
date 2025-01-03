/*
This configuration file provisions the application tier of the Lyria application.
It provisions the following resources:
1. Lambda function - To get the song order from DynamoDB and return the song list, audio, and image files from S3
2. API Gateway - To expose the Lambda function as an API
3. CloudFront - To cache the API Gateway responses
*/

##########################################################
# API Gateway - To expose Lambda function
##########################################################

resource "aws_apigatewayv2_api" "lyria_lambda_api" {
  name          = "${var.name-prefix}-lambda-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_methods = ["GET"]
    allow_origins = ["*"]
  }
}

resource "aws_apigatewayv2_integration" "lyria_lambda_integration" {
  api_id                 = aws_apigatewayv2_api.lyria_lambda_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.lyria.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "lyria_lambda_route" {
  api_id    = aws_apigatewayv2_api.lyria_lambda_api.id
  route_key = "GET /index"
  target    = "integrations/${aws_apigatewayv2_integration.lyria_lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "dev" {
  api_id      = aws_apigatewayv2_api.lyria_lambda_api.id
  name        = "dev"
  auto_deploy = true
  stage_variables = {
    bucket = "lyria-storage-2024-dev"
  }
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.lyria_lambda_api.id
  name        = "prod"
  auto_deploy = true
  stage_variables = {
    bucket = "lyria-storage-2024-prod"
  }
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lyria.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lyria_lambda_api.execution_arn}/*/*"
}

##########################################################
# Lambda Function - For interacting with DynamoDB and S3
##########################################################

provider "aws" {
  region  = "us-east-1"
  profile = "kris84"
}

resource "aws_lambda_function" "lyria" {
  function_name = "${var.name-prefix}-lambda"
  description   = "Lambda function for Lyria - Gets song order from DynamoDB and returns song list, audio and image files"
  handler       = "lambda_function.handler"
  runtime       = "python3.12"
  filename      = "./src/lambda.zip"
  role          = aws_iam_role.lambda_exec.arn
}

resource "aws_iam_policy" "lambda_dynamodb_s3_access" {
  name = "${var.name-prefix}-lambda-dynamodb-s3-access"
  path = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:ListBucket",
        "s3:GetObject"
      ]
      Resource = [
        data.aws_s3_bucket.lyria_storage_dev.arn,
        "${data.aws_s3_bucket.lyria_storage_dev.arn}/*",
        data.aws_s3_bucket.lyria_storage_prod.arn,
        "${data.aws_s3_bucket.lyria_storage_prod.arn}/*"
      ]
      },
      {
        Effect   = "Allow"
        Action   = "dynamodb:Scan"
        Resource = [
          data.aws_dynamodb_table.song_order_dev.arn,
          data.aws_dynamodb_table.song_order_prod.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
    }]
  })
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.name-prefix}-lambda-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lyria_lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_dynamodb_s3_access.arn
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "./src"
  output_path = "./src/lambda.zip"
}

# Removes the lambda.zip file on a destroy operation
resource "terraform_data" "lambda_zip_remove" {
  depends_on = [data.archive_file.lambda_zip]

  provisioner "local-exec" {
    working_dir = "./src"
    command     = "rm lambda.zip"
    when        = destroy
  }
}

##########################################################
# CloudFront - For caching API Gateway Responses
##########################################################

resource "aws_cloudfront_distribution" "lyria_lambda_cloudfront" {
  comment = "Caches API Gateway response for Lyria - Song order and file URLs"
  origin {
    domain_name = replace(aws_apigatewayv2_api.lyria_lambda_api.api_endpoint, "https://", "")
    origin_id   = "api"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  default_root_object = null

  default_cache_behavior {
    target_origin_id         = "api"
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD", "OPTIONS"]
    cache_policy_id          = var.cache_policy_id
    origin_request_policy_id = var.origin_request_policy_id
    viewer_protocol_policy   = "redirect-to-https"
    min_ttl                  = 0
    default_ttl              = 0
    max_ttl                  = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "${var.name-prefix}-cloudfront"
  }
}
