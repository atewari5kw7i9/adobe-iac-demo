import boto3
from os.path import join
import uuid
import os
from urllib.parse import unquote_plus


def lambda_handler(event, context):
    emr_cluster_id = os.environ['emr_cluster_id']
    output_path = os.environ['output_path']
    executor_memory = os.environ['executor_memory']
    driver_memory = os.environ['driver_memory']
    job_name = os.environ['job_name']
    code_artifacts = os.environ['code_artifacts']
    jar_file = os.environ['jar_file']

    version = 'latest'
    main_path = join(code_artifacts, version, 'main.py')
    modules_path = join(code_artifacts, version, 'src.zip')

    bucket_name_src = event["Records"][0]["s3"]["bucket"]["name"]
    s3_file_name_src = unquote_plus(event["Records"][0]["s3"]["object"]["key"])
    input_path = "{}//{}/{}".format("s3:", bucket_name_src, s3_file_name_src)
    emr = boto3.client('emr')
    job_parameters = {
        'job_name': job_name,
        'input_path': input_path,
        'output_path': output_path,
        'spark_config': {
            '--executor-memory': executor_memory,
            '--driver-memory': driver_memory
        }
    }

    step_args = [
        "/usr/bin/spark-submit",
        '--py-files', modules_path,
        main_path, str(job_parameters)
    ]

    rand_str = str(uuid.uuid1())
    emr_job_name = job_parameters['job_name'] + rand_str
    step = {
        "Name": emr_job_name,
        'ActionOnFailure': 'CONTINUE',
        'HadoopJarStep': {
            'Jar': jar_file,
            'Args': step_args
        }
    }

    action = emr.add_job_flow_steps(JobFlowId=emr_cluster_id, Steps=[step])
    return action
