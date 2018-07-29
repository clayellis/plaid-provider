import Foundation

public enum PlaidEnvironment {
    case sandbox
    case development
    case production

    var api: String {
        switch self {
        case .sandbox: return "https://sandbox.plaid.com"
        case .development: return "https://development.plaid.com"
        case .production: return "https://production.plaid.com"
        }
    }
}
