import boto3
import os
def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'body': 'File processed successfully!'
    }

