import Foundation

/** デバイス名.取得.コマンド */
class UartCommandDeviceNameRead: UartCommand {
    override var length: UInt8 { return 1 }
    override var type: UInt8 { return 0x05}
    
    override func createPayload() -> Data? {
        return nil
    }
}

/** デバイス名.取得.レスポンス */
class UartResponseDeviceNameRead: UartResponse {
    let name: AsciiString

    override init(rxPayload: Data) {
        self.name = AsciiString(data: rxPayload)
        super.init(rxPayload: rxPayload)
    }
    
    static let type: UInt8 = 0x45
    
    override func toString() -> String {
        return "<\(Swift.type(of: self)): name=\(name)>"
    }
}


/** デバイス名.設定.コマンド */
class UartCommandDeviceNameWrite: UartCommand {
    let name: AsciiString
    
    init(name: AsciiString) {
        self.name = name
    }
    
    override var length: UInt8 { return UInt8(1 + name.value.count) }
    override var type: UInt8 { return 0x06}
    
    override func createPayload() -> Data? {
        return name.toData()
    }
}

/** デバイス名.設定.レスポンス */
class UartResponseDeviceNameWrite: UartResponse {
    static let length: UInt8 = 1
    static let type: UInt8 = 0x46

    override init(rxPayload: Data) {
        super.init(rxPayload: rxPayload)
    }
}
