import Foundation

// MARK: - Garmin Data Type Settings

enum GarminDataType1: String, JSON, CaseIterable, Identifiable, Codable, Hashable {
    var id: String { rawValue }

    case cob
    case sensRatio

    var displayName: String {
        switch self {
        case .cob:
            return String(localized: "COB", comment: "")
        case .sensRatio:
            return String(localized: "Sensitivity Ratio", comment: "")
        }
    }
}

enum GarminDataType2: String, JSON, CaseIterable, Identifiable, Codable, Hashable {
    var id: String { rawValue }

    case tbr
    case eventualBG

    var displayName: String {
        switch self {
        case .tbr:
            return String(localized: "TBR (Temp Basal Rate)", comment: "")
        case .eventualBG:
            return String(localized: "Eventual BG", comment: "")
        }
    }
}

// MARK: - Garmin Watchface Setting

enum GarminWatchface: String, JSON, CaseIterable, Identifiable, Codable, Hashable {
    var id: String { rawValue }

    case trio
    case swissalpine

    var displayName: String {
        switch self {
        case .trio:
            return String(localized: "Trio original", comment: "")
        case .swissalpine:
            return String(localized: "Swissalpine xDrip+", comment: "")
        }
    }

    var watchfaceUUID: UUID? {
        switch self {
        case .trio:
            return UUID(uuidString: "EC3420F6-027D-49B3-B45F-D81D6D3ED90A")
        case .swissalpine:
            return UUID(uuidString: "5A643C13-D5A7-40D4-B809-84789FDF4A1F")
        }
    }

    var datafieldUUID: UUID? {
        switch self {
        case .trio:
            return UUID(uuidString: "71CF0982-CA41-42A5-8441-EA81D36056C3")
        case .swissalpine:
            return UUID(uuidString: "71CF0982-CA41-42A5-8441-EA81D36056C3")
        }
    }
}

// MARK: - Garmin Watchface Data Toggle

// struct to group related settings

struct GarminWatchSettings: Codable, Hashable {
    var watchface: GarminWatchface = .trio
    var dataType1: GarminDataType1 = .cob
    var dataType2: GarminDataType2 = .tbr
    var garminDisableWatchfaceData: Bool = false
}
