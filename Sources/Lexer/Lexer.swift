#if os(macOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

// extension Character {
//     var value: Int32 {
//         return Int32(String(self).unicodeScalars.first!.value)
//     }
//     var isSpace: Bool {
//         return isspace(value) != 0
//     }
//     var isAlphanumeric: Bool {
//         return isalnum(value) != 0 || self == "_"
//     }
// }

extension Character {
    var value: Int32 {
        return Int32(String(self).unicodeScalars.first!.value)
    }
    var isSpace: Bool {
        return isspace(value) != 0
    }
    
    var isNewLine: Bool {
        return self == "\n" || self == "\r"
    }
    var isAlphanumeric: Bool {
        return isalnum(value) != 0 || self == "_"
    }
}

public class Lexer {
    private final let input: String
    private final var index: String.Index

    @inline(__always)
    public init(input: String) {
        self.input = input
        self.index = input.startIndex
    }

    @inline(__always)
    private final var currentChar: Character? {
        return index < input.endIndex ? input[index] : nil
    }
    // private final var current: TokenType? {
    //     guard let char = self.currentChar else {
    //         return nil
    //     }
    //     return TokenType(rawValue: char)
    // }
    
    // private final var identifier: String {
    //     var str = ""
    //     while let char = currentChar, char.isAlphanumeric || Self.identifierChar.contains(char) {
    //         str.append(char);advance()
    //     }
        
    //     return str
    // }

    @inline(__always)
    private func readIdentifierOrNumber() -> String {
        var str = ""
        while let char = currentChar, char.isAlphanumeric || char == "." {
            str.append(char)
            advance()
        }
        return str
    }

    @inline(__always)
    private final var next: Token? {
        // Skip all spaces until a non-space token
        while let char = currentChar, char.isSpace || char.isNewLine {
            advance()
        }
        // If we hit the end of the input, then we're done
        guard let char = currentChar else {
            return nil
        }
    
        return
            self._charToken(char) ??
            self._identifierToken(char) ??
            self._commentToken(char)
    }

    @inline(__always)
    private func _markToken(_ char: Character) -> Token? {
        return Mark(rawValue: char)?.token
    }

    @inline(__always)
    private func _operatorToken(_ char: Character) -> Token? {
        return BinaryOperator(rawValue: char)?.token
    }

    @inline(__always)
    private func _charToken(_ char: Character) -> Token? {
        let token = self._markToken(char) ?? self._operatorToken(char)
        defer {
            if token != nil {self.advance()}
        }
        return token
    }

    @inline(__always)
    private func _identifierToken(_ char: Character) -> Token? {
        if char.isAlphanumeric {
            let str = readIdentifierOrNumber()

            if let dbl = Double(str) {
                return .number(dbl)
            }

            return Keyword(rawValue: str)?.token ?? .identifier(str)
        }
        return nil
    }
    
    
//    if (LastChar == '#') {
//      // Comment until end of line.
//      do
//        LastChar = getchar();
//      while (LastChar != EOF && LastChar != '\n' && LastChar != '\r');
//
//      if (LastChar != EOF)
//        return gettok();
//    }
    @inline(__always)
    private func _commentToken(_ char: Character) -> Token? {
        if char == "#" {
            var text = ""
            while let char = currentChar, !char.isNewLine {
                text.append(char)
                advance()
            }
            return .comment(text)
        }
        return nil
    }

    @inline(__always)
    public final func lex() -> [Token] {
        var toks = [Token]()
        while let tok = self.next {
            toks.append(tok)
        }
        return toks
    }
}

// MARK: Index move
extension Lexer {
    @inline(__always)
    private final func advance() {
        self.index = self.input.index(after: self.index)
    }
    
    @inline(__always)
    private final func before() {
        self.index = self.input.index(before: self.index)
    }
}
