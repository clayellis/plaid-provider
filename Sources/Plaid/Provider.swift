import Vapor

public final class PlaidProvider: Provider {
    public static let repositoryName = "plaid-provider"

    public init() {}

    public func didBoot(_ container: Container) throws -> Future<Void> {
        return .done(on: container)
    }

    public func register(_ services: inout Services) throws {
        services.register { container -> PlaidClient in
            try PlaidClient(client: container.make(), config: container.make())
        }
    }
}
