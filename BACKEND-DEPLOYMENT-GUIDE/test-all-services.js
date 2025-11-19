// Test script for all Flask/FastAPI services
const ADMIN_BASE = 'http://localhost:8001';
const REQUESTOR_BASE = 'http://localhost:8000';

// Note: This script tests local Docker Compose setup
// For production API Gateway testing, use production-test.sh

async function testAdminService() {
  console.log('=== TESTING ADMIN SERVICE (Port 8001) ===\n');
  
  try {
    // Health check
    console.log('1. Health Check...');
    let response = await fetch(`${ADMIN_BASE}/health`);
    console.log('Status:', response.status);
    console.log('Data:', await response.json());

    // Admin authentication
    console.log('\n2. Admin Authentication...');
    response = await fetch(`${ADMIN_BASE}/admin/auth`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'admin',
        role: 'admin'
      })
    });
    console.log('Status:', response.status);
    const authData = await response.json();
    console.log('Token received:', !!authData.access_token);

    // Register application
    console.log('\n3. Register Application...');
    response = await fetch(`${ADMIN_BASE}/admin/applications`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        App_name: 'TestApp',
        Application: 'test-app-001',
        Email: 'test@example.com',
        Domain: 'example.com'
      })
    });
    console.log('Status:', response.status);
    console.log('Data:', await response.json());

    // List applications
    console.log('\n4. List Applications...');
    response = await fetch(`${ADMIN_BASE}/admin/applications`);
    console.log('Status:', response.status);
    console.log('Data:', await response.json());

  } catch (error) {
    console.error('Admin Service Error:', error.message);
  }
}

async function testRequestorService() {
  console.log('\n=== TESTING REQUESTOR SERVICE (Port 8000) ===\n');
  
  try {
    // Health check
    console.log('1. Health Check...');
    let response = await fetch(`${REQUESTOR_BASE}/health`);
    console.log('Status:', response.status);
    console.log('Data:', await response.json());

    // Generate auth token
    console.log('\n2. Generate Auth Token...');
    response = await fetch(`${REQUESTOR_BASE}/auth`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: 'client',
        role: 'client'
      })
    });
    console.log('Status:', response.status);
    const authData = await response.json();
    console.log('Token received:', !!authData.access_token);

    // Send notification request
    console.log('\n3. Send Notification Request...');
    response = await fetch(`${REQUESTOR_BASE}/notifications`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        Application: 'test-app-001',
        Recipient: 'test-user',
        Subject: 'Test Notification',
        Message: 'This is a test message',
        OutputType: 'EMAIL',
        EmailAddresses: ['test@example.com'],
        Interval: {
          Once: true
        }
      })
    });
    console.log('Status:', response.status);
    console.log('Data:', await response.json());

  } catch (error) {
    console.error('Requestor Service Error:', error.message);
  }
}

async function runAllTests() {
  await testAdminService();
  await testRequestorService();
  console.log('\n=== WORKER SERVICE ===');
  console.log('Worker service runs in background - no HTTP endpoints to test');
  console.log('It processes SQS messages and sends notifications via AWS SES/SNS');
}

runAllTests();