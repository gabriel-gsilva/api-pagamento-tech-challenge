output "lambda_criar_preferencia_function_name" {
  description = "Nome da função Lambda para criar preferência"
  value       = aws_lambda_function.criar_preferencia.function_name
}

output "lambda_retorno_function_name" {
  description = "Nome da função Lambda para processar retorno"
  value       = aws_lambda_function.retorno.function_name
}

output "lambda_criar_preferencia_invoke_arn" {
  description = "ARN de invocação da função Lambda para criar preferência"
  value       = aws_lambda_function.criar_preferencia.invoke_arn
}

output "lambda_retorno_invoke_arn" {
  description = "ARN de invocação da função Lambda para processar retorno"
  value       = aws_lambda_function.retorno.invoke_arn
}

output "api_gateway_id" {
  description = "ID do API Gateway"
  value       = aws_api_gateway_rest_api.mercadopago_api.id
}

output "api_gateway_root_resource_id" {
  description = "ID do recurso raiz do API Gateway"
  value       = aws_api_gateway_rest_api.mercadopago_api.root_resource_id
}

output "api_gateway_execution_arn" {
  description = "ARN de execução do API Gateway"
  value       = aws_api_gateway_rest_api.mercadopago_api.execution_arn
}

output "api_gateway_stage_name" {
  description = "Nome do estágio do API Gateway"
  value       = aws_api_gateway_stage.api_stage.stage_name
}

output "api_gateway_invoke_url" {
  description = "URL de invocação do API Gateway"
  value       = aws_api_gateway_stage.api_stage.invoke_url
}

output "criar_preferencia_url" {
  description = "URL completa para criar preferência"
  value       = "${aws_api_gateway_stage.api_stage.invoke_url}${aws_api_gateway_resource.criar_preferencia.path}"
}

output "retorno_url" {
  description = "URL completa para o retorno do Mercado Pago"
  value       = "${aws_api_gateway_stage.api_stage.invoke_url}${aws_api_gateway_resource.retorno.path}"
}

output "iam_role_name" {
  description = "Nome da IAM Role criada para as funções Lambda"
  value       = aws_iam_role.lambda_role.name
}

output "iam_role_arn" {
  description = "ARN da IAM Role criada para as funções Lambda"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_function_criar_preferencia_arn" {
   value       = aws_lambda_function.criar_preferencia.arn 
}

output "lambda_function_retorno_arn" {
   value       = aws_lambda_function.retorno.arn 
}