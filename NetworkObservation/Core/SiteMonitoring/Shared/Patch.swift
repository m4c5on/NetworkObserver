nonisolated enum Patch<T> {
    case keep
    case clear
    case set(T)

    func resolved(current: T?) -> T? {
        switch self {
        case .keep: current
        case .clear: nil
        case .set(let value): value
        }
    }
}
