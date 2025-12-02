import boto3
import os
from botocore.config import Config

s3 = boto3.client(
    's3',
    endpoint_url='http://localhost:4566',
    aws_access_key_id='test',
    aws_secret_access_key='test',
    region_name='us-east-1',
    config=Config(s3={'use_path_style': True, 'signature_version': 's3v4'})
)

import sys
bucket = sys.argv[1] if len(sys.argv) > 1 else 'hello-nextjs-dev-devcontainer-localstack'
local_dir = '/workspaces/experimental-nextjs-app/hello-nextjs/out'

def upload_dir(prefix=''):
    for root, dirs, files in os.walk(local_dir):
        for file in files:
            local_path = os.path.join(root, file)
            s3_key = os.path.relpath(local_path, local_dir).replace('\\', '/')
            if prefix:
                s3_key = prefix + '/' + s3_key
            print(f'Uploading {local_path} to s3://{bucket}/{s3_key}')
            content_type = 'text/html'
            if s3_key.endswith('.js'):
                content_type = 'application/javascript'
            elif s3_key.endswith('.css'):
                content_type = 'text/css'
            elif s3_key.endswith('.json'):
                content_type = 'application/json'
            elif s3_key.endswith('.ico') or s3_key.endswith('.png') or s3_key.endswith('.jpg') or s3_key.endswith('.svg'):
                content_type = 'image/' + s3_key.split('.')[-1]
            s3.upload_file(local_path, bucket, s3_key, ExtraArgs={'ContentType': content_type})

# Delete old files first (simulate --delete)
paginator = s3.get_paginator('list_objects_v2')
pages = paginator.paginate(Bucket=bucket)
for page in pages:
    if 'Contents' in page:
        for obj in page['Contents']:
            print(f'Deleting s3://{bucket}/{obj["Key"]}')
            s3.delete_object(Bucket=bucket, Key=obj['Key'])

upload_dir()
print(f'Deploy to s3://{bucket} complete!')
