import Foundation
import Vapor

public struct PlaidItem: Content {
    public let availableProducts: [PlaidProduct]
    public let billedProducts: [PlaidProduct]
    public let error: String?
    public let institutionID: String
    public let itemID: String
    public let webhook: String

    enum CodingKeys: String, CodingKey {
        case availableProducts = "available_products"
        case billedProducts = "billed_products"
        case error
        case institutionID
        case itemID
        case webhook
    }
}
