import Vapor

public struct PlaidInstitution: Content {
    public let institutionID: String
    public let name: String
    public let credentials: [Credential]
    public let products: [PlaidProduct]
    public let hasMFA: Bool
    public let mfa: [String]

    enum CodingKeys: String, CodingKey {
        case institutionID = "institution_id"
        case name
        case credentials
        case products
        case hasMFA = "has_mfa"
        case mfa
    }

    public struct Credential: Codable {
        public let label: String
        public let name: String
        public let type: String
    }
}
