import SwiftUI

/// Design-Richtung nach Product Vision §30: modern, hochwertig, spielerisch,
/// etwas frech - aber nicht kindisch. Warme, dunkle Grundflaeche, ein
/// kraeftiger Bernstein-Akzent, keine Dauer-Animationen.
public enum BQColor {
    public static let background = Color(red: 0.09, green: 0.08, blue: 0.07)
    public static let surface    = Color(red: 0.14, green: 0.12, blue: 0.11)
    public static let surfaceAlt = Color(red: 0.19, green: 0.17, blue: 0.15)
    public static let accent     = Color(red: 0.98, green: 0.70, blue: 0.19)
    public static let accentDeep = Color(red: 0.85, green: 0.52, blue: 0.10)
    public static let textPrimary   = Color(red: 0.97, green: 0.96, blue: 0.94)
    public static let textSecondary = Color(red: 0.67, green: 0.64, blue: 0.60)
    public static let success = Color(red: 0.36, green: 0.78, blue: 0.45)
    public static let danger  = Color(red: 0.89, green: 0.35, blue: 0.31)
}

public enum BQFont {
    public static let display = Font.system(size: 34, weight: .heavy, design: .rounded)
    public static let title   = Font.system(size: 22, weight: .bold, design: .rounded)
    public static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    public static let body    = Font.system(size: 16, weight: .regular)
    public static let caption = Font.system(size: 13, weight: .medium)
    public static let number  = Font.system(size: 28, weight: .heavy, design: .rounded)
}

public enum BQSpacing {
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 16
    public static let l: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let corner: CGFloat = 16
}
