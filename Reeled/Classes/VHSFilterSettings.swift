import Foundation
import Observation

@Observable
final class VHSFilterSettings: @unchecked Sendable {
    var chromaticAberration: Double = 0.0 { didSet { version += 1 } }
    var saturation: Double = 0.68 { didSet { version += 1 } }
    var brightness: Double = -0.045 { didSet { version += 1 } }
    var contrast: Double = 1.15 { didSet { version += 1 } }
    var warmth: Double = 5620 { didSet { version += 1 } }
    var softness: Double = 1.1 { didSet { version += 1 } }
    var scanlineOpacity: Double = 0.17 { didSet { version += 1 } }
    var noiseLines: Double = 0.85 { didSet { version += 1 } }
    var displacement: Double = 1.6 { didSet { version += 1 } }
    var grain: Double = 0.1 { didSet { version += 1 } }
    var microDistortion: Double = 0.6 { didSet { version += 1 } }
    var vignette: Double = 1.0 { didSet { version += 1 } }
    var bloom: Double = 0.03 { didSet { version += 1 } }
    var sharpness: Double = 1.6 { didSet { version += 1 } }

    private(set) var version: Int = 0

    private static let storageKey = "VHSFilterSettings"

    func resetToDefaults() {
        chromaticAberration = 0.0
        saturation = 0.68
        brightness = -0.045
        contrast = 1.15
        warmth = 5620
        softness = 1.1
        scanlineOpacity = 0.05
        noiseLines = 0.85
        displacement = 1.6
        grain = 0.1
        microDistortion = 0.6
        vignette = 1.0
        bloom = 0.03
        sharpness = 1.6
    }

    func save() {
        let dict: [String: Double] = [
            "chromaticAberration": chromaticAberration,
            "saturation": saturation,
            "brightness": brightness,
            "contrast": contrast,
            "warmth": warmth,
            "softness": softness,
            "scanlineOpacity": scanlineOpacity,
            "noiseLines": noiseLines,
            "displacement": displacement,
            "grain": grain,
            "microDistortion": microDistortion,
            "vignette": vignette,
            "bloom": bloom,
            "sharpness": sharpness
        ]
        UserDefaults.standard.set(dict, forKey: Self.storageKey)
    }

    func load() {
        guard let dict = UserDefaults.standard.dictionary(forKey: Self.storageKey) as? [String: Double] else { return }
        if let val = dict["chromaticAberration"] { chromaticAberration = val }
        if let val = dict["saturation"] { saturation = val }
        if let val = dict["brightness"] { brightness = val }
        if let val = dict["contrast"] { contrast = val }
        if let val = dict["warmth"] { warmth = val }
        if let val = dict["softness"] { softness = val }
        if let val = dict["scanlineOpacity"] { scanlineOpacity = val }
        if let val = dict["noiseLines"] { noiseLines = val }
        if let val = dict["displacement"] { displacement = val }
        if let val = dict["grain"] { grain = val }
        if let val = dict["microDistortion"] { microDistortion = val }
        if let val = dict["vignette"] { vignette = val }
        if let val = dict["bloom"] { bloom = val }
        if let val = dict["sharpness"] { sharpness = val }
    }

    func snapshot() -> Snapshot {
        Snapshot(
            chromaticAberration: chromaticAberration,
            saturation: saturation,
            brightness: brightness,
            contrast: contrast,
            warmth: warmth,
            softness: softness,
            scanlineOpacity: scanlineOpacity,
            noiseLines: noiseLines,
            displacement: displacement,
            grain: grain,
            microDistortion: microDistortion,
            vignette: vignette,
            bloom: bloom,
            sharpness: sharpness
        )
    }

    struct Snapshot: Sendable {
        let chromaticAberration: Double
        let saturation: Double
        let brightness: Double
        let contrast: Double
        let warmth: Double
        let softness: Double
        let scanlineOpacity: Double
        let noiseLines: Double
        let displacement: Double
        let grain: Double
        let microDistortion: Double
        let vignette: Double
        let bloom: Double
        let sharpness: Double
    }
}
