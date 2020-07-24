public enum Token {
    case keyword(Keyword)
    case `operator`(BinaryOperator)
    case mark(Mark)

    case identifier(String)
    case number(Double)
    case comment(String)
    
    case other(Character)
}

extension Token: Equatable {}

public extension Token {
//    var string: String {
//        switch self {
//        case let .keyword(keyword): return keyword.rawValue
//        case let .operator(op): return String(op.rawValue)
//        case let .mark(mark): return String(mark.rawValue)
//        case let .identifier(id): return id
//        case let .number(num): return "\(num)"
//        case let .comment(comment): return comment
//        case let .other(char): return String(char)
//        }
//    }
//    
    var char: Character? {
        switch self {
        case .keyword(_): return nil
        case let .operator(op): return op.rawValue
        case let .mark(mark): return mark.rawValue
        case .identifier(_): return nil
        case .number(_): return nil
        case .comment(_): return nil
        case let .other(char): return char
        }
    }
    var isASCII: Bool {
        switch self {
        case .keyword(_): return false
        case let .operator(op): return op.rawValue.isASCII
        case let .mark(mark): return mark.rawValue.isASCII
        case .identifier(_): return false
        case .number(_): return false
        case .comment(_): return false // don't care
        case let .other(char): return char.isASCII
        }
    }
}

extension Token: CustomStringConvertible {
    public var raw: String {
        switch self {
        case .keyword(let kw):
            return kw.rawValue
        case .operator(let op):
            return "\(op.rawValue)"
        case .mark(let m):
            return "\(m.rawValue)"
        case .identifier(let id):
            return id
        case .number(let num):
            return "\(num)"
        case .comment(let c):
            return "# \(c)"
        case let .other(char):
            return "\(char)"
        }
    }

    public var description: String {
        switch self {
        case .keyword(let kw):
            return "keyword: \(kw)"
        case .operator(let op):
            return "operator: \(op)"
        case .mark(let m):
            return "mark: \(m)"
        case .identifier(let id):
            return "identifier: \(id)"
        case .number(let num):
            return "number: \(num)"
        case .comment(let c):
            return "comment: \(c)"
        case let .other(char):
            return String(char)
        }
    }
}
