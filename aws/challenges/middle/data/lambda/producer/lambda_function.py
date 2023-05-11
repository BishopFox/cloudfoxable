# send_sqs_message.py
import os
import boto3
import pickle
import json
import base64

def lambda_handler(event, context):
    command = "echo \"hello world\" > /tmp/hello.txt"
    pickled_command = pickle.dumps(command)
    encoded_pickled_command = base64.b64encode(pickled_command).decode('utf-8')
    payload = {
        'command': encoded_pickled_command
    }

    sqs = boto3.client('sqs')
    queue_url = os.environ['TARGET_SQS_QUEUE_NAME']
    #queue_url = sqs.get_queue_url(QueueName=queue_name)['QueueUrl']

    sqs.send_message(QueueUrl=queue_url, MessageBody=json.dumps(payload))

    return {
        'statusCode': 200,
        'body': 'Message sent to the SQS queue'
    }
