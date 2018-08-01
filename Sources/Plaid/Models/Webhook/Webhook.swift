import Foundation
import Vapor

// NOTE: These types are provided as a convenience which consumers of this package
// may choose to use in their own servers when parsing webhooks. The PlaidClient will
// never return these types.

/// A generic webhook type that can represent any webhook.
public struct PlaidWebhook: Content {
    public let webhookType: WebhookType
    public let webhookCode: WebhookCode
    public let error: WebhookError?
    public let itemID: String?
    public let newTransactions: Int?
    public let removedTransactions: [String]?
    public let newWebhook: String?
    public let assetReportID: String?

    private enum CodingKeys: String, CodingKey {
        case webhookType = "webhook_type"
        case webhookCode = "webhook_code"
        case error
        case itemID = "item_id"
        case newTransactions = "new_transactions"
        case removedTransactions = "removed_transactions"
        case newWebhook = "new_webhook"
        case assetReportID = "asset_report_id"
    }
}

extension PlaidWebhook {

    /// Webhook types.
    public enum WebhookType: String, Codable {
        case transactions = "TRANSACTIONS"
        case item = "ITEM"
        case income = "INCOME"
        case assets = "ASSETS"
    }
}

extension PlaidWebhook {

    /// Webhook codes.
    public enum WebhookCode: String, Codable {
        // Transactions
        case initialUpdate = "INITIAL_UPDATE"
        case historicalUpdate = "HISTORICAL_UPDATE"
        case defaultUpdate = "DEFAULT_UPDATE"
        case transactionsRemoved = "TRANSACTIONS_REMOVED"

        // Item
        case webhookUpdateAcknowledged = "WEBHOOK_UPDATE_ACKNOWLEDGED"

        // Income & Assets
        case productReady = "PRODUCT_READY"

        // Generic
        case error = "ERROR"
    }
}

extension PlaidWebhook {

    /// Webhook errors.
    public struct WebhookError: Codable {
        public let displayMessage: String
        public let errorCode: String
        public let errorMessage: String
        public let errorType: String
        public let status: Int?

        private enum CodingKeys: String, CodingKey {
            case displayMessage = "display_message"
            case errorCode = "error_code"
            case errorMessage = "error_message"
            case errorType = "error_type"
            case status
        }
    }
}

//// MARK: - Webhooks
//
//internal protocol WebhookContent: Content {
//    var webhookType: PlaidWebhook.WebhookType { get }
//    var webhookCode: PlaidWebhook.WebhookCode { get }
//    var error: PlaidWebhook.WebhookError? { get }
//}
//
//internal protocol ItemWebhookContent: WebhookContent {
//    var itemID: String { get }
//}
//
//// MARK: - Transactions
//
//extension PlaidWebhook {
//
//    public typealias InitialTransaction = Transaction
//    public typealias HistoricalTransaction = Transaction
//    public typealias DefaultTransaction = Transaction
//
//    public struct Transaction: ItemWebhookContent {
//        public let webhookType: PlaidWebhook.WebhookType
//        public let webhookCode: PlaidWebhook.WebhookCode
//        public let error: PlaidWebhook.WebhookError?
//        public let itemID: String
//        public let newTransactions: Int
//    }
//
//    public struct RemovedTransaction: ItemWebhookContent {
//        public let webhookType: PlaidWebhook.WebhookType
//        public let webhookCode: PlaidWebhook.WebhookCode
//        public let error: PlaidWebhook.WebhookError?
//        public let itemID: String
//        public let removedTransactions: [String]
//    }
//}
//
//// MARK: - Item
//
//extension PlaidWebhook {
//
//
//}
//
//// MARK: - Coding Keys
