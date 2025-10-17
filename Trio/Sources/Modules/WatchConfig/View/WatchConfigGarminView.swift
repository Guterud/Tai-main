import SwiftUI

struct WatchConfigGarminView: View {
    @ObservedObject var state: WatchConfig.StateModel

    @Environment(\.colorScheme) var colorScheme
    @Environment(AppState.self) var appState

    var body: some View {
        if state.devices.isEmpty {
            // No devices connected - show device list/add view
            WatchConfigGarminDeviceListView(state: state)
        } else {
            // Devices connected - go directly to configuration with nav option to device list
            NavigationView {
                WatchConfigGarminAppConfigView(state: state)
                    .navigationTitle("Garmin")
                    .navigationBarTitleDisplayMode(.automatic)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            NavigationLink(destination: WatchConfigGarminDeviceListView(state: state)) {
                                Text("Devices")
                            }
                        }
                    }
            }
        }
    }
}
