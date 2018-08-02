import Vapor

public struct PlaidConfig: Service {
    public let clientID: String
    public let secret: String
    public let publicKey: String
    public let environment: PlaidEnvironment
    public let version: PlaidAPIVersion?
    public let clientLoggingOptions: ClientLoggingOptions

    public init(clientID: String,
                secret: String,
                publicKey: String,
                environment: PlaidEnvironment,
                version: PlaidAPIVersion? = nil,
                clientLoggingOptions: ClientLoggingOptions = []) {
        self.clientID = clientID
        self.secret = secret
        self.publicKey = publicKey
        self.environment = environment
        self.version = version
        self.clientLoggingOptions = clientLoggingOptions
    }

    public struct ClientLoggingOptions: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let logResponses = ClientLoggingOptions(rawValue: 1 << 0)
        public static let logRequests = ClientLoggingOptions(rawValue: 1 << 1)
    }
}
