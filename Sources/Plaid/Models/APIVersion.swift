public enum PlaidAPIVersion {
    case v2018_05_22

    var versionString: String {
        switch self {
        case .v2018_05_22: return "2018-05-22"
        }
    }
}
