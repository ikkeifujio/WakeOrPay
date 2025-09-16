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
  // Only allow POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { action, alarmId, fireDate, phoneNumber, deviceId, deadline, timestamp } = req.body;
    
    console.log('Webhook received:', { action, alarmId, phoneNumber });

    if (action === 'register') {
      // Register alarm and schedule SMS
      const scheduleTime = new Date(deadline * 1000);
      const now = new Date();
      
      if (scheduleTime > now) {
        // Store alarm info in Redis with expiration
        const key = `alarm:${alarmId}:${deviceId}`;
        const alarmData = {
          alarmId,
          phoneNumber,
          deviceId,
          fireDate,
          deadline,
          status: 'scheduled',
          createdAt: timestamp
        };
        
        // Set expiration to deadline + 5 minutes buffer
        const expirationSeconds = Math.ceil((scheduleTime.getTime() - now.getTime()) / 1000) + 300;
        
        await redis.setex(key, expirationSeconds, JSON.stringify(alarmData));
        console.log(`Alarm registered: ${alarmId}, expires in ${expirationSeconds}s`);
      }
      
      return res.status(200).json({ success: true, message: 'Alarm registered' });
      
    } else if (action === 'success') {
      // Cancel scheduled SMS
      const key = `alarm:${alarmId}:${deviceId}`;
      const deleted = await redis.del(key);
      
      if (deleted > 0) {
        console.log(`Alarm cancelled: ${alarmId}`);
      }
      
      return res.status(200).json({ success: true, message: 'Alarm cancelled' });
      
    } else if (action === 'timeout') {
      // Send SMS immediately
      const message = `WakeOrPay緊急通知: アラーム${alarmId}のQRコードスキャンがタイムアウトしました。`;
      
      try {
        await twilioClient.messages.create({
          body: message,
          from: process.env.TWILIO_PHONE_NUMBER,
          to: phoneNumber
        });
        
        console.log(`SMS sent immediately for alarm: ${alarmId}`);
        return res.status(200).json({ success: true, message: 'SMS sent' });
      } catch (error) {
        console.error('SMS sending failed:', error);
        return res.status(500).json({ error: 'SMS sending failed', details: error.message });
      }
    }
    
    return res.status(400).json({ error: 'Invalid action' });
    
  } catch (error) {
    console.error('Webhook error:', error);
    return res.status(500).json({ error: error.message });
  }
}

