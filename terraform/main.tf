provider "aws" {
  region = var.aws_region
}

# DynamoDB Table
resource "aws_dynamodb_table" "preferencias" {
  name           = var.dynamodb_table_name
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = "id_preferencia"
  range_key      = "produto"

  attribute {
    name = "id_preferencia"
    type = "S"
  }

  attribute {
    name = "produto"
    type = "S"
  }

  tags = var.tags
}

# IAM Role para as funções Lambda
resource "aws_iam_role" "lambda_role" {
  name_prefix = "lambda_mercadopago_role_"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  tags = var.tags
}

# Política para as funções Lambda Necessaria
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_mercadopago_policy"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = aws_dynamodb_table.preferencias.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Lambda function para criar preferência
resource "aws_lambda_function" "criar_preferencia" {
  filename         = "../src/lambda_criar_preferencia.zip"
  function_name    = "${var.lambda_function_name}_criar_preferencia"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_criar_preferencia.lambda_handler"
  runtime          = var.lambda_runtime
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout
  source_code_hash = filebase64sha256("../src/lambda_criar_preferencia.zip")
  environment {
    variables = {
      DYNAMODB_TABLE           = aws_dynamodb_table.preferencias.name
      MERCADOPAGO_ACCESS_TOKEN = var.mercadopago_access_token
      API_GATEWAY_URL          = "https://${aws_api_gateway_rest_api.mercadopago_api.id}.execute-api.${var.aws_region}.amazonaws.com/${var.api_gateway_stage_name}"
    }
  }
  tags = var.tags
}

# Lambda function para retorno
resource "aws_lambda_function" "retorno" {
  filename         = "../src/lambda_retorno.zip"
  function_name    = "${var.lambda_function_name}_retorno"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_retorno.lambda_handler"
  runtime          = var.lambda_runtime
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout
  source_code_hash = filebase64sha256("../src/lambda_retorno.zip")
  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.preferencias.name
      REDIRECT_URL   = var.redirect_url
    }
  }
  tags = var.tags
}

# API Gateway
resource "aws_api_gateway_rest_api" "mercadopago_api" {
  name        = var.api_gateway_name
  description = "API para integração com Mercado Pago"

  tags = var.tags
}

# Recurso para criar preferência
resource "aws_api_gateway_resource" "criar_preferencia" {
  rest_api_id = aws_api_gateway_rest_api.mercadopago_api.id
  parent_id   = aws_api_gateway_rest_api.mercadopago_api.root_resource_id
  path_part   = "criar_preferencia"
}

# Método POST para criar preferência
resource "aws_api_gateway_method" "post_criar_preferencia" {
  rest_api_id   = aws_api_gateway_rest_api.mercadopago_api.id
  resource_id   = aws_api_gateway_resource.criar_preferencia.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integração do método POST com a função Lambda
resource "aws_api_gateway_integration" "lambda_criar_preferencia" {
  rest_api_id = aws_api_gateway_rest_api.mercadopago_api.id
  resource_id = aws_api_gateway_resource.criar_preferencia.id
  http_method = aws_api_gateway_method.post_criar_preferencia.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.criar_preferencia.invoke_arn
}

# Recurso para retorno
resource "aws_api_gateway_resource" "retorno" {
  rest_api_id = aws_api_gateway_rest_api.mercadopago_api.id
  parent_id   = aws_api_gateway_rest_api.mercadopago_api.root_resource_id
  path_part   = "retorno"
}

# Método GET para retorno
resource "aws_api_gateway_method" "get_retorno" {
  rest_api_id   = aws_api_gateway_rest_api.mercadopago_api.id
  resource_id   = aws_api_gateway_resource.retorno.id
  http_method   = "GET"
  authorization = "NONE"
}

# Integração do método GET com a função Lambda de retorno
resource "aws_api_gateway_integration" "lambda_retorno" {
  rest_api_id = aws_api_gateway_rest_api.mercadopago_api.id
  resource_id = aws_api_gateway_resource.retorno.id
  http_method = aws_api_gateway_method.get_retorno.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.retorno.invoke_arn
}

# IAM Role para CloudWatch Logs do API Gateway
resource "aws_iam_role" "api_gateway_cloudwatch_role" {
  name = "APIGatewayCloudWatchLogsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
  role       = aws_iam_role.api_gateway_cloudwatch_role.id
}

# Configuração da conta do API Gateway
resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_role.arn
}

# Deployment do API Gateway
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.mercadopago_api.id
  
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.criar_preferencia.id,
      aws_api_gateway_method.post_criar_preferencia.id,
      aws_api_gateway_integration.lambda_criar_preferencia.id,
      aws_api_gateway_resource.retorno.id,
      aws_api_gateway_method.get_retorno.id,
      aws_api_gateway_integration.lambda_retorno.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.post_criar_preferencia,
    aws_api_gateway_integration.lambda_criar_preferencia,
    aws_api_gateway_method.get_retorno,
    aws_api_gateway_integration.lambda_retorno,
  ]
}

# Stage do API Gateway
resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.mercadopago_api.id
  stage_name    = var.api_gateway_stage_name
}

# Configurações de método para habilitar logs
resource "aws_api_gateway_method_settings" "api_gateway_logs" {
  rest_api_id = aws_api_gateway_rest_api.mercadopago_api.id
  stage_name  = aws_api_gateway_stage.api_stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = var.enable_api_gateway_logging ? "INFO" : "OFF"
  }

  depends_on = [aws_api_gateway_account.main]
}

# Permissões para o API Gateway invocar as funções Lambda
resource "aws_lambda_permission" "apigw_lambda_criar_preferencia" {
  statement_id  = "AllowAPIGatewayInvokeCriarPreferencia"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.criar_preferencia.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.mercadopago_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_lambda_retorno" {
  statement_id  = "AllowAPIGatewayInvokeRetorno"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.retorno.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.mercadopago_api.execution_arn}/*/*"
}