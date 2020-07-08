#if os(macOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif
import Token

public class Lexer {
    private final let input: String

    @inline(__always)
    public init(input: String) {
        self.input = input
    }
    
    @inline(__always)
    public final func lex() -> [Token] {
        return self.map{$0}
    }
}

extension Lexer {
    public class Iterator: IteratorProtocol {
        private final let input: String
        private final var index: String.Index
        @inline(__always)
        public init(input: String) {
            self.input = input
            self.index = input.startIndex
        }
        
        @inline(__always)
        public func next() -> Token? {
            // Skip all spaces until a non-space token
            while let char = currentChar, char.isSpace || char.isNewLine {
                self.advance()
            }
            
            // If we hit the end of the input, then we're done
            guard let char = self.currentChar else {
                return nil
            }
        
            return
                self._charToken(char) ??
                self._identifierToken(char) ??
                self._commentToken(char) ??
                self._otherToken(char)
        }
    }
}

extension Lexer.Iterator {
    @inline(__always)
    private final var currentChar: Character? {
        return index < input.endIndex ? input[index] : nil
    }

    @inline(__always)
    private func readIdentifierOrNumber() -> String {
        var str = ""
        while let char = currentChar, char.isAlphanumeric || char == "." {
            str.append(char)
            self.advance()
        }
        return str
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
    private func _otherToken(_ char: Character) -> Token? {
        if char.isASCII {
            defer{ advance() }
            return .other(char)
        }
        
        return nil
    }
}

// MARK: Index move
extension Lexer.Iterator {
    @inline(__always)
    private final func advance() {
        self.index = self.input.index(after: self.index)
    }
    
    @inline(__always)
    private final func before() {
        self.index = self.input.index(before: self.index)
    }
}

extension Lexer: Sequence {
    public __consuming func makeIterator() -> Lexer.Iterator {
        return Iterator(input: self.input)
    }
}
