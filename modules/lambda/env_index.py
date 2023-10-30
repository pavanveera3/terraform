import boto3
import os
def lambda_handler(event, context):
    s3 = boto3.client('s3')

    # Get the input bucket name from the Lambda function environment
    input_bucket_name = os.environ['input_bucket_name']
   # input_bucket_name = context.function_environment['input_bucket_name']
    input_file_key = "input/sample_file.txt"
    input_file_object = s3.get_object(Bucket=input_bucket_name, Key=input_file_key)
    input_file_content = input_file_object['Body'].read().decode('utf-8')

    # Count the number of records in the file
    record_count = len(input_file_content.split('\n'))

    # Write the count to the output file
    output_file_content = f"Number of records: {record_count}"
    s3.put_object(Bucket=input_bucket_name, Key="output/output_file.txt", Body=output_file_content)


    return {
        'statusCode': 200,
        'body': 'File processed successfully!'
    }



