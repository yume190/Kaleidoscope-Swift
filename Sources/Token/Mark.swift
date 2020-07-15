public enum Mark: Character {
    /// (
    case openParen = "("
    /// )
    case closeParen = ")"
    
    /// [
    case openSquareBracket = "["
    /// ]
    case closeSquareBracket = "]"
    
    /// {
    case openCurlyBracket = "{"
    /// }
    case closeCurlyBracket = "}"

    /// ,
    case comma = ","
    /// ;
    case semicolon = ";"
}

extension Mark: Tokenable {
    public var token: Token {
        return .mark(self)
    }
}
