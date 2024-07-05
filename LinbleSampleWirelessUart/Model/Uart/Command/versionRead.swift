import Foundation

/** ホストマイコンバージョン確認.コマンド */
class UartCommandVersionRead: UartCommand {
    override var length: UInt8 { return 1 }
    override var type: UInt8 { return 0x03 }
    
    override func createPayload() -> Data? {
        return nil
    }
}

/** ホストマイコンバージョン確認.レスポンス（可変長） */
class UartResponseVersionRead: UartResponse {
    let version: AsciiString
    
    override init(rxPayload: Data) {
        self.version = AsciiString(data: rxPayload)
        super.init(rxPayload: rxPayload)
    }
    
    static let type: UInt8 = 0x43
    
    override func toString() -> String {
        return "<\(Swift.type(of: self)): version=\(version)>"
    }
}
