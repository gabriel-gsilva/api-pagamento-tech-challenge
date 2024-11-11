import json
import uuid
import boto3
import mercadopago
from botocore.exceptions import ClientError
from decimal import Decimal
import os

# Inicialização dos clientes
sdk = mercadopago.SDK(os.environ['MERCADOPAGO_ACCESS_TOKEN'])
dynamodb = boto3.resource('dynamodb', region_name='sa-east-1')
table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])

def float_to_decimal(obj):
    if isinstance(obj, float):
        return Decimal(str(obj))
    elif isinstance(obj, dict):
        return {k: float_to_decimal(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [float_to_decimal(v) for v in obj]
    return obj

def salvar_preferencias_dynamodb(preferencia, sandbox_init_point):
    try:
        id_preferencia = str(uuid.uuid4())
        with table.batch_writer(overwrite_by_pkeys=['id_preferencia']) as batch:
            for item in preferencia['items']:
                item_dynamodb = {
                    'id_preferencia': id_preferencia,
                    'id_mercadopago': preferencia['id'],
                    'produto': item['title'],
                    'quantidade': item['quantity'],
                    'tipo_moeda': item['currency_id'],
                    'valor_unitario': Decimal(str(item['unit_price'])),
                    'sandbox_init_point': sandbox_init_point
                }
                item_dynamodb = float_to_decimal(item_dynamodb)
                batch.put_item(Item=item_dynamodb)
        print(f"Preferência salva no DynamoDB com ID: {id_preferencia}")
        return True
    except ClientError as e:
        print(f"Erro ao salvar no DynamoDB: {str(e)}")
        return False

def criar_preferencia(items):
    preference_data = {
        "items": items,
        "back_urls": {
            "success": "https://seu-dominio.com/compracerta",
            "failure": "https://seu-dominio.com/compraerrada",
            "pending": "https://seu-dominio.com/compraerrada",
        },
        "auto_return": "all"
    }

    try:
        preference_response = sdk.preference().create(preference_data)
        if preference_response["status"] == 201:
            return preference_response["response"]
        else:
            print(f"Erro ao criar preferência: Status {preference_response['status']}")
            return None
    except Exception as e:
        print(f"Erro ao criar preferência no Mercado Pago: {str(e)}")
        return None

def lambda_handler(event, context):
    try:
        # Parse o corpo da requisição
        body = json.loads(event['body'])
        items = body.get('items', [])

        if not items:
            return {
                'statusCode': 400,
                'body': json.dumps({"message": "Nenhum item fornecido"})
            }

        preferencia = criar_preferencia(items)
        if not preferencia:
            return {
                'statusCode': 500,
                'body': json.dumps({"message": "Falha ao criar preferência no Mercado Pago"})
            }

        sandbox_init_point = preferencia.get('sandbox_init_point', 'Não disponível')
        
        if not salvar_preferencias_dynamodb(preferencia, sandbox_init_point):
            return {
                'statusCode': 500,
                'body': json.dumps({"message": "Falha ao salvar preferências no DynamoDB"})
            }

        print(f"URL do Mercado Pago: {sandbox_init_point}")
        print("Execução bem-sucedida!")

        return {
            'statusCode': 200,
            'body': json.dumps({
                "message": "Preferência criada e salva com sucesso",
                "id_preferencia": preferencia['id'],
                "itens": [
                    {
                        "titulo": item['title'],
                        "preco": item['unit_price'],
                        "quantidade": item['quantity']
                    } for item in preferencia['items']
                ],
                "link_pagamento": sandbox_init_point
            })
        }

    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'body': json.dumps({"message": "Corpo da requisição inválido"})
        }
    except Exception as e:
        print(f"Erro não tratado: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({"message": "Erro interno do servidor"})
        }