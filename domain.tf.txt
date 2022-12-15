#  terraform import aws_route53_zone.primary YOUR_ROUTE_53_ZONE_ID

data "aws_route53_zone" "primary" {
  name         = "yourapp.com"
  private_zone = false
}

resource "aws_apigatewayv2_domain_name" "www_yourapp_com" {
  domain_name = format("www.%s", var.domain)

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.www_yourapp_com.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}


resource "aws_route53_record" "www_yourapp_com" {
  name    = aws_apigatewayv2_domain_name.www_yourapp_com.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.primary.zone_id
  depends_on = [
    aws_acm_certificate.www_yourapp_com
  ]

  alias {
    name                   = aws_apigatewayv2_domain_name.www_yourapp_com.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.www_yourapp_com.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "alias_route53_record" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = ""
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.www_yourapp_com.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.www_yourapp_com.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "yourapp_com" {
  domain_name = var.domain
  validation_method = "DNS"
}

resource "aws_acm_certificate" "www_yourapp_com" {
  domain_name = format("www.%s", var.domain)
  validation_method = "DNS"
}

resource "aws_apigatewayv2_api_mapping" "api_mapping" {
  api_id      = aws_apigatewayv2_api.api.id
  domain_name = aws_apigatewayv2_domain_name.www_yourapp_com.id
  stage       = aws_apigatewayv2_stage.apigateway.id
}
