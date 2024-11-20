import json
import boto3
import os
from botocore.exceptions import ClientError
import logging
from boto3.dynamodb.conditions import Key

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])

def atualizar_status_pagamento(id_preferencia, status, max_retries=3):
    for attempt in range(max_retries):
        try:
            # Primeiro, consulte o item para obter todos os produtos associados
            response = table.query(
                KeyConditionExpression=Key('id_preferencia').eq(id_preferencia)
            )
            
            if not response['Items']:
                logger.error(f"Nenhum item encontrado para id_preferencia: {id_preferencia}")
                return False

            # Atualize o status para todos os itens com o mesmo id_preferencia
            for item in response['Items']:
                table.update_item(
                    Key={
                        'id_preferencia': id_preferencia,
                        'produto': item['produto']
                    },
                    UpdateExpression="set status_pagamento = :s",
                    ExpressionAttributeValues={':s': status},
                    ReturnValues="UPDATED_NEW"
                )
            logger.info(f"Status atualizado para {id_preferencia}: {status}")
            return True
        except ClientError as e:
            if attempt == max_retries - 1:
                logger.error(f"Erro ao atualizar status no DynamoDB após {max_retries} tentativas: {str(e)}")
                return False
            else:
                logger.warning(f"Tentativa {attempt + 1} falhou. Tentando novamente...")
    return False

def lambda_handler(event, context):
    logger.info(f"Evento recebido: {json.dumps(event)}")
    try:
        query_params = event.get('queryStringParameters', {})
        status = query_params.get('collection_status')
        external_reference = query_params.get('external_reference')

        logger.info(f"Parâmetros recebidos: status={status}, external_reference={external_reference}")

        if not status or not external_reference:
            return {
                'statusCode': 400,
                'body': json.dumps({"message": "Parâmetros collection_status e external_reference são obrigatórios"})
            }

        status_mapping = {
            'approved': 'success',
            'pending': 'pending',
            'in_process': 'pending',
            'rejected': 'failure',
            'cancelled': 'failure',
            'refunded': 'refunded',
            'charged_back': 'charged_back'
        }
        
        if status not in status_mapping:
            logger.warning(f"Status desconhecido recebido: {status}")
            return {
                'statusCode': 400,
                'body': json.dumps({"message": "Status de pagamento inválido"})
            }

        internal_status = status_mapping[status]

        if atualizar_status_pagamento(external_reference, internal_status):
            mensagem = f"Status de pagamento atualizado com sucesso: {internal_status}"
            status_code = 200
        else:
            mensagem = "Falha ao atualizar status de pagamento"
            status_code = 500

        redirect_url = os.environ.get('REDIRECT_URL', '')

        if redirect_url:
            redirect_url += f"?status={internal_status}&external_reference={external_reference}"
            return {
                'statusCode': 302,
                'headers': {
                    'Location': redirect_url
                },
                'body': json.dumps({"message": mensagem})
            }
        else:
            return {
                'statusCode': status_code,
                'body': json.dumps({"message": mensagem, "status": internal_status, "external_reference": external_reference})
            }

    except Exception as e:
        logger.error(f"Erro não tratado: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({"message": f"Erro interno do servidor: {str(e)}"})
        }