import XCTest
@testable import LinbleSampleWirelessUart

final class TxPacketDividerTests: XCTestCase {
    func testTxPacketDividerChuncked() {
        do {
            let devider = TxPacketDivider(data: Data([0x01, 0x02, 0x03]), size: 3)
            XCTAssertEqual(Data([0x01, 0x02, 0x03]), devider.next )
            XCTAssertEqual(0, devider.remain.count )
        }
        
        do {
            let devider = TxPacketDivider(data: Data([0x01, 0x02, 0x03, 0x04]), size: 3)
            XCTAssertEqual(Data([0x01, 0x02, 0x03]), devider.next)
            XCTAssertEqual(1, devider.remain.count)
            XCTAssertEqual(Data([0x04]), devider.next)
            XCTAssertEqual(0, devider.remain.count)
        }
        
        do {
            let devider = TxPacketDivider(data: Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x10]), size: 3)
            XCTAssertEqual(Data([0x01, 0x02, 0x03]), devider.next)
            XCTAssertEqual(3, devider.remain.count)
            XCTAssertEqual(Data([0x04, 0x05, 0x06]), devider.next)
            XCTAssertEqual(2, devider.remain.count)
            XCTAssertEqual(Data([0x07, 0x08, 0x09]), devider.next)
            XCTAssertEqual(1, devider.remain.count)
            XCTAssertEqual(Data([0x10]), devider.next)
            XCTAssertEqual(0, devider.remain.count)
        }
    }
}
