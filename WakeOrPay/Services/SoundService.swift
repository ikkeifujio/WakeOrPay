//
//  SoundService.swift
//  WakeOrPay
//
//  Created by fujio ikkei on 2025/09/14.
//

import Foundation
import AVFoundation
import UIKit

class SoundService: ObservableObject {
    static let shared = SoundService()
    
    @Published var isPlaying: Bool = false
    @Published var currentVolume: Float = 0.8
    
    private var audioPlayer: AVAudioPlayer?
    private var hapticFeedback: UIImpactFeedbackGenerator?
    
    private init() {
        setupAudioSession()
        setupHapticFeedback()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
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
        stopAlarmSound()
        
        guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: "wav") else {
            print("音声ファイルが見つかりません: \(soundName)")
            playDefaultSound(volume: volume)
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.volume = volume
            audioPlayer?.numberOfLoops = -1 // 無限ループ
            audioPlayer?.play()
            
            isPlaying = true
            currentVolume = volume
            
            print("アラーム音を再生開始: \(soundName)")
        } catch {
            print("音声再生に失敗: \(error)")
            playDefaultSound(volume: volume)
        }
    }
    
    private func playDefaultSound(volume: Float) {
        // システム音を使用
        AudioServicesPlaySystemSound(1005) // アラーム音
        isPlaying = true
        currentVolume = volume
    }
    
    func stopAlarmSound() {
        audioPlayer?.stop()
        audioPlayer = nil
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
}

// MARK: - Audio Services

import AudioToolbox

extension SoundService {
    func playSystemSound(_ soundID: SystemSoundID) {
        AudioServicesPlaySystemSound(soundID)
    }
}
