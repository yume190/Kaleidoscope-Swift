public enum BinaryOperator: Character {
    case plus = "+", minus = "-",
         times = "*", divide = "/",
         mod = "%", equals = "=",
         less = "<", great = ">"
}

extension BinaryOperator: Tokenable {
    public var token: Token {
        return .operator(self)
    }
}
