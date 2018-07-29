import Vapor

public struct PlaidConfig: Service {
    public let clientID: String
    public let secret: String
    public let publicKey: String
    public let environment: PlaidEnvironment
    public let version: PlaidAPIVersion?

    public init(clientID: String,
                secret: String,
                publicKey: String,
                environment: PlaidEnvironment,
                version: PlaidAPIVersion? = nil) {
        self.clientID = clientID
        self.secret = secret
        self.publicKey = publicKey
        self.environment = environment
        self.version = version
    }
}
