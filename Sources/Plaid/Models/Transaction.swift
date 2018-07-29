import Vapor

/// See [Transactions](https://plaid.com/docs/api/#transactions)
public struct PlaidTransaction: Content {
    public let accountID: String
    public let amount: Float
    // TODO: Make currency code enum with iso, unofficial cases?
    public let isoCurrencyCode: String?
    public let unofficialCurrentCode: String?
    public let category: [String]
    public let categoryID: String
    public let date: Date
    public let location: Location
    public let name: String
    public let paymentMeta: Payment
    public let pending: Bool // TODO: Rename isPending?
    public let pendingTransactionID: String?
    public let accountOwner: String?
    public let transactionID: String
    public let transactionType: TransactionType

    public struct Location: Codable {
        public let address: String
        public let city: String
        public let state: String
        public let zip: String
        public let lat: Float?
        public let lon: Float?
    }

    public struct Payment: Codable {
        public let referenceNumber: String
        public let ppdID: String
        public let payeeName: String?
    }

    /// See [Transactions](https://plaid.com/docs/api/#transactions)
    public enum TransactionType: String, Codable {
        case digital
        case place
        case special
        case unresolved
    }
}
