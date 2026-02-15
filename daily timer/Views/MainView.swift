import SwiftUI

struct MainView: View {
    @ObservedObject var userManager: UserManager
    @Binding var timeout: Int
    let onStartSession: () -> Void
    let onEditUsers: () -> Void
    
    var body: some View {
        VStack(spacing: 18) {
            UserListView(userManager: userManager)
            TimerSettingsView(timeout: $timeout)
            SessionInfoView(userManager: userManager, timeout: timeout)
            ActionButtonsView(
                userManager: userManager,
                onStartSession: onStartSession,
                onEditUsers: onEditUsers
            )
        }
        .padding(20)
    }
}

struct ActionButtonsView: View {
    let userManager: UserManager
    let onStartSession: () -> Void
    let onEditUsers: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Edit Users Button
            AnimatedButton(action: onEditUsers) {
                Text("Edit Users")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(.blue, lineWidth: 1.5)
                    )
            }
            
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
        }
        .padding(.bottom, 8)
    }
}
