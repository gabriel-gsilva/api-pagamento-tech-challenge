variable "aws_region" {
  description = "Região da AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "ID da conta AWS"
  type        = string
  default     = "180294215177"
}


variable "environment" {
  description = "O ambiente de implantação (ex: dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB"
  type        = string
  default     = "MercadoPagoPreferencias"
}

variable "lambda_runtime" {
  description = "Runtime para as funções Lambda"
  type        = string
  default     = "python3.8"
}

variable "lambda_function_name" {
  description = "Prefixo para o nome das funções Lambda"
  type        = string
  default     = "mercadopago"
}

variable "api_gateway_name" {
  description = "Nome do API Gateway"
  type        = string
  default     = "MercadoPagoAPI"
}

variable "redirect_url" {
  description = "URL base para redirecionamento após o processamento do pagamento"
  type        = string
  default     = ""
}

variable "mercadopago_access_token" {
  description = "Token de acesso do Mercado Pago"
  type        = string
  default     = "TEST-774461802753823-103118-964b20b4047ff5ab7b3b0c605b9b7786-176575887"
}

variable "tags" {
  description = "Tags a serem aplicadas a todos os recursos"
  type        = map(string)
  default = {
    Project     = "MercadoPagoIntegration"
    Environment = "Development"
  }
}

variable "lambda_memory_size" {
  description = "Quantidade de memória alocada para as funções Lambda (em MB)"
  type        = number
  default     = 256
}

variable "lambda_timeout" {
  description = "Tempo máximo de execução para as funções Lambda (em segundos)"
  type        = number
  default     = 30
}

variable "api_gateway_stage_name" {
  description = "Nome do estágio do API Gateway"
  type        = string
  default     = "v1"
}

variable "lambda_log_retention_in_days" {
  description = "Número de dias para retenção dos logs das funções Lambda no CloudWatch"
  type        = number
  default     = 14
}

variable "enable_api_gateway_logging" {
  description = "Habilitar logging para o API Gateway"
  type        = bool
  default     = true
}
