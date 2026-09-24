/**
 * Test script to verify Resend API configuration
 * Run with: node test-resend.js
 */

require('dotenv').config();
const { Resend } = require('resend');

async function testResend() {
  console.log('=== Resend Email Service Test ===\n');

  // Check environment variables
  console.log('1. Checking environment variables...');
  const apiKey = process.env.RESEND_API_KEY;
  const fromEmail = process.env.RESEND_FROM_EMAIL || 'onboarding@resend.dev';
  
  if (!apiKey) {
    console.error('❌ RESEND_API_KEY is not set in .env file');
    process.exit(1);
  }
  
  console.log(`✓ RESEND_API_KEY found (length: ${apiKey.length})`);
  console.log(`✓ RESEND_FROM_EMAIL: ${fromEmail}\n`);

  // Initialize Resend client
  console.log('2. Initializing Resend client...');
  const resend = new Resend(apiKey);
  console.log('✓ Resend client initialized\n');

  // Test email sending
  console.log('3. Attempting to send test email...');
  console.log(`   From: AssetGuard AI <${fromEmail}>`);
  console.log(`   To: delivered@resend.dev (Resend test address)`);
  console.log(`   Subject: Resend API Test\n`);

  try {
    const { data, error } = await resend.emails.send({
      from: `AssetGuard AI <${fromEmail}>`,
      to: ['delivered@resend.dev'],  // Resend's official test email
      subject: 'Resend API Test - AssetGuard',
      html: '<p>This is a test email from AssetGuard backend.</p><p>If you receive this, the Resend API configuration is working correctly.</p>',
    });

    if (error) {
      console.error('❌ Email sending failed with Resend API error:');
      console.error('   Error name:', error.name);
      console.error('   Error message:', error.message);
      
      if (error.message.includes('API key')) {
        console.error('\n💡 Diagnosis: Invalid or expired API key');
        console.error('   Action: Get a new API key from https://resend.com/api-keys');
      } else if (error.message.includes('domain')) {
        console.error('\n💡 Diagnosis: Domain verification issue');
        console.error('   Action: Verify your domain in Resend dashboard');
      } else if (error.message.includes('from')) {
        console.error('\n💡 Diagnosis: Invalid sender email');
        console.error('   Action: Use a verified sender address in RESEND_FROM_EMAIL');
      }
      
      process.exit(1);
    }

    console.log('✅ Email sent successfully!');
    console.log('   Email ID:', data.id);
    console.log('\n=== Test Passed ===');
    console.log('Resend API is configured correctly.\n');
    
  } catch (err) {
    console.error('❌ Unexpected error during email send:');
    console.error('   Error:', err.message);
    
    if (err.message.includes('timeout')) {
      console.error('\n💡 Diagnosis: Network timeout');
      console.error('   Action: Check internet connectivity to api.resend.com');
    } else if (err.code === 'ENOTFOUND' || err.code === 'ECONNREFUSED') {
      console.error('\n💡 Diagnosis: Cannot reach Resend API');
      console.error('   Action: Check internet connection and firewall settings');
    }
    
    process.exit(1);
  }
}

testResend();
