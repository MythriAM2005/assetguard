/**
 * Test Cross-User Community Detection Fix
 * 
 * Scenario:
 * - User A owns asset "laptop" with trackerId = AG-001, status = LOST
 * - User B detects AG-001 via BLE at -38 dBm
 * - User B should be able to report the detection
 * - Backend should create a CommunityDetection record
 * - User B should NOT gain access to User A's private asset data
 */

const http = require('http');

const API_HOST = 'localhost';
const API_PORT = 5000;

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

// ANSI colors
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m',
};

function log(msg, color = 'reset') {
  console.log(`${colors[color]}${msg}${colors.reset}`);
}

function logSection(title) {
  console.log(`\n${colors.cyan}${'='.repeat(70)}`);
  log(title, 'cyan');
  console.log(`${colors.cyan}${'='.repeat(70)}${colors.reset}\n`);
}

async function runTest() {
  log('\n╔════════════════════════════════════════════════════════════╗', 'cyan');
  log('║  CROSS-USER COMMUNITY DETECTION TEST                       ║', 'cyan');
  log('╚════════════════════════════════════════════════════════════╝', 'cyan');

  let tokenA, tokenB, userIdA, userIdB, assetId, testTrackerId;

  try {
    // ═══════════════════════════════════════════════════════════════
    logSection('STEP 1: Setup User A (Asset Owner)');
    
    // Login as User A (alice)
    log('Logging in as User A (alice.dev.test@gmail.com)...');
    const loginA = await makeRequest('POST', '/api/auth/login', {
      email: 'alice.dev.test@gmail.com',
      password: 'SecurePass123',
    });

    if (loginA.status !== 200) {
      log('❌ User A login failed. Make sure User A exists.', 'red');
      log('   Run test-email-verification-bypass.js first to create users.', 'yellow');
      process.exit(1);
    }

    tokenA = loginA.data.token;
    userIdA = loginA.data.user._id;
    log(`✓ User A logged in: ${loginA.data.user.name} (ID: ${userIdA})`, 'green');

    // Check if User A has an asset with a unique test trackerId
    log('\nChecking User A\'s assets...');
    const assetsA = await makeRequest('GET', '/api/assets', null, tokenA);
    
    // Use a unique trackerId to avoid conflicts
    testTrackerId = 'AG-TEST-CROSS-USER';
    let asset = assetsA.data.assets?.find(a => a.trackerId === testTrackerId);
    
    if (!asset) {
      // Create the asset
      log(`Creating asset "laptop" with trackerId ${testTrackerId}...`);
      const createResp = await makeRequest('POST', '/api/assets', {
        name: 'laptop',
        category: 'Electronics',
        description: 'MacBook Pro',
        trackerId: testTrackerId,
      }, tokenA);
      
      asset = createResp.data.asset;
      log(`✓ Asset created: ${asset.name} (ID: ${asset._id})`, 'green');
    } else {
      log(`✓ Asset found: ${asset.name} (ID: ${asset._id})`, 'green');
    }

    assetId = asset._id;

    // Ensure asset is marked as LOST
    if (asset.status !== 'LOST') {
      log('\nMarking asset as LOST...');
      const lostResp = await makeRequest('PATCH', `/api/assets/${assetId}/lost`, null, tokenA);
      log(`✓ Asset status: ${lostResp.data.asset.status}`, 'green');
    } else {
      log(`✓ Asset status: ${asset.status}`, 'green');
    }

    // ═══════════════════════════════════════════════════════════════
    logSection('STEP 2: Setup User B (Community Member)');
    
    // Login as User B (bob)
    log('Logging in as User B (bob.test.verify@outlook.com)...');
    const loginB = await makeRequest('POST', '/api/auth/login', {
      email: 'bob.test.verify@outlook.com',
      password: 'TestPass456',
    });

    if (loginB.status !== 200) {
      log('❌ User B login failed. Make sure User B exists.', 'red');
      log('   Run test-email-verification-bypass.js first to create users.', 'yellow');
      process.exit(1);
    }

    tokenB = loginB.data.token;
    userIdB = loginB.data.user._id;
    log(`✓ User B logged in: ${loginB.data.user.name} (ID: ${userIdB})`, 'green');

    // Verify User B does NOT own the test trackerId
    log(`\nVerifying User B does not own trackerId ${testTrackerId}...`);
    const assetsB = await makeRequest('GET', '/api/assets', null, tokenB);
    const hasTestTracker = assetsB.data.assets?.some(a => a.trackerId === testTrackerId);
    
    if (hasTestTracker) {
      log(`⚠ User B owns ${testTrackerId} - this test requires it to belong ONLY to User A`, 'yellow');
      log('   Please delete it from User B\'s assets and re-run.', 'yellow');
      process.exit(1);
    }
    log(`✓ User B does not own ${testTrackerId}`, 'green');

    // ═══════════════════════════════════════════════════════════════
    logSection('STEP 3: User B Reports Community Detection');
    
    log(`User B reports detecting ${testTrackerId} at -38 dBm...`);
    const detection = await makeRequest('POST', '/api/community/detections', {
      trackerId: testTrackerId,
      rssi: -38,
      remoteId: 'AA:BB:CC:DD:EE:FF',
      detectedAt: new Date().toISOString(),
    }, tokenB);

    if (detection.status === 201) {
      log('✓ Community detection accepted!', 'green');
      log(`  Message: ${detection.data.message}`, 'green');
      log(`  Detection ID: ${detection.data.detectionId}`, 'green');
    } else {
      log(`❌ Community detection failed (status ${detection.status})`, 'red');
      log(`   Error: ${detection.data.message}`, 'red');
      throw new Error('Community detection was rejected');
    }

    // ═══════════════════════════════════════════════════════════════
    logSection('STEP 4: Verify Security - User B Cannot Access User A\'s Asset');
    
    log('Testing: User B tries to GET asset by ID...');
    const getAsset = await makeRequest('GET', `/api/assets/${assetId}`, null, tokenB);
    
    if (getAsset.status === 404) {
      log('✓ User B cannot access User A\'s asset (404)', 'green');
    } else if (getAsset.status === 200) {
      log('❌ SECURITY ISSUE: User B can access User A\'s asset!', 'red');
      throw new Error('Cross-user asset access vulnerability');
    }

    log('\nTesting: User B tries to UPDATE User A\'s asset...');
    const updateAsset = await makeRequest('PUT', `/api/assets/${assetId}`, {
      name: 'Hacked Laptop',
    }, tokenB);
    
    if (updateAsset.status === 404) {
      log('✓ User B cannot update User A\'s asset (404)', 'green');
    } else {
      log('❌ SECURITY ISSUE: User B can update User A\'s asset!', 'red');
      throw new Error('Cross-user asset modification vulnerability');
    }

    log('\nTesting: User B tries to DELETE User A\'s asset...');
    const deleteAsset = await makeRequest('DELETE', `/api/assets/${assetId}`, null, tokenB);
    
    if (deleteAsset.status === 404) {
      log('✓ User B cannot delete User A\'s asset (404)', 'green');
    } else {
      log('❌ SECURITY ISSUE: User B can delete User A\'s asset!', 'red');
      throw new Error('Cross-user asset deletion vulnerability');
    }

    // ═══════════════════════════════════════════════════════════════
    logSection('STEP 5: Verify Owner Detection Endpoint Still Scoped');
    
    log(`Testing: User B tries to submit OWNER detection for ${testTrackerId}...`);
    const ownerDetection = await makeRequest('POST', '/api/detections', {
      trackerId: testTrackerId,
      bleRssi: -45,
      timestamp: new Date().toISOString(),
    }, tokenB);

    if (ownerDetection.status === 404) {
      log('✓ Owner detection endpoint correctly rejected (404)', 'green');
      log(`  Error: ${ownerDetection.data.message}`, 'green');
    } else if (ownerDetection.status === 201) {
      log('❌ Owner detection endpoint incorrectly accepted!', 'red');
      log('   This endpoint should only accept detections for owned assets.', 'red');
      throw new Error('Owner detection endpoint not properly scoped');
    }

    // ═══════════════════════════════════════════════════════════════
    logSection('TEST SUMMARY');
    
    log('✅ Cross-user community detection: WORKING', 'green');
    log('✅ Asset ownership security: INTACT', 'green');
    log('✅ Owner detection scoping: CORRECT', 'green');
    log('✅ Community detection can report other users\' LOST assets', 'green');
    log('✅ Community members cannot access/modify/delete others\' assets', 'green');
    
    log('\n╔════════════════════════════════════════════════════════════╗', 'green');
    log('║  ALL TESTS PASSED ✓                                        ║', 'green');
    log('╚════════════════════════════════════════════════════════════╝', 'green');

  } catch (error) {
    log('\n╔════════════════════════════════════════════════════════════╗', 'red');
    log('║  TEST FAILED ✗                                             ║', 'red');
    log('╚════════════════════════════════════════════════════════════╝', 'red');
    log(`\nError: ${error.message}`, 'red');
    console.error(error);
    process.exit(1);
  }
}

runTest();
