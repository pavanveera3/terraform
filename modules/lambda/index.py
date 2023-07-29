import boto3

def lambda_handler(event, context):
    s3 = boto3.client('s3')

    # Get the sample text file from the input bucket
    input_bucket_name = "input-bucket-name12345testing"  # Replace with your input bucket name
    input_file_key = "sample_file.txt"
    input_file_object = s3.get_object(Bucket=input_bucket_name, Key=input_file_key)
    input_file_content = input_file_object['Body'].read().decode('utf-8')

    # Count the number of records in the file
    record_count = len(input_file_content.split('\n'))

    # Write the count to the output file
    output_file_content = f"Number of records: {record_count}"
    s3.put_object(Bucket="input-bucket-name12345testing", Key="output_file.txt", Body=output_file_content)  # Replace with your output bucket name

    return {
        'statusCode': 200,
        'body': 'File processed successfully!'
    }

