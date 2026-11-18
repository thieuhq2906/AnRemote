import Foundation

enum ACMode: String, CaseIterable, Codable, Identifiable {
    case auto, cool, dry, heat, fan

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: return "Tự động"
        case .cool: return "Làm lạnh"
        case .dry: return "Hút ẩm"
        case .heat: return "Sưởi"
        case .fan: return "Quạt"
        }
    }

    var symbol: String {
        switch self {
        case .auto: return "a.circle"
        case .cool: return "snowflake"
        case .dry: return "drop"
        case .heat: return "sun.max"
        case .fan: return "wind"
        }
    }
}

/// Toàn bộ trạng thái remote. Điều hòa Toshiba nhận đủ trạng thái trong mỗi lệnh.
struct ACState: Codable, Equatable {
    static let tempRange = 17...30
    static let fanRange = 0...5

    var power = false
    var mode: ACMode = .cool
    var temp = 25
    /// 0 = tự động, 1...5 = mức gió.
    var fan = 0
    var swing = false
    var turbo = false
    var econo = false
}
