//
//  SoundService.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import Foundation
import AVFoundation
import UIKit
import UserNotifications

class SoundService: ObservableObject {
    static let shared = SoundService()
    
    @Published var isPlaying: Bool = false
    @Published var currentVolume: Float = 0.8
    
    private var audioPlayer: AVAudioPlayer?
    private var hapticFeedback: UIImpactFeedbackGenerator?
    private var alarmTimer: Timer?
    private var alarmDuration: TimeInterval = 30.0 // 30秒間のアラーム
    
    private init() {
        setupAudioSession()
        setupHapticFeedback()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("オーディオセッションの設定に失敗: \(error)")
        }
    }
    
    private func setupHapticFeedback() {
        hapticFeedback = UIImpactFeedbackGenerator(style: .heavy)
        hapticFeedback?.prepare()
    }
    
    func playAlarmSound(_ soundName: String, volume: Float = 0.8) {
        print("playAlarmSound呼び出し: \(soundName), volume: \(volume)")
        stopAlarmSound()
        
        // オーディオセッションを再設定
        setupAudioSession()
        
        // 30秒間のアラームタイマーを設定
        startAlarmTimer()
        
        // 音声ファイルが存在するかチェック
        guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: "wav") else {
            print("音声ファイルが見つかりません: \(soundName).wav - デフォルト音を使用")
            playDefaultSound(volume: volume)
            return
        }
        
        print("音声ファイルが見つかりました: \(soundURL)")
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.volume = volume
            audioPlayer?.numberOfLoops = -1 // 無限ループ
            audioPlayer?.prepareToPlay()
            
            let success = audioPlayer?.play() ?? false
            if success {
                isPlaying = true
                currentVolume = volume
                print("アラーム音を再生開始: \(soundName) (30秒間)")
            } else {
                print("音声再生に失敗 - デフォルト音を使用")
                playDefaultSound(volume: volume)
            }
        } catch {
            print("音声再生に失敗: \(error) - デフォルト音を使用")
            playDefaultSound(volume: volume)
        }
    }
    
    private func playDefaultSound(volume: Float) {
        print("デフォルト音を再生開始")
        // 30秒間のアラームタイマーを設定
        startAlarmTimer()
        
        // システム音を使用（30秒間繰り返し）
        playSystemAlarmRepeatedly()
        isPlaying = true
        currentVolume = volume
        print("デフォルト音再生完了")
    }
    
    func stopAlarmSound() {
        audioPlayer?.stop()
        audioPlayer = nil
        alarmTimer?.invalidate()
        alarmTimer = nil
        isPlaying = false
        print("アラーム音を停止")
    }
    
    func playHapticFeedback() {
        hapticFeedback?.impactOccurred()
    }
    
    func playSnoozeSound() {
        AudioServicesPlaySystemSound(1003) // スヌーズ音
    }
    
    func playStopSound() {
        AudioServicesPlaySystemSound(1004) // 停止音
    }
    
    func adjustVolume(_ volume: Float) {
        currentVolume = max(0.0, min(1.0, volume))
        audioPlayer?.volume = currentVolume
    }
    
    // MARK: - Available Sounds
    
    static let availableSounds = [
        "default": "デフォルト",
        "bell": "ベル",
        "chime": "チャイム",
        "gentle": "優しい音",
        "energetic": "エネルギッシュ",
        "nature": "自然音"
    ]
    
    func getAvailableSounds() -> [(String, String)] {
        return SoundService.availableSounds.map { ($0.key, $0.value) }
    }
    
    // MARK: - Alarm Timer Methods
    
    private func startAlarmTimer() {
        alarmTimer?.invalidate()
        alarmTimer = Timer.scheduledTimer(withTimeInterval: alarmDuration, repeats: false) { [weak self] _ in
            self?.stopAlarmSound()
        }
    }
    
    private func playSystemAlarmRepeatedly() {
        print("システムアラーム音を繰り返し再生開始")
        // システム音を1秒間隔で30秒間繰り返し
        var count = 0
        let maxCount = Int(alarmDuration) // 1秒間隔
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            print("システム音再生: \(count + 1)/\(maxCount)")
            AudioServicesPlaySystemSound(1005) // アラーム音
            count += 1
            
            if count >= maxCount || !(self?.isPlaying ?? false) {
                timer.invalidate()
                print("システムアラーム音繰り返し終了")
            }
        }
    }
    
    // MARK: - Alarm Duration Settings
    
    func setAlarmDuration(_ duration: TimeInterval) {
        alarmDuration = duration
    }
    
    func getAlarmDuration() -> TimeInterval {
        return alarmDuration
    }
    
    // MARK: - Simple Test Methods
    
    func playSimpleTestSound() {
        stopAlarmSound()
        
        // シンプルなシステム音を1回だけ再生
        AudioServicesPlaySystemSound(1005)
        print("テスト音を再生しました")
    }
    
    func playTestAlarm() {
        stopAlarmSound()
        setupAudioSession()
        
        // 3秒間のテストアラーム
        let testDuration: TimeInterval = 3.0
        var count = 0
        let maxCount = Int(testDuration)
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            AudioServicesPlaySystemSound(1005)
            count += 1
            print("テストアラーム: \(count)/\(maxCount)")
            
            if count >= maxCount {
                timer.invalidate()
                print("テストアラーム終了")
            }
        }
    }
}

// MARK: - Audio Services

import AudioToolbox

extension SoundService {
    func playSystemSound(_ soundID: SystemSoundID) {
        AudioServicesPlaySystemSound(soundID)
    }
}
