import SwiftUI

struct ContentView: View {
    @StateObject private var model = RemoteModel()
    @State private var showSettings = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    StatusChip(link: model.link, host: model.host) {
                        Task { await model.refresh() }
                    }

                    VStack(spacing: 16) {
                        temperatureCard
                        modeCard
                        fanCard
                        optionsCard
                    }
                    .disabled(!model.state.power)
                    .opacity(model.state.power ? 1 : 0.45)
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) { powerButton }
            .navigationTitle("Điều hòa Toshiba")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Cài đặt")
                }
            }
        }
        .navigationViewStyle(.stack)
        .tint(Theme.brand)
        .sheet(isPresented: $showSettings) {
            SettingsView(model: model)
        }
        .task { await model.refresh() }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                Task { await model.refresh() }
            }
        }
    }

    // MARK: - Nhiệt độ

    private var temperatureCard: some View {
        Card {
            HStack {
                RoundButton(symbol: "minus", label: "Giảm nhiệt độ") {
                    model.change { $0.temp = max(ACState.tempRange.lowerBound, $0.temp - 1) }
                }
                .disabled(model.state.temp <= ACState.tempRange.lowerBound)

                Spacer()

                VStack(spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(model.state.temp)")
                            .font(.system(size: 80, weight: .light, design: .rounded))
                            .monospacedDigit()
                        Text("°C")
                            .font(.system(size: 28, weight: .regular, design: .rounded))
                            .foregroundColor(Theme.muted)
                    }
                    .foregroundColor(Theme.ink)
                    .accessibilityElement(children: .combine)

                    Label(model.state.mode.title, systemImage: model.state.mode.symbol)
                        .font(.subheadline)
                        .foregroundColor(Theme.muted)
                }

                Spacer()

                RoundButton(symbol: "plus", label: "Tăng nhiệt độ") {
                    model.change { $0.temp = min(ACState.tempRange.upperBound, $0.temp + 1) }
                }
                .disabled(model.state.temp >= ACState.tempRange.upperBound)
            }
        }
    }

    // MARK: - Chế độ

    private var modeCard: some View {
        Card(title: "Chế độ") {
            HStack(spacing: 8) {
                ForEach(ACMode.allCases) { mode in
                    ChoiceButton(
                        isSelected: model.state.mode == mode,
                        accessibilityLabel: mode.title
                    ) {
                        model.change { $0.mode = mode }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: mode.symbol)
                                .font(.system(size: 20))
                            Text(mode.title)
                                .font(.caption2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity, minHeight: 58)
                    }
                }
            }
        }
    }

    // MARK: - Quạt

    private var fanCard: some View {
        Card(title: "Tốc độ quạt") {
            HStack(spacing: 8) {
                ForEach(Array(ACState.fanRange), id: \.self) { level in
                    ChoiceButton(
                        isSelected: model.state.fan == level,
                        accessibilityLabel: level == 0 ? "Quạt tự động" : "Quạt mức \(level)"
                    ) {
                        model.change { $0.fan = level }
                    } label: {
                        Text(level == 0 ? "Auto" : "\(level)")
                            .font(.callout.weight(.medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                }
            }
        }
    }

    // MARK: - Tùy chọn

    private var optionsCard: some View {
        Card(title: "Tùy chọn") {
            HStack(spacing: 8) {
                optionButton("Đảo gió", symbol: "arrow.up.and.down", isOn: model.state.swing) {
                    model.change { $0.swing.toggle() }
                }
                optionButton("Hi-Power", symbol: "bolt.fill", isOn: model.state.turbo) {
                    model.change {
                        $0.turbo.toggle()
                        if $0.turbo { $0.econo = false }
                    }
                }
                optionButton("Eco", symbol: "leaf.fill", isOn: model.state.econo) {
                    model.change {
                        $0.econo.toggle()
                        if $0.econo { $0.turbo = false }
                    }
                }
            }
        }
    }

    private func optionButton(
        _ title: String,
        symbol: String,
        isOn: Bool,
        action: @escaping () -> Void
    ) -> some View {
        ChoiceButton(
            isSelected: isOn,
            accessibilityLabel: "\(title), \(isOn ? "đang bật" : "đang tắt")",
            action: action
        ) {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 18))
                Text(title)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(isOn ? "Bật" : "Tắt")
                    .font(.caption2.weight(.semibold))
            }
            .frame(maxWidth: .infinity, minHeight: 72)
        }
    }

    // MARK: - Nguồn

    private var powerButton: some View {
        Button {
            Haptics.tap()
            model.change { $0.power.toggle() }
        } label: {
            Label(model.state.power ? "Tắt máy" : "Bật máy", systemImage: "power")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 54)
                .foregroundColor(model.state.power ? Theme.onInk : Theme.onBrand)
                .background(model.state.power ? Theme.ink : Theme.brand)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.background.opacity(0.96))
    }
}

// MARK: - Thành phần dùng chung

private struct Card<Content: View>: View {
    var title: String?
    let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Theme.muted)
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct RoundButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .semibold))
                .frame(width: 60, height: 60)
                .foregroundColor(Theme.brand)
                .background(Theme.background)
                .clipShape(Circle())
                .overlay(Circle().stroke(Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct ChoiceButton<Label: View>: View {
    let isSelected: Bool
    let accessibilityLabel: String
    let action: () -> Void
    let label: Label

    init(
        isSelected: Bool,
        accessibilityLabel: String,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.isSelected = isSelected
        self.accessibilityLabel = accessibilityLabel
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            label
                .foregroundColor(isSelected ? Theme.onBrand : Theme.ink)
                .background(isSelected ? Theme.brand : Theme.background)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? Theme.brand : Theme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

struct StatusChip: View {
    let link: RemoteModel.Link
    let host: String
    let retry: () -> Void

    var body: some View {
        Button(action: retry) {
            HStack(spacing: 8) {
                icon
                Text(text)
                    .font(.footnote.weight(.medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if case .offline = link {
                    Text("Thử lại")
                        .font(.footnote.weight(.semibold))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundColor(foreground)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var icon: some View {
        switch link {
        case .busy:
            ProgressView()
        case .online:
            Image(systemName: "checkmark.circle.fill")
        case .offline:
            Image(systemName: "exclamationmark.triangle.fill")
        case .unknown:
            Image(systemName: "wifi")
        }
    }

    private var text: String {
        switch link {
        case .unknown: return "Chưa kết nối · \(host)"
        case .busy: return "Đang gửi tới \(host)…"
        case .online: return "Đã kết nối · \(host)"
        case .offline(let reason): return "\(reason) · \(host)"
        }
    }

    private var foreground: Color {
        switch link {
        case .online: return Theme.okText
        case .offline: return Theme.warnText
        default: return Theme.muted
        }
    }

    private var background: Color {
        switch link {
        case .online: return Theme.okBackground
        case .offline: return Theme.warnBackground
        default: return Theme.card
        }
    }
}
