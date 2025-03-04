variable "aws_profile" {
  description = "AWS profile to use"
  type        = string
  default     = "kris84"
}

variable "aws_region" {
  description = "AWS region to use"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Domain name to use for the SSL certificate"
  type        = string
  default     = "meettheafflerbaughs.com"
}

variable "alternate_domains" {
  description = "Alternate domain names to use for the SSL certificate"
  type        = list(string)
  default = [
    "www.meettheafflerbaughs.com",
    "meettheafflerbaughs.com",
  ]
}

variable "key_algorithm" {
  description = "Key algorithm to use for the SSL certificate"
  type        = string
  default     = "EC_prime256v1"
}

variable "tags" {
  description = "Tags to apply to the SSL certificate"
  type        = map(string)
  default     = {
    Name    = "SSL Certificate"
    Project = "Lyria"
    Use     = "Static Files CloudFront distribution"
  }
}