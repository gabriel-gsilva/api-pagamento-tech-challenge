variable "aws_region" {
  description = "A região da AWS onde os recursos serão criados"
  default     = "sa-east-1"
}

variable "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB"
  default     = "PreferenciaMercadoPago"
}

variable "ambiente" {
  description = "Ambiente de implantação"
  default     = "Producao"
}

variable "lambda_function_name" {
  description = "Nome da função Lambda"
  default     = "mercadopago_preferencia"
}

variable "mercadopago_access_token" {
  description = "Token de acesso do Mercado Pago"
  sensitive   = true
}