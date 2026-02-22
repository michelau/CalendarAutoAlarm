import SwiftUI

/// SwiftUI view displayed on the Apple Watch face when a calendar alarm fires.
struct NotificationView: View {

    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: "bell.fill")
                .font(.headline)
                .foregroundStyle(.yellow)
            Text(message)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }
}
