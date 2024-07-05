import Foundation

struct RegisterNumber {
    let value: UInt8
    
    init(value: UInt8) {
        precondition(0 <= value && value <= 7, "Value must be in the range of 0 to 7.")
        self.value = value
    }
}
