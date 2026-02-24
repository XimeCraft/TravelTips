import SwiftUI

// MARK: - Checkbox

struct CheckboxView: View {
    let isChecked: Bool
    var color: Color = Theme.primary
    var size: CGFloat = 22
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.32)
                    .fill(isChecked ? color : Color.clear)
                    .frame(width: size, height: size)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.32)
                            .stroke(isChecked ? Color.clear : Color(.systemGray3), lineWidth: 2)
                    )
                if isChecked {
                    Text("✓")
                        .font(.system(size: size * 0.59, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isChecked)
    }
}

// MARK: - Card

struct CardView<Content: View>: View {
    let action: (() -> Void)?
    @ViewBuilder let content: Content

    init(action: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) { inner }
                    .buttonStyle(.plain)
            } else {
                inner
            }
        }
    }

    private var inner: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Theme.card)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
    }
}

// MARK: - Pill

struct PillView: View {
    let text: String
    let bg: Color
    let fg: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(bg)
            .foregroundColor(fg)
            .cornerRadius(20)
    }
}

// MARK: - Flow Layout (wraps items to next row when width exceeded)

struct FlowHStack: Layout {
    var spacing: CGFloat = 5

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.gray)
            .textCase(.uppercase)
            .kerning(1.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }
}

// MARK: - Back Button

struct BackButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text("‹")
                    .font(.system(size: 22))
                Text(label)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(Theme.primary)
            .padding(.leading, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Button (MVP2: top-right corner + button)

struct AddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(Theme.primary)
                .cornerRadius(9)
                .shadow(color: Theme.primary.opacity(0.3), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - View Details Button (MVP2: centered, tinted background; MVP3: optional action)

struct ViewDetailsButton: View {
    let color: Color
    var action: (() -> Void)? = nil

    var body: some View {
        let label = Text("View details ›")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.08))
            .cornerRadius(10)

        if let action {
            Button(action: action) { label }
                .buttonStyle(.plain)
        } else {
            label
        }
    }
}

// MARK: - Sheet Form Field

struct SheetField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var multiline: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textSec)
                .textCase(.uppercase)
                .kerning(0.8)
            if multiline {
                TextEditor(text: $text)
                    .font(.system(size: 14))
                    .frame(minHeight: 60)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 14))
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Sheet Save Button

struct SheetSaveButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.primary)
                .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
}

// MARK: - Tab Bar

enum MainTab: String, CaseIterable {
    case trips, reminders, settings

    var icon: String {
        switch self {
        case .trips:     return "house.fill"
        case .reminders: return "bell.fill"
        case .settings:  return "gearshape.fill"
        }
    }

    var label: String {
        switch self {
        case .trips:     return "Trips"
        case .reminders: return "Reminders"
        case .settings:  return "Settings"
        }
    }
}

enum TripTab: String, CaseIterable {
    case overview, transport, accommodation, destinations, info

    var icon: String {
        switch self {
        case .overview:      return "list.bullet.rectangle"
        case .transport:     return "airplane"
        case .accommodation: return "bed.double.fill"
        case .destinations:  return "mappin"
        case .info:          return "info.circle.fill"
        }
    }

    var label: String {
        switch self {
        case .overview:      return "Overview"
        case .transport:     return "Transport"
        case .accommodation: return "Hotels"
        case .destinations:  return "Places"
        case .info:          return "Info"
        }
    }
}

struct AppTabBar: View {
    let inTrip: Bool
    @Binding var mainTab: MainTab
    @Binding var tripTab: TripTab
    let onTripTabChange: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                if inTrip {
                    ForEach(TripTab.allCases, id: \.self) { tab in
                        tabItem(
                            icon: tab.icon,
                            label: tab.label,
                            isActive: tripTab == tab
                        ) {
                            tripTab = tab
                            onTripTabChange()
                        }
                    }
                } else {
                    ForEach(MainTab.allCases, id: \.self) { tab in
                        tabItem(
                            icon: tab.icon,
                            label: tab.label,
                            isActive: mainTab == tab
                        ) {
                            mainTab = tab
                        }
                    }
                }
            }
            .frame(height: 49)
            .padding(.bottom, 4)
        }
        .background(.ultraThinMaterial)
        .animation(.easeInOut(duration: 0.2), value: inTrip)
    }

    private func tabItem(icon: String, label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(0.3)
            }
            .foregroundColor(isActive ? Theme.primary : Theme.textTer)
            .frame(maxWidth: .infinity)
            .animation(.easeInOut(duration: 0.2), value: isActive)
        }
        .buttonStyle(.plain)
    }
}
