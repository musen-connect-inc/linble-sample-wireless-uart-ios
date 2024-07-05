import Foundation

class UartCommandConnectionTest: UartCommand {
    override var length: UInt8 { return 1 }
    override var type: UInt8 { return 0x00 }

    override func createPayload() -> Data? {
        return nil
    }
}


class UartResponseConnectionTest: UartResponse {
    static let length: UInt8 = 1
    static let type: UInt8 = 0x40

    override init(rxPayload: Data) {
        super.init(rxPayload: rxPayload)
    }
}
