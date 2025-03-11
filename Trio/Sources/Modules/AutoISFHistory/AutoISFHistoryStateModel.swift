import Combine
import CoreData
import SwiftUI

extension Decimal {
    func rounded(to scale: Int) -> Decimal {
        var value = self // Create a mutable copy of self
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, .plain) // Perform rounding
        return result
    }
}

extension AutoISFHistory {
    final class StateModel: BaseStateModel<Provider> {
        @Published var selectedEndTime = Date() { didSet { Task { await createEntries() }}}
        @Published var selectedTimeIntervalIndex = 1 { didSet { Task { await createEntries() }}} // Default to 2 hours
        @Published var units: GlucoseUnits = .mgdL
        @Published var autoISFEntries: [autoISFHistory] = []
        @Published var timeIntervalOptions = [1, 2, 4, 8] // Hours
        private let context = CoreDataStack.shared.newTaskContext()

        override func subscribe() {
            units = settingsManager.settings.units
            Task { await createEntries() }
        }

        private func fetchedAutoISF() async -> [autoISFHistory] {
            let endTime = selectedEndTime
            let intervalHours = timeIntervalOptions[selectedTimeIntervalIndex]
            let startTime = Calendar.current.date(byAdding: .hour, value: -intervalHours, to: endTime)!

            let results = await CoreDataStack.shared.fetchEntitiesAsync(
                ofType: OrefDetermination.self,
                onContext: context,
                predicate: NSPredicate.determinationPeriod(from: startTime, to: endTime),
                key: "deliverAt",
                ascending: false,
                fetchLimit: intervalHours * 15
            )

            return await context.perform {
                guard let fetchedResults = results as? [OrefDetermination] else { return [] }
                return fetchedResults.compactMap { determination in
                    autoISFHistory(
                        smb: determination.smbToDeliver as? Decimal,
                        insulin_req: determination.insulinReq as? Decimal,
                        sensitivity_ratio: determination.sensitivityRatio as? Decimal,
                        tbr: determination.rate as? Decimal,
                        timestamp: determination.deliverAt,
                        bg: determination.glucose as? Decimal,
                        isf: determination.insulinSensitivity as? Decimal,
                        smb_ratio: determination.smbRatio as? Decimal,
                        dura_ratio: determination.duraISFratio as? Decimal,
                        bg_ratio: determination.bgISFratio as? Decimal,
                        pp_ratio: determination.ppISFratio as? Decimal,
                        acce_ratio: determination.acceISFratio as? Decimal,
                        autoISF_ratio: determination.autoISFratio as? Decimal,
                        iob_TH: determination.iobTH as? Decimal,
                        iob: (determination.iob as? Decimal)?.rounded(to: 2)
                    )
                }
            }
        }

        @MainActor func createEntries() async {
            autoISFEntries = await fetchedAutoISF()
        }
    }
}
