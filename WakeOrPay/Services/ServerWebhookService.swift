//
//  ServerWebhookService.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import Foundation
import UIKit

class ServerWebhookService: ObservableObject {
    static let shared = ServerWebhookService()
    
    private let baseURL = "https://wakeorpay-server.vercel.app" // Vercel Functions エンドポイント
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Success Reporting
    
    func reportSuccess(alarmId: UUID, fireDate: Date) async {
        let payload: [String: Any] = [
            "action": "cancel",
            "alarmId": alarmId.uuidString,
            "fireDate": fireDate.timeIntervalSince1970,
            "timestamp": Date().timeIntervalSince1970,
            "deviceId": getDeviceId()
        ]
        
        await sendWebhook(payload: payload, endpoint: "/api/cancel")
    }
    
    // MARK: - Alarm Registration
    
    func registerAlarm(alarmId: UUID, fireDate: Date, phoneNumber: String) async {
        let payload: [String: Any] = [
            "action": "register",
            "alarmId": alarmId.uuidString,
            "fireDate": fireDate.timeIntervalSince1970,
            "phoneNumber": phoneNumber,
            "deviceId": getDeviceId(),
            "deadline": fireDate.addingTimeInterval(60).timeIntervalSince1970 // 60秒後
        ]
        
        await sendWebhook(payload: payload, endpoint: "/api/register")
    }
    
    // MARK: - Timeout Notification
    
    func reportTimeout(alarmId: UUID, fireDate: Date, phoneNumber: String) async {
        let payload: [String: Any] = [
            "action": "timeout",
            "alarmId": alarmId.uuidString,
            "fireDate": fireDate.timeIntervalSince1970,
            "phoneNumber": phoneNumber,
            "deviceId": getDeviceId(),
            "timestamp": Date().timeIntervalSince1970
        ]
        
        await sendWebhook(payload: payload, endpoint: "/api/timeout")
    }
    
    func notifyTimeout(alarmId: UUID, fireDate: Date, phoneNumber: String) async {
        let payload: [String: Any] = [
            "action": "timeout",
            "alarmId": alarmId.uuidString,
            "fireDate": fireDate.timeIntervalSince1970,
            "phoneNumber": phoneNumber,
            "deviceId": getDeviceId(),
            "timestamp": Date().timeIntervalSince1970,
            "message": "アラームの停止に失敗しました。緊急連絡先にSMSが送信されました。"
        ]
        
        await sendWebhook(payload: payload, endpoint: "/api/timeout")
    }
    
    // MARK: - Private Methods
    
    private func sendWebhook(payload: [String: Any], endpoint: String = "/api/webhook") async {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            print("ServerWebhookService: 無効なURL - \(baseURL)\(endpoint)")
            return
        }
        
        print("ServerWebhookService: 送信先URL - \(url)")
        print("ServerWebhookService: ペイロード - \(payload)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0 // タイムアウトを10秒に設定
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = jsonData
            
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("ServerWebhookService: Webhook送信完了 - Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    print("ServerWebhookService: 成功")
                } else {
                    print("ServerWebhookService: エラー - Status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("ServerWebhookService: レスポンス: \(responseString)")
                    }
                }
            }
        } catch {
            print("ServerWebhookService: Webhook送信エラー: \(error)")
        }
    }
    
    private func getDeviceId() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }
}

// MARK: - Vercel Server Implementation (for reference)

/*
// Vercel Functions + Upstash Redis + Twilio implementation
// Files: api/webhook.js, api/cron.js, vercel.json, package.json

// api/webhook.js - Handle alarm registration, success, and timeout
const { Redis } = require('@upstash/redis');
const twilio = require('twilio');

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL,
  token: process.env.UPSTASH_REDIS_REST_TOKEN,
});

const twilioClient = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { action, alarmId, fireDate, phoneNumber, deviceId, deadline } = req.body;
    
    if (action === 'register') {
      // Store alarm in Redis with expiration
      const key = `alarm:${alarmId}:${deviceId}`;
      const expirationSeconds = Math.ceil((new Date(deadline * 1000) - new Date()) / 1000) + 300;
      
      await redis.setex(key, expirationSeconds, JSON.stringify({
        alarmId, phoneNumber, deviceId, fireDate, deadline, status: 'scheduled'
      }));
      
      return res.status(200).json({ success: true, message: 'Alarm registered' });
      
    } else if (action === 'success') {
      // Cancel scheduled SMS
      const key = `alarm:${alarmId}:${deviceId}`;
      await redis.del(key);
      
      return res.status(200).json({ success: true, message: 'Alarm cancelled' });
      
    } else if (action === 'timeout') {
      // Send SMS immediately
      const message = `WakeOrPay緊急通知: アラーム${alarmId}のQRコードスキャンがタイムアウトしました。`;
      
      await twilioClient.messages.create({
        body: message,
        from: process.env.TWILIO_PHONE_NUMBER,
        to: phoneNumber
      });
      
      return res.status(200).json({ success: true, message: 'SMS sent' });
    }
    
  } catch (error) {
    console.error('Webhook error:', error);
    return res.status(500).json({ error: error.message });
  }
}

// api/cron.js - Check for expired alarms every 10 seconds
export default async function handler(req, res) {
  const keys = await redis.keys('alarm:*');
  const now = Date.now();
  
  for (const key of keys) {
    const alarmData = JSON.parse(await redis.get(key));
    const deadlineTime = alarmData.deadline * 1000;
    
    if (now >= deadlineTime) {
      // Send SMS and remove from Redis
      await twilioClient.messages.create({
        body: `WakeOrPay緊急通知: アラーム${alarmData.alarmId}のQRコードスキャンがタイムアウトしました。`,
        from: process.env.TWILIO_PHONE_NUMBER,
        to: alarmData.phoneNumber
      });
      
      await redis.del(key);
    }
  }
  
  return res.status(200).json({ success: true });
}

// vercel.json - Configure cron job
// {
//   "crons": [
//     {
//       "path": "/api/cron",
//       "schedule": "every 10 seconds"
//     }
//   ]
// }
*/
