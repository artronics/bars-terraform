data "aws_route53_zone" "jalalhosseini-do-com" {
  name = var.domain_name
}

resource "aws_acm_certificate" "bars_certificate" {
  provider                  = aws.acm_provider
  domain_name               = var.domain_name
  subject_alternative_names = ["bars.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "bars" {
  zone_id = data.aws_route53_zone.jalalhosseini-do-com.id
  name = aws_apigatewayv2_domain_name.bars_api_domain_name.domain_name
#  name    = aws_api_gateway_domain_name.bars_domain.domain_name
  type    = "A"
  alias {
    evaluate_target_health = true
    name                   = aws_apigatewayv2_domain_name.bars_api_domain_name.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.bars_api_domain_name.domain_name_configuration[0].hosted_zone_id
  }
}

resource "aws_route53_record" "dns_validation" {
  for_each = {
  for dvo in aws_acm_certificate.bars_certificate.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
  }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.jalalhosseini-do-com.zone_id
}

resource "aws_acm_certificate_validation" "cert_validation_root" {
  provider                = aws.acm_provider
  certificate_arn         = aws_acm_certificate.bars_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.dns_validation : record.fqdn]
}
