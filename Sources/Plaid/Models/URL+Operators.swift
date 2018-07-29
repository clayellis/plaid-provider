import Foundation

extension URL {
    static func / (url: URL, pathComponent: String) -> URL {
        return url.appendingPathComponent(pathComponent, isDirectory: false)
    }
}
