import Vapor

public struct PlaidAccount: Content {
    public let accountID: String
    public let balances: Balances
    public let mask: String
    public let name: String
    public let officialName: String
    public let type: AccountType
    public let subtype: String

    enum CodingKeys: String, CodingKey {
        case accountID = "account_id"
        case balances
        case mask
        case name
        case officialName = "official_name"
        case type
        case subtype
    }

    public struct Balances: Content {
        public let available: Int?
        public let current: Int? // TODO: Might not be optional
        public let limit: Int? // TODO: Might not be optional
        public let isoCurrencyCode: String?
        public let unofficialCurrencyCode: String?

        enum CodingKeys: String, CodingKey {
            case available
            case current
            case limit
            case isoCurrencyCode = "iso_currency_code"
            case unofficialCurrencyCode = "unofficial_currency_code"
        }
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
