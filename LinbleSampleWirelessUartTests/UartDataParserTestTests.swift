import XCTest
import Foundation
@testable import LinbleSampleWirelessUart

final class UartDataParserTestTests: XCTestCase, UartDataParserDelegate {
    private var uartDataParser: UartDataParser!
    private var parsedPacket: UartRxPacket? = nil
    
    override func setUpWithError() throws {
        uartDataParser = UartDataParser(delegate: self)
    }
    
    func uartDataParserDelegate(_: LinbleSampleWirelessUart.UartDataParser, didParse rxPacket: LinbleSampleWirelessUart.UartRxPacket) {
        parsedPacket = rxPacket
    }
    
    func testAsHexStringToData() {
        let expect = Data([0x12, 0x34, 0x56])
        let actual = "123456".asHexStringToData()
        
        XCTAssertEqual(expect, actual)
    }
    
    func testParseUartResponseConnectionTest() {
        uartDataParser.parse(data: "0140".asHexStringToData())
        let parsedPacket = parsedPacket
        XCTAssertTrue(parsedPacket is UartResponseConnectionTest)
    }
    
    func testUartResponseRegisterRead() {
        uartDataParser.parse(data: "034102FF".asHexStringToData())
        let parsedPacket = parsedPacket
        XCTAssertTrue(parsedPacket is UartResponseRegisterRead)
        
        if let uartResponseRegisterRead = parsedPacket as? UartResponseRegisterRead {
            XCTAssertEqual(2, uartResponseRegisterRead.registerNumber.value)
            XCTAssertEqual(0xFF, uartResponseRegisterRead.hexdecimal)
        }
    }
    
    func testUartResponseRegisterWrite() {
        uartDataParser.parse(data: "0142".asHexStringToData())
        let parsedPacket = parsedPacket
        XCTAssertTrue(parsedPacket is UartResponseRegisterWrite)
    }
    
    func testUartResponseVersionRead() {
        uartDataParser.parse(data: "0D43312E322E332E393837363534".asHexStringToData())
        
        let parsedPacket = parsedPacket
        XCTAssertTrue(parsedPacket is UartResponseVersionRead)
        
        if let uartResponseVersionRead = parsedPacket as? UartResponseVersionRead {
            XCTAssertEqual("1.2.3.987654", uartResponseVersionRead.version.value)
        }
    }
    
    func testUartResponseSensorSampling() {
        uartDataParser.parse(data: "0144".asHexStringToData())
        let parsedPacket = parsedPacket
        XCTAssertTrue(parsedPacket is UartResponseSensorSampling)
    }
    
    func testUartEventSensorSampling() {
        //        ```
        //        <length>84<state>[<value>]
        //        ```
        //
        //        |パラメータ|サイズ|説明|
        //        |:---|:---:|:---|
        //        |`<state>`|1|サンプリング継続状態。`1`または`0`。`1`の場合、後続に`<value>`が出現する。|
        //        |`<value>`|4|取得したセンサ値のIEEE754単精度(float)表現の値。例：`42009062` (`32.141`)|
        //
        //        **例:**
        //
        //        ```
        //        Tx | 020405
        //        Rx | 0144
        //        Rx | 06840142F7D2F1 // 123.91199493408203125
        //        Rx | 06840142F85062 // 124.1569976806640625
        //        Rx | 06840142F82C8B // 124.08699798583984375
        //        Rx | 06840142F7FBE7 // 123.99199676513671875
        //        Rx | 06840142F7C51E // 123.8849945068359375
        //        Rx | 028400
        //        ```
        
        do {
            uartDataParser.parse(data: "06840142F7D2F1".asHexStringToData())
            
            let parsedPacket = parsedPacket
            XCTAssertTrue(parsedPacket is UartEventSensorSampling)
            
            if let uartEventSensorSampling = parsedPacket as? UartEventSensorSampling {
                XCTAssertEqual(SamplingState.sampling, uartEventSensorSampling.state)
                XCTAssertEqual(123.91199493408203125, Double(uartEventSensorSampling.value!), accuracy: 0.000001)
            }
        }
        
        do {
            uartDataParser.parse(data: "028400".asHexStringToData())
            
            let parsedPacket = parsedPacket
            XCTAssertTrue(parsedPacket is UartEventSensorSampling)
            
            if let uartEventSensorSampling = parsedPacket as? UartEventSensorSampling {
                XCTAssertEqual(SamplingState.stopped, uartEventSensorSampling.state)
                XCTAssertNil(uartEventSensorSampling.value)
            }
        }
    }
    
    func testUartResponseDeviceNameRead() {
        uartDataParser.parse(data: "1A4553616D706C652D55617274436f6E74726F6C6C65722D303031".asHexStringToData())
        
        let parsedPacket = parsedPacket
        XCTAssertTrue(parsedPacket is UartResponseDeviceNameRead)
        
        if let uartResponseDeviceNameRead = parsedPacket as? UartResponseDeviceNameRead {
            XCTAssertEqual("Sample-UartController-001", uartResponseDeviceNameRead.name.value)
        }
    }
    
    func testUartResponseDeviceNameWrite() {
        uartDataParser.parse(data: "0146".asHexStringToData())
        let parsedPacket = parsedPacket
        XCTAssertTrue(parsedPacket is UartResponseDeviceNameWrite)
    }
    
    func testParseNoData() {
        uartDataParser.parse(data: ("".asHexStringToData()))
        
        XCTAssertNil(parsedPacket)
    }
    
    func testParseTooLongLength() {
        uartDataParser.parse(data: ("ff".asHexStringToData()))
        
        XCTAssertNil(parsedPacket)
    }
    
    func testParseUnknownRxType() {
        uartDataParser.parse(data: "01ff".asHexStringToData())
        
        XCTAssertNil(parsedPacket)
    }
    
    func testParseDestructuring () throws {
        uartDataParser.parse(data: "1A4553616D706C652D55617274".asHexStringToData())
        uartDataParser.parse(data: "436f6E74726F".asHexStringToData())
        uartDataParser.parse(data: "6C6C65722D3030".asHexStringToData())
        uartDataParser.parse(data: "31".asHexStringToData())
        
        let parsedPacket = parsedPacket
        
        let unwrapped = try XCTUnwrap(parsedPacket)
        
        XCTAssertTrue(unwrapped is UartResponseDeviceNameRead)
        
        if let uartResponseDeviceNameRead = unwrapped as? UartResponseDeviceNameRead {
            XCTAssertEqual("Sample-UartController-001", uartResponseDeviceNameRead.name.value)
        }
    }
}
