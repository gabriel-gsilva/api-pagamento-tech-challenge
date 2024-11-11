output "api_url" {
  value = "${aws_api_gateway_deployment.mercadopago_deployment.invoke_url}/criar_preferencia"
}