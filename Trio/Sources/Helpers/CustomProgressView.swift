import SwiftUI

struct CustomProgressView: View {
    @State var animate = false

    let text: String

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Text(text)
                .font(.system(.body, design: .rounded))
                .bold()
                .offset(x: 0, y: -25)

            RoundedRectangle(cornerRadius: 3)
                .stroke(Color(.systemGray5), lineWidth: 3)
                .frame(width: 250, height: 3)

            RoundedRectangle(cornerRadius: 3)
                .stroke(
                    TaiStyle.linearGradient(
                        startPoint: .trailing, // Orange on right
                        endPoint: .leading // Cyan on left
                    ),
                    lineWidth: 3
                )
                .frame(width: 250, height: 3)
                .mask(
                    RoundedRectangle(cornerRadius: 3)
                        .frame(width: 80, height: 3)
                        .offset(x: self.animate ? 180 : -180, y: 0)
                        .animation(
                            Animation.linear(duration: 1)
                                .repeatForever(autoreverses: false), value: UUID()
                        )
                )
        }
        .onAppear {
            self.animate.toggle()
        }
    }
}

enum ProgressText: CaseIterable {
    case updatingIOB
    case updatingCOB
    case updatingHistory
    case updatingTreatments
    case updatingIOBandCOB

    var displayName: String {
        switch self {
        case .updatingIOB:
            return String(localized: "Updating IOB ...", comment: "Status message for updating IOB")
        case .updatingCOB:

            return String(localized: "Updating COB ...", comment: "Status message for updating COB")
        case .updatingHistory:
            return String(localized: "Updating History ...", comment: "Status message for updating history")
        case .updatingTreatments:
            return String(localized: "Updating Treatments ...", comment: "Status message for updating treatments")
        case .updatingIOBandCOB:
            return String(localized: "Updating IOB and COB ...", comment: "Status message for updating both IOB and COB")
        }
    }
}
