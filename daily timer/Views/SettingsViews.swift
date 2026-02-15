import SwiftUI

struct TimerSettingsView: View {
    @Binding var timeout: Int
    private let timeoutRange = 10...600
    
    private var clampedTimeout: Binding<Int> {
        Binding(
            get: { timeout },
            set: { timeout = min(max($0, timeoutRange.lowerBound), timeoutRange.upperBound) }
        )
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Timer Settings")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack(spacing: 12) {
                Text("Duration:")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                TextField("90", value: clampedTimeout, formatter: timeoutFormatter)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                
                Stepper("", value: clampedTimeout, in: timeoutRange, step: 5)
                    .labelsHidden()
                
                Text("seconds")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray.opacity(0.1))
            )
        }
    }
}

private let timeoutFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .none
    formatter.minimum = 10
    formatter.maximum = 600
    return formatter
}()

struct SessionInfoView: View {
    @ObservedObject var userManager: UserManager
    let timeout: Int
    
    private func calculateTotalTime() -> Int {
        let selectedCount = userManager.users.filter { $0.isSelected }.count
        let totalSeconds = selectedCount * timeout
        return Int(ceil(Double(totalSeconds) / 60.0))
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                    .frame(width: 16)
                Text("Teammates today: \(userManager.users.filter { $0.isSelected }.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                    .frame(width: 16)
                Text("Total time: \(calculateTotalTime()) minutes")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray.opacity(0.1))
        )
    }
}
