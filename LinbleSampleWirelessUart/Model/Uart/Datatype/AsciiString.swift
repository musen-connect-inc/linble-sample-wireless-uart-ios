import Foundation

struct AsciiString {
    let value: String
    
    init(value: String) {
        guard let asciiString = String(bytes: value.utf8.filter { $0 < 128 }, encoding: .utf8) else {
            fatalError("Failed to convert String to AsciiString.")
        }
        precondition(value == asciiString)
        self.value = value
    }
    
    init(data: Data) {
        guard let string = String(bytes: data, encoding: .ascii) else {
            fatalError("Failed to initialize AsciiString from byte array.")
        }
        self.init(value: string)
    }
    
    func toData() -> Data {
        guard let data = value.data(using: .ascii) else {
            fatalError("Failed to convert AsciiString to byte array.")
        }
        return Data(data)
    }
}
