#######################################################
# Global Variables
#######################################################

variable "aws_region" {
  description = "The AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "The AWS profile"
  type        = string
  default     = "kris84"
}

variable "name_prefix" {
  description = "The prefix name of all resources"
  type        = string
  default     = "lyria"
}

#######################################################
# Logging Bucket
#######################################################

variable "log_bucket" {
  description = "The bucket to store logs"
  type        = string
  default     = "lyria-logs-2024"
}

variable "log_bucket_endpoint" {
  description = "Endpoint for the logging bucket"
  default     = "lyria-logs-2024.s3.amazonaws.com"
}

#######################################################
# CloudFront Distribution
#######################################################

variable "cache_policy_id" {
  description = "The ID of the cache policy"
  type        = string
  default     = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
}

variable "origin_request_policy_id" {
  description = "The ID of the origin request policy"
  type        = string
  default     = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf" # CORS-S3Origin
}

variable "response_headers_policy_id" {
  description = "The ID of the response headers policy"
  type        = string
  default     = "eaab4381-ed33-4a86-88ca-d9558dc6cd63" # CORS-with-preflight-and-SecurityHeadersPolicy
}

#######################################################
# DynamoDB
#######################################################

variable "table_name" {
  description = "The name of the DynamoDB table"
  type        = string
  default     = "song_order"
}

variable "billing_mode" {
  description = "The billing mode for the DynamoDB table"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "hash_key" {
  description = "The hash key for the DynamoDB table"
  type        = string
  default     = "song_order"
}

variable "hash_key_type" {
  description = "The hash key type for the DynamoDB table"
  type        = string
  default     = "S"
}