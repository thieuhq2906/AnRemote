import Foundation

enum ACClientError: LocalizedError {
    case badHost
    case badResponse(Int)

    var errorDescription: String? {
        switch self {
        case .badHost:
            return "Địa chỉ bộ phát không hợp lệ"
        case .badResponse(let code):
            return "Bộ phát trả về lỗi \(code)"
        }
    }
}

/// Gọi HTTP tới bộ phát hồng ngoại (ESP) trong mạng Wi-Fi nhà.
struct ACClient {
    let host: String

    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 8
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    /// Bỏ "http://" và dấu "/" thừa nếu người dùng dán cả URL.
    static func normalize(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        for prefix in ["http://", "https://"] where text.hasPrefix(prefix) {
            text.removeFirst(prefix.count)
        }
        if let slash = text.firstIndex(of: "/") {
            text = String(text[..<slash])
        }
        return text
    }

    private func url(_ path: String) throws -> URL {
        let clean = Self.normalize(host)
        guard !clean.isEmpty, let url = URL(string: "http://\(clean)\(path)") else {
            throw ACClientError.badHost
        }
        return url
    }

    func fetch() async throws -> ACState {
        let request = URLRequest(url: try url("/api/state"))
        return try await perform(request)
    }

    func send(_ state: ACState) async throws -> ACState {
        var request = URLRequest(url: try url("/api/set"))
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let fields: [(String, String)] = [
            ("power", state.power ? "1" : "0"),
            ("mode", state.mode.rawValue),
            ("temp", String(state.temp)),
            ("fan", String(state.fan)),
            ("swing", state.swing ? "1" : "0"),
            ("turbo", state.turbo ? "1" : "0"),
            ("econo", state.econo ? "1" : "0"),
        ]
        let body = fields.map { "\($0.0)=\($0.1)" }.joined(separator: "&")
        request.httpBody = Data(body.utf8)
        return try await perform(request)
    }

    private func perform(_ request: URLRequest) async throws -> ACState {
        let (data, response) = try await Self.session.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw ACClientError.badResponse(http.statusCode)
        }
        return try JSONDecoder().decode(ACState.self, from: data)
    }
}
