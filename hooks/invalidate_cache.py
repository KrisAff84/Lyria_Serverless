import os
from datetime import datetime
import boto3


session = boto3.Session(profile_name='kris84')
cloudfront = session.client('cloudfront')

def invalidate_cloudfront_cache(distribution):
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
    invalidate_cloudfront_cache(distribution)

if __name__ == '__main__':
    main()