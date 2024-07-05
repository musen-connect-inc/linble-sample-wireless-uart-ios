import Foundation

enum OperationStep {
    case initializing
    case scanning
    case connecting
    case connected
    
    func toString() -> String {
        return switch self {
        case .initializing:
            "初期化中"
        case .scanning:
            "スキャン中"
        case .connecting:
            "接続中"
        case .connected:
            "通信可能"
        }
    }
}
