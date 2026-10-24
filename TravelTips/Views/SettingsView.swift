import SwiftUI
import SwiftData
import UIKit
import UserNotifications

struct SettingsView: View {
    @AppStorage(NotificationScheduler.enabledKey) private var notificationsEnabled: Bool = false
    @Environment(\.modelContext) private var modelContext
    @State private var showPermissionDenied = false

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

                // Language: iOS per-app language (Settings > TravelTips > Language).
                // Changing it there relaunches the app in that language.
                CardView(action: openAppSettings) {
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.primary)
                            .frame(width: 26)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Language")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                            Text("Change it in iOS Settings")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textSec)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Text(currentLanguageName)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSec)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(.systemGray3))
                    }
                }

                // Notifications
                CardView {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.primary)
                            .frame(width: 26)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notifications")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                            Text("The evening before a trip, and each morning's plan during it")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textSec)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Toggle("", isOn: $notificationsEnabled)
                            .labelsHidden()
                            .tint(Theme.primary)
                            .onChange(of: notificationsEnabled) { _, enabled in
                                Task { await notificationsToggled(enabled) }
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
                CardView {
                    PendingNotificationsDebugView()
                }
                #endif

                Spacer(minLength: 20)
            }
        }
        .task { await syncWithSystemPermission() }
        .alert("Notifications are off", isPresented: $showPermissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Allow notifications for TravelTips in iOS Settings to get trip reminders.")
        }
    }

    /// The app's current UI language, named in that language ("English", "简体中文").
    private var currentLanguageName: String {
        let code = Bundle.main.preferredLocalizations.first ?? "en"
        return Locale(identifier: code).localizedString(forIdentifier: code)?.capitalized(with: Locale(identifier: code)) ?? code
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
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
        return String(localized: "Version \(version) (\(build))")
    }

    private func notificationsToggled(_ enabled: Bool) async {
        guard enabled else {
            await NotificationScheduler.clearTripNotifications()
            return
        }
        if await NotificationScheduler.requestPermission() {
            await NotificationScheduler.reschedule(context: modelContext)
        } else {
            notificationsEnabled = false
            showPermissionDenied = true
        }
    }

    /// Keeps the toggle honest if permission was revoked in iOS Settings.
    private func syncWithSystemPermission() async {
        guard notificationsEnabled else { return }
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        if status == .denied { notificationsEnabled = false }
    }
}
