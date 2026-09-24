/**
 * Test script to verify email verification bypass in development mode
 * Run with: node test-registration-flow.js
 */

require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./src/models/User');

async function testRegistrationFlow() {
  console.log('=== Email Verification Bypass Test ===\n');

  // Check environment variable
  const emailVerificationEnabled = process.env.EMAIL_VERIFICATION_ENABLED !== 'false';
  
  console.log('1. Environment Configuration:');
  console.log(`   EMAIL_VERIFICATION_ENABLED = ${process.env.EMAIL_VERIFICATION_ENABLED || 'not set (defaults to true)'}`);
  console.log(`   Actual behavior: ${emailVerificationEnabled ? 'PRODUCTION MODE (email required)' : 'DEVELOPMENT MODE (auto-verify)'}\n`);

  // Connect to MongoDB
  console.log('2. Connecting to MongoDB...');
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('   ✓ Connected to database\n');
  } catch (err) {
    console.error('   ✗ Database connection failed:', err.message);
    process.exit(1);
  }

  // Clean up test users
  console.log('3. Cleaning up test users...');
  await User.deleteMany({ email: { $in: ['testuserA@example.com', 'testuserB@example.com'] } });
  console.log('   ✓ Test users cleaned up\n');

  console.log('4. Testing registration via API...');
  console.log('   Use these curl commands to test:\n');
  
  console.log('   # Register User A:');
  console.log('   curl -X POST http://localhost:5000/api/auth/register \\');
  console.log('     -H "Content-Type: application/json" \\');
  console.log('     -d \'{"name":"Alice Owner","email":"alice@gmail.com","password":"password123"}\'\n');
  
  console.log('   # Register User B:');
  console.log('   curl -X POST http://localhost:5000/api/auth/register \\');
  console.log('     -H "Content-Type: application/json" \\');
  console.log('     -d \'{"name":"Bob Detector","email":"bob@outlook.com","password":"password123"}\'\n');

  if (!emailVerificationEnabled) {
    console.log('   ✓ DEVELOPMENT MODE: Users will be auto-verified and receive JWT immediately\n');
  } else {
    console.log('   ⚠️  PRODUCTION MODE: Users will need to verify email before login\n');
  }

  console.log('5. Expected Behavior:\n');
  
  if (!emailVerificationEnabled) {
    console.log('   DEVELOPMENT MODE (EMAIL_VERIFICATION_ENABLED=false):');
    console.log('   ✓ Registration returns: { token, user, message }');
    console.log('   ✓ User can login immediately without email verification');
    console.log('   ✓ Backend logs: "Email verification DISABLED — development mode"');
    console.log('   ✓ No email sent to Resend');
    console.log('   ✓ User.emailVerified = true in database\n');
  } else {
    console.log('   PRODUCTION MODE (EMAIL_VERIFICATION_ENABLED=true):');
    console.log('   ✓ Registration returns: { message, emailSent: true }');
    console.log('   ✓ User cannot login until email verified');
    console.log('   ✓ Backend logs: "Email verification ENABLED — sending verification email"');
    console.log('   ✓ Email sent via Resend');
    console.log('   ✓ User.emailVerified = false until verification\n');
  }

  console.log('6. To test login after registration:\n');
  console.log('   curl -X POST http://localhost:5000/api/auth/login \\');
  console.log('     -H "Content-Type: application/json" \\');
  console.log('     -d \'{"email":"alice@gmail.com","password":"password123"}\'\n');

  console.log('=== Test Guide Complete ===\n');
  
  await mongoose.connection.close();
  console.log('Database connection closed.');
}

testRegistrationFlow().catch(err => {
  console.error('Test failed:', err);
  process.exit(1);
});
