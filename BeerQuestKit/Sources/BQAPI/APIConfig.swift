import Foundation

/// Zugangsdaten fuer Supabase. Im Client liegt ausschliesslich der
/// **Anon Key** - er ist oeffentlich und ausschliesslich durch RLS
/// abgesichert. Der Service-Role-Key gehoert niemals in die App.
///
/// Werte kommen aus `Config.xcconfig` (nicht eingecheckt) ueber die
/// Info.plist. Siehe `docs/SETUP.md`.
public struct APIConfig: Sendable {
    public let url: URL
    public let anonKey: String

    public init(url: URL, anonKey: String) {
        self.url = url
        self.anonKey = anonKey
    }

    public enum ConfigError: Error, CustomStringConvertible {
        case missing(String)

        public var description: String {
            switch self {
            case .missing(let key):
                return "Info.plist key '\(key)' fehlt. Siehe docs/SETUP.md."
            }
        }
    }

    public static func fromBundle(_ bundle: Bundle = .main) throws -> APIConfig {
        guard let urlString = bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let url = URL(string: urlString), !urlString.isEmpty else {
            throw ConfigError.missing("SUPABASE_URL")
        }
        guard let key = bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty else {
            throw ConfigError.missing("SUPABASE_ANON_KEY")
        }
        return APIConfig(url: url, anonKey: key)
    }
}
