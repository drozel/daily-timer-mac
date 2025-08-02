import SwiftUI

struct TimerView: View {
    let currentUser: User
    let timeRemaining: Int
    let onNextUser: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // User name with refined typography
            Text(currentUser.name)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            ZStack {
                if timeRemaining == 0 {
                    Circle()
                        .fill(.red.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text("🔥")
                                .font(.system(size: 32))
                                .scaleEffect(1.0)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: timeRemaining)
                        )
                } else {
                    // Timer with circular progress background
                    Circle()
                        .fill(.gray.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text("\(timeRemaining)")
                                .font(.system(size: 28, weight: .medium, design: .rounded))
                                .foregroundColor(timeRemaining <= 10 ? .red : .primary)
                                .monospacedDigit()
                        )
                }
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
                        .fill(.blue)
                )
            }
        }
        .padding(20)
    }
}

struct SessionEndView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
                .symbolEffect(.bounce, value: true)
            
            Text("Done!")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            AnimatedButton(action: { exit(0) }) {
                HStack {
                    Text("Finish")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.green)
                )
            }
        }
        .padding(20)
    }
}
