import Combine
import Observation
import SwiftUI

extension KetoProtectSettings {
    final class StateModel: BaseStateModel<Provider> {
        @Injected() var settings: SettingsManager!

        var units: GlucoseUnits = .mgdL

        // Published properties for state binding
        @Published var ketoProtect: Bool = false
        @Published var variableKetoProtect: Bool = false
        @Published var ketoProtectBasalPercent: Decimal = 0.2
        @Published var ketoProtectAbsolut: Bool = false
        @Published var ketoProtectBasalAbsolut: Decimal = 0

        override func subscribe() {
            units = settingsManager.settings.units

            // Ensure all preferences map to state properties correctly
            subscribePreferencesSetting(\.ketoProtect, on: $ketoProtect) { ketoProtect = $0 }
            subscribePreferencesSetting(\.variableKetoProtect, on: $variableKetoProtect) { variableKetoProtect = $0 }
            subscribePreferencesSetting(\.ketoProtectBasalPercent, on: $ketoProtectBasalPercent) { ketoProtectBasalPercent = $0 }
            subscribePreferencesSetting(\.ketoProtectAbsolut, on: $ketoProtectAbsolut) { ketoProtectAbsolut = $0 }
            subscribePreferencesSetting(\.ketoProtectBasalAbsolut, on: $ketoProtectBasalAbsolut) { ketoProtectBasalAbsolut = $0 }
        }
    }
}

extension KetoProtectSettings.StateModel: SettingsObserver {
    func settingsDidChange(_: TrioSettings) {
        // React to settings changes if necessary
    }
}
