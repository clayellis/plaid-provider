import Foundation

extension Data {
    /// Returns a pretty-printed string representation of the JSON data.
    func prettyPrinted(encoding: String.Encoding = .ascii) -> String? {
        if let dataAsJSON = try? JSONSerialization.jsonObject(with: self, options: .allowFragments) {
            return (try? JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted))
                .flatMap { String(data: $0, encoding: encoding) }
        } else {
            return String(data: self, encoding: encoding)
        }
    }
}
