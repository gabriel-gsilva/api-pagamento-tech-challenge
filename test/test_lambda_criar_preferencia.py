import pytest
from unittest.mock import patch, MagicMock
import json
import os
import sys

# Definindo variáveis de ambiente necessárias para o teste
os.environ['MERCADOPAGO_ACCESS_TOKEN'] = 'TEST-774461802753823-103118-964b20b4047ff5ab7b3b0c605b9b7786-176575887'
os.environ['DYNAMODB_TABLE'] = 'MercadoPagoPreferencias'
os.environ['API_GATEWAY_URL'] = 'http://mock-api-gateway-url'

# Adiciona o diretório src ao PYTHONPATH
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../src')))

# Verifica se o módulo pode ser importado
try:
    import lambda_criar_preferencia
except ModuleNotFoundError:
    print("Erro: Não foi possível encontrar o módulo 'lambda_criar_preferencia'. Verifique se o caminho está correto.")
    sys.exit(1)

@pytest.fixture
def mock_env_vars(monkeypatch):
    monkeypatch.setenv('MERCADOPAGO_ACCESS_TOKEN', 'TEST-774461802753823-103118-964b20b4047ff5ab7b3b0c605b9b7786-176575887')
    monkeypatch.setenv('DYNAMODB_TABLE', 'MercadoPagoPreferencias')
    monkeypatch.setenv('API_GATEWAY_URL', 'http://mock-api-gateway-url')
    
@patch('lambda_criar_preferencia.sdk.preference')
@patch('lambda_criar_preferencia.table.batch_writer')
def test_lambda_handler_sucesso(mock_batch_writer, mock_preference, mock_env_vars):
    # Mock da resposta do Mercado Pago
    mock_preference().create.return_value = {
        "status": 201,
        "response": {
            "id": "12345",
            "sandbox_init_point": "http://sandbox.mercadopago.com",
            "items": [
                {
                    'title': 'Produto 1',
                    'quantity': 1,
                    'currency_id': 'BRL',
                    'unit_price': 100.0
                }
            ]
        }
    }

    # Mock do batch_writer do DynamoDB
    mock_batch_writer.return_value.__enter__.return_value = MagicMock()

    event = {
        'body': json.dumps({
            'items': [
                {
                    'title': 'Produto 1',
                    'quantity': 1,
                    'currency_id': 'BRL',
                    'unit_price': 100.0
                }
            ]
        })
    }

    context = {}

    response = lambda_criar_preferencia.lambda_handler(event, context)

    assert response['statusCode'] == 200
    body = json.loads(response['body'])
    assert body['message'] == "Preferência criada e salva com sucesso"
    assert body['external_reference'] is not None
    assert body['itens'][0]['titulo'] == 'Produto 1'
    assert body['itens'][0]['preco'] == 100.0
    assert body['itens'][0]['quantidade'] == 1
    assert body['link_pagamento'] == "http://sandbox.mercadopago.com"

@patch('lambda_criar_preferencia.sdk.preference')
def test_lambda_handler_erro_mercadopago(mock_preference, mock_env_vars):
    # Mock da resposta de erro do Mercado Pago
    mock_preference().create.return_value = {
        "status": 400,
        "response": {}
    }

    event = {
        'body': json.dumps({
            'items': [
                {
                    'title': 'Produto 1',
                    'quantity': 1,
                    'currency_id': 'BRL',
                    'unit_price': 100.0
                }
            ]
        })
    }

    context = {}

    response = lambda_criar_preferencia.lambda_handler(event, context)

    assert response['statusCode'] == 500
    body = json.loads(response['body'])
    assert body['message'] == "Falha ao criar preferência no Mercado Pago"

def test_lambda_handler_sem_itens(mock_env_vars):
    event = {
        'body': json.dumps({})
    }

    context = {}

    response = lambda_criar_preferencia.lambda_handler(event, context)

    assert response['statusCode'] == 400
    body = json.loads(response['body'])
    assert body['message'] == "Nenhum item fornecido"