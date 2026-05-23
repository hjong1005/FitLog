import SwiftUI

// ─────────────────────────────────────────────────────
// MARK: - Brand palette
// ─────────────────────────────────────────────────────
extension Color {
    /// #FF375F  — vivid crimson
    static let brand       = Color(red: 1.00, green: 0.216, blue: 0.373)
    /// #FF9F0A  — warm amber
    static let brandAmber  = Color(red: 1.00, green: 0.624, blue: 0.039)
    /// #30D158  — iOS green
    static let fitGreen    = Color(red: 0.188, green: 0.820, blue: 0.345)
    /// #0A84FF  — iOS blue
    static let fitBlue     = Color(red: 0.039, green: 0.518, blue: 1.000)

    // Surfaces
    static let appBG       = Color(red: 0.039, green: 0.039, blue: 0.039)  // #0A0A0A
    static let surface1    = Color(red: 0.110, green: 0.110, blue: 0.118)  // #1C1C1E
    static let surface2    = Color(red: 0.173, green: 0.173, blue: 0.180)  // #2C2C2E
    static let surface3    = Color(red: 0.227, green: 0.227, blue: 0.235)  // #3A3A3C

    // Text
    static let textPri     = Color.white
    static let textSec     = Color.white.opacity(0.80)
    static let textTer     = Color.white.opacity(0.55)
}

// ─────────────────────────────────────────────────────
// MARK: - Corner radii
// ─────────────────────────────────────────────────────
extension CGFloat {
    static let rSM: CGFloat = 10
    static let rMD: CGFloat = 14
    static let rLG: CGFloat = 18
}

// ─────────────────────────────────────────────────────
// MARK: - Reusable components
// ─────────────────────────────────────────────────────

/// Small coloured badge pill
struct Pill: View {
    let text: String
    var color: Color = .brand
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .cornerRadius(7)
    }
}

/// Square stat tile — count centred, label below
struct StatTile: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.textPri)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.textTer)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(Color.surface1)
        .cornerRadius(.rMD)
    }
}

/// Compact workout card for lists
struct WorkoutCard: View {
    let workout: WorkoutRecord
    private let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE, d MMM yyyy"; return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(fmt.string(from: workout.wrappedDate))
                .font(.system(size: 11))
                .foregroundColor(.textTer)

            HStack(alignment: .center) {
                Text(workout.wrappedName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPri)
                Spacer()
                Pill(text: "\(workout.exercisesArray.count) exercises")
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textTer)
            }

            Text("\(workout.totalSets) total sets")
                .font(.system(size: 12))
                .foregroundColor(.textSec)
        }
        .padding(14)
        .background(Color.surface1)
        .cornerRadius(.rMD)
    }
}

// ─────────────────────────────────────────────────────
// MARK: - Double formatting helper
// ─────────────────────────────────────────────────────
extension Double {
    var neatString: String {
        truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(self))
            : String(format: "%.1f", self)
    }
}
