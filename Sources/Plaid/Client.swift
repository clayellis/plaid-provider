import Vapor

private protocol PlaidResponse: Content {
    var requestID: String { get }
}

public final class PlaidClient: Service {
    let httpClient: Client
    let config: PlaidConfig

    public init(client: Client, config: PlaidConfig) {
        self.httpClient = client
        self.config = config
    }

    private lazy var api = config.environment.api

    private lazy var defaultHeaders: HTTPHeaders = {
        var headers = HTTPHeaders()
        if let version = config.version {
            headers.add(name: "Plaid-Version", value: version.versionString)
            headers.add(name: .userAgent, value: "Plaid Vapor v\(_version)")
        }
        return headers
    }()

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-DD"
        return formatter
    }()

    private lazy var jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
//        encoder.keyEncodingStrategy = .custom({ keys -> CodingKey in
//            let key = keys.last!.stringValue
//            let converted = convertToSnakeCase(key, keepingWholeWords: ["IDs"])
//            return StringKey(converted)
//        })
        return encoder
    }()

    private lazy var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
//        decoder.keyDecodingStrategy = .custom({ keys -> CodingKey in
//            let key = keys.last!.stringValue
//            let converted = convertFromSnakeCase(key, uppercasing: ["id", "mfa"])
//            return StringKey(converted)
//        })
        return decoder
    }()

    private enum Authentication {
        case clientIDSecretPair
        case publicKey
        case none
    }

    private func request<Parameters, Response>(
        // TODO: Consider making path accept variadic String path components: String...
//        path: String...,
        path: String,
        parameters: Parameters?,
        expectedResponse: Response.Type = Response.self,
        authentication: Authentication = .clientIDSecretPair
    ) -> Future<Response> where Parameters: Content, Response: Content {
//        let url = api + "/" + path.joined(separator: "/")
        return httpClient.post(api + path, headers: defaultHeaders) { request in
            guard let parameters = parameters else {
                return
            }

            /// Represents the body of the request that is safe to log.
            /// Any injected authentication is stripped.
            var loggableBody: HTTPBody?

            switch authentication {
            case .none:

                do {
                    try request.content.encode(json: parameters, using: jsonEncoder)
                    loggableBody = request.http.body
                } catch {
                    throw PlaidClientError.parameterEncodingError(error)
                }

            case .clientIDSecretPair, .publicKey:

                // Inject keys into the encoded request
                do {
                    // Encode the parameters
                    let encodedParameters = try self.jsonEncoder.encode(parameters)

                    // Set the loggableBody before authentication is injected
                    if config.clientLoggingOptions.contains(.logRequests) {
                        loggableBody = HTTPBody(data: encodedParameters)
                    }

                    // Create a dictionary representation of the encoded parameters
                    let encodedObject = try JSONSerialization.jsonObject(with: encodedParameters, options: .mutableContainers)
                    guard var encodedDictionary = encodedObject as? [String: Any] else {
                        throw PlaidClientError.parameterEncodingError(nil)
                    }

                    // Inject the correct authentication
                    switch authentication {
                    case .clientIDSecretPair:
                        encodedDictionary["client_id"] = self.config.clientID
                        encodedDictionary["secret"] = self.config.secret
                    case .publicKey:
                        encodedDictionary["public_key"] = self.config.publicKey
                    case .none:
                        // Shouldn't get here
                        break
                    }

                    // Re-encode the data
                    let encodedData = try JSONSerialization.data(withJSONObject: encodedDictionary, options: [])

                    // Set the body to the re-encoded data
                    request.http.contentType = .json
                    request.http.body = HTTPBody(data: encodedData)

                } catch {
                    throw PlaidClientError.parameterEncodingError(error)
                }
            }

            if config.clientLoggingOptions.contains(.logRequests) {
                let logger = try request.make(Logger.self)
                var message = ["Outgoing PlaidClient Request:"]
                message.append(request.http.method.string)
                message.append(request.http.url.absoluteString)

                if let body = loggableBody {
                    message.append(body.description)
                }

                logger.verbose(message.joined(separator: " "))
            }

        }.map { response in
            guard let data = response.http.body.data else {
                throw PlaidClientError.responseMissingData
            }

            let statusCode = Int(response.http.status.code)

            if self.config.clientLoggingOptions.contains(.logResponses) {
                let logger = try response.make(Logger.self)
                var message = ["Incoming PlaidClient Response:"]
                message.append("(\(statusCode))")
                if let bodyString = data.prettyPrinted() {
                    message.append("\n" + bodyString)
                }
                logger.verbose(message.joined(separator: " "))
            }

            switch statusCode {
            case 200:
                do {
                    return try self.jsonDecoder.decode(expectedResponse, from: data)
                } catch {
                    throw PlaidClientError.responseDecodingError(error)
                }
            default:
                let plaidError: PlaidError
                do {
                    // Use an out-of-box JSONDecoder since PlaidError specifies its own coding keys
                    let errorDecoder = JSONDecoder()
                    plaidError = try errorDecoder.decode(PlaidError.self, from: data)
                } catch {
                    throw PlaidClientError.errorResponseDecodingError(error)
                }

                throw PlaidClientError.plaidError(plaidError)
            }
        }
    }

    private func requestWithAccessToken<Response>(
        _ accessToken: String,
        path: String,
        expectedResponse: Response.Type = Response.self
    ) -> Future<Response> where Response: Content {
        return request(
            path: path,
            parameters: AccessTokenParameters(accessToken: accessToken))
    }
}

// MARK: - Common Parameters

extension PlaidClient {
    private struct AccessTokenParameters: Content {
        let accessToken: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
        }
    }

    /// Used when a parameter type is required, but the parameters are nil.
    private struct NilParameters: Content {
        private init() {}
        static var `nil`: NilParameters? { return nil }
    }

    /// Parameters used in `getAccountBalances` and `getAuth`.
    private struct AccountParameters: Content {
        let accessToken: String
        let options: Options?

        struct Options: Codable {
            let accountIDs: [String]

            enum CodingKeys: String, CodingKey {
                case accountIDs = "account_ids"
            }
        }

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case options
        }

        init(accessToken: String, accountIDs: [String]) {
            self.accessToken = accessToken
            self.options = accountIDs.isEmpty ? nil : Options(accountIDs: accountIDs)
        }
    }
}

// MARK: - Requests

extension PlaidClient {

    // MARK: - Create Public Token (/item/public_token/create)

    public struct CreatePublicTokenResponse: PlaidResponse {
        public let publicToken: String
        public let requestID: String

        enum CodingKeys: String, CodingKey {
            case publicToken = "public_token"
            case requestID = "request_id"
        }
    }

    public func createPublicToken(accessToken: String) -> Future<CreatePublicTokenResponse> {
        return requestWithAccessToken(accessToken, path: "/item/public_token/create")
    }

    // MARK: - Exchange Public Token (/item/public_token/exchange)

    public struct ExchangePublicTokenResponse: PlaidResponse {
        public let accessToken: String
        public let itemID: String
        public let requestID: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case itemID = "item_id"
            case requestID = "request_id"
        }
    }

    public func exchangePublicToken(_ publicToken: String) -> Future<ExchangePublicTokenResponse> {
        struct Parameters: Content {
            let publicToken: String

            enum CodingKeys: String, CodingKey {
                case publicToken = "public_token"
            }
        }

        return request(
            path: "/item/public_token/exchange",
            parameters: Parameters(publicToken: publicToken))
    }

    // MARK: - Update Access Token Version (/item/access_token/update_version)

    public struct UpdateAccessTokenVersionResponse: PlaidResponse {
        public let accessToken: String
        public let itemID: String
        public let requestID: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case itemID = "item_id"
            case requestID = "request_id"
        }
    }

    public func updateAccessTokenVersion(legacyAccessToken: String) -> Future<UpdateAccessTokenVersionResponse> {
        struct Parameters: Content {
            let accessTokenV1: String

            enum CodingKeys: String, CodingKey {
                case accessTokenV1 = "access_token_v1"
            }
        }

        return request(
            path: "/item/access_token/update_version",
            parameters: Parameters(accessTokenV1: legacyAccessToken))
    }

    // MARK: - Update Item Webhook (/item/webhook/update)

    public struct UpdateItemWebhookResponse: PlaidResponse {
        public let item: PlaidItem
        public let requestID: String

        enum CodingKeys: String, CodingKey {
            case item
            case requestID = "request_id"
        }
    }

    public func updateItemWebhook(accessToken: String, webhook: String) -> Future<UpdateItemWebhookResponse> {
        struct Parameters: Content {
            let accessToken: String
            let webhook: String

            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
                case webhook
            }
        }

        return request(
            path: "/item/webhook/update",
            parameters: Parameters(accessToken: accessToken, webhook: webhook))
    }

    // MARK: - Create Processor Token

    public struct CreateProcessorTokenResponse: PlaidResponse {
        public let requestID: String

        enum CodingKeys: String, CodingKey {
            case requestID = "request_id"
        }
    }

    public func createProcessorToken(accessToken: String, accountID: String, processor: PlaidProcessor) -> Future<CreateProcessorTokenResponse> {
        struct Parameters: Content {
            let accessToken: String
            let accountID: String

            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
                case accountID = "account_id"
            }
        }

        let endpoint: String
        switch processor {
        case .stripe:
            endpoint = "/processor/stripe/bank_account_token/create"
        case .processor(let name):
            endpoint = "/processor/\(name)/processor_token/create"
        }

        return request(
            path: endpoint,
            parameters: Parameters(accessToken: accessToken, accountID: accountID))
    }

    // MARK: - Invalidate Access Token (/item/access_token/invalidate)

    public struct InvalidateAccessTokenResponse: PlaidResponse {
        public let newAccessToken: String
        public let requestID: String

        enum CodingKeys: String, CodingKey {
            case newAccessToken = "new_access_token"
            case requestID = "request_id"
        }
    }

    public func invalidateAccessToken(_ accessToken: String) -> Future<InvalidateAccessTokenResponse> {
        return requestWithAccessToken(accessToken, path: "/item/access_token/invalidate")
    }

    // MARK: - Remove Item (/item/remove)

    public struct RemoveItemResponse: PlaidResponse {
        public let removed: Bool
        public let requestID: String

        enum CodingKeys: String, CodingKey {
            case removed
            case requestID = "request_id"
        }
    }

    public func removeItem(accessToken: String) -> Future<RemoveItemResponse> {
        return requestWithAccessToken(accessToken, path: "/item/remove")
    }

    // MARK: - Get Item (/item/get)

    public struct GetItemResponse: PlaidResponse {
        public let item: PlaidItem
        public let requestID: String

        enum CodingKeys: String, CodingKey {
            case item
            case requestID = "request_id"
        }
    }

    public func getItem(accessToken: String) -> Future<GetItemResponse> {
        return requestWithAccessToken(accessToken, path: "/item/get")
    }

    // TODO: The node client shows that there are options you can specify (in the function signature, you can pass an optional Object?)
    // MARK: - Get Accounts (/accounts/get)

    public struct GetAccountsResponse: PlaidResponse {
        public let accounts: [PlaidAccount]
        public let item: PlaidItem
        public let requestID: String

        enum CodingKeys: String, CodingKey {
            case accounts
            case item
            case requestID = "request_id"
        }
    }

    public func getAccounts(accessToken: String) -> Future<GetAccountsResponse> {
        return requestWithAccessToken(accessToken, path: "/accounts/get")
    }

    // MARK: - Get Account Balances (/accounts/balance/get)

    public struct GetAccountBalancesResponse: PlaidResponse {
        public let accounts: [PlaidAccount]
        public let item: PlaidItem
        public let requestID: String

        enum CodingKeys: String, CodingKey {
            case accounts
            case item
            case requestID = "request_id"
        }
    }

    public func getAccountBalances(accessToken: String, accountIDs: [String]) -> Future<GetAccountBalancesResponse> {
        return request(
            path: "/accounts/balance/get",
            parameters: AccountParameters(accessToken: accessToken, accountIDs: accountIDs))
    }

    // MARK: - Get Auth (/auth/get)

    public struct GetAuthResponse: PlaidResponse {
        public let accounts: [PlaidAccount]
        public let numbers: Numbers
        public let item: PlaidItem
        public let requestID: String

        enum CodingKeys: String, CodingKey {
            case accounts
            case numbers
            case item
            case requestID = "request_id"
        }

        public struct Numbers: Codable {
            public let ach: [ACH]
            public let etf: [ETF]

            public struct ACH: Content {
                public let account: String
                public let accountID: String
                public let routing: String
                public let wireRouting: String

                enum CodingKeys: String, CodingKey {
                    case account
                    case accountID = "account_id"
                    case routing
                    case wireRouting = "wire_routing"
                }
            }

            public struct ETF: Content {
                public let account: String
                public let accountID: String
                public let institution: String
                public let branch: String

                enum CodingKeys: String, CodingKey {
                    case account
                    case accountID = "account_id"
                    case institution
                    case branch
                }
            }
        }
    }

    public func getAuth(accessToken: String, accountIDs: [String]) -> Future<GetAuthResponse> {
        return request(
            path: "/auth/get",
            parameters: AccountParameters(accessToken: accessToken, accountIDs: accountIDs))
    }

    // MARK: - Get Identity (/identity/get)

    public struct GetIdentityResponse: PlaidResponse {
        public let accounts: [PlaidAccount]
        public let identity: Identity
        public let item: PlaidItem
        public let requestID: String

        enum CodingKeys: String, CodingKey {
            case accounts
            case identity
            case item
            case requestID = "request_id"
        }

        public struct Identity: Codable {
            public let addresses: [Address]
            public let emails: [Email]
            public let names: [String]
            public let phoneNumbers: [PhoneNumber]

            enum CodingKeys: String, CodingKey {
                case addresses
                case emails
                case names
                case phoneNumbers = "phone_numbers"
            }

            public struct Address: Codable {
                public let accounts: [String]
                public let data: Data
                public let primary: Bool

                public struct Data: Codable {
                    public let city: String
                    public let state: String
                    public let street: String
                    public let zip: String
                }
            }

            public struct Email: Codable {
                public let data: String
                public let primary: Bool
                public let type: String
            }

            public struct PhoneNumber: Codable {
                public let data: String
                public let primary: Bool
                public let type: String
            }
        }
    }

    public func getIdentity(accessToken: String) -> Future<GetIdentityResponse> {
        return requestWithAccessToken(accessToken, path: "/identity/get")
    }

    // MARK: - Get Income (/income/get)

    public struct GetIncomeResponse: PlaidResponse {
        public let income: Income
        public let requestID: String

        enum CodingKeys: String, CodingKey {
            case income
            case requestID = "request_id"
        }

        public struct Income: Codable {
            public let incomeStreams: [IncomeStream]
            public let lastYearIncome: Int
            public let lastYearIncomeBeforeTax: Int
            public let projectedYearlyIncome: Int
            public let projectedYearlyIncomeBeforeTax: String
            public let maxNumberOfOverlappingIncomeStreams: Int
            public let numberOfIncomeStreams: Int

            enum CodingKeys: String, CodingKey {
                case incomeStreams = "income_streams"
                case lastYearIncome = "last_year_income"
                case lastYearIncomeBeforeTax = "last_year_income_before_tax"
                case projectedYearlyIncome = "projected_yearly_income"
                case projectedYearlyIncomeBeforeTax = "projected_yearly_income_before_tax"
                case maxNumberOfOverlappingIncomeStreams = "max_number_of_overlapping_income_streams"
                case numberOfIncomeStreams = "number_of_income_streams"
            }

            public struct IncomeStream: Codable {
                public let confidence: Float
                public let days: Int
                public let monthlyIncome: Int
                public let name: String

                enum CodingKeys: String, CodingKey {
                    case confidence
                    case days
                    case monthlyIncome = "monthly_income"
                    case name
                }
            }
        }
    }

    public func getIncome(accessToken: String) -> Future<GetIncomeResponse> {
        return requestWithAccessToken(accessToken, path: "/income/get")
    }

    // MARK: - Get Transactions (/transactions/get)

    public struct GetTransactionsResponse: PlaidResponse {
        public let accounts: [PlaidAccount]
        public let transactions: [PlaidTransaction]
        public let item: PlaidItem
        public let totalTransactions: Int
        public let requestID: String

        enum CodingKeys: String, CodingKey {
            case accounts
            case transactions
            case item
            case totalTransactions = "total_transactions"
            case requestID = "request_id"
        }
    }

    /// - parameter count: The number of transactions to fetch, where 0 < `count` <= 500. Default = 100.
    /// - parameter offset: The number of transactions to skip, where `offset` >= 0. Default = 0.
    public func getTransactions(accessToken: String, startDate: Date, endDate: Date, accountIDs: [String] = [], count: Int = 100, offset: Int = 0) -> Future<GetTransactionsResponse> {
        struct Parameters: Content {
            let accessToken: String
            let startDate: Date
            let endDate: Date
            let options: Options?

            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
                case startDate = "start_date"
                case endDate = "end_date"
                case options
            }

            struct Options: Codable {
                let accountIDs: [String]?
                let count: Int
                let offset: Int

                enum CodingKeys: String, CodingKey {
                    case accountIDs = "account_ids"
                    case count
                    case offset
                }

                init(accountIDs: [String], count: Int, offset: Int) {
                    self.accountIDs = accountIDs.isEmpty ? nil : accountIDs
                    self.count = count
                    self.offset = offset
                }
            }
        }

        let parameters = Parameters(
            accessToken: accessToken,
            startDate: startDate,
            endDate: endDate,
            options: .init(accountIDs: accountIDs, count: count, offset: offset))

        return request(path: "/transactions/get", parameters: parameters)
    }

    // MARK: - Get All Transactions

    /// - parameter count: The number of transactions to fetch, where 0 < `count` <= 500. Default = 100.
    /// - parameter offset: The number of transactions to skip, where `offset` >= 0. Default = 0.
    public func getAllTransactions(accessToken: String, startDate: Date, endDate: Date, accountIDs: [String] = []) -> Future<[PlaidTransaction]> {
        return _getAllTransactions(accessToken: accessToken, startDate: startDate, endDate: endDate, accountIDs: accountIDs)
    }

    private func _getAllTransactions(accessToken: String, startDate: Date, endDate: Date, accountIDs: [String], transactions: [PlaidTransaction] = []) -> Future<[PlaidTransaction]> {
        return getTransactions(
            accessToken: accessToken,
            startDate: startDate,
            endDate: endDate,
            accountIDs: accountIDs,
            count: 500, // Max allowed
            offset: transactions.count)
            .flatMap(to: [PlaidTransaction].self) { response in
                let transactions = transactions + response.transactions
                if transactions.count >= response.totalTransactions {
                    // Terminate
                    return self.httpClient.container.eventLoop.newSucceededFuture(result: transactions)
                } else {
                    // Recurse
                    return self._getAllTransactions(accessToken: accessToken, startDate: startDate, endDate: endDate, accountIDs: accountIDs, transactions: transactions)
                }
        }
    }

    // TODO: v Finish all of the Asset Report calls later
    // MARK: - Create Asset Report (/asset_report/create)
    // MARK: - Get Asset Report (/asset_report/get)
    // MARK: - Get Asset Report PDF (/asset_report/pdf/get)
    // MARK: - Create Audit Copy (/asset_report/audit_copy/create)
    // MARK: - Remove Audit Copy (/asset_report/audit_copy/remove)
    // MARK: - Remove Asset Report (/asset_report/remove)

    // MARK: - Get Institutions (/institutions/get)

    public struct GetInstitutionsResponse: PlaidResponse {
        public let institutions: [PlaidInstitution]
        public let total: Int
        public let requestID: String

        enum CodingKeys: String, CodingKey {
            case institutions
            case total
            case requestID = "request_id"
        }
    }

    /// - parameter count: The number of institutions to fetch, where 0 < `count` <= 500. Default = 100.
    /// - parameter offset: The number of institutions to skip, where `offset` >= 0. Default = 0.
    public func getInstitutions(withProducts products: [PlaidProduct] = [], count: Int = 100, offset: Int = 0) -> Future<GetInstitutionsResponse> {
        struct Parameters: Content {
            let count: Int
            let offset: Int
            let options: Options

            struct Options: Codable {
                let products: [PlaidProduct]?

                init(products: [PlaidProduct]) {
                    self.products = products.isEmpty ? nil : products
                }
            }
        }

        return request(
            path: "/institutions/get",
            parameters: Parameters(count: count, offset: offset, options: .init(products: products)))
    }

    // MARK: - Get All Institutions

    public func getAllInstitutions(withProducts products: [PlaidProduct] = []) -> Future<[PlaidInstitution]> {
        return _getAllInstitutions(withProducts: products)
    }

    private func _getAllInstitutions(withProducts products: [PlaidProduct], institutions: [PlaidInstitution] = []) -> Future<[PlaidInstitution]> {
        return getInstitutions(
            withProducts: products,
            count: 500, // Max allowed
            offset: institutions.count)
            .flatMap(to: [PlaidInstitution].self) { response in
                let institutions = institutions + response.institutions
                if institutions.count >= response.total {
                    // Terminate
                    return self.httpClient.container.eventLoop.newSucceededFuture(result: institutions)
                } else {
                    // Recurse
                    return self._getAllInstitutions(withProducts: products, institutions: institutions)
                }
        }
    }

    // MARK: - Get Institution By ID (/institutions/get_by_id)

    public struct GetInstitutionResponse: PlaidResponse {
        public let institution: PlaidInstitution
        public let requestID: String

        enum CodingKeys: String, CodingKey {
            case institution
            case requestID = "request_id"
        }
    }

    public func getInstitution(byID institutionID: String) -> Future<GetInstitutionResponse> {
        struct Parameters: Content {
            let institutionID: String
            // TODO: There is options object, but no information on what it contains

            enum CodingKeys: String, CodingKey {
                case institutionID = "institution_id"
            }
        }

        return request(
            path: "/institutions/get_by_id",
            parameters: Parameters(institutionID: institutionID),
            authentication: .publicKey)
    }

    // MARK: - Search Institutions By Name (/institutions/search)

    public struct GetInstitutionsSearchResponse: PlaidResponse {
        public let institutions: [PlaidInstitution]
        public let requestID: String

        enum CodingKeys: String, CodingKey {
            case institutions
            case requestID = "request_id"
        }
    }

    public func getInstitutions(byName query: String, products: [PlaidProduct]) -> Future<GetInstitutionsSearchResponse> {
        struct Parameters: Content {
            let query: String
            let products: [PlaidProduct]
            // TODO: There is options object, but no information on what it contains
        }

        return request(
            path: "/institutions/search",
            parameters: Parameters(query: query, products: products),
            authentication: .publicKey)
    }

    // MARK: - Get Categories (/categories/get)

    public struct GetCategoriesResponse: PlaidResponse {
        public let categories: [Category]
        public let requestID: String

        enum CodingKeys: String, CodingKey {
            case categories
            case requestID = "request_id"
        }

        public struct Category: Codable {
            public let group: String
            public let hierarchy: [String]
            public let categoryID: String

            enum CodingKeys: String, CodingKey {
                case group
                case hierarchy
                case categoryID = "category_id"
            }
        }
    }

    public func getCategories() -> Future<GetCategoriesResponse> {
        return request(path: "/categories/get", parameters: NilParameters.nil, authentication: .none)
    }

}

// MARK: - Sandbox Only

extension PlaidClient {

    // MARK: - Sandbox Public Token Create (/sandbox/public_token/create)

    public struct Sandbox_CreatePublicTokenResponse: PlaidResponse {
        public let publicToken: String
        public let requestID: String

        enum CodingKeys: String, CodingKey {
            case publicToken = "public_token"
            case requestID = "request_id"
        }
    }

    public func sandbox_createPublicToken(institutionID: String, initialProducts: [PlaidProduct], webhook: String?) -> Future<Sandbox_CreatePublicTokenResponse> {
        struct Parameters: Content {
            let institutionID: String
            let initialProducts: [PlaidProduct]
            let options: Options?

            enum CodingKeys: String, CodingKey {
                case institutionID = "institution_id"
                case initialProducts = "initial_products"
                case options
            }

            struct Options: Codable {
                let webhook: String
            }
        }

        let parameters = Parameters(
            institutionID: institutionID,
            initialProducts: initialProducts,
            options: webhook.flatMap(Parameters.Options.init))

        return request(path: "/sandbox/public_token/create", parameters: parameters)
    }

    // MARK: - Reset Login (/sandbox/item/reset_login)

    public struct Sandbox_ResetItemLoginResponse: PlaidResponse {
        public let resetLogin: Bool
        public let requestID: String

        enum CodingKeys: String, CodingKey {
            case resetLogin = "reset_login"
            case requestID = "request_id"
        }
    }

    public func sanbox_resetItemLogin(accessToken: String) -> Future<Sandbox_ResetItemLoginResponse> {
        return requestWithAccessToken(accessToken, path: "/sandbox/item/reset_login")
    }
}

// MARK: - Undocumented and potentially unsupported

extension PlaidClient {

    // MARK: - Get Credit Details (/credit_details/get)

    // FIXME: I'm not entirely sure what this response actually looks like
    public struct GetCreditDetailsResponse: PlaidResponse {
        public let requestID: String

        enum CodingKeys: String, CodingKey {
            case requestID = "request_id"
        }
    }

    public func getCreditDetails(accessToken: String) -> Future<GetCreditDetailsResponse> {
        return requestWithAccessToken(accessToken, path: "/credit_details/get")
    }
}
