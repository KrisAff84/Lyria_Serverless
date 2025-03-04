output "api_gateway_invoke_url_dev" {
  value = "${aws_apigatewayv2_api.lyria_lambda_api.api_endpoint}/${aws_apigatewayv2_stage.dev.name}/${var.api_gateway_route}"
}

output "api_gateway_invoke_url_prod" {
  value = "${aws_apigatewayv2_api.lyria_lambda_api.api_endpoint}/${aws_apigatewayv2_stage.prod.name}/${var.api_gateway_route}"
}

output "base_cloudfront_url" {
  value = aws_cloudfront_distribution.lyria_lambda_cloudfront.domain_name
}

output "dev_cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.lyria_lambda_cloudfront.domain_name}/dev/${var.api_gateway_route}"
}

output "prod_cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.lyria_lambda_cloudfront.domain_name}/prod/${var.api_gateway_route}"
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.lyria_lambda_cloudfront.id
}