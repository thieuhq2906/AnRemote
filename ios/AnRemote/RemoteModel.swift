import Foundation
import SwiftUI

@MainActor
final class RemoteModel: ObservableObject {
    enum Link: Equatable {
        case unknown
        case busy
        case online
        case offline(String)
    }

    @Published var state = ACState()
    @Published var link: Link = .unknown
    @Published private(set) var host: String

    private var pending: Task<Void, Never>?
    private static let hostKey = "deviceHost"
    static let defaultHost = "anremote.local"

    init() {
        let saved = UserDefaults.standard.string(forKey: Self.hostKey) ?? ""
        host = saved.isEmpty ? Self.defaultHost : saved
    }

    func setHost(_ raw: String) {
        let clean = ACClient.normalize(raw)
        host = clean.isEmpty ? Self.defaultHost : clean
        UserDefaults.standard.set(host, forKey: Self.hostKey)
    }

    /// Đọc trạng thái mà bộ phát đang nhớ.
    func refresh() async {
        link = .busy
        do {
            let remote = try await ACClient(host: host).fetch()
            if pending == nil { state = remote }
            link = .online
        } catch {
            link = .offline(Self.describe(error))
        }
    }

    /// Đổi trạng thái trên màn hình ngay, gom các lần bấm liên tiếp rồi mới phát lệnh.
    func change(_ edit: (inout ACState) -> Void) {
        var next = state
        edit(&next)
        guard next != state else { return }
        state = next

        pending?.cancel()
        pending = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await self?.push()
        }
    }

    private func push() async {
        let snapshot = state
        link = .busy
        do {
            let confirmed = try await ACClient(host: host).send(snapshot)
            if state == snapshot {
                state = confirmed
                pending = nil
            }
            link = .online
        } catch {
            if state == snapshot { pending = nil }
            link = .offline(Self.describe(error))
        }
    }

    private static func describe(_ error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return "Không tìm thấy bộ phát"
            case .notConnectedToInternet, .networkConnectionLost:
                return "iPhone chưa vào Wi-Fi"
            default:
                return "Lỗi mạng"
            }
        }
        if error is DecodingError {
            return "Bộ phát trả lời không đúng định dạng"
        }
        return error.localizedDescription
    }
}
