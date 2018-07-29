import Foundation
import Vapor

public struct PlaidItem: Content {
    public let availableProducts: [PlaidProduct]
    public let billedProducts: [PlaidProduct]
    public let error: String?
    public let institutionID: String
    public let itemID: String
    public let webhook: URL
}
