import Foundation
import Observation

@Observable
final class VHSFilterSettings: @unchecked Sendable {
    var chromaticAberration: Double = 0.0 { didSet { version += 1 } }
    var saturation: Double = 0.42 { didSet { version += 1 } }
    var brightness: Double = -0.045 { didSet { version += 1 } }
    var contrast: Double = 1.15 { didSet { version += 1 } }
    var warmth: Double = 5620 { didSet { version += 1 } }
    var softness: Double = 1.1 { didSet { version += 1 } }
    var scanlineOpacity: Double = 0.17 { didSet { version += 1 } }
    var noiseLines: Double = 0.85 { didSet { version += 1 } }
    var displacement: Double = 6.6 { didSet { version += 1 } }
    var grain: Double = 0.4 { didSet { version += 1 } }
    var vignette: Double = 1.0 { didSet { version += 1 } }
    var bloom: Double = 0.03 { didSet { version += 1 } }
    var sharpness: Double = 1.6 { didSet { version += 1 } }

    private(set) var version: Int = 0

    private static let storageKey = "VHSFilterSettings"

    func resetToDefaults() {
        chromaticAberration = 0.0
        saturation = 0.42
        brightness = -0.045
        contrast = 1.15
        warmth = 5620
        softness = 1.1
        scanlineOpacity = 0.17
        noiseLines = 0.85
        displacement = 6.6
        grain = 0.4
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
            "vignette": vignette,
            "bloom": bloom,
            "sharpness": sharpness
        ]
        UserDefaults.standard.set(dict, forKey: Self.storageKey)
    }

    func load() {
        guard let dict = UserDefaults.standard.dictionary(forKey: Self.storageKey) as? [String: Double] else { return }
        if let v = dict["chromaticAberration"] { chromaticAberration = v }
        if let v = dict["saturation"] { saturation = v }
        if let v = dict["brightness"] { brightness = v }
        if let v = dict["contrast"] { contrast = v }
        if let v = dict["warmth"] { warmth = v }
        if let v = dict["softness"] { softness = v }
        if let v = dict["scanlineOpacity"] { scanlineOpacity = v }
        if let v = dict["noiseLines"] { noiseLines = v }
        if let v = dict["displacement"] { displacement = v }
        if let v = dict["grain"] { grain = v }
        if let v = dict["vignette"] { vignette = v }
        if let v = dict["bloom"] { bloom = v }
        if let v = dict["sharpness"] { sharpness = v }
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
        let vignette: Double
        let bloom: Double
        let sharpness: Double
    }
}
