import Foundation

/** レジスタ値アクセス.取得.コマンド */
class UartCommandRegisterRead: UartCommand {
    let registerNumber: RegisterNumber
    
    init(registerNumber: RegisterNumber) {
        self.registerNumber = registerNumber
    }
    
    override var length: UInt8 { return 2 }
    override var type: UInt8 { return 0x01 }
    
    override func createPayload() -> Data? {
        return Data([UInt8(registerNumber.value)])
    }
    
    override func toString() -> String {
        "<\(Swift.type(of: self)): registerNumber=\(registerNumber)>"
    }
}

/** レジスタ値アクセス.取得.レスポンス */
class UartResponseRegisterRead: UartResponse {
    let registerNumber: RegisterNumber
    let hexdecimal: UInt8
    
    override init(rxPayload: Data) {
        self.registerNumber = RegisterNumber(value: rxPayload[0])
        self.hexdecimal = rxPayload[1]
        super.init(rxPayload: rxPayload)
    }
    
    static let length: UInt8 = 3
    static let type: UInt8 = 0x41
    
    override func toString() -> String {
        "<\(Swift.type(of: self)): registerNumber=\(registerNumber), hexdecimal=0x\(String(format: "%02X", hexdecimal as CVarArg))>"
    }
}


/** レジスタ値アクセス.設定.コマンド */
class UartCommandRegisterWrite: UartCommand {
    let registerNumber: RegisterNumber
    let hexdecimal: UInt8
    
    init(registerNumber: RegisterNumber, hexdecimal: UInt8) {
        self.registerNumber = registerNumber
        self.hexdecimal = hexdecimal
        super.init()
    }
    
    override var length: UInt8 { return 3 }
    override var type: UInt8 { return 0x02 }
    
    override func createPayload() -> Data? {
        return Data([registerNumber.value, hexdecimal])
    }
    
    override func toString() -> String {
        return "<\(Swift.type(of: self)): registerNumber=\(registerNumber), hexdecimal=0x\(String(format: "%02X", hexdecimal as CVarArg))>"
    }
}

/** レジスタ値アクセス.設定.レスポンス */
class UartResponseRegisterWrite: UartResponse {
    static let length: UInt8 = 1
    static let type: UInt8 = 0x42
    
    override init(rxPayload: Data) {
        super.init(rxPayload: rxPayload)
    }
}
