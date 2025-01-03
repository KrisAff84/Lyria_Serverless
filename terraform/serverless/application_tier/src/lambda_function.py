import json
import logging
import boto3


logger = logging.getLogger()
logger.setLevel(logging.INFO)
region_name = 'us-east-1'
dynamodb = boto3.client('dynamodb', region_name=region_name)
s3 = boto3.client('s3', region_name=region_name)

def get_song_order(dynamo_db_table_name, dynamo_db_key):
    try:
        dynamo_db_response = dynamodb.scan(TableName=dynamo_db_table_name)
        if not dynamo_db_response['Items']:
            raise ValueError('No items found in the table.')

        song_order_string = dynamo_db_response['Items'][0][dynamo_db_key]['S']
        song_order = [int(i) for i in song_order_string.split(',')]

        return song_order
    except Exception as e:
        raise RuntimeError(f'Error getting song order: {e}')

def get_song_lists(bucket_name, song_order, cloudfront_url):

    split_index = 2 if bucket_name.endswith('dev') else 1
    bucket_prefix = 'dev/songs/' if bucket_name.endswith('dev') else 'songs/'

    # Initialize lists
    title_keys = [] # song list with underscores
    song_list = [] # Song list without underscores
    audio_urls = [] # complete object keys with folder and file name
    image_urls = [] # Path to images

    idx = 1

    response = s3.list_objects_v2(Bucket=bucket_name, Prefix=bucket_prefix)

    # Gets list of song keys without folder name
    while idx < len(response['Contents']):
        # puts song titles with underscores into song_key list
        title_keys.append(response['Contents'][idx]['Key'].split('/')[split_index])
        idx += 1
        # puts path to complete audio file object urls into audio_urls list
        audio_urls.append(f"https://{cloudfront_url}/{response['Contents'][idx]['Key']}")
        idx += 1
        # puts path to complete image object urls into image_urls list
        image_urls.append(f"https://{cloudfront_url}/{response['Contents'][idx]['Key']}")
        idx += 1

    # Replaces underscores with spaces in title_keys list
    song_list_no_dashes = [song.replace('_', ' ') for song in title_keys]
    song_list_no_asterisks = [song.replace('*', "'") for song in song_list_no_dashes]

    song_list = [song_list_no_asterisks[i] for i in song_order]
    audio_urls = [audio_urls[i] for i in song_order]
    image_urls = [image_urls[i] for i in song_order]

    current_idx = 0
    current_title = song_list[current_idx]
    current_audio_url = audio_urls[current_idx]
    current_image_url = image_urls[current_idx]

    context = {
        'song_list': song_list,
        'audio_urls': audio_urls,
        'image_urls': image_urls,
        'current_title': current_title,
        'current_audio_url': current_audio_url,
        'current_image_url': current_image_url,
        'bucket_name': bucket_name,
    }

    logger.info(f'Context: {context}')
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json'
        },
        'body': json.dumps(context)
    }

def handler(event, context):
    stage_variables = event.get('stageVariables')
    bucket_name = stage_variables.get('bucket')
    cloudfront_url = 'd339fsp1ckp0lm.cloudfront.net'
    dynamo_db_table_name = 'lyria_song_order_dev' if bucket_name.endswith('dev') else 'lyria_song_order_prod'
    dynamo_db_key = 'song_order'
    song_order = get_song_order(dynamo_db_table_name, dynamo_db_key)
    response = get_song_lists(bucket_name, song_order, cloudfront_url)
    return response
