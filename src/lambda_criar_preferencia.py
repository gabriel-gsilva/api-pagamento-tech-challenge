import json
import uuid
import boto3
import mercadopago
import os
from botocore.exceptions import ClientError
from decimal import Decimal

# Defina a região da AWS
os.environ['AWS_DEFAULT_REGION'] = 'us-east-1'
# Inicialização dos clientes
sdk = mercadopago.SDK(os.environ['MERCADOPAGO_ACCESS_TOKEN'])
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])

def float_to_decimal(obj):
    if isinstance(obj, float):
        return Decimal(str(obj))
    elif isinstance(obj, dict):
        return {k: float_to_decimal(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [float_to_decimal(v) for v in obj]
    return obj

def salvar_preferencias_dynamodb(preferencia, sandbox_init_point, external_reference):
    try:
        with table.batch_writer() as batch:
            for item in preferencia['items']:
                item_dynamodb = {
                    'external_reference': external_reference,
                    'produto': item['title'],
                    'id_mercadopago': preferencia['id'],
                    'quantidade': item['quantity'],
                    'tipo_moeda': item['currency_id'],
                    'valor_unitario': Decimal(str(item['unit_price'])),
                    'sandbox_init_point': sandbox_init_point,
                    'status_pagamento': 'pending'
                }
                item_dynamodb = float_to_decimal(item_dynamodb)
                batch.put_item(Item=item_dynamodb)
        return external_reference
    except ClientError as e:
        print(f"Erro ao salvar no DynamoDB: {str(e)}")
        raise

def criar_preferencia(items, external_reference):
    preference_data = {
        "items": items,
        "back_urls": {
            "success": f"{os.environ['API_GATEWAY_URL']}/retorno",
            "failure": f"{os.environ['API_GATEWAY_URL']}/retorno",
            "pending": f"{os.environ['API_GATEWAY_URL']}/retorno",
        },
        "auto_return": "approved",
        "external_reference": external_reference
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
    print("Evento recebido:", json.dumps(event))
    try:
        body = json.loads(event['body']) if 'body' in event else event
        items = body.get('items', [])

        if not items:
            return {
                'statusCode': 400,
                'body': json.dumps({"message": "Nenhum item fornecido"})
            }

        external_reference = str(uuid.uuid4())
        preferencia = criar_preferencia(items, external_reference)
        if not preferencia:
            return {
                'statusCode': 500,
                'body': json.dumps({"message": "Falha ao criar preferência no Mercado Pago"})
            }

        sandbox_init_point = preferencia.get('sandbox_init_point', 'Não disponível')
        
        print("Preferência criada:", json.dumps(preferencia))
        print("Salvando no DynamoDB...")

        saved_reference = salvar_preferencias_dynamodb(preferencia, sandbox_init_point, external_reference)
        if not saved_reference:
            return {
                'statusCode': 500,
                'body': json.dumps({"message": "Falha ao salvar preferências no DynamoDB"})
            }

        print("Preferência salva com sucesso no DynamoDB")

        return {
            'statusCode': 200,
            'body': json.dumps({
                "message": "Preferência criada e salva com sucesso",
                "external_reference": external_reference,
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

    except Exception as e:
        print(f"Erro não tratado: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({"message": f"Erro interno do servidor: {str(e)}"})
        }