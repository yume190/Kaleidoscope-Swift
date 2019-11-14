public enum Keyword: String {
    case def
    case extern
    
    case `if`
    case then
    case `else`
}

extension Keyword: Tokenable {
    var token: Token {
        return .keyword(self)
    }
}
