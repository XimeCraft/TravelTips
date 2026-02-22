import SwiftUI

struct InfoTab: View {
    let trip: Trip

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Essential Info")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                    Text("Things to prepare before departure")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSec)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 6)

                ForEach(trip.sortedInfoItems) { item in
                    InfoItemRow(item: item)
                }

                Spacer(minLength: 20)
            }
        }
    }
}

private struct InfoItemRow: View {
    let item: InfoItem

    var body: some View {
        CardView {
            HStack(alignment: .top, spacing: 12) {
                CheckboxView(isChecked: item.isDone) {
                    item.isDone.toggle()
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                        .strikethrough(item.isDone)
                    Text(item.details)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSec)
                        .lineSpacing(4)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .opacity(item.isDone ? 0.45 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: item.isDone)
    }
}
