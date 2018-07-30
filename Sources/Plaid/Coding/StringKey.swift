import Foundation

struct StringKey: CodingKey {
    let stringValue: String
    let intValue: Int? = nil

    init(_ string: String) {
        self.stringValue = string
    }

    init?(stringValue: String) {
        self.init(stringValue)
    }

    init?(intValue: Int) {
        return nil
    }
}
