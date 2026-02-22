import SwiftUI

struct SettingsView: View {
    private let items: [SettingItem] = [
        SettingItem(icon: "globe",           title: "Language",       subtitle: "English"),
        SettingItem(icon: "bell.fill",       title: "Notifications",  subtitle: "On"),
        SettingItem(icon: "cloud.fill",      title: "Backup & Sync",  subtitle: "iCloud"),
        SettingItem(icon: "paintbrush.fill", title: "Appearance",     subtitle: "System"),
        SettingItem(icon: "questionmark.circle.fill", title: "Help & Feedback", subtitle: ""),
        SettingItem(icon: "doc.text.fill",   title: "About",          subtitle: "v1.0"),
    ]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Settings")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 10)

                ForEach(items) { item in
                    CardView {
                        HStack(spacing: 12) {
                            Image(systemName: item.icon)
                                .font(.system(size: 20))
                                .foregroundColor(Theme.primary)
                                .frame(width: 26)
                            Text(item.title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if !item.subtitle.isEmpty {
                                Text(item.subtitle)
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.textSec)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(Color(.systemGray3))
                        }
                    }
                }

                Spacer(minLength: 20)
            }
        }
    }
}

// MARK: - Data

private struct SettingItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
}
