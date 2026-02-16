import SwiftUI

struct LiquidGlassShell<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
    }
}

struct TimerView: View {
    let currentUser: User
    let timeRemaining: Int
    let sessionUsers: [User]
    let currentUserID: UUID
    let showSessionProgressList: Bool
    let onNextUser: () -> Void
    
    var body: some View {
        LiquidGlassShell {
            VStack(spacing: 16) {
                VStack(spacing: 16) {
                    Text(currentUser.name)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    ZStack {
                        if timeRemaining == 0 {
                            Circle()
                                .fill(.red.opacity(0.12))
                                .frame(width: 84, height: 84)
                                .overlay(
                                    Text("🔥")
                                        .font(.system(size: 32))
                                        .scaleEffect(1.0)
                                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: timeRemaining)
                                )
                        } else {
                            Circle()
                                .fill(.thinMaterial)
                                .frame(width: 84, height: 84)
                                .overlay(
                                    Circle()
                                        .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                                )
                                .overlay(
                                    Text("\(timeRemaining)")
                                        .font(.system(size: 28, weight: .medium, design: .rounded))
                                        .foregroundColor(timeRemaining <= 10 ? .red : .primary)
                                        .monospacedDigit()
                                )
                        }
                    }
                }
                .frame(height: 152, alignment: .top)
                .padding(.top, 10)

                if showSessionProgressList {
                    SessionProgressBar(sessionUsers: sessionUsers, currentUserID: currentUserID)
                }
                
                AnimatedButton(action: onNextUser) {
                    HStack(spacing: 6) {
                        Text("Next")
                            .font(.system(size: 16, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.blue.gradient)
                    )
                }
                .padding(.bottom, 8)
            }
        }
    }
}

private struct SessionProgressBar: View {
    let sessionUsers: [User]
    let currentUserID: UUID

    private enum SegmentState {
        case done
        case current
        case upcoming
    }

    private func state(for user: User) -> SegmentState {
        guard let currentIndex = sessionUsers.firstIndex(where: { $0.id == currentUserID }),
              let userIndex = sessionUsers.firstIndex(where: { $0.id == user.id })
        else {
            return .upcoming
        }

        if userIndex < currentIndex { return .done }
        if userIndex == currentIndex { return .current }
        return .upcoming
    }

    private func segmentForeground(for state: SegmentState) -> Color {
        switch state {
        case .done:
            return .secondary.opacity(0.65)
        case .current:
            return .accentColor
        case .upcoming:
            return .secondary.opacity(0.85)
        }
    }

    private func segmentBackground(for state: SegmentState) -> Color {
        switch state {
        case .done:
            return .secondary.opacity(0.14)
        case .current:
            return .accentColor.opacity(0.22)
        case .upcoming:
            return .secondary.opacity(0.08)
        }
    }

    private var progressHeight: CGFloat {
        let rowHeight: CGFloat = 16
        let spacing: CGFloat = 4
        let total = CGFloat(sessionUsers.count) * rowHeight + CGFloat(max(sessionUsers.count - 1, 0)) * spacing + 6
        return min(max(total, 16), 220)
    }

    @ViewBuilder
    private func segmentView(for user: User) -> some View {
        let segmentState = state(for: user)
        HStack(spacing: 6) {
            Circle()
                .fill(segmentForeground(for: segmentState).opacity(segmentState == .current ? 0.9 : 0.55))
                .frame(width: 4, height: 4)
            Text(user.name)
                .font(.system(size: 10, weight: segmentState == .current ? .semibold : .regular))
                .lineLimit(1)
                .foregroundColor(segmentForeground(for: segmentState))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .frame(height: 16)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(segmentBackground(for: segmentState))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(.white.opacity(segmentState == .current ? 0.25 : 0.10), lineWidth: 0.5)
        )
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 4) {
                ForEach(sessionUsers) { user in
                    segmentView(for: user)
                }
            }
            .padding(.horizontal, 1)
            .padding(.vertical, 3)
        }
        .frame(height: progressHeight)
        .accessibilityIdentifier("sessionProgressBar")
    }
}

struct SessionEndView: View {
    let onFinish: () -> Void
    
    var body: some View {
        LiquidGlassShell {
            VStack(spacing: 16) {
                VStack(spacing: 16) {
                    Text("Done!")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Circle()
                        .fill(.thinMaterial)
                        .frame(width: 84, height: 84)
                        .overlay(
                            Circle()
                                .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                        )
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundColor(.green)
                                .symbolEffect(.bounce, value: true)
                        )
                }
                .frame(height: 152, alignment: .top)
                .padding(.top, 10)
                
                AnimatedButton(action: onFinish) {
                    HStack {
                        Text("Finish")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(.green.gradient)
                    )
                }
            }
        }
    }
}
