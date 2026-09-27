import SwiftUI
import SwiftData

// MARK: - Section 21/22/29: identity, My Why, and the 21-day → Stay Quit
// program view. Identity language progresses (never static "ex-smoker").

struct ProfileView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.modelContext) private var context
    @State private var journey: QuitJourney?
    @State private var reason: PersonalReason?
    @State private var editingWhy = false
    @State private var whyDraft = ""

    private var day: Int { journey?.currentDay(now: env.lastTick) ?? 1 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    identityCard
                    whyCard
                    programSection
                    NavigationLink { SettingsView() } label: {
                        SecondaryButton(title: "Settings", systemImage: "gearshape") {}
                            .allowsHitTesting(false)
                    }
                }
                .padding(20)
            }
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Me")
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .onAppear {
            journey = JourneyStore.fetchOrCreateJourney(context: context)
            reason = JourneyStore.fetchOrCreateReason(context: context)
            whyDraft = reason?.text ?? ""
        }
        .sheet(isPresented: $editingWhy) { editWhySheet }
    }

    private var identityLabel: String {
        guard journey?.quitDate != nil else { return "Ready when you are" }
        if day >= 90 { return "Smoking is no longer part of your life." }
        if day >= 22 { return "You're living smoke-free." }
        if day >= 8 { return "You're becoming smoke-free." }
        return "You're quitting."
    }

    private var identityCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(identityLabel).font(Typography.title(22)).foregroundStyle(Theme.textPrimary)
                if journey?.quitDate != nil { Text("Day \(day)").font(Typography.body(14)).foregroundStyle(Theme.textSecondary) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var whyCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("MY WHY").font(Typography.caption()).foregroundStyle(Theme.textTertiary)
                Text(reason?.text.isEmpty == false ? reason!.text : "Add your reason for quitting.")
                    .font(Typography.body(16)).foregroundStyle(Theme.textPrimary)
                Button("Edit") { editingWhy = true }.font(Typography.caption(13)).foregroundStyle(Theme.healthy)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var editWhySheet: some View {
        VStack(spacing: 20) {
            Text("I am quitting because…").font(Typography.headline()).foregroundStyle(Theme.textPrimary)
            TextField("your own words", text: $whyDraft, axis: .vertical)
                .lineLimit(3...6).padding().background(Theme.card, in: RoundedRectangle(cornerRadius: 16)).foregroundStyle(Theme.textPrimary)
            PrimaryButton(title: "Save") {
                reason?.text = whyDraft
                reason?.updatedAt = .now
                try? context.save()
                editingWhy = false
            }
            Spacer()
        }
        .padding(24)
        .presentationDetents([.medium])
        .background(Theme.backgroundGradient.ignoresSafeArea())
    }

    private var programSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(day <= 21 ? "21-DAY PROGRAM" : "STAY QUIT").font(Typography.caption()).foregroundStyle(Theme.textTertiary)
            if day > 21 {
                GlassCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your next goal isn't another 21 days.").font(Typography.headline(16)).foregroundStyle(Theme.textPrimary)
                        Text("It's continuing the life you've started.").font(Typography.body(14)).foregroundStyle(Theme.textSecondary)
                        HStack { ForEach([30, 60, 90], id: \.self) { milestone in
                            Text("\(milestone)d").font(Typography.caption()).padding(8).background(Theme.card, in: Capsule()).foregroundStyle(Theme.textPrimary)
                        }}
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(ProgramContent.days.filter { $0.day <= min(day, 21) }.reversed().prefix(5)) { d in
                    GlassCard(padding: 12) {
                        HStack {
                            Text("DAY \(d.day)").font(Typography.caption(12)).foregroundStyle(Theme.textTertiary).frame(width: 60, alignment: .leading)
                            Text(d.focus).font(Typography.body(14)).foregroundStyle(Theme.textPrimary)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}
