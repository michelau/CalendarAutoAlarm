import SwiftUI

/// Sign-in screen shown when the user is not yet authenticated.
struct SignInView: View {

    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 80))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("Calendar Auto Alarm")
                    .font(.largeTitle.bold())
                Text("Automatically schedule alarms for your Google Calendar events.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 12) {
                Button {
                    Task { await authManager.signIn() }
                } label: {
                    Label("Sign in with Google", systemImage: "person.crop.circle.badge.checkmark")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 32)

                if let error = authManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }

            Spacer()

            VStack(spacing: 4) {
                Text("How it works")
                    .font(.footnote.bold())
                Text("Add **alarm: 5m** (or **alarm: wakeup 1h**) to the description of any Google Calendar event. The app will automatically schedule a named alarm for that event.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
