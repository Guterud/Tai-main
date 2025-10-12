import Foundation
import SwiftUI

// MARK: - Trio Watchface Data Structure (String-based)

struct GarminTrioWatchState: Hashable, Equatable, Sendable, Encodable {
    var glucose: String?
    var trendRaw: String?
    var delta: String?
    var iob: String?
    var cob: String?
    var lastLoopDateInterval: UInt64?
    var eventualBGRaw: String?
    var isf: String?
    var sensRatio: String?

    static func == (lhs: GarminTrioWatchState, rhs: GarminTrioWatchState) -> Bool {
        lhs.glucose == rhs.glucose &&
            lhs.trendRaw == rhs.trendRaw &&
            lhs.delta == rhs.delta &&
            lhs.iob == rhs.iob &&
            lhs.cob == rhs.cob &&
            lhs.lastLoopDateInterval == rhs.lastLoopDateInterval &&
            lhs.eventualBGRaw == rhs.eventualBGRaw &&
            lhs.isf == rhs.isf &&
            lhs.sensRatio == rhs.sensRatio
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(glucose)
        hasher.combine(trendRaw)
        hasher.combine(delta)
        hasher.combine(iob)
        hasher.combine(cob)
        hasher.combine(lastLoopDateInterval)
        hasher.combine(eventualBGRaw)
        hasher.combine(isf)
        hasher.combine(sensRatio)
    }

    // Custom encoding to exclude nil values
    enum CodingKeys: String, CodingKey {
        case glucose
        case trendRaw
        case delta
        case iob
        case cob
        case lastLoopDateInterval
        case eventualBGRaw
        case isf
        case sensRatio
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(glucose, forKey: .glucose)
        try container.encodeIfPresent(trendRaw, forKey: .trendRaw)
        try container.encodeIfPresent(delta, forKey: .delta)
        try container.encodeIfPresent(iob, forKey: .iob)
        try container.encodeIfPresent(cob, forKey: .cob)
        try container.encodeIfPresent(lastLoopDateInterval, forKey: .lastLoopDateInterval)
        try container.encodeIfPresent(eventualBGRaw, forKey: .eventualBGRaw)
        try container.encodeIfPresent(isf, forKey: .isf)
        try container.encodeIfPresent(sensRatio, forKey: .sensRatio)
    }
}

// MARK: - SwissAlpine Watchface Data Structure (Numeric-based)

struct GarminSwissAlpineWatchState: Hashable, Equatable, Sendable, Encodable {
    var date: UInt64? // Timestamp of the determination data
    var sgv: Int16?
    var delta: Int16?
    var direction: String?
    var noise: Double?
    var units_hint: String?
    var iob: Double?
    var tbr: Int16?
    var cob: Double?
    var eventualBG: Int16?
    var isf: Int16?
    var sensRatio: Double?

    static func == (lhs: GarminSwissAlpineWatchState, rhs: GarminSwissAlpineWatchState) -> Bool {
        lhs.date == rhs.date &&
            lhs.sgv == rhs.sgv &&
            lhs.delta == rhs.delta &&
            lhs.direction == rhs.direction &&
            lhs.noise == rhs.noise &&
            lhs.units_hint == rhs.units_hint &&
            lhs.iob == rhs.iob &&
            lhs.tbr == rhs.tbr &&
            lhs.cob == rhs.cob &&
            lhs.eventualBG == rhs.eventualBG &&
            lhs.isf == rhs.isf &&
            lhs.sensRatio == rhs.sensRatio
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(sgv)
        hasher.combine(delta)
        hasher.combine(direction)
        hasher.combine(noise)
        hasher.combine(units_hint)
        hasher.combine(iob)
        hasher.combine(tbr)
        hasher.combine(cob)
        hasher.combine(eventualBG)
        hasher.combine(isf)
        hasher.combine(sensRatio)
    }

    // Custom encoding to exclude nil values
    enum CodingKeys: String, CodingKey {
        case date
        case sgv
        case delta
        case direction
        case noise
        case units_hint
        case iob
        case tbr
        case cob
        case eventualBG
        case isf
        case sensRatio
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(date, forKey: .date)
        try container.encodeIfPresent(sgv, forKey: .sgv)
        try container.encodeIfPresent(delta, forKey: .delta)
        try container.encodeIfPresent(direction, forKey: .direction)
        try container.encodeIfPresent(noise, forKey: .noise)
        try container.encodeIfPresent(units_hint, forKey: .units_hint)
        try container.encodeIfPresent(iob, forKey: .iob)
        try container.encodeIfPresent(tbr, forKey: .tbr)
        try container.encodeIfPresent(cob, forKey: .cob)
        try container.encodeIfPresent(eventualBG, forKey: .eventualBG)
        try container.encodeIfPresent(isf, forKey: .isf)
        try container.encodeIfPresent(sensRatio, forKey: .sensRatio)
    }
}
