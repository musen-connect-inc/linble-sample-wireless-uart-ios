import Foundation

struct DurationIntervalSeconds {
    let value: UInt8
    
    init(value: UInt8) {
        precondition(1 <= value && value <= 60)
        self.value = value
    }
}
