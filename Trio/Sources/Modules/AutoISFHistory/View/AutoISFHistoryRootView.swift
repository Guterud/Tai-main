import CoreData
import Foundation
import SwiftDate
import SwiftUI
import Swinject

extension AutoISFHistory {
    struct RootView: BaseView {
        let resolver: Resolver

        @StateObject var state = StateModel()

        @Environment(\.horizontalSizeClass) var sizeClass
        @Environment(\.colorScheme) var colorScheme
        @Environment(AppState.self) var appState
        @Environment(\.managedObjectContext) var context

        @State private var selectedEndTime = Date()
        @State private var selectedTimeIntervalIndex = 1 // Default to 2 hours
        @State private var timeIntervalOptions = []
        @State private var autoISFResults: [AutoISFHistory] = [] // Holds the fetched results

        private var color: LinearGradient {
            colorScheme == .dark ? LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.011, green: 0.058, blue: 0.109),
                    Color(red: 0.03921568627, green: 0.1333333333, blue: 0.2156862745)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
                :
                LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.1)]), startPoint: .top, endPoint: .bottom)
        }

        private let itemFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .medium
            return formatter
        }()

        private var glucoseFormatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal

            if state.units == .mmolL {
                formatter.maximumFractionDigits = 1
                formatter.minimumFractionDigits = 1
                formatter.roundingMode = .halfUp
            } else {
                formatter.maximumFractionDigits = 0
            }
            return formatter
        }

        @ViewBuilder func historyISF() -> some View {
            autoISFview
        }

        var slots: CGFloat = 12
        var slotwidth: CGFloat = 1

        var body: some View {
            GeometryReader { geometry in
                VStack(alignment: .center) {
                    HStack {
                        CustomDateTimePicker(selection: $state.selectedEndTime, minuteInterval: 15)
                            .frame(height: 30) // Attempt to set a fixed height
                            .clipped() // Ensure it doesn't visually overflow this frame
                        Spacer()
                        Picker("", selection: $state.selectedTimeIntervalIndex) {
                            ForEach(0 ..< state.timeIntervalOptions.count, id: \.self) { index in
                                Text("\(state.timeIntervalOptions[index]) hours").tag(index)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    HStack(alignment: .lastTextBaseline) {
                        Spacer()
                        Text("ISF factors").foregroundColor(.uam)
                            .frame(width: 2 * slotwidth / slots * geometry.size.width, alignment: .center)
                        Text("Insulin").foregroundColor(.insulin)
                            .frame(width: 7 * slotwidth / slots * geometry.size.width, alignment: .center)
                    }
                    HStack(alignment: .bottom) {
                        Group {
                            Spacer()
                            Text("Time")
                            Text("BG").foregroundColor(.loopGreen)
                        }
                        Spacer()
                        Group {
                            Text("final").bold().foregroundColor(.uam)
                            Spacer()
                            Text("acce").foregroundColor(.loopYellow)
                            Spacer()
                            Text("bg").foregroundColor(.loopYellow)
                            Spacer()
                            Text("pp").foregroundColor(.loopYellow)
                            Spacer()
                            Text("dura").foregroundColor(.loopYellow)
                        }
                        Spacer()
                        Group {
                            Text("req.").foregroundColor(.secondary)
                            Spacer()
                            Text("SMB").foregroundColor(.insulin)
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("eff.")
                                Text("iobTH")
                            }.foregroundColor(.insulin)
                            Spacer()
                            Text("IOB").foregroundColor(.insulin)
                        }
                    }
                    .frame(width: 0.95 * geometry.size.width)
                    Divider()
                    historyISF()
                }
                .font(.caption)
                .onAppear(perform: configureView)
                .navigationBarTitle("")
                .navigationBarItems(leading: Button(action: state.hideModal) { Text("Close").foregroundColor(Color.tabBar) })
                .scrollContentBackground(.hidden)
                .background(appState.trioBackgroundColor(for: colorScheme))
            }
        }

        var timeFormatter: DateFormatter = {
            let formatter = DateFormatter()

            formatter.dateStyle = .none
            formatter.timeStyle = .short

            return formatter
        }()

        private func convertGlucose(_ value: Decimal, to units: GlucoseUnits) -> Double { // Use 'GlucoseUnits'
            switch units {
            case .mmolL:
                return Double(value) * 0.0555
            case .mgdL:
                return Double(value)
            }
        }

        var autoISFview: some View {
            GeometryReader { geometry in
                List {
                    ForEach(state.autoISFEntries, id: \.self) { entry in
                        HStack(spacing: 2) {
                            Text(timeFormatter.string(from: entry.timestamp ?? Date()))
                                .frame(width: 1.2 / slots * geometry.size.width, alignment: .leading)

                            let displayGlucose = convertGlucose(entry.bg ?? 0, to: state.units)
                            Text(glucoseFormatter.string(from: NSNumber(value: displayGlucose)) ?? "")
//                            Text("\(entry.bg ?? 0)")
                                .foregroundColor(.loopGreen)
                                .frame(width: 0.85 / slots * geometry.size.width, alignment: .center)
                            Group {
                                Text("\(entry.autoISF_ratio ?? 1)").foregroundColor(.uam)
                                Text("\(entry.acce_ratio ?? 1)").foregroundColor(.loopYellow)
                                Text("\(entry.bg_ratio ?? 1)").foregroundColor(.loopYellow)
                                Text("\(entry.pp_ratio ?? 1)").foregroundColor(.loopYellow)
                                Text("\(entry.dura_ratio ?? 1)").foregroundColor(.loopYellow)
                            }
                            .frame(width: 0.9 / slots * geometry.size.width, alignment: .trailing)
                            Group {
                                Text("\(entry.insulin_req ?? 0)").foregroundColor(.secondary)
                                Text("\(entry.smb ?? 0)").foregroundColor(.insulin)
                                Text("\(entry.iob_TH ?? 0)").foregroundColor(.insulin)
                                Text("\(entry.iob ?? 0)").foregroundColor(.insulin)
                            }
                            .frame(width: slotwidth / slots * geometry.size.width, alignment: .trailing)
                        }
                    }.listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
                .frame(maxWidth: .infinity)
                .listStyle(PlainListStyle())
            }.navigationBarTitle(Text("autoISF History"), displayMode: .inline)
        }
    }
}
