/*
This file configures an SSL certificate and adds the verification records to Route 53.
*/

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

resource "aws_acm_certificate" "ssl" {
  domain_name               = var.domain_name
  subject_alternative_names = var.alternate_domains
  validation_method         = "DNS"
  key_algorithm             = var.key_algorithm

  tags = var.tags
}

resource "aws_acm_certificate_validation" "ssl" {
  certificate_arn         = aws_acm_certificate.ssl.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]

}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.ssl.domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 300
}


data "aws_route53_zone" "main" {
  name = var.domain_name
}