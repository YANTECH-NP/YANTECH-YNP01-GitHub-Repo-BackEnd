// Simple script to test backend connection
const http = require('http');

const BACKEND_IP = '54.196.198.21';
const BACKEND_PORT = 8001;

console.log(`\n🔍 Testing connection to backend at ${BACKEND_IP}:${BACKEND_PORT}...\n`);

// Test 1: Try to connect to the root endpoint
const options = {
  hostname: BACKEND_IP,
  port: BACKEND_PORT,
  path: '/',
  method: 'GET',
  timeout: 5000,
};

const req = http.request(options, (res) => {
  console.log(`✅ Connection successful!`);
  console.log(`   Status Code: ${res.statusCode}`);
  console.log(`   Headers:`, res.headers);
  
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    console.log(`   Response:`, data);
    console.log('\n✅ Backend is reachable!\n');
  });
});

req.on('error', (error) => {
  console.error(`❌ Connection failed!`);
  console.error(`   Error: ${error.message}`);
  console.error(`   Code: ${error.code}\n`);
  
  if (error.code === 'ECONNREFUSED') {
    console.log('📋 Possible causes:');
    console.log('   1. Backend container is not running on EC2');
    console.log('   2. Backend is listening on 127.0.0.1 instead of 0.0.0.0');
    console.log('   3. EC2 Security Group is blocking port 8001');
    console.log('   4. EC2 instance firewall (iptables) is blocking the port\n');
    console.log('🔧 Troubleshooting steps:');
    console.log('   1. SSH into EC2 and run: docker ps');
    console.log('   2. Check if container is running: docker logs fastapi-backend');
    console.log('   3. Check EC2 Security Group inbound rules for port 8001');
    console.log('   4. Test locally on EC2: curl http://localhost:8001\n');
  } else if (error.code === 'ETIMEDOUT') {
    console.log('📋 Connection timed out - likely a firewall/security group issue\n');
  }
});

req.on('timeout', () => {
  console.error('❌ Connection timed out after 5 seconds\n');
  req.destroy();
});

req.end();

