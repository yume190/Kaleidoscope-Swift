public enum Token {
    case keyword(Keyword)
    case `operator`(BinaryOperator)
    case mark(Mark)

    case identifier(String)
    case number(Double)
    case comment(String)
}

extension Token: Equatable {}

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
        }
    }
}
