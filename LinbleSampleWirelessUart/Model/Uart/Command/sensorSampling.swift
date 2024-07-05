import Foundation

/** センササンプリング実行要求.コマンド */
class UartCommandSensorSampling: UartCommand {
    let duration: DurationIntervalSeconds
    
    init(duration: DurationIntervalSeconds) {
        self.duration = duration
    }
    
    override var length: UInt8 { return 2 }
    override var type: UInt8 { return 0x04 }
    
    override func createPayload() -> Data? {
        return Data([duration.value])
    }
    
    override func toString() -> String {
        return "<\(Swift.type(of: self)): duration=\(duration)>"
    }
}

/** センササンプリング実行要求.レスポンス */
class UartResponseSensorSampling: UartResponse {
    static let length: UInt8 = 1
    static let type: UInt8 = 0x44

    override init(rxPayload: Data) {
        super.init(rxPayload: rxPayload)
    }
}


/** センササンプリング実行要求.イベント（可変長） */
class UartEventSensorSampling: UartEvent {
    let state: SamplingState
    var value: Float?
    
    override init(rxPayload: Data) {
        guard let stateByte = rxPayload.first else {
            fatalError("Empty payload for UartEventSensorSampling")
        }
        self.state = SamplingState.from(value: stateByte)!

        self.value = if state == .sampling {
            Float(bitPattern: UInt32(rxPayload.subdata(in: 1..<4 + 1).asCLanguageUnsignedLong))
        } else {
            nil
        }
        
        super.init(rxPayload: rxPayload)
    }
    
    static let type: UInt8 = 0x84
    
    override func toString() -> String {
        return "<\(Swift.type(of: self)): state=\(state), value=\(String(describing: value))>"
    }
}
