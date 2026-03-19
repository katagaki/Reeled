import AVFoundation
import Accelerate

/// Generates synthetic VHS tape hum and noise as a PCM audio file.
struct VHSAudioGenerator {

    static let sampleRate: Double = 44100

    /// Generates a VHS tape hum + noise audio file of the given duration.
    /// Returns the URL of the generated `.m4a` file.
    static func generate(duration: Double) throws -> URL {
        let sampleCount = Int(duration * sampleRate)
        guard sampleCount > 0 else {
            throw GeneratorError.invalidDuration
        }

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleCount)) else {
            throw GeneratorError.bufferAllocationFailed
        }
        buffer.frameLength = AVAudioFrameCount(sampleCount)

        guard let samples = buffer.floatChannelData?[0] else {
            throw GeneratorError.bufferAllocationFailed
        }

        vDSP_vclr(samples, 1, vDSP_Length(sampleCount))
        addTapeHum(to: samples, sampleCount: sampleCount)
        applyWow(to: samples, sampleCount: sampleCount)
        addTapeHiss(to: samples, sampleCount: sampleCount)
        addCracklePops(to: samples, sampleCount: sampleCount, duration: duration)
        applyFades(to: samples, sampleCount: sampleCount)

        let url = try writeAudioFile(buffer: buffer)

        #if DEBUG
        debugPrint("[VHSAudio] Generated \(String(format: "%.2f", duration))s tape hum → \(url.lastPathComponent)")
        #endif
        return url
    }

    // MARK: - Signal Components

    private static func addTapeHum(to samples: UnsafeMutablePointer<Float>, sampleCount: Int) {
        let humFrequencies: [(freq: Double, amp: Float)] = [
            (60.0, 0.10),
            (120.0, 0.08),
            (180.0, 0.05),
            (240.0, 0.02)
        ]
        for (freq, amp) in humFrequencies {
            let phaseIncrement = Float(2.0 * Double.pi * freq / sampleRate)
            for sample in 0..<sampleCount {
                samples[sample] += amp * sinf(phaseIncrement * Float(sample))
            }
        }
    }

    private static func applyWow(to samples: UnsafeMutablePointer<Float>, sampleCount: Int) {
        let wowFreq: Float = 0.5
        let wowDepth: Float = 0.015
        let wowPhaseInc = Float(2.0 * Double.pi * Double(wowFreq) / sampleRate)
        for sample in 0..<sampleCount {
            let wow = 1.0 + wowDepth * sinf(wowPhaseInc * Float(sample))
            samples[sample] *= wow
        }
    }

    private static func addTapeHiss(to samples: UnsafeMutablePointer<Float>, sampleCount: Int) {
        var noiseBuffer = [Float](repeating: 0, count: sampleCount)
        for sample in 0..<sampleCount {
            noiseBuffer[sample] = Float.random(in: -1.0...1.0)
        }

        // One-pole IIR low-pass ~8kHz
        let cutoffRC: Float = 1.0 / (2.0 * .pi * 8000.0)
        let deltaTime: Float = 1.0 / Float(sampleRate)
        let alpha = deltaTime / (cutoffRC + deltaTime)
        var filtered: Float = 0
        for sample in 0..<sampleCount {
            filtered += alpha * (noiseBuffer[sample] - filtered)
            noiseBuffer[sample] = filtered
        }

        let hissLevel: Float = 0.005
        for sample in 0..<sampleCount {
            samples[sample] += noiseBuffer[sample] * hissLevel
        }
    }

    private static func addCracklePops(to samples: UnsafeMutablePointer<Float>, sampleCount: Int, duration: Double) {
        let popsPerSecond = 6.0
        let expectedPops = Int(popsPerSecond * duration)
        for _ in 0..<expectedPops {
            let position = Int.random(in: 0..<sampleCount)
            let popAmplitude = Float.random(in: 0.02...0.06)
            let sign: Float = Bool.random() ? 1.0 : -1.0
            samples[position] += sign * popAmplitude
            let tailLength = min(Int.random(in: 20...80), sampleCount - position)
            for tail in 1..<tailLength {
                let decay = Float(tailLength - tail) / Float(tailLength)
                samples[position + tail] += sign * popAmplitude * decay * 0.3
            }
        }
    }

    private static func applyFades(to samples: UnsafeMutablePointer<Float>, sampleCount: Int) {
        let fadeFrames = min(Int(0.05 * sampleRate), sampleCount / 2)
        for sample in 0..<fadeFrames {
            let ramp = Float(sample) / Float(fadeFrames)
            samples[sample] *= ramp
            samples[sampleCount - 1 - sample] *= ramp
        }
    }

    // MARK: - File Writing

    private static func writeAudioFile(buffer: AVAudioPCMBuffer) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 128000
        ]

        let file = try AVAudioFile(
            forWriting: url,
            settings: outputSettings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        try file.write(from: buffer)
        return url
    }

    enum GeneratorError: LocalizedError {
        case invalidDuration
        case bufferAllocationFailed

        var errorDescription: String? {
            switch self {
            case .invalidDuration: "Invalid audio duration."
            case .bufferAllocationFailed: "Failed to allocate audio buffer."
            }
        }
    }
}
