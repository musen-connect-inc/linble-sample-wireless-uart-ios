import Foundation

/**
 * コマンド
 *
 * 端末からのデータ送信時に利用
 */

protocol UartCommandProtocol {
    var length: UInt8 { get }
    var type: UInt8 { get }
    func createPayload() -> Data?
}

class UartCommand: UartCommandProtocol {
    var length: UInt8 { fatalError("Subclasses must override length.") }
    var type: UInt8 { fatalError("Subclasses must override type.") }

    func createPayload() -> Data? { fatalError("Subclasses must override createPayload().") }

    func toData() -> Data {
        var data = Data([length, type])
        if let payload = createPayload() {
            data.append(payload)
        }
        return data
    }

    func toString() -> String {
        return "<\(Swift.type(of: self))>"
    }
}

/**
 * 受信パケット.
 *
 * LINBLEからのデータ受信時に利用
 */


class UartRxPacket: Equatable {
    private let id = UUID()
    let rxPayload: Data

    init(rxPayload: Data) {
        self.rxPayload = rxPayload
    }
    
    func toString() -> String {
        return "<\(Swift.type(of: self))>"
    }
    
    static func == (lhs: UartRxPacket, rhs: UartRxPacket) -> Bool {
        return lhs.id == rhs.id
    }
}


/** レスポンス */

class UartResponse: UartRxPacket {
    override init(rxPayload: Data) {
        super.init(rxPayload: rxPayload)
    }
}

class UartEvent: UartRxPacket {
    override init(rxPayload: Data) {
        super.init(rxPayload: rxPayload)
    }
}
