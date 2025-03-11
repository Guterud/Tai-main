import Combine
import Observation
import SwiftUI

extension B30Settings {
    final class StateModel: BaseStateModel<Provider> {
        @Injected() var settings: SettingsManager!

        var units: GlucoseUnits = .mgdL

        // Published properties for state binding
        @Published var enableB30: Bool = true
        @Published var B30iTimeStartBolus: Decimal = 1
        @Published var B30iTime: Decimal = 30
        @Published var B30iTimeTarget: Decimal = 80
        @Published var B30upperLimit: Decimal = 130
        @Published var B30upperDelta: Decimal = 8
        @Published var B30basalFactor: Decimal = 7

        override func subscribe() {
            units = settingsManager.settings.units

            // Ensure all preferences map to state properties correctly
            subscribePreferencesSetting(\.enableB30, on: $enableB30) { enableB30 = $0 }
            subscribePreferencesSetting(\.B30iTimeStartBolus, on: $B30iTimeStartBolus) { B30iTimeStartBolus = $0 }
            subscribePreferencesSetting(\.B30iTime, on: $B30iTime) { B30iTime = $0 }
            subscribePreferencesSetting(\.B30iTimeTarget, on: $B30iTimeTarget) { B30iTimeTarget = $0 }
            subscribePreferencesSetting(\.B30upperLimit, on: $B30upperLimit) { B30upperLimit = $0 }
            subscribePreferencesSetting(\.B30upperDelta, on: $B30upperDelta) { B30upperDelta = $0 }
            subscribePreferencesSetting(\.B30basalFactor, on: $B30basalFactor) { B30basalFactor = $0 }
        }
    }
}

extension B30Settings.StateModel: SettingsObserver {
    func settingsDidChange(_: TrioSettings) {
        units = settingsManager.settings.units
    }
}
