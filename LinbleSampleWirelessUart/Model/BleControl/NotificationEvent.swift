import Foundation

struct NotificationEvent: Equatable {
    let data: Data
    let timestamp: Double = Date().timeIntervalSince1970 * 1000
    
    static func ==(lhs: NotificationEvent, rhs: NotificationEvent) -> Bool {
        return lhs.data == rhs.data && lhs.timestamp == rhs.timestamp
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(data)
        hasher.combine(timestamp)
    }
}
