#!/bin/bash

# Generate CloudWatch metrics for ALB dashboard
# This script sends periodic requests to both ALBs to generate metrics data

CLIENT_ALB="YANTECH-requester-alb-dev-1265507803.us-east-1.elb.amazonaws.com"
ADMIN_ALB="YANTECH-admin-alb-dev-271808247.us-east-1.elb.amazonaws.com"

echo "🚀 Starting ALB metrics generation..."
echo "📊 This will send requests every 30 seconds to generate CloudWatch data"
echo "⏱️  Metrics typically appear in CloudWatch within 5-15 minutes"
echo "🛑 Press Ctrl+C to stop"
echo ""

counter=1
while true; do
    echo "[$counter] $(date): Sending requests to ALBs..."
    
    # Send requests to client ALB
    echo "  → Client ALB health check..."
    curl -s "http://$CLIENT_ALB/health" > /dev/null
    
    # Send requests to admin ALB  
    echo "  → Admin ALB health check..."
    curl -s "http://$ADMIN_ALB/health" > /dev/null
    
    # Send a few more requests to generate more data points
    curl -s "http://$CLIENT_ALB/health" > /dev/null
    curl -s "http://$ADMIN_ALB/health" > /dev/null
    
    echo "  ✅ Requests completed"
    echo ""
    
    ((counter++))
    sleep 30
done