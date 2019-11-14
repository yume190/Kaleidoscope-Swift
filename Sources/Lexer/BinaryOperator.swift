public enum BinaryOperator: Character {
    case plus = "+", minus = "-",
         times = "*", divide = "/",
         mod = "%", equals = "=",
         less = "<", great = ">"
}

extension BinaryOperator: Tokenable {
    var token: Token {
        return .operator(self)
    }
}
