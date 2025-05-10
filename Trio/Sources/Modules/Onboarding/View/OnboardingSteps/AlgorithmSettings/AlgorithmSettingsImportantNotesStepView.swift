//
//  AlgorithmSettingsImportantNotesStepView.swift
//  Trio
//
//  Created by Cengiz Deniz on 14.04.25
//
import SwiftUI

struct AlgorithmSettingsImportantNotesStepView: View {
    @Bindable var state: Onboarding.StateModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("A few important notes…")
                .padding(.horizontal)
                .font(.title3)
                .bold()

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Color.bgDarkBlue, Color.orange)
                        .symbolRenderingMode(.palette)
                    Text("Note to Tai users:").foregroundStyle(Color.orange)
                }.bold()
                Text(
                    "If you are an expert user and mix your own insulin, it’s essential to review DIA and Custom Peak Time of your insulin after the onboarding, as they are reset to defaults."
                )
                Text(
                    "Check the other additional \"advanced settings\" like the basal safety multipliers, as they are also reset to defaults during onboarding."
                )
                Text(
                    "You also have to redo the Tai specific algorithm settings in Settings > Algorithm > Extensions!"
                )
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.chart.opacity(0.65))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.orange, lineWidth: 2)
            )
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 10) {
                Text("Some helpful reminders:")
                    .font(.headline)
                    .padding(.bottom, 4)
                    .multilineTextAlignment(.leading)

                BulletPoint(
                    String(
                        localized: "Even if you’re an updating user, you’ll be guided through the algorithm settings configuration step-by-step."
                    )
                )
                BulletPoint(String(localized: "All additional \"advanced settings\" have been reset."))
                BulletPoint(
                    String(localized: "The duration of insulin action (DIA) is now reset to Trio’s new default of 10 hours.")
                )
                BulletPoint(
                    String(localized: "We strongly recommend not changing DIA — it’s essential to stable and safe operation.")
                )
            }
            .padding()
            .background(Color.chart.opacity(0.65))
            .cornerRadius(10)
        }
    }
}
