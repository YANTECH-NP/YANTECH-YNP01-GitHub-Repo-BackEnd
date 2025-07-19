from flask import Flask, request, jsonify
import boto3
import os
from datetime import datetime

# Initialize Flask application
app = Flask(__name__)

# Load SQS queue URL from environment variable
QUEUE_URL = os.getenv("SQS_QUEUE_URL")
print("QUEUE_URL:", QUEUE_URL)


# # Initialize AWS SQS client (will use ECS task role or env credentials)
# sqs = boto3.client('sqs', region_name=os.getenv("AWS_REGION", "us-east-1"))

AWS_REGION = os.getenv("AWS_REGION", "us-east-1")


# Force boto3 to use LocalStack
sqs = boto3.client('sqs', region_name=AWS_REGION, endpoint_url=LOCALSTACK_ENDPOINT)

# Define required fields for validation
REQUIRED_FIELDS = ['Application', 'Recipient', 'Subject', 'Message', 'OutputType', 'Date', 'Time', 'Interval']

# Define conversion factors for interval types to number of days
INTERVAL_FACTORS = {
    'Days': 1,
    'Weeks': 7,
    'Months': 30,
    'Years': 365
}

def validate_payload(data):
    """
    Validate that all required fields are present and correctly structured.
    """
    # Check for missing fields
    missing = [field for field in REQUIRED_FIELDS if field not in data]
    if missing:
        return False, f"Missing fields: {', '.join(missing)}"
    
    # Check that Interval is a dictionary
    if not isinstance(data['Interval'], dict):
        return False, "Interval must be a dictionary with 'Type' and 'Values'"
    
    # Ensure the interval type is supported
    if data['Interval'].get("Type") not in INTERVAL_FACTORS:
        return False, f"Invalid interval type. Supported: {list(INTERVAL_FACTORS.keys())}"
    
    # Ensure values are a list
    if not isinstance(data['Interval'].get("Values"), list):
        return False, "Interval.Values must be a list of numbers"
    
    return True, ""


def convert_interval_to_days(interval):
    """
    Convert interval values (e.g., Weeks, Months, Years) to days using defined factors.
    """
    interval_type = interval['Type']
    values = interval['Values']
    factor = INTERVAL_FACTORS[interval_type]
    return [v * factor for v in values]


@app.route('/notify', methods=['POST'])
def handle_notification():
    """
    REST API endpoint that receives a notification request and pushes it to SQS.
    """
    data = request.get_json()

    # Validate the input payload
    valid, msg = validate_payload(data)
    if not valid:
        return jsonify({"error": msg}), 400

    # Convert interval to days for internal processing or future scheduling
    interval_days = convert_interval_to_days(data['Interval'])

    # Construct the payload to send to SQS
    message_body = {
        "Application": data["Application"],
        "Recipient": data["Recipient"],
        "Subject": data["Subject"],
        "Message": data["Message"],
        "OutputType": data["OutputType"],
        "Date": data["Date"],
        "Time": data["Time"],
        "IntervalDays": interval_days,               # Normalized values
        "OriginalInterval": data["Interval"],        # Preserve original interval object
        "ReceivedAt": datetime.utcnow().isoformat()  # Add timestamp for tracking
    }

    # Attempt to send message to the SQS queue
    try:
        response = sqs.send_message(
            QueueUrl=QUEUE_URL,
            MessageBody=jsonify(message_body).get_data(as_text=True)
        )
        return jsonify({
            "message": "Notification received and queued.",
            "messageId": response['MessageId']
        }), 200

    except Exception as e:
        # If something goes wrong with SQS call, return error
        return jsonify({"error": str(e)}), 500


# Run app if started directly (for local dev)
if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0', port=5000)
