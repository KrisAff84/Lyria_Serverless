#########################################################
# Global Variables
#########################################################

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

#########################################################
# S3 Variables
#########################################################



#########################################################
# CloudFront Variables
#########################################################

variable "cache_policy_id" {
  description = "ID of the cache policy for CloudFront"
  default     = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
}

variable "origin_request_policy_id" {
  description = "ID of the origin request policy for CloudFront"
  default     = "b689b0a8-53d0-40ab-baf2-68738e2966ac" # AllViewerExceptHostHeader
}