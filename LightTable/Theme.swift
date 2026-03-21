import SwiftUI

enum Theme {
    // Data accent colors
    static let helvetiaBlue = Color(red: 0/255, green: 126/255, blue: 167/255)    // #007EA7
    static let dullCitrine  = Color(red: 155/255, green: 138/255, blue: 47/255)   // #9B8A2F

    // Neutrals
    static let bg          = Color(red: 17/255, green: 17/255, blue: 17/255)      // #111111
    static let bgElevated  = Color(red: 26/255, green: 26/255, blue: 26/255)      // #1A1A1A
    static let surface     = Color.white.opacity(0.035)
    static let border      = Color.white.opacity(0.07)
    static let text1       = Color(red: 242/255, green: 240/255, blue: 235/255)   // #F2F0EB
    static let text2       = Color.white.opacity(0.45)
    static let text3       = Color.white.opacity(0.25)
}
