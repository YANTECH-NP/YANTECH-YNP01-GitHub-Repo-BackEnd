from flask import Flask, request, jsonify
import boto3
import os
import json
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
QUEUE_URL = os.getenv("SQS_QUEUE_URL")
sqs = boto3.client('sqs', region_name=AWS_REGION, endpoint_url="http://localstack:4566")

@app.route('/notify', methods=['POST'])
def handle_notification():
    data = request.get_json()
    required_fields = ['Application', 'Recipient', 'Subject', 'Message', 'OutputType', 'Date', 'Time', 'Interval']
    for field in required_fields:
        if field not in data:
            return jsonify({"error": f"Missing field: {field}"}), 400

    message = json.dumps(data)
    try:
        response = sqs.send_message(QueueUrl=QUEUE_URL, MessageBody=message)
        return jsonify({"message": "Notification received and queued.", "messageId": response['MessageId']}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
