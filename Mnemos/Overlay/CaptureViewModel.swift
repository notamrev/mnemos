import Foundation
import Observation

@MainActor
@Observable
final class CaptureViewModel {
    var content = ""
    var tagInput = ""
    var showConfirmation = false

    var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var parsedTags: [String] {
        tagInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
