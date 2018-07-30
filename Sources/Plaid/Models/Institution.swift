import Vapor

public struct Institution: Content {
    public let institutionID: String
    public let name: String
    public let credentials: [Credential]
    public let products: [PlaidProduct]
    public let hasMFA: Bool
    public let mfa: [String]

    public struct Credential: Codable {
        public let label: String
        public let name: String
        public let type: String
    }
}
