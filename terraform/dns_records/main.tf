provider "aws" {
  region  = "us-east-1"
  profile = "kris84"
}

resource "aws_route53_record" "alias" {
  for_each = toset(["A", "AAAA"])
  zone_id  = var.hz_zone_id
  name     = var.record_name
  type     = each.key

  alias {
    name                   = data.aws_cloudfront_distribution.static_files.domain_name
    zone_id                = data.aws_cloudfront_distribution.static_files.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www" {
  zone_id = var.hz_zone_id
  name    = "www.${var.record_name}"
  type    = "CNAME"
  ttl     = var.cname_ttl

  records = [ "${var.record_name}."]
}