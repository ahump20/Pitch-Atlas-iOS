import Foundation

enum BlazeMood: String, CaseIterable {
    case idle
    case chasing
    case caught
    case sniffing
    case napping
    case concerned
    case still
    case hidden

    static func mood(for tab: AppTab, seriousFlow: Bool = false) -> BlazeMood {
        if seriousFlow { return .still }
        switch tab {
        case .atlas: return .sniffing
        case .index: return .hidden
        case .grips: return .hidden
        case .craftsmen: return .idle
        case .sources: return .still
        }
    }

    var imageName: String {
        switch self {
        case .idle: return "BlazeIdle"
        case .chasing: return "BlazeChasing"
        case .caught: return "BlazeCaught"
        case .sniffing: return "BlazeSniffing"
        case .napping: return "BlazeNapping"
        case .concerned: return "BlazeConcerned"
        case .still, .hidden: return "BlazeStill"
        }
    }
}
