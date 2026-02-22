import SwiftUI

struct DayDetailView: View {
    let trip: Trip
    let dayIndex: Int
    let onBack: () -> Void

    @State private var currentPage = 0
    @State private var showDone = true

    private var day: TripDay { trip.sortedDays[dayIndex] }

    private var visibleDetails: [DayDetail] {
        let sorted = day.sortedDetails
        return showDone ? sorted : sorted.filter { !$0.isDone }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──────────────────────────────────────────────────────
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Text("‹").font(.system(size: 22))
                        Text("Overview").font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(Theme.primary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    showDone.toggle()
                    currentPage = 0
                } label: {
                    Text(showDone ? "Hide done" : "Show all")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Theme.primaryFaint)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // ── Day title ────────────────────────────────────────────────────
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Day \(dayIndex + 1)")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                    Text("\(fmtDate(day.date)) · \(day.city)")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSec)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 4)

            // ── Horizontal paging cards ──────────────────────────────────────
            if visibleDetails.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Text("✅")
                        .font(.system(size: 48))
                    Text("All done!")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.textSec)
                    Button("Show all") {
                        showDone = true
                        currentPage = 0
                    }
                    .foregroundColor(Theme.primary)
                }
                Spacer()
            } else {
                TabView(selection: $currentPage) {
                    ForEach(Array(visibleDetails.enumerated()), id: \.element.id) { i, detail in
                        DayDetailCard(
                            detail: detail,
                            index: i,
                            total: visibleDetails.count
                        )
                        .padding(.horizontal, 20)
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.2), value: visibleDetails.count)

                // ── Page dots ────────────────────────────────────────────────
                HStack(spacing: 6) {
                    ForEach(0..<visibleDetails.count, id: \.self) { i in
                        Button { currentPage = i } label: {
                            RoundedRectangle(cornerRadius: 4)
                                .frame(width: currentPage == i ? 22 : 7, height: 7)
                                .foregroundColor(currentPage == i ? Theme.primary : Color(.systemGray4))
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 14)
            }
        }
    }
}

// MARK: - Single card

private struct DayDetailCard: View {
    let detail: DayDetail
    let index: Int
    let total: Int

    private static let cardGradients: [Gradient] = [
        Gradient(colors: [.white, Color(hex: "F8FAF8")]),
        Gradient(colors: [Color(hex: "F5FAF7"), Color(hex: "EDF5F0")]),
        Gradient(colors: [.white, Color(hex: "F6F9F7")]),
    ]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Background
            LinearGradient(
                gradient: detail.isDone
                    ? Gradient(colors: [Color(hex: "EDEEEB"), Color(hex: "E6E7E3")])
                    : Self.cardGradients[index % 3],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative circles
            Circle()
                .fill(Theme.primaryGhost)
                .frame(width: 140, height: 140)
                .offset(x: 40, y: 40)
            Circle()
                .fill(Theme.primaryGhost)
                .frame(width: 60, height: 60)
                .offset(x: -10, y: -20)

            // Content
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    // Time badge
                    Text(detail.time)
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(Theme.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Theme.primaryMuted)
                        .cornerRadius(12)

                    Spacer()

                    // Checkbox
                    CheckboxView(isChecked: detail.isDone) {
                        detail.isDone.toggle()
                    }
                }

                Spacer().frame(height: 36)

                Text(detail.title)
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(Theme.textPrimary)
                    .strikethrough(detail.isDone)
                    .fixedSize(horizontal: false, vertical: true)

                if let note = detail.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSec)
                        .lineSpacing(6)
                        .padding(.top, 14)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 16)

                Text("\(index + 1) / \(total)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textTer)
            }
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    detail.isDone ? Color.clear : Theme.primary.opacity(0.06),
                    lineWidth: 1
                )
        )
        .shadow(
            color: detail.isDone ? .clear : Theme.primary.opacity(0.06),
            radius: 12, x: 0, y: 4
        )
        .frame(maxWidth: .infinity)
        .frame(minHeight: 380)
        .opacity(detail.isDone ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: detail.isDone)
    }
}
