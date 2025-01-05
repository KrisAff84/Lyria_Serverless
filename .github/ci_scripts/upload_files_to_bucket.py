""" This script will upload the necessary files for the
    website to the specified bucket.
"""

import os
import boto3

aws_region = os.environ.get("AWS_REGION")
bucket_name = os.environ.get("BUCKET_NAME")
access_key_id = os.environ.get("AWS_ACCESS_KEY_ID")
secret_access_key = os.environ.get("AWS_SECRET_ACCESS_KEY")
excluded_paths = [
   "icons"
]

paths_to_upload = []
objects_to_upload = []

content_type = {
    "html" : "text/html",
    "css" : "text/css",
    "js" : "application/javascript",
    "png" : "image/png"
}

items = os.listdir("../../static")

s3 = boto3.client(
    's3',
    region_name=aws_region,
    aws_access_key_id=access_key_id,
    aws_secret_access_key=secret_access_key
    )

# Add items to paths_to_upload if they are not in the excluded_paths list
for item in items:
    if item not in excluded_paths:
        paths_to_upload.append(item)

for item in paths_to_upload:
    # check if item is file or a directory
    if os.path.isfile(f"../../{item}"):
        objects_to_upload.append(item)
    else:
        sub_items = os.listdir(f"../../{item}")
        # Add sub items to objects_to_upload if they are not in the excluded_paths list
        for sub_item in sub_items:
            if sub_item not in excluded_paths:
                objects_to_upload.append(f"{item}/{sub_item}")

print("Files to upload:")
for object in objects_to_upload:
    print(object)
    if object.split(".")[1] in content_type:
        s3.upload_file(f"../../{object}", bucket_name, object, ExtraArgs={'ContentType': content_type[f'{object.split(".")[1]}']})

    else:
        s3.upload_file(f"../../{object}", bucket_name, object)
        print(f"Content type for {object} not found. ContentType will need to be added to file manually in the S3 console.")

print(f"Files uploaded to {bucket_name} successfully.")