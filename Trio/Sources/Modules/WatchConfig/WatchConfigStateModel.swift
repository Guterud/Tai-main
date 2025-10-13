import ConnectIQ
import SwiftUI

extension WatchConfig {
    final class StateModel: BaseStateModel<Provider> {
        @Injected() private var garmin: GarminManager!

        @Published var units: GlucoseUnits = .mgdL
        @Published var devices: [IQDevice] = []
        @Published var confirmBolusFaster = false
        @Published var garminWatchface: GarminWatchface = .trio
        @Published var garminDataType1: GarminDataType1 = .cob
        @Published var garminDataType2: GarminDataType2 = .tbr
        @Published var garminDisableWatchfaceData: Bool = false

        private(set) var preferences = Preferences()

        override func subscribe() {
            preferences = provider.preferences
            units = settingsManager.settings.units
            subscribeSetting(\.garminDataType1, on: $garminDataType1) { garminDataType1 = $0 }
            subscribeSetting(\.garminDataType2, on: $garminDataType2) { garminDataType2 = $0 }
            subscribeSetting(\.garminWatchface, on: $garminWatchface) { garminWatchface = $0 }
            subscribeSetting(\.garminDisableWatchfaceData, on: $garminDisableWatchfaceData) { garminDisableWatchfaceData = $0 }
            subscribeSetting(\.confirmBolusFaster, on: $confirmBolusFaster) { confirmBolusFaster = $0 }

            devices = garmin.devices
        }

        func selectGarminDevices() {
            garmin.selectDevices()
                .receive(on: DispatchQueue.main)
                .weakAssign(to: \.devices, on: self)
                .store(in: &lifetime)
        }

        func deleteGarminDevice() {
            garmin.updateDeviceList(devices)
        }
    }
}

extension WatchConfig.StateModel: SettingsObserver {
    func settingsDidChange(_: TrioSettings) {
        units = settingsManager.settings.units
    }
}
