# WakeOrPay Server Setup

This server provides automatic SMS notifications when QR code scanning times out.

## Architecture

- **Vercel Functions**: Serverless functions for webhook and cron jobs
- **Upstash Redis**: In-memory database for alarm scheduling
- **Twilio**: SMS service provider
- **Vercel Cron**: Scheduled tasks (every 10 seconds)

## Setup Instructions

### 1. Install Dependencies

```bash
npm install
```

### 2. Environment Variables

Copy `env.example` to `.env.local` and fill in your credentials:

```bash
cp env.example .env.local
```

Required variables:
- `UPSTASH_REDIS_REST_URL`: Your Upstash Redis REST URL
- `UPSTASH_REDIS_REST_TOKEN`: Your Upstash Redis REST token
- `TWILIO_ACCOUNT_SID`: Your Twilio Account SID
- `TWILIO_AUTH_TOKEN`: Your Twilio Auth Token
- `TWILIO_PHONE_NUMBER`: Your Twilio phone number (e.g., +1234567890)

### 3. Get Upstash Redis

1. Go to [Upstash Console](https://console.upstash.com/)
2. Create a new Redis database
3. Copy the REST URL and token from the database details

### 4. Get Twilio Credentials

1. Go to [Twilio Console](https://console.twilio.com/)
2. Get your Account SID and Auth Token from the dashboard
3. Purchase a phone number for sending SMS

### 5. Deploy to Vercel

```bash
# Install Vercel CLI
npm install -g vercel

# Login to Vercel
vercel login

# Deploy
vercel

# Set environment variables in Vercel dashboard
vercel env add UPSTASH_REDIS_REST_URL
vercel env add UPSTASH_REDIS_REST_TOKEN
vercel env add TWILIO_ACCOUNT_SID
vercel env add TWILIO_AUTH_TOKEN
vercel env add TWILIO_PHONE_NUMBER
```

### 6. Update iOS App

Update the `baseURL` in `ServerWebhookService.swift`:

```swift
private let baseURL = "https://your-vercel-app.vercel.app"
```

## How It Works

### 1. Alarm Registration
When an alarm starts, the iOS app sends a POST request to `/api/webhook` with:
```json
{
  "action": "register",
  "alarmId": "uuid",
  "fireDate": 1234567890,
  "phoneNumber": "+1234567890",
  "deviceId": "device-uuid",
  "deadline": 1234567950
}
```

The server stores this in Redis with expiration set to the deadline.

### 2. Success Cancellation
When QR code is scanned successfully, the app sends:
```json
{
  "action": "success",
  "alarmId": "uuid",
  "fireDate": 1234567890,
  "deviceId": "device-uuid"
}
```

The server removes the alarm from Redis, preventing SMS sending.

### 3. Immediate Timeout
If timeout is detected immediately, the app sends:
```json
{
  "action": "timeout",
  "alarmId": "uuid",
  "fireDate": 1234567890,
  "phoneNumber": "+1234567890",
  "deviceId": "device-uuid"
}
```

The server sends SMS immediately.

### 4. Cron Job
Every 10 seconds, Vercel Cron triggers `/api/cron` which:
1. Checks all alarms in Redis
2. Finds alarms past their deadline
3. Sends SMS for expired alarms
4. Removes processed alarms from Redis

## Testing

### Local Development

```bash
# Start local server
npm run dev

# Test webhook
curl -X POST http://localhost:3000/api/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "action": "register",
    "alarmId": "test-uuid",
    "fireDate": 1234567890,
    "phoneNumber": "+1234567890",
    "deviceId": "test-device",
    "deadline": 1234567895
  }'
```

### Production

Replace `localhost:3000` with your Vercel deployment URL.

## Monitoring

- Check Vercel function logs in the dashboard
- Monitor Redis usage in Upstash console
- Check Twilio usage and logs

## Troubleshooting

### Common Issues

1. **SMS not sending**: Check Twilio credentials and phone number format
2. **Redis connection failed**: Verify Upstash credentials and network access
3. **Cron not running**: Check Vercel cron configuration in vercel.json
4. **Functions timing out**: Increase maxDuration in vercel.json if needed

### Debug Mode

Enable debug logging by setting environment variable:
```
DEBUG=true
```

## Security Notes

- All API endpoints are public - consider adding authentication
- Redis data expires automatically for security
- Twilio credentials should be kept secret
- Use HTTPS in production (Vercel provides this automatically)

