import base64
import json
import zlib
import datetime
import os
import boto3
import re
from botocore.exceptions import ClientError

print('Loading function')


def lambda_handler(event, context):
    data = zlib.decompress(base64.b64decode(
        event['awslogs']['data']), 16+zlib.MAX_WBITS)
    data_json = json.loads(data)
    log_json = json.loads(json.dumps(
        data_json["logEvents"][0], ensure_ascii=False))

    send_message = True

    # logfilter
    try:
        # get filterlist
        bucket_name = os.environ['BUCKET_NAME']
        filter_file_name = os.environ['FILTER_FILE_NAME']
        s3 = boto3.resource('s3')
        filter_file = s3.Object(bucket_name, filter_file_name).get()
        filter_list = filter_file['Body'].read().decode('utf-8').splitlines()
        filter_list = list(filter(None, filter_list))

        # filter check
        str_data = json.dumps(log_json['message'])

        for w in filter_list:
            if re.search(w, str_data):
                print("This LogAlert is filtered.")
                print("Filtered Message is here.")
                print(log_json['message'])
                send_message = False
                break

    except Exception as e:
        print(e)

    # SNS Publish
    if (send_message):
        try:
            sns = boto3.client('sns')

            publishResponse = sns.publish(
                TopicArn=os.environ['SNS_TOPIC_ARN'],
                Message=log_json['message'],
                Subject=os.environ['ALARM_SUBJECT']
            )
        except Exception as e:
            print(e)
