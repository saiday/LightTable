import SwiftUI

enum Theme {
    // Data accent colors
    static let eosinePink  = Color(red: 228/255, green: 92/255, blue: 108/255)    // #E45C6C
    static let neutralGray = Color(red: 180/255, green: 180/255, blue: 184/255)   // #B4B4B8

    // Neutrals – light theme
    static let bg          = Color(red: 244/255, green: 244/255, blue: 244/255)   // #F4F4F4
    static let bgElevated  = Color.white                                           // #FFFFFF
    static let surface     = Color.white
    static let border      = Color.black.opacity(0.12)
    static let text1       = Color(red: 28/255, green: 28/255, blue: 30/255)      // #1C1C1E
    static let text2       = Color.black.opacity(0.60)
    static let text3       = Color.black.opacity(0.42)
}

// MARK: - Surface Card Modifier

struct SurfaceCard: ViewModifier {
    var padding: EdgeInsets

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func surfaceCard(padding: EdgeInsets = EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)) -> some View {
        modifier(SurfaceCard(padding: padding))
    }
}

// MARK: - Shared Formatters

enum Formatters {
    static let byteCount: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f
    }()

    static let duration: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.hour, .minute]
        f.unitsStyle = .abbreviated
        f.zeroFormattingBehavior = .dropLeading
        return f
    }()
}

func formatBytes(_ bytes: Int64) -> String {
    Formatters.byteCount.string(fromByteCount: bytes)
}

func formatDuration(_ seconds: TimeInterval) -> String {
    Formatters.duration.string(from: seconds) ?? ""
}
