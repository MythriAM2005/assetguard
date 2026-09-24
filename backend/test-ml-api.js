/**
 * TEST SCRIPT: Diagnose V2 ML API 422 errors
 * 
 * Tests different Wi-Fi fingerprint formats to identify what causes 422.
 */

const ML_API_URL = process.env.ML_API_URL || 'http://10.135.90.221:8000';

async function testMLRequest(testName, payload) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`TEST: ${testName}`);
  console.log(`${'='.repeat(60)}`);
  console.log('Payload:', JSON.stringify(payload, null, 2));
  
  try {
    const response = await fetch(`${ML_API_URL}/predict-room`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    
    console.log('Status:', response.status, response.statusText);
    
    const responseText = await response.text();
    console.log('Response body:', responseText);
    
    if (response.ok) {
      try {
        const data = JSON.parse(responseText);
        console.log('✓ SUCCESS - Room:', data.room || data.predicted_room);
        console.log('✓ Confidence:', data.confidence);
      } catch (e) {
        console.log('✓ SUCCESS but response not JSON');
      }
    } else {
      console.log('✗ FAILED');
      try {
        const errorData = JSON.parse(responseText);
        console.log('Error details:', JSON.stringify(errorData, null, 2));
      } catch (e) {
        // Already logged as text
      }
    }
  } catch (error) {
    console.log('✗ REQUEST FAILED:', error.message);
  }
}

async function runTests() {
  console.log('V2 ML API DIAGNOSTIC TESTS');
  console.log('ML Server:', ML_API_URL);
  console.log('Testing /predict-room endpoint\n');
  
  // Test 1: Simple valid fingerprint (3 BSSIDs)
  await testMLRequest('Test 1: Small fingerprint (3 BSSIDs)', {
    wifi: {
      "84:d8:1b:aa:bb:cc": -43,
      "84:d8:1b:11:22:33": -67,
      "84:d8:1b:44:55:66": -89
    }
  });
  
  // Test 2: Larger fingerprint (30 BSSIDs)
  const fingerprint30 = {};
  for (let i = 0; i < 30; i++) {
    fingerprint30[`84:d8:1b:${i.toString(16).padStart(2, '0')}:${i.toString(16).padStart(2, '0')}:${i.toString(16).padStart(2, '0')}`] = -40 - i;
  }
  await testMLRequest('Test 2: Medium fingerprint (30 BSSIDs)', {
    wifi: fingerprint30
  });
  
  // Test 3: Exact 106 BSSIDs (model feature count)
  const fingerprint106 = {};
  for (let i = 0; i < 106; i++) {
    fingerprint106[`84:d8:1b:${(i % 256).toString(16).padStart(2, '0')}:${Math.floor(i / 256).toString(16).padStart(2, '0')}:${i.toString(16).padStart(2, '0')}`] = -40 - (i % 80);
  }
  await testMLRequest('Test 3: Exact 106 BSSIDs (model feature count)', {
    wifi: fingerprint106
  });
  
  // Test 4: More than 106 BSSIDs
  const fingerprint120 = {};
  for (let i = 0; i < 120; i++) {
    fingerprint120[`84:d8:1b:${(i % 256).toString(16).padStart(2, '0')}:${Math.floor(i / 256).toString(16).padStart(2, '0')}:${i.toString(16).padStart(2, '0')}`] = -40 - (i % 80);
  }
  await testMLRequest('Test 4: Large fingerprint (120 BSSIDs)', {
    wifi: fingerprint120
  });
  
  // Test 5: Empty fingerprint
  await testMLRequest('Test 5: Empty fingerprint', {
    wifi: {}
  });
  
  // Test 6: Missing 'wifi' key
  await testMLRequest('Test 6: Missing wifi key', {
    fingerprint: {
      "84:d8:1b:aa:bb:cc": -43
    }
  });
  
  // Test 7: Array format instead of object
  await testMLRequest('Test 7: Array format (wrong)', {
    wifi: [
      { bssid: "84:d8:1b:aa:bb:cc", rssi: -43 },
      { bssid: "84:d8:1b:11:22:33", rssi: -67 }
    ]
  });
  
  // Test 8: String RSSI values
  await testMLRequest('Test 8: String RSSI values (wrong type)', {
    wifi: {
      "84:d8:1b:aa:bb:cc": "-43",
      "84:d8:1b:11:22:33": "-67"
    }
  });
  
  // Test 9: Null/undefined values
  await testMLRequest('Test 9: Null RSSI value', {
    wifi: {
      "84:d8:1b:aa:bb:cc": -43,
      "84:d8:1b:11:22:33": null
    }
  });
  
  // Test 10: Out of range RSSI values
  await testMLRequest('Test 10: Out of range RSSI (+10 dBm)', {
    wifi: {
      "84:d8:1b:aa:bb:cc": 10,
      "84:d8:1b:11:22:33": -67
    }
  });
  
  console.log(`\n${'='.repeat(60)}`);
  console.log('TESTS COMPLETE');
  console.log(`${'='.repeat(60)}\n`);
}

runTests().catch(console.error);
