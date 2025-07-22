from flask import Flask, request, jsonify
import boto3
import os
from dotenv import load_dotenv

# Load .env (safe for local dev; ignored in AWS if ENV vars are set directly)
load_dotenv()

app = Flask(__name__)

# Load from environment or fallback defaults
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
APP_TABLE = os.getenv("APP_TABLE_NAME", "AppTable")

# Create AWS service clients (no endpoint override — this is for real AWS)
ses = boto3.client('ses', region_name=AWS_REGION)
sns = boto3.client('sns', region_name=AWS_REGION)
dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION)
table = dynamodb.Table(APP_TABLE)

@app.route('/app', methods=['POST'])
def register_app():
    try:
        data = request.get_json()

        # Basic field validation
        required = ['App name', 'ApplicationID', 'Email', 'Domain']
        for field in required:
            if field not in data:
                return jsonify({"error": f"Missing field: {field}"}), 400

        app_name = data['App name']
        app_id = data['ApplicationID']
        email = data['Email']
        domain = data['Domain']

        # Create SES domain identity
        ses.verify_domain_identity(Domain=domain)
        ses_arn = f"arn:aws:ses:{AWS_REGION}:{get_account_id()}:identity/{domain}"

        # Create SNS topic
        sns_resp = sns.create_topic(Name=f"{app_id}-notifications")
        sns_arn = sns_resp['TopicArn']

        # Store record in DynamoDB
        table.put_item(Item={
            "ApplicationID": app_id,
            "App name": app_name,
            "Email": email,
            "Domain": domain,
            "SES-Domain-ARN": ses_arn,
            "SNS-Topic-ARN": sns_arn
        })

        return jsonify({
            "message": "Application registered successfully.",
            "ApplicationID": app_id,
            "SES-Domain-ARN": ses_arn,
            "SNS-Topic-ARN": sns_arn
        }), 201

    except Exception as e:
        print("Error in /app:", str(e))
        return jsonify({"error": str(e)}), 500


def get_account_id():
    """Get the current AWS account ID for ARN construction"""
    sts = boto3.client('sts')
    return sts.get_caller_identity()['Account']


if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0', port=5001)
