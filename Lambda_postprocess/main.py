import boto3
from datetime import datetime
from urllib.parse import unquote_plus
import os

def lambda_handler(event, context):

    bucket_name_src = event["Records"][0]["s3"]["bucket"]["name"]
    s3_file_name_src = unquote_plus(event["Records"][0]["s3"]["object"]["key"])
    todays_dt = datetime.today().strftime('%Y-%m-%d')

    s3 = boto3.resource('s3')
    copy_source = {
        'Bucket': bucket_name_src,
        'Key': s3_file_name_src
    }

    output_bucket = os.environ["output_bucket"]
    output_prefix = os.environ["output_prefix"]
    destination_key_name = "{}/{}_{}".format(output_prefix, todays_dt, "_SearchKeywordPerformance.tab")
    s3.meta.client.copy(copy_source, output_bucket, destination_key_name)
    resp = {"status": 0, "Desc": "file moved successfully"}
    return resp
