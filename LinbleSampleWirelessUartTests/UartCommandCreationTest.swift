import XCTest
@testable import LinbleSampleWirelessUart

final class UartCommandCreationTest: XCTestCase {
    func testUartCommandConnectionTest() {
        XCTAssertEqual(Data([0x01, 0x00]), UartCommandConnectionTest().toData())
    }
    
    func testUartCommandRegisterRead(){
        XCTAssertEqual(Data([0x02, 0x01, 0x02]), UartCommandRegisterRead(registerNumber: RegisterNumber(value: 2)).toData())
    }
    
    func testUartCommandRegisterWrite(){
        XCTAssertEqual(Data([0x03, 0x02, 0x04, 0x0F]), UartCommandRegisterWrite(registerNumber: RegisterNumber(value: 4), hexdecimal: 0x0F).toData())
    }
    
    func testUartCommandVersionRead(){
        XCTAssertEqual(Data([0x01, 0x03]), UartCommandVersionRead().toData())
    }
    
    func testUartCommandSensorSampling(){
        XCTAssertEqual(Data([0x02, 0x04, 0x05]), UartCommandSensorSampling(duration: DurationIntervalSeconds(value: 5)).toData())
    }
    
    func testUartCommandDeviceNameRead(){
        XCTAssertEqual(Data([0x01, 0x05]), UartCommandDeviceNameRead().toData())
    }
    
    func testUartCommandDeviceNameWrite(){
        XCTAssertEqual("0x1A0653616D706C652D55617274436F6E74726F6C6C65722D303031", UartCommandDeviceNameWrite(name: AsciiString(value: "Sample-UartController-001")).toData().toHexString())
    }
}
