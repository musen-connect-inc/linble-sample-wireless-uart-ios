import Foundation
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: #file)

protocol UartDataParserDelegate: AnyObject {
    func uartDataParserDelegate(_: UartDataParser, didParse rxPacket: UartRxPacket)
}

class RxPacketFactory {
    static func create(rxType: UInt8, rxPayload: Data) -> UartRxPacket? {
        return switch rxType {
        case UartResponseConnectionTest.type:
            UartResponseConnectionTest(rxPayload: rxPayload)
        case UartResponseRegisterWrite.type:
            UartResponseRegisterWrite(rxPayload: rxPayload)
        case UartResponseRegisterRead.type:
            UartResponseRegisterRead(rxPayload: rxPayload)
        case UartResponseVersionRead.type:
            UartResponseVersionRead(rxPayload: rxPayload)
        case UartResponseSensorSampling.type:
            UartResponseSensorSampling(rxPayload: rxPayload)
        case UartResponseDeviceNameRead.type:
            UartResponseDeviceNameRead(rxPayload: rxPayload)
        case UartResponseDeviceNameWrite.type:
            UartResponseDeviceNameWrite(rxPayload: rxPayload)
        case UartEventSensorSampling.type:
            UartEventSensorSampling(rxPayload: rxPayload)
        default:
            nil
        }
    }
}

class UartDataParser {
    private let delegate: UartDataParserDelegate
    
    init(delegate: UartDataParserDelegate) {
        self.delegate = delegate
    }
    
    private var rxDataBuffer: Data = Data()
    
    func clear() {
        rxDataBuffer.removeAll()
    }
    
    func parse(data: Data) {
        logger.info("\(#function) parse: data=<count=\(data.count), hex=\(data.toHexString())>")
        
        // rxDataBufferの末尾に新規受信データを追加する
        rxDataBuffer += data
        logger.info("\(#function) rxDataBuffer=<count=\(self.rxDataBuffer.count), hex=\(self.rxDataBuffer.toHexString())>")
        
        while !rxDataBuffer.isEmpty {
            // rxDataBufferのindex=0から1個のデータを参照し、lengthとする
            let length = rxDataBuffer[0]
            logger.info("\(#function) length=\(length)")
            
            // rxDataBufferのindex=1からlength個のデータを参照し、followingとする
            if (rxDataBuffer.count - 1) < length {
                return
            }
            
            let following = Data(rxDataBuffer[1...Int(length)])
            logger.info("\(#function) following=<count=\(following.count), hex=\(following.toHexString())>")
            
            // rxDataBufferからlengthとfollowing部分のデータを削除する
            rxDataBuffer = Data(rxDataBuffer.advanced(by: Int(length) + 1))
            
            // followingのindex=0から1個のデータを取り出し、rxTypeとする
            guard let rxType = following.first else {
                return
            }
            logger.info("\(#function) rxType=\(rxType.toHexString())")
            
            // followingのindex=1からlength-1個のデータを取り出し、rxPayloadとする
            let rxPayload = following.subdata(in: 1..<Int(length))
            logger.info("\(#function) rxPayload=<count=\(rxPayload.count), hex=\(rxPayload.toHexString())>")
            
            // rxTypeと一致するtypeを持つUartRxPacketのサブクラスを特定し、そのオブジェクトを生成する
            if let rxPacket = RxPacketFactory.create(rxType: rxType, rxPayload: rxPayload) {
                logger.info("\(#function) rxPacketClass=\(type(of: rxPacket))")
                
                // 生成オブジェクトを解析結果として上層へ通知
                delegate.uartDataParserDelegate(self, didParse: rxPacket)
            }
        }
    }
}
