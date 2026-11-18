import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: RemoteModel
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""

    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text("Địa chỉ bộ phát hồng ngoại"),
                    footer: Text("Mặc định là anremote.local. Nếu không kết nối được, nhập địa chỉ IP của mạch ESP (xem trong danh sách thiết bị của router), ví dụ 192.168.1.50.")
                ) {
                    TextField(RemoteModel.defaultHost, text: $draft)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }

                Section {
                    Button("Lưu và kiểm tra kết nối") {
                        model.setHost(draft)
                        draft = model.host
                        Task { await model.refresh() }
                    }
                    StatusChip(link: model.link, host: model.host) {
                        Task { await model.refresh() }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }

                Section(header: Text("Lưu ý")) {
                    Label("iPhone và bộ phát phải cùng một mạng Wi-Fi.", systemImage: "wifi")
                    Label("Lần đầu mở app, chọn Cho phép khi iOS hỏi quyền truy cập mạng nội bộ.", systemImage: "hand.raised")
                    Label("Đặt bộ phát hướng đèn hồng ngoại về phía điều hòa, trong khoảng vài mét.", systemImage: "dot.radiowaves.right")
                }
                .font(.footnote)
            }
            .navigationTitle("Cài đặt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong") { dismiss() }
                }
            }
            .onAppear { draft = model.host }
        }
        .navigationViewStyle(.stack)
        .tint(Theme.brand)
    }
}
