import Vapor

public struct PlaidAccount: Content {
    public let accountID: String
    public let balances: [Balance]
    public let mask: String
    public let name: String
    public let officialName: String
    public let type: AccountType
    public let subtype: String

    public struct Balance: Content {
        public let available: Int?
        public let current: Int? // TODO: Might not be optional
        public let limit: Int? // TODO: Might not be optional
        public let isoCurrencyCode: String?
        public let unofficialCurrencyCode: String?
    }

    public enum AccountType: String, Codable {
        case brokerage
        case credit
        case depository
        case loan
        case mortgage
        case other
    }
}
