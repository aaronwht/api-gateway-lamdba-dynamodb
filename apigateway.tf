resource "aws_apigatewayv2_api" "http" {
  name          = terraform.workspace
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins  = ["*"]
    allow_methods  = ["*"]
    allow_headers  = ["*"]
    expose_headers = ["*"]
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  for_each           = local.function
  api_id             = aws_apigatewayv2_api.http.id
  integration_uri    = aws_lambda_function.lambda[each.key].invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "lambda" {
  for_each  = local.function
  api_id    = aws_apigatewayv2_api.http.id
  route_key = each.value
  target    = "integrations/${aws_apigatewayv2_integration.lambda[each.key].id}"
}
