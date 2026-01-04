public enum ButtonState: Int32, Sendable {
    case released
    case pressed
    case repeated
    init(_ rawValue: Int32) {
        switch rawValue {
            case 0: self = .released
            case 1: self = .pressed
            case 2: self = .repeated
            default: self = .released
        }
    }
}
