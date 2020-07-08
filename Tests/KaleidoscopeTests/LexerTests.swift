import XCTest
import class Foundation.Bundle
@testable import Lexer
@testable import Token

final class LexerTests: XCTestCase {
    func testFullCode1() throws {
        let code = """
        def fib(x)
          if x < 3 then
            1
          else
            fib(x-1)+fib(x-2)

        fib(40)
        """

        let tokens = Lexer(input: code).lex()
        XCTAssertEqual(tokens.count, 29)
        XCTAssertEqual(tokens[0], Token.keyword(.def))
        XCTAssertEqual(tokens[28], Token.mark(.closeParen))
    }
    
    func testComment() {
        let code = "# Compute the x'th fibonacci number."

        let tokens = Lexer(input: code).lex()
        XCTAssertEqual(tokens.count, 1)
        XCTAssertEqual(tokens[0], Token.comment("# Compute the x'th fibonacci number."))
    }
    
    func testUnary() {
        let code = """
        def unary!(v)
          1;
        """
        
        let tokens = Lexer(input: code).lex()
        XCTAssertEqual(tokens.count, 8)
    }
    
    func testBinary() {
        let code = """
        def binary| 5 (LHS RHS)
          1;
        """
        
        let tokens = Lexer(input: code).lex()
        XCTAssertEqual(tokens.count, 10)
    }

    static var allTests = [
        ("testFullCode1", testFullCode1),
        ("testComment", testComment)
    ]
}
