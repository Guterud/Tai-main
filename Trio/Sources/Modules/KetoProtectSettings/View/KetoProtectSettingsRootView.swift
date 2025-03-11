import SwiftUI
import Swinject

extension KetoProtectSettings {
    struct RootView: BaseView {
        let resolver: Resolver
        @StateObject var state = StateModel()
        @State private var shouldDisplayHint: Bool = false
        @State var hintDetent = PresentationDetent.large
        @State var selectedVerboseHint: AnyView?
        @State var hintLabel: String?
        @State private var decimalPlaceholder: Decimal = 0.0
        @State private var booleanPlaceholder: Bool = false

        @Environment(\.colorScheme) var colorScheme
        @Environment(AppState.self) var appState

        var body: some View {
            List {
                Section(
                    header: Text("Enable"),
                    content: {
                        SettingInputSection(
                            decimalValue: .constant(0),
                            booleanValue: $state.ketoProtect,
                            shouldDisplayHint: $shouldDisplayHint,
                            selectedVerboseHint: Binding(
                                get: { selectedVerboseHint },
                                set: {
                                    selectedVerboseHint = $0.map { AnyView($0) }
                                    hintLabel = String(localized: "Activate KetoProtection", comment: "Enable KetoProtection")
                                }
                            ),
                            units: state.units,
                            type: .boolean,
                            label: String(localized: "Activate KetoProtection", comment: "Enable KetoProtection"),
                            miniHint: String(
                                localized:
                                "This feature enables a small safety Temp Basal Rate (TBR) to reduce ketoacidosis risk. Without the Variable Protection, the safety TBR is always applied."
                            ),
                            verboseHint: AnyView(
                                Text(
                                    String(
                                        localized:
                                        "Ketoacidosis protection will apply a small configurable Temp Basal Rate (TBR) instead of a Zero Temp. This is done either always or if certain conditions arise. For the later you need to enable the Variable KetoProtect Strategy.",
                                        comment: "KetoProtect VerboseHint"
                                    )
                                )
                            )
                        )
                    }
                )
                if state.ketoProtect {
                    Section(
                        header: Text("Strategy Definition"),
                        content: {
                            SettingInputSection(
                                decimalValue: .constant(0),
                                booleanValue: $state.variableKetoProtect,
                                shouldDisplayHint: $shouldDisplayHint,
                                selectedVerboseHint: Binding(
                                    get: { selectedVerboseHint },
                                    set: {
                                        selectedVerboseHint = $0.map { AnyView($0) }
                                        hintLabel = String(
                                            localized:
                                            "Variable Strategy",
                                            comment: "Variable Keto Protection"
                                        )
                                    }
                                ),
                                units: state.units,
                                type: .boolean,
                                label: String(localized: "Variable Strategy", comment: "Variable Keto Protection"),
                                miniHint: String(
                                    localized:
                                    "In addition to the Zero Temp the activiation of KetoProtect is dependant on IOB levels and last Active Insulin.",
                                    comment: "Variable protection miniHint"
                                ),
                                verboseHint: AnyView(
                                    Text(
                                        String(
                                            localized:
                                            "Activated: Safety TBR only kicks in when IOB is in neg. range below current Basal Rate and Active Insulin is also negative.",
                                            comment: "Variable Protection VerboseHint"
                                        )
                                    )
                                )
                            )
                        }
                    )
                    if state.variableKetoProtect {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(
                                "To understand the Variable Keto Protection Strategy, read up on IOB and active Insulin (activity):"
                            )

                            SwiftUI.Link(
                                "OpenAPS on IOB and Activity calculations",
                                destination: URL(
                                    string: "https://openaps.readthedocs.io/en/latest/docs/While%20You%20Wait%20For%20Gear/understanding-insulin-on-board-calculations.html?highlight=final%20note#understanding-insulin-on-board-iob-calculations"
                                )!
                            )
                            .accentColor(.blue)
                        }
                        .multilineTextAlignment(.leading)
                    }

                    Section(
                        header: Text("Settings for protective TBR"),
                        content: {
                            if !state.ketoProtectAbsolut {
                                SettingInputSection(
                                    decimalValue: $state.ketoProtectBasalPercent,
                                    booleanValue: .constant(false),
                                    shouldDisplayHint: $shouldDisplayHint,
                                    selectedVerboseHint: Binding(
                                        get: { selectedVerboseHint },
                                        set: {
                                            selectedVerboseHint = $0.map { AnyView($0) }
                                            hintLabel = String(localized: "Safety TBR in %", comment: "Safety TBR")
                                        }
                                    ),
                                    units: state.units,
                                    type: .decimal("ketoProtectBasalPercent"),
                                    label: String(localized: "Safety TBR in %", comment: "Safety TBR"),
                                    miniHint: String(
                                        localized:
                                        "Quantity of the small safety TBR in % of Profile BR, which is given to avoid ketoacidosis.",
                                        comment: "Safety TBR miniHint"
                                    ),
                                    verboseHint: AnyView(
                                        Text(
                                            String(
                                                localized:
                                                "Set the percentage of the current basal rate to apply for safety against ketoacidosis. Recommended between 10% - 20%",
                                                comment: "Safety TBR VerboseHint"
                                            )
                                        )
                                    )
                                )
                            }
                            SettingInputSection(
                                decimalValue: .constant(0),
                                booleanValue: $state.ketoProtectAbsolut,
                                shouldDisplayHint: $shouldDisplayHint,
                                selectedVerboseHint: Binding(
                                    get: { selectedVerboseHint },
                                    set: {
                                        selectedVerboseHint = $0.map { AnyView($0) }
                                        hintLabel = String(
                                            localized:
                                            "Enable Absolute Safety TBR",
                                            comment: "Enable Absolute TBR"
                                        )
                                    }
                                ),
                                units: state.units,
                                type: .boolean,
                                label: String(localized: "Enable Absolute Safety TBR", comment: "Enable Absolute TBR"),
                                miniHint: String(
                                    localized:
                                    "Specify an absolute TBR between 0 and 2 U/hr instead of a percentage of the current basal rate.",
                                    comment: "Enable Absolute Safety TBR miniHint"
                                ),
                                verboseHint: AnyView(
                                    Text(
                                        String(
                                            localized:
                                            "Absolute safety TBR provides a fixed insulin rate for safety, useful for consistent protection.",
                                            comment: "Absolute TBR VerboseHint"
                                        )
                                    )
                                )
                            )
                            if state.ketoProtectAbsolut {
                                SettingInputSection(
                                    decimalValue: $state.ketoProtectBasalAbsolut,
                                    booleanValue: .constant(false),
                                    shouldDisplayHint: $shouldDisplayHint,
                                    selectedVerboseHint: Binding(
                                        get: { selectedVerboseHint },
                                        set: {
                                            selectedVerboseHint = $0.map { AnyView($0) }
                                            hintLabel = String(localized: "Absolute Safety TBR", comment: "Absolute TBR")
                                        }
                                    ),
                                    units: state.units,
                                    type: .decimal("ketoProtectBasalAbsolut"),
                                    label: String(localized: "Absolute Safety TBR", comment: "Absolute TBR"),
                                    miniHint: String(
                                        localized:
                                        "Amount in U/hr of small safety TBR to avoid ketoacidosis.",
                                        comment: "Absolute Safety TBR miniHint"
                                    ),
                                    verboseHint: AnyView(
                                        Text(
                                            String(
                                                localized:
                                                "Specify a fixed basal rate for safety against ketoacidosis.",
                                                comment: "Absolute TBR VerboseHint"
                                            )
                                        )
                                    )
                                )
                            }
                        }
                    )

                } else {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(
                            "Ketoacidosis protection applies a small safety Temp Basal Rate continuously or under specific conditions (Variable Strategy) to reduce ketoacidosis risk."
                        )
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom)

                        Text(
                            "To understand the Variable Keto Protection Strategy, read up on IOB and active Insulin (activity):"
                        )
                        SwiftUI.Link(
                            "OpenAPS documentation",
                            destination: URL(
                                string: "https://openaps.readthedocs.io/en/latest/docs/While%20You%20Wait%20For%20Gear/understanding-insulin-on-board-calculations.html?highlight=final%20note#understanding-insulin-on-board-iob-calculations"
                            )!
                        )
                        .accentColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $shouldDisplayHint) {
                SettingInputHintView(
                    hintDetent: $hintDetent,
                    shouldDisplayHint: $shouldDisplayHint,
                    hintLabel: hintLabel ?? "",
                    hintText: selectedVerboseHint ?? AnyView(EmptyView()),
                    sheetTitle: "Help"
                )
            }
            .scrollContentBackground(.hidden)
            .background(appState.trioBackgroundColor(for: colorScheme))
            .onAppear(perform: configureView)
            .navigationTitle("KetoProtect Settings")
            .navigationBarTitleDisplayMode(.automatic)
        }
    }
}
