# consume_sqs_message.py
import boto3
import pickle
import base64
import json
import os

def lambda_handler(event, context):
    sqs = boto3.client('sqs')

    for record in event['Records']:
        message = record['body']
        receipt_handle = record['receiptHandle']
        queue_url = os.environ['TARGET_SQS_QUEUE_NAME']

        payload = json.loads(message)
        encoded_pickled_command = payload['command']

        pickled_command = base64.b64decode(encoded_pickled_command)
        command = pickle.loads(pickled_command)
        #os.system(command)        
        print(command)

        sqs.delete_message(QueueUrl=queue_url, ReceiptHandle=receipt_handle)

    return {
        'statusCode': 200,
        'body': 'Command executed successfully'
    }
