from flask import Flask, request, jsonify
import boto3
import os
from dotenv import load_dotenv
import logging

logging.basicConfig(
    level=logging.INFO,  # Options: DEBUG, INFO, WARNING, ERROR, CRITICAL
    format="%(asctime)s - %(levelname)s - %(message)s"
)

load_dotenv()

app = Flask(__name__)
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
APP_TABLE = os.getenv("APP_TABLE_NAME", "AppTable")

ses = boto3.client('ses', region_name=AWS_REGION, endpoint_url="http://localstack:4566")
sns = boto3.client('sns', region_name=AWS_REGION, endpoint_url="http://localstack:4566")
dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION, endpoint_url="http://localstack:4566")
table = dynamodb.Table(APP_TABLE)

@app.route('/app', methods=['POST'])
def register_app():
    try:
        data = request.get_json()
        required = ['App name', 'ApplicationID', 'Email', 'Domain']
        for field in required:
            if field not in data:
                return jsonify({"error": f"Missing field: {field}"}), 400

        app_name = data['App name']
        app_id = data['ApplicationID']
        email = data['Email']
        domain = data['Domain']

        logging.info(f"Registering application: {app_name}, ID: {app_id}, Email: {email}, Domain: {domain}")

        ses.verify_domain_identity(Domain=domain)
        ses_arn = f"arn:aws:ses:{AWS_REGION}:000000000000:identity/{domain}"

        logging.info(f"SES Domain ARN: {ses_arn}")  

        sns_resp = sns.create_topic(Name=f"{app_id}-notifications")
        sns_arn = sns_resp['TopicArn']

        logging.info(f"SNS Topic ARN: {sns_arn}")

       logging.info(f"{app_id} {app_name} {email} {domain} {ses_arn} {sns_arn}")

        
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
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)
