import Vapor

/// [Errors](https://plaid.com/docs/api/#errors-overview)
public struct PlaidError: Error, Codable {
    public let type: ErrorType
    // TODO: Make an ErrorCode for every error_code
    public let code: String
    public let message: String
    public let displayMessage: String?
    public let httpCode: Int
    public let requestID: String

    private enum CodingKeys: String, CodingKey {
        case type = "error_type"
        case code = "error_code"
        case message = "error_message"
        case displayMessage = "display_message"
        case httpCode = "http_code"
        case requestID = "request_id"
    }
}

extension PlaidError {
    public enum ErrorType: String, Codable {
        case invalidRequest = "INVALID_REQUEST"
        case invalidInput = "INVALID_INPUT"
        case institutionError = "INSTITUTION_ERROR"
        case rateLimitExceeded = "RATE_LIMIT_EXCEEDED"
        case apiError = "API_ERROR"
        case itemError = "ITEM_ERROR"
        case assetReportError = "ASSET_REPORT_ERROR"
    }
}

extension PlaidError: Debuggable {
    public var identifier: String {
        return code
    }

    public var reason: String {
        return message
    }
}

/*

 Error codes:

 // Invalid Request
 "MISSING_FIELDS",
 "UNKNOWN_FIELDS",
 "INVALID_FIELD",
 "INVALID_BODY",
 "INVALID_HEADERS",
 "NOT_FOUND",
 "SANDBOX_ONLY"

 // Invalid Input
 "INVALID_API_KEYS",
 "UNAUTHORIZED_ENVIRONMENT",
 "INVALID_ACCESS_TOKEN",
 "INVALID_PUBLIC_TOKEN",
 "INVALID_PRODUCT",
 "INVALID_ACCOUNT_ID",
 "INVALID_INSTITUTION"

 // Rate limit exceeded
 "ADDITION_LIMIT",
 "AUTH_LIMIT",
 "TRANSACTIONS_LIMIT",
 "IDENTITY_LIMIT",
 "INCOME_LIMIT",
 "ITEM_GET_LIMIT",
 "RATE_LIMIT"

 // API Error
 "INTERNAL_SERVER_ERROR",
 "PLANNED_MAINTENANCE"

 // Item error
 "INVALID_CREDENTIALS",
 "INVALID_MFA",
 "INVALID_UPDATED_USERNAME",
 "ITEM_LOCKED",
 "ITEM_LOGIN_REQUIRED",
 "ITEM_NO_ERROR",
 "ITEM_NOT_SUPPORTED",
 "USER_SETUP_REQUIRED",
 "MFA_NOT_SUPPORTED",
 "NO_ACCOUNTS",
 "NO_AUTH_ACCOUNTS",
 "PRODUCT_NOT_READY",
 "PRODUCTS_NOT_SUPPORTED"

 // Institution error
 "INSTITUTION_DOWN",
 "INSTITUTION_NOT_RESPONDING",
 "INSTITUTION_NOT_AVAILABLE",
 "INSTITUTION_NO_LONGER_SUPPORTED"

 // ! Missing Asset Report Error !

 */
