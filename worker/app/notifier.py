import boto3
from . import config

ses = boto3.client("ses", region_name=config.AWS_REGION)

sns = boto3.client("sns", region_name=config.AWS_REGION)

def send_email(domain_arn, to_addresses, subject, body):
    # Use verified domain email address
    sender_email = "notifications@project-dolphin.com"
    return ses.send_email(
        Source=sender_email,
        Destination={"ToAddresses": to_addresses},
        Message={
            "Subject": {"Data": subject},
            "Body": {"Text": {"Data": body}}
        }
    )

def send_sns(topic_arn, message):
    return sns.publish(TopicArn=topic_arn, Message=message)

