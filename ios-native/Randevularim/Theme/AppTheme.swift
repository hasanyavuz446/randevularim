import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Theme Config

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

// MARK: - AppTheme

enum AppTheme {
    static var primary = Color(hex: "#496ED9")
    static var accent = Color(hex: "#C9A84C")
    static var background = Color(hex: "#0D0D1A")
    static var surface = Color(hex: "#1A1A2E")
    static var secondarySurface = Color(hex: "#23233A")
    static var textPrimary = Color.white
    static var textSecondary = Color.white.opacity(0.68)
    static var divider = Color.white.opacity(0.10)
    static var isDark = true
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

        isDark = resolvedIsDark
        primary = config.primary
        accent = config.accent
        if resolvedIsDark {
            background = config.darkBackground
            surface = config.darkSurface
            secondarySurface = Color(hex: config.darkSurfaceHex).mix(with: .white, by: 0.08)
            textPrimary = .white
            textSecondary = Color.white.opacity(0.68)
            divider = Color.white.opacity(0.10)
        } else {
            background = config.lightBackground
            surface = Color.white
            secondarySurface = Color(hex: "#E5E5EA")
            textPrimary = Color(hex: "#1C1C1E")
            textSecondary = Color.black.opacity(0.5)
            divider = Color.black.opacity(0.08)
        }
        applyUIKitAppearance(colorSchemePref: colorSchemePref)
    }

    #if canImport(UIKit)
    @MainActor
    private static func applyUIKitAppearance(colorSchemePref: String) {
        let backgroundUIColor = UIColor(background)
        let surfaceUIColor = UIColor(surface)
        let secondarySurfaceUIColor = UIColor(secondarySurface)
        let textUIColor = UIColor(textPrimary)
        let secondaryTextUIColor = UIColor(textSecondary)
        let primaryUIColor = UIColor(primary)
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
                refresh(view: window)
                window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
                window.setNeedsLayout()
            }
    }

    @MainActor
    private static func refresh(view: UIView) {
        if let tableView = view as? UITableView {
            tableView.backgroundColor = UIColor(background)
            tableView.visibleCells.forEach { cell in
                cell.backgroundColor = UIColor(surface)
                cell.contentView.backgroundColor = UIColor(surface)
            }
            tableView.reloadData()
        } else if let collectionView = view as? UICollectionView {
            collectionView.backgroundColor = UIColor(background)
            collectionView.reloadData()
        } else if let tabBar = view as? UITabBar {
            tabBar.tintColor = UIColor(primary)
            tabBar.unselectedItemTintColor = UIColor(textSecondary)
            tabBar.setNeedsLayout()
        } else if let navigationBar = view as? UINavigationBar {
            navigationBar.tintColor = UIColor(primary)
            navigationBar.setNeedsLayout()
        }

        view.setNeedsDisplay()
        view.setNeedsLayout()
        view.subviews.forEach(refresh)
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
    @AppStorage("themeRevision") private var themeRevision = 0

    var body: some View {
        let _ = themeRevision
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
