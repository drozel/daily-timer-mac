import SwiftUI

struct MainView: View {
    @ObservedObject var userManager: UserManager
    @Binding var timeout: Int
    let onStartSession: () -> Void
    
    var body: some View {
        VStack(spacing: 18) {
            UserListView(userManager: userManager)
            TimerSettingsView(timeout: $timeout)
            SessionInfoView(userManager: userManager, timeout: timeout)
            ActionButtonsView(
                userManager: userManager,
                onStartSession: onStartSession
            )
        }
        .padding(20)
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
