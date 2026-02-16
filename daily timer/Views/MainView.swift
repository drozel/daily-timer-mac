import SwiftUI

struct MainView: View {
    @ObservedObject var userManager: UserManager
    @Binding var timeout: Int
    @Binding var showSessionProgressList: Bool
    let onStartSession: () -> Void
    
    var body: some View {
        VStack(spacing: 18) {
            UserListView(userManager: userManager)
            TimerSettingsView(timeout: $timeout)
            TimerPresentationSettingsView(showSessionProgressList: $showSessionProgressList)
            SessionInfoView(userManager: userManager, timeout: timeout)
            ActionButtonsView(
                userManager: userManager,
                onStartSession: onStartSession
            )
        }
        .padding(20)
    }
}

struct TimerPresentationSettingsView: View {
    @Binding var showSessionProgressList: Bool

    var body: some View {
        HStack {
            Toggle("Show session progress list", isOn: $showSessionProgressList)
                .font(.system(size: 13, weight: .medium))
                .toggleStyle(.switch)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray.opacity(0.1))
        )
    }
}

struct ActionButtonsView: View {
    let userManager: UserManager
    let onStartSession: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            // START Button
            AnimatedButton(
                action: onStartSession,
                isEnabled: !userManager.users.filter { $0.isSelected }.isEmpty
            ) {
                Text("START")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(.blue)
                    )
            }
            Spacer()
        }
        .padding(.bottom, 8)
    }
}
