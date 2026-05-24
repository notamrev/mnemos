import Foundation

struct CaptureRequest: Decodable {
    let source: String
    let content: String
    let tags: [String]
}
