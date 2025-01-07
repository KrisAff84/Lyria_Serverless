variable "hz_zone_id" {
  description = "Route53 zone ID for main domain"
  type        = string
  default     = "Z0128391RQJHDAKVG5ED"
}

variable "record_name" {
  description = "Domain name of records"
  type        = string
  default     = "meettheafflerbaughs.com"
}

variable "cloudfront_id" {
  description = "ID of the CloudFront distribution for the site"
  type        = string
  default     = "E11QCPE7ZK4PG7"
}

variable "cname_ttl" {
  description = "TTL for the CNAME record"
  type        = number
  default     = 172800
}