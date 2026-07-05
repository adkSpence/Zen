import SwiftUI

extension Animation {
    static let focusDefault = Animation.spring(response: 0.45, dampingFraction: 0.82)
    static let modeTransition = Animation.spring(response: 0.6, dampingFraction: 0.85)
    static let progressBar = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let reorder = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let chartBar = Animation.spring(response: 0.6, dampingFraction: 0.75)
    static let reduceMotion = Animation.easeOut(duration: 0.2)
}
