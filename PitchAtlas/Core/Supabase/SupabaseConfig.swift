import Foundation
import Supabase

enum SupabaseConfig {
    static let projectURL = URL(string: "https://cloeoulvrrfcbitrjpso.supabase.co")!
    static let publishableKey = "sb_publishable_jMuBalGcB-qEBIVAYegthg_0Rr4pUgT"
    static let authRedirectURL = URL(string: "pitchatlas://auth-callback")!

    static var functionsURL: URL {
        projectURL.appendingPathComponent("functions/v1")
    }

    static func makeClient() -> SupabaseClient {
        SupabaseClient(supabaseURL: projectURL, supabaseKey: publishableKey)
    }
}
