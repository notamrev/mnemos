import Foundation
import Network

@MainActor
final class CaptureServer {
    static let shared = CaptureServer()

    private var listener: NWListener?
    private let store: KnowledgeStore
    let port: UInt16

    init(store: KnowledgeStore = .shared, port: UInt16 = 40842) {
        self.store = store
        self.port = port
    }

    func start() {
        guard listener == nil else { return }
        do {
            listener = try NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: port)!)
            listener?.newConnectionHandler = { [weak self] connection in
                Task { @MainActor [weak self] in self?.accept(connection) }
            }
            listener?.start(queue: .main)
        } catch {
            // port already in use — silently skip
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    // MARK: - Private

    private func accept(_ connection: NWConnection) {
        connection.start(queue: .main)
        receive(on: connection)
    }

    private func receive(on connection: NWConnection, accumulated: Data = Data()) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, _, error in
            Task { @MainActor [weak self] in
                guard let self, error == nil else { connection.cancel(); return }
                let buffer = accumulated + (data ?? Data())
                guard !buffer.isEmpty else { connection.cancel(); return }

                let separator = Data("\r\n\r\n".utf8)
                guard let headerEndRange = buffer.range(of: separator) else {
                    self.receive(on: connection, accumulated: buffer)
                    return
                }

                let headerStr = String(data: buffer[buffer.startIndex..<headerEndRange.lowerBound], encoding: .utf8) ?? ""
                let contentLength: Int = headerStr
                    .components(separatedBy: "\r\n")
                    .first(where: { $0.lowercased().hasPrefix("content-length:") })
                    .flatMap {
                        Int($0.split(separator: ":", maxSplits: 1).last?.trimmingCharacters(in: .whitespaces) ?? "")
                    } ?? 0

                let bodyReceived = buffer.count - headerEndRange.upperBound
                guard bodyReceived >= contentLength else {
                    self.receive(on: connection, accumulated: buffer)
                    return
                }

                self.process(buffer, on: connection)
            }
        }
    }

    private func process(_ data: Data, on connection: NWConnection) {
        guard let raw = String(data: data, encoding: .utf8),
              let headerEnd = raw.range(of: "\r\n\r\n") else {
            respond(connection, status: 400); return
        }

        let requestLine = raw.prefix(while: { $0 != "\r" && $0 != "\n" })
        guard requestLine.contains("POST") && requestLine.contains("/capture") else {
            respond(connection, status: 404); return
        }

        let bodyStr = String(raw[headerEnd.upperBound...])
        guard let bodyData = bodyStr.data(using: .utf8),
              let req = try? JSONDecoder().decode(CaptureRequest.self, from: bodyData),
              !req.content.trimmingCharacters(in: .whitespaces).isEmpty else {
            respond(connection, status: 400); return
        }

        try? store.save(KnowledgeSnippet(content: req.content, tags: req.tags))
        respond(connection, status: 201)
    }

    private func respond(_ connection: NWConnection, status: Int) {
        let phrase: String
        switch status {
        case 201: phrase = "Created"
        case 404: phrase = "Not Found"
        default:  phrase = "Bad Request"
        }
        let http = "HTTP/1.1 \(status) \(phrase)\r\nContent-Length: \(phrase.utf8.count)\r\nConnection: close\r\n\r\n\(phrase)"
        connection.send(content: Data(http.utf8), completion: .contentProcessed { _ in connection.cancel() })
    }
}
