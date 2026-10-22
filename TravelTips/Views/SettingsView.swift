import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("appLanguage") private var language: String = "en"
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 2) {
                    Text("Settings")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 10)

                SectionHeader(title: "Preferences")

                // Language
                CardView {
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.primary)
                            .frame(width: 26)
                        Text("Language")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack(spacing: 4) {
                            ForEach([("en", "EN"), ("zh", "中文")], id: \.0) { code, label in
                                Button {
                                    language = code
                                } label: {
                                    Text(label)
                                        .font(.system(size: 12, weight: .semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(language == code ? Theme.primary : Color(.systemGray5))
                                        .foregroundColor(language == code ? .white : Theme.textSec)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Notifications
                CardView {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.primary)
                            .frame(width: 26)
                        Text("Notifications")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Toggle("", isOn: $notificationsEnabled)
                            .labelsHidden()
                            .tint(Theme.primary)
                            .onChange(of: notificationsEnabled) { _, enabled in
                                if enabled { requestNotificationPermission() }
                            }
                    }
                }

                SectionHeader(title: "About")

                // About card
                CardView {
                    VStack(alignment: .center, spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient(
                                    colors: [Theme.primary, Theme.primaryLight],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                                .frame(width: 52, height: 52)
                            Text("🧳")
                                .font(.system(size: 24))
                        }
                        Text(appName)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        Text(appVersion)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSec)
                        Text("Your offline travel companion.\nOrganize itineraries, store tickets & documents.")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textTer)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }

                #if DEBUG
                SectionHeader(title: "Debug")
                CardView {
                    OnDeviceAIStatusView()
                }
                #endif

                Spacer(minLength: 20)
            }
        }
    }

    private var appName: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? "TravelTips"
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "Version \(version) (\(build))"
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}
