import Foundation

enum SamplingState: UInt8 {
    case stopped = 0
    case sampling = 1

    func toByte() -> UInt8 {
        return self.rawValue
    }

    static func from(value: UInt8) -> SamplingState? {
        return SamplingState(rawValue: value)
    }
}
