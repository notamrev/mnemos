import Foundation
import Observation

enum OverlayMode {
    case capture
    case browse
}

@MainActor
@Observable
final class OverlayViewModel {
    var mode: OverlayMode = .capture

    func toggleMode() {
        mode = (mode == .capture) ? .browse : .capture
    }

    func reset() {
        mode = .capture
    }
}
