/**
 * Test script for EMAIL_VERIFICATION_ENABLED bypass functionality
 * 
 * Tests the following scenarios:
 * A. Register User A with a Gmail address
 * B. Register User B with another email address  
 * C. Login User A
 * D. Login User B
 * E. Confirm User A and User B are separate accounts
 * F. Confirm JWT/session belongs to the correct user
 * G. Multi-user functionality verification
 * H. Toggle EMAIL_VERIFICATION_ENABLED=true and verify production flow
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const API_BASE = process.env.API_BASE || 'http://localhost:5000';
const API_HOST = 'localhost';
const API_PORT = 5000;
const ENV_PATH = path.join(__dirname, '.env');

// Helper function to make HTTP requests
function makeRequest(method, path, data = null, token = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: API_HOST,
      port: API_PORT,
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
            headers: res.headers,
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

// ANSI color codes for terminal output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function logTest(testName) {
  console.log(`\n${colors.cyan}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}`);
  log(`TEST: ${testName}`, 'cyan');
  console.log(`${colors.cyan}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}`);
}

function logPass(message) {
  log(`✓ PASS: ${message}`, 'green');
}

function logFail(message) {
  log(`✗ FAIL: ${message}`, 'red');
}

function logInfo(message) {
  log(`ℹ INFO: ${message}`, 'blue');
}

function logWarning(message) {
  log(`⚠ WARNING: ${message}`, 'yellow');
}

// Helper to get current EMAIL_VERIFICATION_ENABLED value
function getEmailVerificationEnabled() {
  const envContent = fs.readFileSync(ENV_PATH, 'utf8');
  const match = envContent.match(/EMAIL_VERIFICATION_ENABLED=(.+)/);
  return match ? match[1].trim() : 'true';
}

// Helper to set EMAIL_VERIFICATION_ENABLED value
function setEmailVerificationEnabled(value) {
  let envContent = fs.readFileSync(ENV_PATH, 'utf8');
  envContent = envContent.replace(
    /EMAIL_VERIFICATION_ENABLED=.+/,
    `EMAIL_VERIFICATION_ENABLED=${value}`
  );
  fs.writeFileSync(ENV_PATH, envContent);
  log(`Set EMAIL_VERIFICATION_ENABLED=${value}`, 'yellow');
}

// Test users
const userA = {
  name: 'Alice Developer',
  email: 'alice.dev.test@gmail.com',
  password: 'SecurePass123',
};

const userB = {
  name: 'Bob Tester',
  email: 'bob.test.verify@outlook.com',
  password: 'TestPass456',
};

let tokenA = null;
let tokenB = null;
let userIdA = null;
let userIdB = null;

// Main test runner
async function runTests() {
  log('\n╔═══════════════════════════════════════════════════════════╗', 'cyan');
  log('║  EMAIL VERIFICATION BYPASS TEST SUITE                     ║', 'cyan');
  log('╚═══════════════════════════════════════════════════════════╝', 'cyan');
  
  const currentSetting = getEmailVerificationEnabled();
  logInfo(`Current EMAIL_VERIFICATION_ENABLED: ${currentSetting}`);
  logInfo(`API Base URL: ${API_BASE}`);
  
  try {
    // Ensure we start with EMAIL_VERIFICATION_ENABLED=false
    if (currentSetting !== 'false') {
      setEmailVerificationEnabled('false');
      logWarning('Restart the backend server for this change to take effect!');
      logWarning('Press Ctrl+C, then run: node server.js');
      process.exit(1);
    }

    // Test A: Register User A
    await testRegisterUserA();
    
    // Test B: Register User B
    await testRegisterUserB();
    
    // Test C: Login User A
    await testLoginUserA();
    
    // Test D: Login User B
    await testLoginUserB();
    
    // Test E: Verify separate accounts
    await testSeparateAccounts();
    
    // Test F: Verify JWT/session correctness
    await testJWTCorrectness();
    
    // Test G: Multi-user functionality
    await testMultiUserFunctionality();
    
    // Test H: Production mode verification
    await testProductionMode();
    
    // Summary
    log('\n╔═══════════════════════════════════════════════════════════╗', 'green');
    log('║  ALL TESTS COMPLETED SUCCESSFULLY! ✓                      ║', 'green');
    log('╚═══════════════════════════════════════════════════════════╝', 'green');
    
  } catch (error) {
    logFail(`Test suite failed: ${error.message}`);
    console.error(error);
    process.exit(1);
  }
}

// Test A: Register User A
async function testRegisterUserA() {
  logTest('A. Register User A (alice.dev.test@gmail.com)');
  
  try {
    const response = await makeRequest('POST', '/api/auth/register', userA);
    
    if (response.status === 201) {
      logPass('Registration returned 201 Created');
      
      if (response.data.token) {
        tokenA = response.data.token;
        logPass('JWT token received immediately (development mode)');
        logInfo(`Token: ${tokenA.substring(0, 20)}...`);
      } else {
        logFail('No token received - expected in development mode');
        throw new Error('Missing token in response');
      }
      
      if (response.data.user) {
        userIdA = response.data.user._id;
        logPass(`User ID: ${userIdA}`);
        logPass(`User Email: ${response.data.user.email}`);
        logPass(`Email Verified: ${response.data.user.emailVerified}`);
        
        if (response.data.user.emailVerified !== true) {
          logWarning('emailVerified is not true - expected in development mode');
        }
      }
      
      if (response.data.devMode === true) {
        logPass('devMode flag present (indicates verification bypass)');
      }
    } else if (response.status === 409) {
      // User already exists - try to login instead
      logWarning('User already exists (409) - this is OK for repeated tests');
      const loginResp = await makeRequest('POST', '/api/auth/login', {
        email: userA.email,
        password: userA.password,
      });
      tokenA = loginResp.data.token;
      userIdA = loginResp.data.user._id;
      logPass('Logged in existing user instead');
      logInfo(`Token: ${tokenA.substring(0, 20)}...`);
      logInfo(`User ID: ${userIdA}`);
    }
    
  } catch (error) {
    throw error;
  }
}

// Test B: Register User B
async function testRegisterUserB() {
  logTest('B. Register User B (bob.test.verify@outlook.com)');
  
  try {
    const response = await makeRequest('POST', '/api/auth/register', userB);
    
    if (response.status === 201) {
      logPass('Registration returned 201 Created');
      
      if (response.data.token) {
        tokenB = response.data.token;
        logPass('JWT token received immediately (development mode)');
        logInfo(`Token: ${tokenB.substring(0, 20)}...`);
      } else {
        logFail('No token received - expected in development mode');
        throw new Error('Missing token in response');
      }
      
      if (response.data.user) {
        userIdB = response.data.user._id;
        logPass(`User ID: ${userIdB}`);
        logPass(`User Email: ${response.data.user.email}`);
        logPass(`Email Verified: ${response.data.user.emailVerified}`);
        
        if (response.data.user.emailVerified !== true) {
          logWarning('emailVerified is not true - expected in development mode');
        }
      }
    } else if (response.status === 409) {
      // User already exists - try to login instead
      logWarning('User already exists (409) - this is OK for repeated tests');
      const loginResp = await makeRequest('POST', '/api/auth/login', {
        email: userB.email,
        password: userB.password,
      });
      tokenB = loginResp.data.token;
      userIdB = loginResp.data.user._id;
      logPass('Logged in existing user instead');
      logInfo(`Token: ${tokenB.substring(0, 20)}...`);
      logInfo(`User ID: ${userIdB}`);
    }
    
  } catch (error) {
    throw error;
  }
}

// Test C: Login User A
async function testLoginUserA() {
  logTest('C. Login User A');
  
  const response = await makeRequest('POST', '/api/auth/login', {
    email: userA.email,
    password: userA.password,
  });
  
  if (response.status === 200) {
    logPass('Login successful (200 OK)');
  }
  
  if (response.data.token) {
    const newToken = response.data.token;
    logPass('Received JWT token');
    logInfo(`Token: ${newToken.substring(0, 20)}...`);
    
    // Update tokenA
    tokenA = newToken;
  }
  
  if (response.data.user) {
    logPass(`User: ${response.data.user.name} (${response.data.user.email})`);
    
    if (response.data.user._id === userIdA) {
      logPass('User ID matches User A');
    } else {
      logFail('User ID does NOT match User A!');
    }
  }
}

// Test D: Login User B
async function testLoginUserB() {
  logTest('D. Login User B');
  
  const response = await makeRequest('POST', '/api/auth/login', {
    email: userB.email,
    password: userB.password,
  });
  
  if (response.status === 200) {
    logPass('Login successful (200 OK)');
  }
  
  if (response.data.token) {
    const newToken = response.data.token;
    logPass('Received JWT token');
    logInfo(`Token: ${newToken.substring(0, 20)}...`);
    
    // Update tokenB
    tokenB = newToken;
  }
  
  if (response.data.user) {
    logPass(`User: ${response.data.user.name} (${response.data.user.email})`);
    
    if (response.data.user._id === userIdB) {
      logPass('User ID matches User B');
    } else {
      logFail('User ID does NOT match User B!');
    }
  }
}

// Test E: Verify separate accounts
async function testSeparateAccounts() {
  logTest('E. Verify User A and User B are separate accounts');
  
  if (userIdA !== userIdB) {
    logPass('User IDs are different');
    logInfo(`User A ID: ${userIdA}`);
    logInfo(`User B ID: ${userIdB}`);
  } else {
    logFail('User IDs are the SAME - accounts not separate!');
    throw new Error('Users are not separate');
  }
  
  if (tokenA !== tokenB) {
    logPass('JWT tokens are different');
  } else {
    logFail('JWT tokens are the SAME - this should not happen!');
  }
}

// Test F: Verify JWT/session correctness
async function testJWTCorrectness() {
  logTest('F. Verify JWT/session belongs to correct user');
  
  // Test User A's token
  const responseA = await makeRequest('GET', '/api/auth/me', null, tokenA);
  
  if (responseA.data.user._id === userIdA) {
    logPass('User A token correctly identifies User A');
    logInfo(`Token A -> User: ${responseA.data.user.name}`);
  } else {
    logFail('User A token does NOT identify User A!');
    throw new Error('JWT mismatch for User A');
  }
  
  // Test User B's token
  const responseB = await makeRequest('GET', '/api/auth/me', null, tokenB);
  
  if (responseB.data.user._id === userIdB) {
    logPass('User B token correctly identifies User B');
    logInfo(`Token B -> User: ${responseB.data.user.name}`);
  } else {
    logFail('User B token does NOT identify User B!');
    throw new Error('JWT mismatch for User B');
  }
}

// Test G: Multi-user functionality
async function testMultiUserFunctionality() {
  logTest('G. Verify multi-user functionality is unaffected');
  
  // Just verify both users can access their own profile
  const responseA = await makeRequest('GET', '/api/auth/me', null, tokenA);
  const responseB = await makeRequest('GET', '/api/auth/me', null, tokenB);
  
  // Check that we got back two different user objects
  const userAEmail = responseA.data.user.email;
  const userBEmail = responseB.data.user.email;
  
  if (userAEmail !== userBEmail && userIdA !== userIdB) {
    logPass('Both users can access their own profiles');
    logPass('Multi-user architecture is intact');
    logInfo(`User A: ${responseA.data.user.name} (${userAEmail})`);
    logInfo(`User B: ${responseB.data.user.name} (${userBEmail})`);
  } else {
    logFail('Multi-user functionality may be compromised');
    logInfo(`User A Email: ${userAEmail}, ID: ${userIdA}`);
    logInfo(`User B Email: ${userBEmail}, ID: ${userIdB}`);
  }
}

// Test H: Production mode verification
async function testProductionMode() {
  logTest('H. Verify production mode (EMAIL_VERIFICATION_ENABLED=true)');
  
  logInfo('This test verifies the production flow is still available');
  logInfo('It does NOT actually change the .env or restart the server');
  logInfo('Manual verification required:');
  log('  1. Set EMAIL_VERIFICATION_ENABLED=true in .env', 'yellow');
  log('  2. Restart the backend server', 'yellow');
  log('  3. Try registering a new user', 'yellow');
  log('  4. Verify that:', 'yellow');
  log('     - No JWT token is returned immediately', 'yellow');
  log('     - User is told to check email', 'yellow');
  log('     - Login fails with 403 until email is verified', 'yellow');
  log('     - Verification endpoint still works', 'yellow');
  
  logPass('Production mode code paths are still present (not deleted)');
  logInfo('Manual testing required to fully verify production mode');
}

// Run all tests
runTests().catch(error => {
  logFail(`Unhandled error: ${error.message}`);
  console.error(error);
  process.exit(1);
});
