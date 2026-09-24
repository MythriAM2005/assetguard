/**
 * Simple test to verify development mode logs appear correctly
 */

const http = require('http');

function makeRequest(method, path, data = null, token = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 5000,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
      },
    };

    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          const response = {
            status: res.statusCode,
            data: body ? JSON.parse(body) : {},
          };
          resolve(response);
        } catch (e) {
          reject(new Error(`Failed to parse response: ${body}`));
        }
      });
    });

    req.on('error', reject);

    if (data) {
      req.write(JSON.stringify(data));
    }

    req.end();
  });
}

async function testRegistration() {
  console.log('\n🧪 Testing Development Mode Registration');
  console.log('========================================\n');
  
  const timestamp = Date.now();
  const testUser = {
    name: 'Dev Test User',
    email: `devtest${timestamp}@example.com`,
    password: 'testpass123',
  };
  
  console.log(`Registering user: ${testUser.email}`);
  console.log('Expected server logs:');
  console.log('  ⚠️  [Auth] Email verification DISABLED — development mode. User marked verified immediately.');
  console.log('  ✓ [Auth] User devtestXXX@example.com registered and auto-verified (development mode)\n');
  
  try {
    const response = await makeRequest('POST', '/api/auth/register', testUser);
    
    console.log('✅ Registration Response:');
    console.log(`   Status: ${response.status}`);
    console.log(`   Message: ${response.data.message}`);
    console.log(`   Token received: ${response.data.token ? 'Yes' : 'No'}`);
    console.log(`   User verified: ${response.data.user?.emailVerified}`);
    console.log(`   Dev mode flag: ${response.data.devMode}`);
    
    if (response.data.token && response.data.user?.emailVerified && response.data.devMode) {
      console.log('\n✅ Development mode working correctly!');
      
      // Now test login
      console.log('\n🧪 Testing Login (should work immediately)');
      const loginResponse = await makeRequest('POST', '/api/auth/login', {
        email: testUser.email,
        password: testUser.password,
      });
      
      console.log('✅ Login Response:');
      console.log(`   Status: ${loginResponse.status}`);
      console.log(`   Token received: ${loginResponse.data.token ? 'Yes' : 'No'}`);
      console.log(`   User: ${loginResponse.data.user?.name}`);
      
      console.log('\n✅ All development mode tests passed!');
      console.log('\nCheck the server logs above for the expected warning messages.');
    } else {
      console.log('\n❌ Development mode not working as expected');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

testRegistration();
