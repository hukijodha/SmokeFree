import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Section 48/49/3: settings, export, delete, privacy.

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.modelContext) private var context
    @Query private var smoking: [SmokingEvent]
    @Query private var cravings: [CravingEvent]
    @Query private var checkIns: [DailyCheckIn]
    @State private var journey: QuitJourney?
    @State private var showDeleteConfirm = false
    @State private var showPrivacy = false
    @State private var exportDoc: ExportDocument?

    var body: some View {
        @Bindable var env = env
        List {
            Section("Notifications") {
                Toggle("Daily reminders", isOn: $env.settings.notificationsEnabled)
            }
            Section("Voice") {
                Toggle("Voice logging", isOn: $env.settings.voiceLoggingEnabled)
            }
            Section("Apple Health") {
                Text("Not connected in this version — no HealthKit data type currently represents a smoking-cessation streak accurately.")
                    .font(Typography.caption(12)).foregroundStyle(.secondary)
            }
            Section("Apple Watch") {
                Text("Companion architecture is in place; the paired watch app arrives in a future update.")
                    .font(Typography.caption(12)).foregroundStyle(.secondary)
            }
            Section("Your Data") {
                Button("Export My Data (JSON)") { export(format: .json) }
                Button("Export My Data (CSV)") { export(format: .commaSeparatedText) }
                Button("View Privacy Info") { showPrivacy = true }
                Button("Delete My Data", role: .destructive) { showDeleteConfirm = true }
            }
            Section("About") {
                Text("QUIT21 — 21 Days. One Decision. A Healthier Life.")
                Text("Health information sourced from publicly available CDC/WHO cessation guidance.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .onAppear { journey = JourneyStore.fetchOrCreateJourney(context: context) }
        .confirmationDialog("Delete all your data?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Everything", role: .destructive) {
                try? DataExportService.deleteEverything(context: context)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes your quit journey, cravings, smoking events and check-ins from this device. This cannot be undone.")
        }
        .sheet(isPresented: $showPrivacy) { PrivacyInfoView() }
        .fileExporter(isPresented: Binding(get: { exportDoc != nil }, set: { if !$0 { exportDoc = nil } }),
                     document: exportDoc, contentType: exportDoc?.type ?? .json,
                     defaultFilename: "quit21-export") { _ in exportDoc = nil }
    }

    private func export(format: UTType) {
        let snapshot = DataExportService.snapshot(journey: journey, smoking: smoking, craving: cravings, checkIns: checkIns)
        let data = format == .json ? DataExportService.json(snapshot) : DataExportService.csv(snapshot)
        exportDoc = ExportDocument(data: data, type: format)
    }
}

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .commaSeparatedText] }
    let data: Data
    let type: UTType
    init(data: Data, type: UTType) { self.data = data; self.type = type }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data(); type = .json }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

/// Section 47: the privacy screen.
struct PrivacyInfoView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("YOUR JOURNEY IS YOURS.").font(Typography.title(24)).foregroundStyle(Theme.textPrimary)
                    ForEach([
                        "Your quit journey is stored locally on your device.",
                        "We do not need your name.",
                        "We do not need your phone number.",
                        "We do not need your email.",
                        "We do not sell your personal data.",
                        "We do not build advertising profiles from your health information.",
                        "Your smoking history stays on your device.",
                        "If you delete the app without an export you created yourself, your local journey data will be deleted.",
                    ], id: \.self) { line in
                        Text(line).font(Typography.body(15)).foregroundStyle(Theme.textSecondary)
                    }
                    PrimaryButton(title: "Close") { dismiss() }.padding(.top, 12)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.backgroundGradient.ignoresSafeArea())
    }
}
