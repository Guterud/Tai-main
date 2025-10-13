import SwiftUI

struct WatchConfigGarminView: View {
    @ObservedObject var state: WatchConfig.StateModel

    @State private var shouldDisplayHint1: Bool = false
    @State private var shouldDisplayHint2: Bool = false
    @State private var shouldDisplayHint3: Bool = false
    @State private var shouldDisplayHint4: Bool = false
    @State var hintDetent = PresentationDetent.large
    @State var selectedVerboseHint: AnyView?
    @State var hintLabel: String?
    @State private var decimalPlaceholder: Decimal = 0.0
    @State private var booleanPlaceholder: Bool = false

    @Environment(\.colorScheme) var colorScheme
    @Environment(AppState.self) var appState

    private func onDelete(offsets: IndexSet) {
        state.devices.remove(atOffsets: offsets)
        state.deleteGarminDevice()
    }

    var body: some View {
        List {
            Section(
                header: Text("Garmin Configuration"),
                content:
                {
                    VStack {
                        Button {
                            state.selectGarminDevices()
                        } label: {
                            Text("Add Device")
                                .font(.title3) }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .buttonStyle(.bordered)

                        HStack(alignment: .center) {
                            Text(
                                "Add a Garmin Device to Trio."
                            )
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                            Spacer()
                            Button(
                                action: {
                                    shouldDisplayHint1.toggle()
                                },
                                label: {
                                    HStack {
                                        Image(systemName: "questionmark.circle")
                                    }
                                }
                            ).buttonStyle(BorderlessButtonStyle())
                        }.padding(.top)
                    }.padding(.vertical)
                }
            ).listRowBackground(Color.chart)

            Section(
                header: Text("Garmin Watch Settings"),
                content: {
                    VStack {
                        Picker(
                            selection: $state.garminWatchface,
                            label: Text("Watchface").multilineTextAlignment(.leading)
                        ) {
                            ForEach(GarminWatchface.allCases) { selection in
                                Text(selection.displayName).tag(selection)
                            }
                        }.padding(.top)
                        HStack(alignment: .center) {
                            Text(
                                "Choose which watchface/datafield to support."
                            )
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                            Spacer()
                            Button(
                                action: {
                                    shouldDisplayHint2.toggle()
                                },
                                label: {
                                    HStack {
                                        Image(systemName: "questionmark.circle")
                                    }
                                }
                            ).buttonStyle(BorderlessButtonStyle())
                        }.padding(.top)
                    }.padding(.vertical)
                }
            ).listRowBackground(Color.chart)
            Section(
                content: {
                    VStack {
                        Picker(
                            selection: $state.garminDataType1,
                            label: Text("Data Field 1").multilineTextAlignment(.leading)
                        ) {
                            ForEach(GarminDataType1.allCases) { selection in
                                Text(selection.displayName).tag(selection)
                            }
                        }.padding(.top)
                        HStack(alignment: .center) {
                            Text(
                                "Choose between COB and Sensitivity Ratio on Garmin device."
                            )
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                            Spacer()
                            Button(
                                action: {
                                    shouldDisplayHint3.toggle()
                                },
                                label: {
                                    HStack {
                                        Image(systemName: "questionmark.circle")
                                    }
                                }
                            ).buttonStyle(BorderlessButtonStyle())
                        }.padding(.top)
                    }.padding(.vertical)
                }
            ).listRowBackground(Color.chart)
            if state.garminWatchface == .swissalpine {
                Section(
                    content: {
                        VStack {
                            Picker(
                                selection: $state.garminDataType2,
                                label: Text("Data Field 2").multilineTextAlignment(.leading)
                            ) {
                                ForEach(GarminDataType2.allCases) { selection in
                                    Text(selection.displayName).tag(selection)
                                }
                            }.padding(.top)
                            HStack(alignment: .center) {
                                Text(
                                    "Choose between TBR and Eventual BG on Garmin device."
                                )
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                                Spacer()
                                Button(
                                    action: {
                                        shouldDisplayHint4.toggle()
                                    },
                                    label: {
                                        HStack {
                                            Image(systemName: "questionmark.circle")
                                        }
                                    }
                                ).buttonStyle(BorderlessButtonStyle())
                            }.padding(.top)
                        }.padding(.vertical)
                    }
                ).listRowBackground(Color.chart)
            }
        }
        .listSectionSpacing(sectionSpacing)
        .sheet(isPresented: $shouldDisplayHint1) {
            SettingInputHintView(
                hintDetent: $hintDetent,
                shouldDisplayHint: $shouldDisplayHint1,
                hintLabel: "Add Device",
                hintText: Text(
                    "Add Garmin Device to Trio. Please look at the docs to see which devices are supported."
                ),
                sheetTitle: String(localized: "Help", comment: "Help sheet title")
            )
        }
        .sheet(isPresented: $shouldDisplayHint2) {
            SettingInputHintView(
                hintDetent: $hintDetent,
                shouldDisplayHint: $shouldDisplayHint2,
                hintLabel: "Choose Garmin App support.",
                hintText: Text(
                    "Choose which watchface and datafield combination on your Garmin device you wish to provide data for. Trying to use watchfaces and data fields of different developers will not work. Both must use the same data structure provided by Trio.\n\n" +
                        "Important: If you want to use a different watchface on your Garmin device that has no data requirement from this app, change the Watchface option to Disabled! Otherwise you will not be able to get current data once you re-enable the Trio watchface and you will have to re-install it on your Garmin device."
                ),
                sheetTitle: String(localized: "Help", comment: "Help sheet title")
            )
        }
        .sheet(isPresented: $shouldDisplayHint3) {
            SettingInputHintView(
                hintDetent: $hintDetent,
                shouldDisplayHint: $shouldDisplayHint3,
                hintLabel: "Choose data support",
                hintText: Text(
                    "Choose which data type, along BG and IOB etc., you want to show on your Garmin device. That data type will be shown both on watchface and datafield"
                ),
                sheetTitle: String(localized: "Help", comment: "Help sheet title")
            )
        }
        .sheet(isPresented: $shouldDisplayHint4) {
            SettingInputHintView(
                hintDetent: $hintDetent,
                shouldDisplayHint: $shouldDisplayHint4,
                hintLabel: "Choose data support",
                hintText: Text(
                    "Choose which data type, along BG and IOB etc., you want to show on your Garmin device. That data type will be shown both on watchface and datafield"
                ),
                sheetTitle: String(localized: "Help", comment: "Help sheet title")
            )
        }
        .navigationTitle("Garmin")
        .navigationBarTitleDisplayMode(.automatic)
        .scrollContentBackground(.hidden)
        .background(appState.trioBackgroundColor(for: colorScheme))
    }
}
