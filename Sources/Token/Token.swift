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

//public extension Token {
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
//    var char: Character? {
//        switch self {
//        case let .keyword(keyword): return keyword.rawValue.first
//        case let .operator(op): return op.rawValue
//        case let .mark(mark): return mark.rawValue
//        case let .identifier(id): return id.first
//        case let .number(num): return "\(num)".first
//        case let .comment(comment): return comment.first
//        case let .other(char): return char
//        }
//    }
//}

extension Token: CustomStringConvertible {
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
