import AVFoundation
import Foundation

@MainActor
final class ButtonClickPlayer {
    static let shared = ButtonClickPlayer()

    private var player: AVAudioPlayer?

    private init() {
        preparePlayer()
    }

    func play() {
        if player == nil {
            preparePlayer()
        }
        player?.currentTime = 0
        player?.play()
    }

    private func preparePlayer() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(data: Self.clickWAVData())
            player.volume = 0.42
            player.prepareToPlay()
            self.player = player
        } catch {
            #if DEBUG
            print("Unable to prepare button click sound: \(error)")
            #endif
        }
    }

    private static func clickWAVData() -> Data {
        let sampleRate = 44_100
        let duration = 0.045
        let sampleCount = Int(Double(sampleRate) * duration)
        var samples = Data()
        samples.reserveCapacity(sampleCount * 2)

        for index in 0..<sampleCount {
            let progress = Double(index) / Double(sampleCount)
            let envelope = pow(1.0 - progress, 4.2)
            let primary = sin(2.0 * .pi * 1_650.0 * Double(index) / Double(sampleRate))
            let snap = sin(2.0 * .pi * 3_400.0 * Double(index) / Double(sampleRate)) * 0.28
            let value = max(-1.0, min(1.0, (primary + snap) * envelope * 0.72))
            var intSample = Int16(value * Double(Int16.max)).littleEndian
            samples.append(Data(bytes: &intSample, count: MemoryLayout<Int16>.size))
        }

        return wavData(fromPCM: samples, sampleRate: sampleRate)
    }

    private static func wavData(fromPCM samples: Data, sampleRate: Int) -> Data {
        var data = Data()
        data.append("RIFF".data(using: .ascii)!)
        data.append(UInt32(36 + samples.count).littleEndianData)
        data.append("WAVE".data(using: .ascii)!)
        data.append("fmt ".data(using: .ascii)!)
        data.append(UInt32(16).littleEndianData)
        data.append(UInt16(1).littleEndianData)
        data.append(UInt16(1).littleEndianData)
        data.append(UInt32(sampleRate).littleEndianData)
        data.append(UInt32(sampleRate * 2).littleEndianData)
        data.append(UInt16(2).littleEndianData)
        data.append(UInt16(16).littleEndianData)
        data.append("data".data(using: .ascii)!)
        data.append(UInt32(samples.count).littleEndianData)
        data.append(samples)
        return data
    }
}

private extension FixedWidthInteger {
    var littleEndianData: Data {
        var value = littleEndian
        return Data(bytes: &value, count: MemoryLayout<Self>.size)
    }
}
