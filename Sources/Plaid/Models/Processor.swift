public enum PlaidProcessor {
    case stripe
    case processor(String)

    var processorName: String {
        switch self {
        case .stripe: return "stripe"
        case .processor(let name): return name
        }
    }
}
