'''
Script used to configure the song order in the Lyria playlist. Zero based index.
Script will prompt for the song order. Separate indexes by comma and press enter to continue.
'''

import boto3
from invalidate_cache import invalidate_cloudfront_cache

session = boto3.Session(profile_name='kris84')

table_name_suffix = input("Which table would you like to update? dev or prod?: ")
table_name = f"lyria_song_order_{table_name_suffix}"

dynamodb = session.client('dynamodb')
response = dynamodb.scan(
    TableName=table_name
)
try:
    old_song_order = response['Items'][0]['song_order']['S']
    print(f"Old song order: {old_song_order}")
    proceed = input("Are you sure you want to update the song order? (y/n) ")

except IndexError:
    print("No song order found in table.")
    proceed = input("Would you like to add a new song order? (y/n) ")

if proceed == 'y':
    new_song_order = input("Enter the new song order. Separate indexes by comma: ")
    try:
        dynamodb.delete_item(
            TableName=table_name,
            Key={
                'song_order': {
                    'S': old_song_order
                }
            }
        )
    except NameError:
        pass

    dynamodb.put_item(
        TableName=table_name,
        Item={
            'song_order': {
                'S': new_song_order
            }
        }
    )
    print("Song order updated.")

    invalidate_cloudfront_cache('E2POYN6J2WTI8C', session)


else:
    print("Song order not updated. Exiting...")
