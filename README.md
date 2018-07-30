# Plaid Provider

This is an experimental Vapor provider for the Plaid API.

## API

| Plaid Endpoint                                  | Plaid Provider                                                                                                                       |
|-------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------|
| `/item/public_token/exchange`                   | `exchangePublicToken(_ publicToken: String)`                                                                                         |
| `/item/public_token/create`                     | `createPublicToken(accessToken: String)`                                                                                             |
| `/accounts/get`                                 | `getAccounts(accessToken: String)`                                                                                                   |
| `/item/get`                                     | `getItem(accessToken: String)`                                                                                                       |
| `/item/webhook/update`                          | `updateItemWebhook(accessToken: String, webhook: URL)`                                                                               |
| `/item/access_token/invalidate`                 | `invalidateAccessToken(_ accessToken: String)`                                                                                       |
| `/item/access_token/update_version`             | `updateAccessTokenVersion(legacyAccessToken: String)`                                                                                |
| `/item/remove`                                  | `removeItem(accessToken: String)`                                                                                                    |
| `/auth/get`                                     | `getAuth(accessToken: String, accountIDs: [String])`                                                                                 |
| `/transactions/get`                             | ```swift
getTransactions(accessToken: String, startDate: Date, endDate: Date, accountIDs: [String] = [], count: Int = 100, offset: Int = 0)
``` |
| `/transactions/get` (Get All)                   | `getAllTransactions(accessToken: String, startDate: Date, endDate: Date, accountIDs: [String] = [])`                                 |
| `/accounts/balance/get`                         | `getAccountBalances(accessToken: String, accountIDs: [String])`                                                                      |
| `/identity/get`                                 | `getIdentity(accessToken: String)`                                                                                                   |
| `/income/get`                                   | `getIncome(accessToken: String)`                                                                                                     |
| `/asset_report/get`                             | -                                                                                                                                    |
| `/asset_report/pdf/get`                         | -                                                                                                                                    |
| `/asset_report/create`                          | -                                                                                                                                    |
| `/asset_report/remove`                          | -                                                                                                                                    |
| `/asset_report/audit_copy/create`               | -                                                                                                                                    |
| `/asset_report/audit_copy/remove`               | -                                                                                                                                    |
| `/institutions/get`                             | `getInstitutions(withProducts products: [PlaidProduct] = [], count: Int = 100, offset: Int = 0)`                                     |
| `/institutions/get` (Get All)                   | `getAllInstitutions(withProducts products: [PlaidProduct] = [])`                                                                     |
| `/institutions/get_by_id`                     | `getInstitution(byID institutionID: String)`                                                                                         |
| `/institutions/search`                          | `getInstitutions(byName query: String, products: [PlaidProduct])`                                                                    |
| `/categories/get`                               | `getCategories()`                                                                                                                    |
| *Not Documented*                                |                                                                                                                                      |
| `/item/create`                                  | `createItem(usingCredentials credentials: Credentials, institutionID: String, initialProducts: Set)`                                 |
| `/item/mfa`                                     | `answerItemMFA(accessToken: String, mfaType: String, responses: [String])`                                                           |
| `/item/credentials/update`                      | `updateItemCredentials(accessToken: String, credentials: Credentials)`                                                               |
| `/processor/stripe/bank_account_token/create` | `createProcessorToken(accessToken: String, accountID: String, processor: PlaidProcessor.stripe)`                                     |
| `/processor/PROCESSOR/processor_token/create`   | `createProcessorToken(accessToken: String, accountID: String, processor: PlaidProcessor.processor("PROCESSOR")`                      |
| `/item/delete`                                  | `deleteItem(accessToken: String)`                                                                                                    |
| `/credit_details/get`                           | `getCreditDetails(accessToken: String)`                                                                                              |
| `/sandbox/public_token/create`                  | `sandbox_createPublicToken(institutionID: String, initialProducts: [PlaidProduct], webhook: URL?)`                                   |
| `/sandbox/item/reset_login`                     | `sanbox_resetItemLogin(accessToken: String)`                                                                                         |