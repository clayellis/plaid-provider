import Vapor

/// Errors thrown by the PlaidClient.
public enum PlaidClientError: Error {
    case responseMissingData
    case parameterEncodingError(Error?)
    case responseDecodingError(Error)
    case errorResponseDecodingError(Error)
    case plaidError(PlaidError)
}

extension PlaidClientError: Debuggable {
    public var identifier: String {
        switch self {
        case .responseMissingData: return "responseMissingData"
        case .parameterEncodingError: return "parameterEncodingError"
        case .responseDecodingError: return "responseDecodingError"
        case .errorResponseDecodingError: return "errorResponseDecodingError"
        case .plaidError(let error): return "plaidError:\(error.code)"
        }
    }

    public var reason: String {
        switch self {
        case .responseMissingData:
            return "API response was missing data."

        case .parameterEncodingError(let error):
            let prefix = "Failed to encode parameters"
            if let error = error {
                return prefix + ": \(error.localizedDescription)"
            } else {
                return prefix + "."
            }

        case .responseDecodingError(let error):
            return "Failed to decode API response: \(error.localizedDescription)"

        case .errorResponseDecodingError(let error):
            return "Failed to decode API error response: \(error.localizedDescription)"

        case .plaidError(let error):
            return "Plaid API Error: \(error)"
        }
    }
}
