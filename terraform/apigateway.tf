resource "aws_api_gateway_rest_api" "bars_mock_receiver" {
  name = "bars-mock-receiver"
}

resource "aws_api_gateway_domain_name" "bars_domain" {
  domain_name              = "bars.${var.domain_name}"
  regional_certificate_arn = aws_acm_certificate_validation.cert_validation_root.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "service" {
  parent_id   = aws_api_gateway_rest_api.bars_mock_receiver.root_resource_id
  path_part   = "service"
  rest_api_id = aws_api_gateway_rest_api.bars_mock_receiver.id
}

resource "aws_api_gateway_method" "get_service" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.service.id
  rest_api_id   = aws_api_gateway_rest_api.bars_mock_receiver.id
}

resource "aws_api_gateway_integration" "service_integration" {
  http_method = aws_api_gateway_method.get_service.http_method
  resource_id = aws_api_gateway_resource.service.id
  rest_api_id = aws_api_gateway_rest_api.bars_mock_receiver.id
  type        = "MOCK"
}

resource "aws_api_gateway_deployment" "bars_mock_receiver_deployment" {
  rest_api_id = aws_api_gateway_rest_api.bars_mock_receiver.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.service.id,
      aws_api_gateway_method.get_service.id,
      aws_api_gateway_integration.service_integration,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage_test" {
  deployment_id = aws_api_gateway_deployment.bars_mock_receiver_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.bars_mock_receiver.id
  stage_name    = var.environment
}
