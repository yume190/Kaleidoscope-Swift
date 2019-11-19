public enum Token {
    case keyword(Keyword)
    case `operator`(BinaryOperator)
    case mark(Mark)

    case identifier(String)
    case number(Double)
    case comment(String)
}

extension Token: Equatable {}
