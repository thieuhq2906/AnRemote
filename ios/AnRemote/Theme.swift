import SwiftUI
import UIKit

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Color {
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

/// Bảng màu: xanh dương, mực, xám, hổ phách cho cảnh báo. Không dùng tông đỏ.
enum Theme {
    static let brand = Color.dynamic(light: 0x1768AE, dark: 0x4C9FE0)
    static let onBrand = Color.dynamic(light: 0xFFFFFF, dark: 0x0B1520)
    static let ink = Color.dynamic(light: 0x20344D, dark: 0xE6EDF5)
    static let onInk = Color.dynamic(light: 0xFFFFFF, dark: 0x0F1722)
    static let muted = Color.dynamic(light: 0x64748B, dark: 0x94A3B8)
    static let background = Color.dynamic(light: 0xF4F7FB, dark: 0x0F1722)
    static let card = Color.dynamic(light: 0xFFFFFF, dark: 0x1A2533)
    static let border = Color.dynamic(light: 0xDFE7EF, dark: 0x2A3A4D)
    static let warnBackground = Color.dynamic(light: 0xFFF4E5, dark: 0x3A2E14)
    static let warnText = Color.dynamic(light: 0x9A5B00, dark: 0xF2C46B)
    static let okBackground = Color.dynamic(light: 0xE6F5EC, dark: 0x163326)
    static let okText = Color.dynamic(light: 0x1F7A45, dark: 0x8FD9AE)
}

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
