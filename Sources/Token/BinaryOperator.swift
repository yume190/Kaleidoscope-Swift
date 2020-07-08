public enum BinaryOperator: Character {
    case plus = "+", minus = "-",
         times = "*", divide = "/",
         mod = "%", equals = "=",
         less = "<", great = ">"
}
public typealias Precedence = Int

extension BinaryOperator: Tokenable {
    public var token: Token {
        return .operator(self)
    }
}

extension BinaryOperator: CustomStringConvertible {
    public var description: String {
        return String(self.rawValue)
    }
}
