import Foundation

extension UInt8 {
    func toHexString() -> String {
        return "0x" + String(format: "%02X", self)
    }
}

extension String {
    func asHexStringToData () -> Data {
        let length = self.count
        precondition(length % 2 == 0)
        
        let anchors = (0..<(length / 2)).map {
            self.index(self.startIndex, offsetBy: $0 * 2)
        }
        
        let bytes = anchors.map { a1 in
            let a2 = self.index(a1, offsetBy: 1)
            let chars = self[a1...a2]
            
            return UInt8(chars, radix: 16)!
        }
        
        return Data(bytes)
    }
}
