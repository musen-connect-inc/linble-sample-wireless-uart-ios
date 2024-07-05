import Foundation

enum BluetoothConnectionError: Error {
    case DeviceBluetoothStateErrorException
    case DisconnectedAfterOnlineException
    case UnsupportedDeviceConnectedException
}


enum FailureGattOperationException: Error, LocalizedError {
    case request(String)
    case response(String)
    case timeout(String)
    
    var errorDescription: String? {
        return switch self {
        case .request(let methodName):
            "failed \(methodName) request"
        case .response(let methodName):
            "failed \(methodName) response"
        case .timeout(let methodName):
            "failed \(methodName) timeout"
        }
    }
}
