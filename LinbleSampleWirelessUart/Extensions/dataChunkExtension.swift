import Foundation

extension Data {
    func toHexString() -> String {
        return "0x" + map { String(format: "%02X", $0) }.joined()
    }
    
    func chunked(expectedSize: Int) -> [Data] {
        var index = startIndex
        var fragmentedDataList: [Data] = []
        
        while index < count {
            let endIndex = index.advanced(by: expectedSize) > count ? count : index.advanced(by: expectedSize)
            
            let chunk = self[index..<endIndex]
            fragmentedDataList.append(chunk)
            
            index = endIndex
        }
        
        return fragmentedDataList
    }
    
    var asCLanguageUnsignedLong: UInt32 {
        /*
         {0x4d, 0x8e, 0xf3, 0xc2}
         のCollection<UInt8>を
         0x4d8ef3c2
         のUInt32に変換
         */
        
        return self.enumerated().reduce(UInt32(0)) { (result, element) in
            let (index, byte) = element
            return result | (UInt32(byte) << UInt32((3 - index) * 8))
        }
    }
}
