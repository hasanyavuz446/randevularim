import SwiftUI

// MARK: - Theme Config

struct ThemeConfig {
    let id: String
    let name: String
    let primaryHex: String
    let accentHex: String
    let bgHex: String
    let surfaceHex: String
    let secondarySurfaceHex: String

    var primary: Color { Color(hex: primaryHex) }
    var accent: Color { Color(hex: accentHex) }
    var background: Color { Color(hex: bgHex) }
    var surface: Color { Color(hex: surfaceHex) }
    var secondarySurface: Color { Color(hex: secondarySurfaceHex) }

    static let all: [ThemeConfig] = [
        nightBlue, forest, rose, lavender, ocean, sunset, anthracite, cream
    ]

    static func from(_ id: String) -> ThemeConfig {
        all.first { $0.id == id } ?? nightBlue
    }

    static let nightBlue = ThemeConfig(
        id: "night_blue", name: "Gece Mavisi",
        primaryHex: "#496ED9", accentHex: "#C9A84C",
        bgHex: "#0D0D1A", surfaceHex: "#1A1A2E", secondarySurfaceHex: "#23233A"
    )
    static let forest = ThemeConfig(
        id: "forest", name: "Orman Yeşili",
        primaryHex: "#2D6A4F", accentHex: "#52B788",
        bgHex: "#0B1A12", surfaceHex: "#1A2E22", secondarySurfaceHex: "#243D2D"
    )
    static let rose = ThemeConfig(
        id: "rose", name: "Gül",
        primaryHex: "#9D0208", accentHex: "#E85D04",
        bgHex: "#1A0203", surfaceHex: "#2E0A0B", secondarySurfaceHex: "#3E1112"
    )
    static let lavender = ThemeConfig(
        id: "lavender", name: "Lavanta",
        primaryHex: "#5E548E", accentHex: "#BE95C4",
        bgHex: "#16111F", surfaceHex: "#26203A", secondarySurfaceHex: "#332D47"
    )
    static let ocean = ThemeConfig(
        id: "ocean", name: "Okyanus",
        primaryHex: "#0077B6", accentHex: "#00B4D8",
        bgHex: "#001A2E", surfaceHex: "#002D4E", secondarySurfaceHex: "#003D66"
    )
    static let sunset = ThemeConfig(
        id: "sunset", name: "Güneş Batımı",
        primaryHex: "#D62828", accentHex: "#F77F00",
        bgHex: "#1F0A00", surfaceHex: "#331200", secondarySurfaceHex: "#421800"
    )
    static let anthracite = ThemeConfig(
        id: "anthracite", name: "Antrasit",
        primaryHex: "#5A6080", accentHex: "#8D99AE",
        bgHex: "#0D0E12", surfaceHex: "#1A1C24", secondarySurfaceHex: "#232630"
    )
    static let cream = ThemeConfig(
        id: "cream", name: "Krem",
        primaryHex: "#6B4226", accentHex: "#D4A373",
        bgHex: "#1A0C03", surfaceHex: "#2E1A0A", secondarySurfaceHex: "#3D2210"
    )
}

// MARK: - AppTheme

enum AppTheme {
    static var primary = Color(hex: "#496ED9")
    static var accent = Color(hex: "#C9A84C")
    static var background = Color(hex: "#0D0D1A")
    static var surface = Color(hex: "#1A1A2E")
    static var secondarySurface = Color(hex: "#23233A")
    static var textSecondary = Color.white.opacity(0.68)
    static var divider = Color.white.opacity(0.10)
    static let success = Color(hex: "#34C759")
    static let danger = Color(hex: "#FF3B30")
    static let warning = Color(hex: "#FF9500")

    static func apply(id: String, colorSchemePref: String = "dark") {
        let config = ThemeConfig.from(id)
        primary = config.primary
        accent = config.accent
        if colorSchemePref == "light" {
            background = Color(hex: "#F2F2F7")
            surface = Color.white
            secondarySurface = Color(hex: "#E5E5EA")
            textSecondary = Color.black.opacity(0.5)
            divider = Color.black.opacity(0.08)
        } else {
            background = config.background
            surface = config.surface
            secondarySurface = config.secondarySurface
            textSecondary = Color.white.opacity(0.68)
            divider = Color.white.opacity(0.10)
        }
    }
}

// MARK: - Color helpers

extension Color {
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)
        let r, g, b: UInt64
        switch sanitized.count {
        case 6:
            r = (value >> 16) & 0xFF
            g = (value >> 8) & 0xFF
            b = value & 0xFF
        default:
            r = 0x49; g = 0x6E; b = 0xD9
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: 1)
    }
}

// MARK: - RandevularimScreen

struct RandevularimScreen<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                content
            }
            .navigationTitle(title)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - MetricTile

struct MetricTile: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
