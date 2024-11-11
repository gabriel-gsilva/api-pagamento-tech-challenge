provider "aws" {
  region = var.aws_region
}

# DynamoDB Table
resource "aws_dynamodb_table" "preferencias" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "id_preferencia"
    type = "S"
  }
  attribute {
    name = "produto"
    type = "S"
  }
  attribute {
    name = "id_mercadopago"
    type = "S"
  }

  hash_key  = "id_preferencia"
  range_key = "produto"

  global_secondary_index {
    name               = "IdMercadoPagoIndex"
    hash_key           = "id_mercadopago"
    projection_type    = "ALL"
  }

  tags = {
    Ambiente = var.ambiente
  }
}

# IAM Role para a função Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_mercadopago_role"

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
}

# Política para a função Lambda acessar o DynamoDB
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
          "dynamodb:BatchWriteItem"
        ]
        Resource = aws_dynamodb_table.preferencias.arn
      }
    ]
  })
}

# Preparação do código Lambda
resource "null_resource" "install_dependencies" {
  provisioner "local-exec" {
    command = "python -m pip install -r ${path.module}/src/requirements.txt -t ${path.module}/src/ --no-user"
  }

  triggers = {
    dependencies_versions = filemd5("${path.module}/src/requirements.txt")
  }
}

# Arquivo ZIP para a função Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda_function.zip"

  depends_on = [null_resource.install_dependencies]
}

# Função Lambda
resource "aws_lambda_function" "mercadopago_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.8"

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.preferencias.name
      MERCADOPAGO_ACCESS_TOKEN = var.mercadopago_access_token
    }
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "mercadopago_api" {
  name        = "MercadoPagoAPI"
  description = "API para gerenciar preferências do Mercado Pago"
}

resource "aws_api_gateway_resource" "criar_preferencia" {
  rest_api_id = aws_api_gateway_rest_api.mercadopago_api.id
  parent_id   = aws_api_gateway_rest_api.mercadopago_api.root_resource_id
  path_part   = "criar_preferencia"
}

resource "aws_api_gateway_method" "post_criar_preferencia" {
  rest_api_id   = aws_api_gateway_rest_api.mercadopago_api.id
  resource_id   = aws_api_gateway_resource.criar_preferencia.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.mercadopago_api.id
  resource_id = aws_api_gateway_resource.criar_preferencia.id
  http_method = aws_api_gateway_method.post_criar_preferencia.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.mercadopago_lambda.invoke_arn
}

# Implantação do API Gateway
resource "aws_api_gateway_deployment" "mercadopago_deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration]

  rest_api_id = aws_api_gateway_rest_api.mercadopago_api.id
  stage_name  = "prod"
}

# Permissão para o API Gateway invocar a função Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.mercadopago_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.mercadopago_api.execution_arn}/*/*"
}