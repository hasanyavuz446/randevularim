import SwiftUI
import Observation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - ThemeConfig

struct ThemeConfig {
    let id: String
    let name: String
    let primaryHex: String
    let accentHex: String
    let lightBgHex: String
    let darkBgHex: String
    let darkSurfaceHex: String

    var primary: Color { Color(hex: primaryHex) }
    var accent: Color { Color(hex: accentHex) }
    var lightBackground: Color { Color(hex: lightBgHex) }
    var darkBackground: Color { Color(hex: darkBgHex) }
    var darkSurface: Color { Color(hex: darkSurfaceHex) }

    static let all: [ThemeConfig] = [
        nightBlue, forest, rose, lavender, ocean, sunset, anthracite, cream
    ]

    static func from(_ id: String) -> ThemeConfig {
        all.first { $0.id == id } ?? nightBlue
    }

    static let nightBlue = ThemeConfig(
        id: "night_blue", name: "Gece Mavisi",
        primaryHex: "#496ED9", accentHex: "#C9A84C",
        lightBgHex: "#F2F2F7", darkBgHex: "#0D0D1A", darkSurfaceHex: "#1A1A2E"
    )
    static let forest = ThemeConfig(
        id: "forest", name: "Orman Yeşili",
        primaryHex: "#2D6A4F", accentHex: "#52B788",
        lightBgHex: "#F0F7F4", darkBgHex: "#0B1A12", darkSurfaceHex: "#1A2E22"
    )
    static let rose = ThemeConfig(
        id: "rose", name: "Gül",
        primaryHex: "#9D0208", accentHex: "#E85D04",
        lightBgHex: "#FFF5F5", darkBgHex: "#1A0203", darkSurfaceHex: "#2E0A0B"
    )
    static let lavender = ThemeConfig(
        id: "lavender", name: "Lavanta",
        primaryHex: "#5E548E", accentHex: "#BE95C4",
        lightBgHex: "#F4F0F8", darkBgHex: "#16111F", darkSurfaceHex: "#26203A"
    )
    static let ocean = ThemeConfig(
        id: "ocean", name: "Okyanus",
        primaryHex: "#0077B6", accentHex: "#00B4D8",
        lightBgHex: "#F0F7FF", darkBgHex: "#001A2E", darkSurfaceHex: "#002D4E"
    )
    static let sunset = ThemeConfig(
        id: "sunset", name: "Güneş Batımı",
        primaryHex: "#D62828", accentHex: "#F77F00",
        lightBgHex: "#FFF8F0", darkBgHex: "#1F0A00", darkSurfaceHex: "#331200"
    )
    static let anthracite = ThemeConfig(
        id: "anthracite", name: "Antrasit",
        primaryHex: "#2B2D42", accentHex: "#8D99AE",
        lightBgHex: "#F0F1F2", darkBgHex: "#0D0E12", darkSurfaceHex: "#1A1C24"
    )
    static let cream = ThemeConfig(
        id: "cream", name: "Krem",
        primaryHex: "#6B4226", accentHex: "#D4A373",
        lightBgHex: "#FAF3E0", darkBgHex: "#1A0C03", darkSurfaceHex: "#2E1A0A"
    )
}

// MARK: - ThemeValues (Observable)
// @Observable sayesinde bu nesnenin property'lerini okuyan her SwiftUI view,
// değişince otomatik yeniden render edilir — themeRevision gibi hiçbir hack gerekmez.

@Observable
final class ThemeValues {
    var primary: Color = Color(hex: "#496ED9")
    var accent: Color = Color(hex: "#C9A84C")
    var background: Color = Color(hex: "#0D0D1A")
    var surface: Color = Color(hex: "#1A1A2E")
    var secondarySurface: Color = Color(hex: "#23233A")
    var textPrimary: Color = .white
    var textSecondary: Color = Color.white.opacity(0.68)
    var divider: Color = Color.white.opacity(0.10)
    var isDark: Bool = true
}

// MARK: - AppTheme

enum AppTheme {
    // Tek shared instance; property erişimi @Observable tracking'i tetikler.
    static let _state = ThemeValues()

    static var primary: Color { _state.primary }
    static var accent: Color { _state.accent }
    static var background: Color { _state.background }
    static var surface: Color { _state.surface }
    static var secondarySurface: Color { _state.secondarySurface }
    static var textPrimary: Color { _state.textPrimary }
    static var textSecondary: Color { _state.textSecondary }
    static var divider: Color { _state.divider }
    static var isDark: Bool { _state.isDark }

    static let success = Color(hex: "#34C759")
    static let danger = Color(hex: "#FF3B30")
    static let warning = Color(hex: "#FF9500")

    @MainActor
    static func apply(id: String, colorSchemePref: String = "dark") {
        apply(id: id, colorSchemePref: colorSchemePref, systemColorScheme: .dark)
    }

    @MainActor
    static func apply(id: String, colorSchemePref: String, systemColorScheme: ColorScheme) {
        let config = ThemeConfig.from(id)
        let resolvedIsDark: Bool
        switch colorSchemePref {
        case "light":
            resolvedIsDark = false
        case "dark":
            resolvedIsDark = true
        default:
            resolvedIsDark = systemColorScheme == .dark
        }

        _state.isDark = resolvedIsDark
        _state.primary = config.primary
        _state.accent = config.accent
        if resolvedIsDark {
            _state.background = config.darkBackground
            _state.surface = config.darkSurface
            _state.secondarySurface = Color(hex: config.darkSurfaceHex).mix(with: .white, by: 0.08)
            _state.textPrimary = .white
            _state.textSecondary = Color.white.opacity(0.68)
            _state.divider = Color.white.opacity(0.10)
        } else {
            _state.background = config.lightBackground
            _state.surface = .white
            _state.secondarySurface = Color(hex: "#E5E5EA")
            _state.textPrimary = Color(hex: "#1C1C1E")
            _state.textSecondary = Color.black.opacity(0.5)
            _state.divider = Color.black.opacity(0.08)
        }
        #if canImport(UIKit)
        applyUIKitAppearance(colorSchemePref: colorSchemePref)
        #endif
    }

    #if canImport(UIKit)
    @MainActor
    private static func applyUIKitAppearance(colorSchemePref: String) {
        let backgroundUIColor = UIColor(_state.background)
        let surfaceUIColor = UIColor(_state.surface)
        let secondarySurfaceUIColor = UIColor(_state.secondarySurface)
        let textUIColor = UIColor(_state.textPrimary)
        let secondaryTextUIColor = UIColor(_state.textSecondary)
        let primaryUIColor = UIColor(_state.primary)
        let resolvedStyle: UIUserInterfaceStyle = {
            switch colorSchemePref {
            case "light": return .light
            case "dark": return .dark
            default: return .unspecified
            }
        }()

        UITableView.appearance().backgroundColor = backgroundUIColor
        UITableViewCell.appearance().backgroundColor = surfaceUIColor

        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithOpaqueBackground()
        navigationAppearance.backgroundColor = backgroundUIColor
        navigationAppearance.titleTextAttributes = [.foregroundColor: textUIColor]
        navigationAppearance.largeTitleTextAttributes = [.foregroundColor: textUIColor]
        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance
        UINavigationBar.appearance().tintColor = primaryUIColor

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = backgroundUIColor
        tabAppearance.stackedLayoutAppearance.selected.iconColor = primaryUIColor
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: primaryUIColor]
        tabAppearance.stackedLayoutAppearance.normal.iconColor = secondaryTextUIColor
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: secondaryTextUIColor]
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().tintColor = primaryUIColor
        UITabBar.appearance().unselectedItemTintColor = secondaryTextUIColor

        UISegmentedControl.appearance().selectedSegmentTintColor = primaryUIColor
        UISegmentedControl.appearance().backgroundColor = secondarySurfaceUIColor
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: secondaryTextUIColor], for: .normal)

        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .forEach { window in
                window.overrideUserInterfaceStyle = resolvedStyle
                window.tintColor = primaryUIColor
                window.backgroundColor = backgroundUIColor
                window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
                window.setNeedsLayout()
            }
    }
    #endif
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

    func mix(with other: Color, by amount: Double) -> Color {
        let amount = min(max(amount, 0), 1)
        #if canImport(UIKit)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        UIColor(self).getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        UIColor(other).getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(
            red: Double(r1) * (1 - amount) + Double(r2) * amount,
            green: Double(g1) * (1 - amount) + Double(g2) * amount,
            blue: Double(b1) * (1 - amount) + Double(b2) * amount,
            opacity: Double(a1) * (1 - amount) + Double(a2) * amount
        )
        #else
        return self
        #endif
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
            .foregroundStyle(AppTheme.textPrimary)
            .navigationTitle(title)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarColorScheme(AppTheme.isDark ? .dark : .light, for: .navigationBar)
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
                .foregroundStyle(AppTheme.textPrimary)
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

// MARK: - Theme Segmented Control

struct ThemeSegmentedControl<Option: CaseIterable & Hashable & RawRepresentable>: View where Option.RawValue == String {
    @Binding var selection: Option

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(Option.allCases), id: \.self) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selection = option
                    }
                } label: {
                    Text(option.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .foregroundStyle(selection == option ? .white : AppTheme.textSecondary)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(selection == option ? AppTheme.primary : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(AppTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(AppTheme.divider, lineWidth: 1)
        )
    }
}
