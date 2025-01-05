import os
from datetime import datetime
import boto3

def set_up_boto3_session():
    aws_access_key_id = os.getenv("AWS_ACCESS_KEY_ID")
    aws_secret_access_key = os.getenv("AWS_SECRET_ACCESS_KEY")
    region = os.getenv("AWS_REGION")

    if aws_access_key_id and aws_secret_access_key and region:
        session = boto3.Session(
            aws_access_key_id=aws_access_key_id,
            aws_secret_access_key=aws_secret_access_key,
            region_name='us-east-1'
        )
    else:
        session = boto3.Session(profile_name='kris84')

    return session


def invalidate_cloudfront_cache(distribution, session):
    cloudfront = session.client('cloudfront')
    '''
    Invalidate CloudFront cache of specified distribution. Path is set to all objects.
    '''
    print('Invalidating Cloudfront cache...')

    response = cloudfront.create_invalidation(
        DistributionId=distribution,
        InvalidationBatch= {
            'Paths': {
                'Quantity': 1,
                'Items': [
                    "/*",
                ]
            },
            'CallerReference': str(datetime.timestamp(datetime.now()))
        }
    )

    invalidation_id = response['Invalidation']['Id']

    invalidated = cloudfront.get_waiter('invalidation_completed')
    invalidated.wait(
        DistributionId=distribution,
        Id=invalidation_id
    )

    print('Cloudfront cache invalidated successfully')


def main():
    distribution = os.getenv("DISTRIBUTION")
    session = set_up_boto3_session()
    invalidate_cloudfront_cache(distribution, session)

if __name__ == '__main__':
    main()