const { Redis } = require('@upstash/redis');
const twilio = require('twilio');

// Initialize Redis client
const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL,
  token: process.env.UPSTASH_REDIS_REST_TOKEN,
});

// Initialize Twilio client
const twilioClient = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

export default async function handler(req, res) {
  // Only allow GET requests (for cron)
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    console.log('Cron job started');
    
    // Get all alarm keys
    const keys = await redis.keys('alarm:*');
    const now = Date.now();
    
    console.log(`Found ${keys.length} alarm keys`);
    
    for (const key of keys) {
      try {
        // Get alarm data
        const alarmDataStr = await redis.get(key);
        
        if (!alarmDataStr) {
          // Key expired or doesn't exist, skip
          continue;
        }
        
        const alarmData = JSON.parse(alarmDataStr);
        
        // Check if it's time to send SMS
        const deadlineTime = alarmData.deadline * 1000;
        
        if (now >= deadlineTime) {
          console.log(`Sending SMS for expired alarm: ${alarmData.alarmId}`);
          
          // Send SMS
          const message = `WakeOrPay緊急通知: アラーム${alarmData.alarmId}のQRコードスキャンがタイムアウトしました。`;
          
          try {
            await twilioClient.messages.create({
              body: message,
              from: process.env.TWILIO_PHONE_NUMBER,
              to: alarmData.phoneNumber
            });
            
            console.log(`SMS sent for alarm: ${alarmData.alarmId}`);
            
            // Remove the key after sending SMS
            await redis.del(key);
            
          } catch (smsError) {
            console.error(`Failed to send SMS for alarm ${alarmData.alarmId}:`, smsError);
            
            // Mark as failed and set shorter expiration
            alarmData.status = 'failed';
            alarmData.error = smsError.message;
            alarmData.failedAt = Date.now();
            
            // Retry in 5 minutes
            await redis.setex(key, 300, JSON.stringify(alarmData));
          }
        }
        
      } catch (error) {
        console.error(`Error processing key ${key}:`, error);
        // Continue with next key
      }
    }
    
    console.log('Cron job completed');
    return res.status(200).json({ success: true, processed: keys.length });
    
  } catch (error) {
    console.error('Cron job error:', error);
    return res.status(500).json({ error: error.message });
  }
}

