variable "name-prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "lyria"
}

variable "api_gateway_route" {
  description = "Route for API Gateway"
  type        = string
  default     = "index"
}

variable "cache_policy_id" {
  description = "ID of the cache policy for CloudFront"
  default     = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
}

variable "origin_request_policy_id" {
  description = "ID of the origin request policy for CloudFront"
  default     = "b689b0a8-53d0-40ab-baf2-68738e2966ac" # AllViewerExceptHostHeader
}