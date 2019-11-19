/// L5 Lexer Extensions for If/Then/Else
public enum Keyword: String {
    case def
    case extern
    
    case `if`
    case then
    case `else`
}

extension Keyword: Tokenable {
    public var token: Token {
        return .keyword(self)
    }
}
