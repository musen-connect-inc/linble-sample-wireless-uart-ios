import Foundation

class TxPacketDivider {
    let data: Data
    let size: Int
    
    private var fragmentedDataList: [Data]!
    
    init(data: Data, size: Int) {
        self.data = data
        self.size = size
        
        fragmentedDataList = data.chunked(expectedSize: size)
    }
    
    var remain: [Data] {
        return fragmentedDataList
    }
    
    var next: Data? {
        return fragmentedDataList.isEmpty ? nil : fragmentedDataList.remove(at: 0)
    }
}
