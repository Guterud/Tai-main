import SwiftUI

struct WatchConfigGarminDeviceListView: View {
    @ObservedObject var state: WatchConfig.StateModel

    @State private var shouldDisplayHint: Bool = false
    @State var hintDetent = PresentationDetent.large

    @Environment(\.colorScheme) var colorScheme
    @Environment(AppState.self) var appState

    /// Handles deletion of devices from the device list
    private func onDelete(offsets: IndexSet) {
        state.devices.remove(atOffsets: offsets)
        state.deleteGarminDevice()
    }

    var body: some View {
        Form {
            // MARK: - Device Configuration Section

            Section(
                header: Text("Garmin Configuration"),
                content: {
                    VStack {
                        Button {
                            state.selectGarminDevices()
                        } label: {
                            Text("Add Device")
                                .font(.title3)
                        }
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
                                    shouldDisplayHint.toggle()
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

            // MARK: - Device List Section

            if !state.devices.isEmpty {
                Section(
                    header: Text("Garmin Watch"),
                    content: {
                        List {
                            ForEach(state.devices, id: \.uuid) { device in
                                Text(device.friendlyName)
                            }
                            .onDelete(perform: onDelete)
                        }
                    }
                ).listRowBackground(Color.chart)
            }
        }
        .listSectionSpacing(sectionSpacing)
        .navigationTitle("Garmin Devices")
        .navigationBarTitleDisplayMode(.automatic)
        .scrollContentBackground(.hidden)
        .background(appState.trioBackgroundColor(for: colorScheme))
        .sheet(isPresented: $shouldDisplayHint) {
            SettingInputHintView(
                hintDetent: $hintDetent,
                shouldDisplayHint: $shouldDisplayHint,
                hintLabel: "Add Device",
                hintText: Text(
                    "Add Garmin Device to Trio. This happens via Garmin Connect. If you have multiple phones with Garmin Connect and the same Garmin device, you will run into connectivity issue between watch and phone depending of proximity of the phones, which might also affect your watchface function."
                ),
                sheetTitle: String(localized: "Help", comment: "Help sheet title")
            )
        }
    }
}
